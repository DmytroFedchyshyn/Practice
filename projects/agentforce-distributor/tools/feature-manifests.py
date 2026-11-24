#!/usr/bin/env python3
"""Writes one manifest per feature from the features of project.config.json
(docs/engineering/development-foundation.md §1.4 *Deploying by feature*).

    python3 tools/feature-manifests.py           # write manifest/features/<slug>.xml
    python3 tools/feature-manifests.py --check   # write nothing; stop when a manifest is out of date

Every component of the build folder belongs to one feature. A feature in project.config.json has:

    slug        the manifest's name, manifest/features/<slug>.xml
    label       a human name
    dependsOn   the slugs of the features that must be in an org before this one
    paths       globs relative to the build folder: "classes/AcmeInvoice*", "objects/Invoice__c",
                "lwc/acmeInvoice*", "**". A glob that names a folder or a bundle takes everything in it.
    members     optional, "Type:FullName" globs for components that share a file with others:
                "CustomLabel:Acme_Invoice_*", "SharingCriteriaRule:Account.Acme_*".

When several features match a component, the most specific pattern wins: a `members` pattern before a
`paths` glob, then the pattern with the most literal characters. So a catch-all feature (`"paths": ["**"]`)
takes what no other feature names. Two features matching with equally specific patterns is an error.

The script stops, and writes nothing, when a component matches no feature, when two features tie for it,
when a feature names an unknown dependency or the dependencies form a cycle. `tools/deploy-build.sh
--feature` runs it with --check first. Python 3.10+, standard library only.
"""

import json
import re
import sys
import xml.etree.ElementTree as ET
from fnmatch import fnmatchcase
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = json.loads((ROOT / "project.config.json").read_text())
SRC = CONFIG["buildDir"].rstrip("/")
OUT = "manifest/features"

# Folders of the build whose components are one file each: folder → (type, file suffix).
FILES = {
    "aiEvaluationDefinitions": ("AiEvaluationDefinition", ".aiEvaluationDefinition-meta.xml"),
    "applications": ("CustomApplication", ".app-meta.xml"),
    "classes": ("ApexClass", ".cls"),
    "customMetadata": ("CustomMetadata", ".md-meta.xml"),
    "customPermissions": ("CustomPermission", ".customPermission-meta.xml"),
    "enablementProgramDefinitions": ("EnablementProgramDefinition", ".enablementProgramDefinition-meta.xml"),
    "flexipages": ("FlexiPage", ".flexipage-meta.xml"),
    "flows": ("Flow", ".flow-meta.xml"),
    "forecastingFilterConditions": ("ForecastingFilterCondition", ".forecastingFilterCondition-meta.xml"),
    "forecastingFilters": ("ForecastingFilter", ".forecastingFilter-meta.xml"),
    "forecastingSourceDefinitions": ("ForecastingSourceDefinition", ".forecastingSourceDefinition-meta.xml"),
    "forecastingTypeSources": ("ForecastingTypeSource", ".forecastingTypeSource-meta.xml"),
    "forecastingTypes": ("ForecastingType", ".forecastingType-meta.xml"),
    "genAiPlugins": ("GenAiPlugin", ".genAiPlugin-meta.xml"),
    "genAiPromptTemplates": ("GenAiPromptTemplate", ".genAiPromptTemplate-meta.xml"),
    "groups": ("Group", ".group-meta.xml"),
    "layouts": ("Layout", ".layout-meta.xml"),
    "navigationMenus": ("NavigationMenu", ".navigationMenu-meta.xml"),
    "networks": ("Network", ".network-meta.xml"),
    "notificationtypes": ("CustomNotificationType", ".notiftype-meta.xml"),
    "permissionsetgroups": ("PermissionSetGroup", ".permissionsetgroup-meta.xml"),
    "permissionsets": ("PermissionSet", ".permissionset-meta.xml"),
    "profiles": ("Profile", ".profile-meta.xml"),
    "queues": ("Queue", ".queue-meta.xml"),
    "quickActions": ("QuickAction", ".quickAction-meta.xml"),
    "reportTypes": ("ReportType", ".reportType-meta.xml"),
    "roles": ("Role", ".role-meta.xml"),
    "sharingSets": ("SharingSet", ".sharingSet-meta.xml"),
    "sites": ("CustomSite", ".site-meta.xml"),
    "staticresources": ("StaticResource", ".resource-meta.xml"),
    "tabs": ("CustomTab", ".tab-meta.xml"),
    "triggers": ("ApexTrigger", ".trigger"),
}
# Folders whose components are a folder each. An Agentforce agent written in Agent Script is an
# AiAuthoringBundle; GenAiFunction and GenAiPlannerBundle are what the platform generates or older agents
# hold. Bot is not listed: the CLI splits it into a Bot and its BotVersions, which this script does not model.
BUNDLES = {
    "aiAuthoringBundles": "AiAuthoringBundle",
    "aura": "AuraDefinitionBundle",
    "experiences": "ExperienceBundle",
    "genAiFunctions": "GenAiFunction",
    "genAiPlannerBundles": "GenAiPlannerBundle",
    "lwc": "LightningComponentBundle",
}
FOLDERED = {"reports": ("Report", ".report-meta.xml", ".reportFolder-meta.xml"),
            "dashboards": ("Dashboard", ".dashboard-meta.xml", ".dashboardFolder-meta.xml")}
OBJECT_CHILDREN = {
    "compactLayouts": ("CompactLayout", ".compactLayout-meta.xml"),
    "fields": ("CustomField", ".field-meta.xml"),
    "listViews": ("ListView", ".listView-meta.xml"),
    "validationRules": ("ValidationRule", ".validationRule-meta.xml"),
}
SHARING_RULES = {"sharingCriteriaRules": "SharingCriteriaRule", "sharingOwnerRules": "SharingOwnerRule"}
NS = {"md": "http://soap.sforce.com/2006/04/metadata"}
# What `sf` leaves out of a deployment without being told, on top of .forceignore.
DEFAULT_IGNORE = ["**/.DS_Store", "**/jsconfig.json", "**/.eslintrc.json", "**/__tests__/**"]


class Stop(Exception):
    pass


def ignore_patterns():
    """The patterns of .forceignore and sf's defaults, as regular expressions on a path from the repository root."""
    lines = (ROOT / ".forceignore").read_text().splitlines() + DEFAULT_IGNORE
    patterns = []
    for line in (l.strip() for l in lines):
        if not line or line.startswith(("#", "!")):
            continue
        glob, regex, i = line.strip("/"), "", 0
        while i < len(glob):
            if glob.startswith("**/", i):
                regex, i = regex + "(?:.*/)?", i + 3
            elif glob.startswith("**", i):
                regex, i = regex + ".*", i + 2
            else:
                regex += {"*": "[^/]*", "?": "[^/]"}.get(glob[i], re.escape(glob[i]))
                i += 1
        if not line.startswith("/") and "/" not in glob:
            regex = "(?:.*/)?" + regex
        patterns.append(re.compile(regex + "(?:/.*)?$"))
    return patterns


def part_of_component(path):
    """A trigger's -meta.xml beside its body, or a static resource's file or folder beside its -meta.xml."""
    if path.name.endswith("-meta.xml") and path.with_name(path.name[: -len("-meta.xml")]).exists():
        return True
    return path.with_name(path.stem + ".resource-meta.xml").exists()


def components():
    """(type, full name, path) of every component in the build folder, named as the Metadata API names them.

    A file the script does not know stops it, unless .forceignore keeps it out of a deployment, so a new kind
    of component is added here rather than left out of every feature. The containers CustomLabels and
    SharingRules are left out: a manifest names their labels and rules, and a deployment carries only those.
    """
    found, unknown = [], []
    src = ROOT / SRC
    for folder in sorted(p for p in src.iterdir() if p.is_dir()):
        name = folder.name
        if name == "vendor":
            # Third-party code, one folder per library (docs/engineering/architecture.md §5): only its Apex
            # classes are components.
            for path in sorted(p for p in folder.rglob("*") if p.is_file()):
                if path.suffix == ".cls":
                    found.append(("ApexClass", path.stem, path))
                elif not part_of_component(path):
                    unknown.append(path)
        elif name in FILES:
            kind, suffix = FILES[name]
            for path in sorted(folder.iterdir()):
                if path.name.endswith(suffix):
                    found.append((kind, path.name[: -len(suffix)], path))
                elif not part_of_component(path):
                    unknown.append(path)
        elif name in BUNDLES:
            for path in sorted(folder.iterdir()):
                if path.is_dir():
                    found.append((BUNDLES[name], path.name, path))
                elif not (name == "experiences" and path.name.endswith(".site-meta.xml")):
                    unknown.append(path)
        elif name in FOLDERED:
            kind, suffix, folder_suffix = FOLDERED[name]
            for path in sorted(folder.rglob("*")):
                rel = path.relative_to(folder).as_posix()
                if path.is_dir():
                    continue
                if rel.endswith(folder_suffix):
                    # A folder is named with a trailing slash, as `sf project generate manifest` names it.
                    found.append((kind, rel[: -len(folder_suffix)] + "/", path))
                elif rel.endswith(suffix):
                    found.append((kind, rel[: -len(suffix)], path))
                else:
                    unknown.append(path)
        elif name == "objects":
            for obj in sorted(p for p in folder.iterdir() if p.is_dir()):
                for path in sorted(obj.rglob("*")):
                    if path.is_dir():
                        continue
                    parts = path.relative_to(obj).parts
                    if parts == (obj.name + ".object-meta.xml",):
                        found.append(("CustomObject", obj.name, path))
                    elif len(parts) == 2 and parts[0] in OBJECT_CHILDREN and parts[1].endswith(OBJECT_CHILDREN[parts[0]][1]):
                        kind, suffix = OBJECT_CHILDREN[parts[0]]
                        found.append((kind, f"{obj.name}.{parts[1][: -len(suffix)]}", path))
                    else:
                        unknown.append(path)
        elif name == "labels":
            for path in sorted(folder.iterdir()):
                if not path.name.endswith(".labels-meta.xml"):
                    unknown.append(path)
                    continue
                for label in ET.parse(path).getroot().findall("md:labels/md:fullName", NS):
                    found.append(("CustomLabel", label.text, path))
        elif name == "sharingRules":
            for path in sorted(folder.iterdir()):
                if not path.name.endswith(".sharingRules-meta.xml"):
                    unknown.append(path)
                    continue
                obj = path.name[: -len(".sharingRules-meta.xml")]
                for rule in ET.parse(path).getroot():
                    tag = rule.tag.split("}")[-1]
                    if tag not in SHARING_RULES:
                        raise Stop(f"{path.relative_to(ROOT)}: {tag} is a kind of sharing rule this script does not "
                                   f"know; add it to SHARING_RULES")
                    found.append((SHARING_RULES[tag], f"{obj}.{rule.find('md:fullName', NS).text}", path))
        else:
            unknown.extend(p for p in folder.rglob("*") if p.is_file())
    ignored = ignore_patterns()
    unknown = [p for p in unknown if not any(i.match(p.relative_to(ROOT).as_posix()) for i in ignored)]
    if unknown:
        raise Stop("\n".join(f"{p.relative_to(ROOT)}: a kind of component this script does not know; add it to "
                             f"FILES, BUNDLES, FOLDERED or OBJECT_CHILDREN" for p in unknown))
    return [(kind, name, path.relative_to(ROOT).as_posix()) for kind, name, path in found]


def glob_regex(glob):
    """A path glob as a regular expression: ** any depth, * and ? within one segment; a glob also takes
    everything inside the folder or bundle it names."""
    regex, i = "", 0
    glob = glob.strip("/")
    while i < len(glob):
        if glob.startswith("**/", i):
            regex, i = regex + "(?:.*/)?", i + 3
        elif glob.startswith("**", i):
            regex, i = regex + ".*", i + 2
        else:
            regex += {"*": "[^/]*", "?": "[^/]"}.get(glob[i], re.escape(glob[i]))
            i += 1
    return re.compile(regex + "(?:/.*)?$")


def literal_length(pattern):
    return len(re.sub(r"[*?]", "", pattern))


def features():
    """The features in deploy order: each after the ones it depends on, otherwise as listed."""
    listed = CONFIG.get("features") or []
    if not listed:
        raise Stop("project.config.json has no features: add at least one, for example a catch-all with paths [\"**\"]")
    by_slug, gaps = {}, []
    for feature in listed:
        slug = feature.get("slug", "")
        if not re.fullmatch(r"[a-z][a-z0-9-]*", slug):
            gaps.append(f"feature slug '{slug}': lower-case letters, digits and hyphens, starting with a letter")
        elif slug in by_slug:
            gaps.append(f"feature '{slug}' is listed twice")
        by_slug[slug] = feature
        if not feature.get("paths") and not feature.get("members"):
            gaps.append(f"feature '{slug}' has neither paths nor members")
    for feature in listed:
        for dependency in feature.get("dependsOn", []):
            if dependency not in by_slug:
                gaps.append(f"feature '{feature['slug']}' depends on '{dependency}', which is not a feature")
    if gaps:
        raise Stop("\n".join(gaps))
    ordered, state = [], {}

    def visit(slug, trail):
        if state.get(slug) == "done":
            return
        if state.get(slug) == "visiting":
            raise Stop(f"features depend on each other in a cycle: {' -> '.join(trail + [slug])}")
        state[slug] = "visiting"
        for dependency in by_slug[slug].get("dependsOn", []):
            visit(dependency, trail + [slug])
        state[slug] = "done"
        ordered.append(by_slug[slug])

    for feature in listed:
        visit(feature["slug"], [])
    return ordered


def owners(ordered):
    """The feature slug of every component, or Stop naming each component without exactly one."""
    rules = []
    for feature in ordered:
        for pattern in feature.get("paths", []):
            rules.append((feature["slug"], 0, literal_length(pattern), pattern, "path", glob_regex(pattern)))
        for pattern in feature.get("members", []):
            rules.append((feature["slug"], 1, literal_length(pattern), pattern, "member", None))
    owned, gaps = {}, []
    for component in components():
        kind, full, path = component
        rel = path[len(SRC) + 1:]
        hits = []
        for slug, rank, length, pattern, how, regex in rules:
            if how == "path" and regex.match(rel) or how == "member" and fnmatchcase(f"{kind}:{full.rstrip('/')}", pattern):
                hits.append((rank, length, slug, pattern))
        if not hits:
            gaps.append(f"{kind} {full} ({path}): no feature in project.config.json matches it")
            continue
        best = max((rank, length) for rank, length, _, _ in hits)
        winners = sorted({(slug, pattern) for rank, length, slug, pattern in hits if (rank, length) == best})
        if len({slug for slug, _ in winners}) > 1:
            gaps.append(f"{kind} {full} ({path}): features tie for it: "
                        + ", ".join(f"{slug} ({pattern})" for slug, pattern in winners))
        else:
            owned[component] = winners[0][0]
    if gaps:
        raise Stop("\n".join(gaps))
    return owned


def manifests():
    version = json.loads((ROOT / "sfdx-project.json").read_text())["sourceApiVersion"]
    ordered = features()
    by_feature = {}
    for (kind, full, _), slug in owners(ordered).items():
        by_feature.setdefault(slug, {}).setdefault(kind, set()).add(full)
    result = {}
    for feature in ordered:
        slug = feature["slug"]
        if slug not in by_feature:
            continue
        lines = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            f"<!-- Feature {feature.get('label', slug)}: generated from project.config.json by tools/feature-manifests.py; do not edit. -->",
            '<Package xmlns="http://soap.sforce.com/2006/04/metadata">',
        ]
        for kind in sorted(by_feature[slug]):
            lines.append("    <types>")
            lines += [f"        <members>{member}</members>" for member in sorted(by_feature[slug][kind])]
            lines += [f"        <name>{kind}</name>", "    </types>"]
        lines += [f"    <version>{version}</version>", "</Package>", ""]
        result[f"{OUT}/{slug}.xml"] = "\n".join(lines)
    return result


def main():
    check = sys.argv[1:] == ["--check"]
    if sys.argv[1:] not in ([], ["--check"]):
        sys.exit("usage: tools/feature-manifests.py [--check]")
    try:
        if not (ROOT / SRC).is_dir():
            raise Stop(f"{SRC}: the build folder named in project.config.json does not exist")
        wanted = manifests()
    except Stop as reason:
        print(f"feature-manifests: stopped, nothing written.\n{reason}", file=sys.stderr)
        sys.exit(1)
    present = {p.relative_to(ROOT).as_posix() for p in (ROOT / OUT).glob("*.xml")}
    stale = sorted(p for p in wanted if p not in present or (ROOT / p).read_text() != wanted[p])
    extra = sorted(present - set(wanted))
    if check:
        if stale or extra:
            print("feature-manifests: out of date — run tools/feature-manifests.py and commit the result: "
                  + ", ".join(stale + extra), file=sys.stderr)
            sys.exit(1)
        print(f"feature-manifests: every manifest matches project.config.json ({len(wanted)} with components)")
        return
    (ROOT / OUT).mkdir(parents=True, exist_ok=True)
    for path in stale:
        (ROOT / path).write_text(wanted[path])
    for path in extra:
        (ROOT / path).unlink()
    for path, text in wanted.items():
        members = re.findall(r"<members>([^<]+)</members>", text)
        tests = re.findall(r"<members>(\w+Test)</members>", text)
        print(f"{path}: {len(members)} components, {len(tests)} test classes{' (written)' if path in stale else ''}")
    for path in extra:
        print(f"{path}: removed, no feature has it any more")


if __name__ == "__main__":
    main()
