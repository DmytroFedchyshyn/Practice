# Development foundation — repository structure, code conventions and the foundation specification

**Internal · delivery team · Agentforce Distributor**
**Status:** template from the delivery kit. The team reads it, adjusts each default it does not keep, and records
the agreement in its decisions log before the first line of build code; the build starts from this page, not the
other way round.
**Sources:** the technical design (`docs/technical-design.md`, project-owned); the environments page
(`docs/environments.md`, project-owned); the org snapshot in `force-app/main/default/`.

---

## 0 · What this page settles

Three things, agreed before the first line of build code:

1. **Structure** — where code and metadata live, which org is for what, and how work moves through Git.
2. **Conventions** — how Apex, LWC, flows and metadata are named and written.
3. **The foundation** — ten components every feature uses: a trigger base, a bypass, parameters, an
   error log, notifications, test data, release tooling, the map of existing automation we collide
   with, the write, and switches per feature.

Why first: every Apex component is named in the design before it is built, so that what the client receives
is what was agreed and nothing grows in passing. This page names the shared ones; each feature's spec names its
own.

Status words used below: **Agreed** — decided, with who and when, in the decisions log. **Proposed** — the
team's proposal, to be agreed. **Open** — waiting on someone, named in the open questions. A choice the kit
makes for every project is marked **Default — adjust per project.**, with what changes if a project decides
otherwise.

---

## 1 · Structure

### 1.1 Repository layout

```
<repository>/
├── force-app/main/default/        the org as it was before the build — read only
├── force-app/distributor/           the build — the only folder that is deployed
├── manifest/                package.xml for the build, updated in the same MR as the metadata it lists;
│                            features/ holds one manifest per feature, generated (§1.4)
├── config/                  orgs.json, only for a project that deploys to an org fleet (§1.3)
├── tools/                   scripts the team runs and keeps in Git: deploy, feature manifests, CI
├── project.config.json      build and snapshot folders, default branch, protected paths, features
├── scripts/                 personal helpers, git-ignored
└── docs/                    documentation, English
```

| Folder | Rule |
|---|---|
| `force-app/main/default/` | The baseline we diff against: a retrieve of the org before the build started, committed once. Nothing in it is edited. A second package directory in `sfdx-project.json`, never the default. **Check:** `git diff --diff-filter=AM <baseline commit> -- force-app/main/default` is always empty |
| `force-app/distributor/` | Every component we create, and every snapshot component we change. Its own package directory in `sfdx-project.json`, the default one, so a retrieve or a new component lands here unless told otherwise. Deployed as `--source-dir force-app/distributor` |

**Default — adjust per project.** A project that builds in the snapshot's folder instead loses the clean diff
against the org as it was, and every check that reads `force-app/distributor` has to be pointed at the whole of
`force-app`.

**One component, one place.** To change a snapshot component, move its file from `force-app/main/default/` to the same
relative path under `force-app/distributor/` with `git mv`, then edit it. The diff then shows exactly what changed, and no
component sits in two folders. A component retrieved from an org that is not ours lands in `force-app/main/default/` and
is moved before it is committed.

**An object's own file and its fields may live apart.** An object's `.object-meta.xml` stays in
`force-app/main/default/` while our new fields on it sit under `force-app/distributor/objects/<Object>/fields/`: only the
`CustomField` components go into the deployment, and the object's own settings are not touched. When the object's
own file changes — an action override, history tracking — that file moves to `force-app/distributor/` as well, and a
deploy then sends the object's own settings too, though not the fields, list views or rules left in
`force-app/main/default/`. Try this once with a validation in a build org before relying on it.

### 1.2 Inside `force-app/distributor/`

Flat, by metadata type, exactly as Salesforce names the folders:

```
force-app/distributor/
├── classes/            Apex classes and their tests
├── triggers/           one trigger per object
├── lwc/                Lightning web components
├── objects/            new objects; new fields on existing objects (objects/<Object>/fields/)
├── flows/
├── aiAuthoringBundles/ agents, in Agent Script (agentforce.md)
├── genAiPromptTemplates/
├── permissionsets/
├── permissionsetgroups/
├── customMetadata/     Custom Metadata records
├── customPermissions/
├── labels/
├── notificationtypes/
├── vendor/             third-party code, one folder per library, as its authors published it
└── …                   other types under their standard folder names
```

**Why not one folder per feature:** features share components — one object carries fields that several
features read and write — and a shared component would have to live in one feature's folder or be split, which
breaks *one component, one place*. The feature a component belongs to is in its description (§2.2) and in the
`features` list of `project.config.json` (§1.4 *Deploying by feature*), not its path.

**Third-party code is the one exception:** `vendor/<library>/` keeps each library together with its license,
unchanged, so an upgrade is a copy. Which libraries and why: `architecture.md` §3, §5.

### 1.3 Orgs

| Org | Alias | Type | What it is for |
|---|---|---|---|
| Build org, one per developer | `agentforce-dev` | Developer sandbox | The developer's stories are built and validated here |
| CI | `agentforce-ci` | Sandbox | The pipeline's Apex validation (§1.5); a sandbox user, never a production one |
| System testing | *per project* | Partial Copy sandbox | System and integration testing |
| UAT | *per project* | Full Copy sandbox | Source of the baseline; user acceptance and the go-live rehearsal |
| Production | — | — | Releases only, through `release-runbook.md` |

The project's actual orgs, who owns each and the licenses they use are in `docs/environments.md`
(project-owned); credentials live in the team's secret store, never here.

**One build org per developer.** Each developer builds and validates in a sandbox of their own, so that neither
waits behind the other's validation — a full validation of a large build runs for tens of minutes, and an org runs
one deployment at a time — and neither overwrites the other's unmerged work. Each sets theirs once per machine as
the default org, `sf config set target-org <alias> --global` (without `--global` it holds for one checkout only,
not for a worktree). While a story is built, `tools/deploy-changes.sh` deploys only what the branch changes
(§3 F-7). What the default branch gains from other developers' merges reaches the org the same way: on
`master`, after `git pull`, `tools/deploy-changes.sh --from <the commit the org last took>` — right
after a single pull, that is `ORIG_HEAD`. The whole build is validated with `tools/deploy-build.sh`, with
`--exclude <path>` for a component a given org cannot take. *Rules out:* one shared build org for stories in
progress.
**Default — adjust per project.** A team that shares one build org must serialize its deployments and accept that
one developer's deploy can revert another's unmerged work; check the org's running deployments before each one.

**An org fleet instead.** A project that deploys the same build to many orgs — a set of client orgs, regional
orgs, one org per business unit — keeps them in `config/orgs.json`, grouped, and deploys a group at a time with
the manual fleet deploy described in `ci-cd.md`, one CI environment per org with its own login. The build orgs
above stay as they are; the fleet is for releases, not for stories in progress.

**Tests only when asked, while the build is in active development.** A deployment to a build org runs no test
unless someone asks for them: `tools/deploy-changes.sh` deploys without tests, `--tests` adds those that cover the
change and `--all-tests` every one, and the pipeline's `apex-validate` waits to be started by hand (§1.5). A
sandbox takes a deployment without tests, so a change reaches the org in a minute or two. `tools/deploy-build.sh`,
which runs every test of the build, is for the whole build and for a release. *Rules out:* a test run on every
deployment while the build is in active development; the tests run before a release all the same.
**Default — adjust per project.** A project that runs the tests on every deployment gets an earlier signal of a
broken test, and pays for it in every deployment's duration and in queued deployments.

**The snapshot stands in for production.** When the team has no access to production, the snapshot in
`force-app/main/default/` is taken as production for the components we touch. A sandbox drifts from production after it
is created, and the snapshot can be older than either, so the assumption can be wrong for a given component:
before a snapshot component is moved into `force-app/distributor/` and edited, the same component is retrieved from the
most recent org available and compared, and a difference is resolved before our change is made.

**The org's own tests.** Run the org's existing tests once in a build org before the build starts and record the
result in `docs/environments.md` (project-owned). Tests written against data, users or rules that no longer exist
often fail in every org, production included; then a deployment with `RunLocalTests` would fail on tests that are
not ours, and **every release runs only the build's own tests, with `RunSpecifiedTests`** — which
`tools/deploy-build.sh` already does (F-7). The failing tests and the classes without coverage are reported to
the client's administrator, not fixed in passing.

### 1.4 Git and merge requests

| | Rule |
|---|---|
| Default branch | `master`. Documentation and tooling may be pushed straight to it when the person asks, after `git fetch` and a fast-forward — **except changes under `force-app/`, which always go through a merge request**. Never force-push, never rewrite published history |
| Branches | From an up-to-date default branch: `git fetch origin && git switch -c <branch> origin/master`. Names carry the issue key: `feature/123-short-slug`; also `fix/…`, `docs/…`, `meta/…` (metadata-only) |
| Updating a branch | Merge the default branch into it, never rebase: `git fetch origin && git merge origin/master`, then push the merge commit |
| Commits | One logical change each. Imperative one-line summary; a body when the change needs context. No tool attribution of any kind |
| Merge request | Title `#123 · what changed`. Description: **What**, **Why**, **How to verify**, the issue link, and any manual step after deploy (§3 F-7; the sheet is `release-runbook.md`). One concern per MR; split before review if it grows past a reviewable size |
| Documentation | Ships in the same MR as the change it describes |
| Features | A component an MR adds under `force-app/distributor/` is covered by exactly one feature in `project.config.json`; when no glob covers it, the MR changes `features`, and it commits `manifest/features/` as `tools/feature-manifests.py` rewrites it (*Deploying by feature* below) |
| Review | A second reviewer is welcome, not required; the author may merge their own MR |

**Default — adjust per project.** `force-app/` only through a merge request, documentation straight to the
default branch: a project that sends everything through a merge request adds `docs/` and `tools/` to
`protectedPaths` in `project.config.json`; one that allows metadata straight to the default branch loses the
pipeline's review threads on that metadata before it lands.

**Merge, never rebase.** Merging the default branch into a branch keeps every published commit as it is, so a
branch others have pulled is never rewritten and never needs a force-push. A rebase replays each commit, rewrites
the branch and stops at each commit that touches a file the default branch changed. A conflict in
`manifest/features/` is not resolved by hand: take either side, rerun `tools/feature-manifests.py`, and commit
what it writes. A commit made through the Git host's API has one parent, so a branch is updated by a local merge
and a push, not by an API commit.
**Default — adjust per project.** A team that rebases gets a linear history, and must then allow a force-push to
its own branches and agree that nobody else builds on a branch under review.

**How the `force-app/` rule holds.** Not every Git host can block a push by path on the server, so three checks
share the job (where the host does offer such a rule, use it as well):

- **Before a push** — `.githooks/pre-push`, enabled by `npm install`, stops a push to the default branch when one
  of its commits changes `force-app/`, and names the commits and files. Documentation and tooling still go
  straight to the default branch.
- **For Claude** — a `PreToolUse` hook, `.claude/hooks/protected-path-guard.sh`, denies `git push --no-verify` and
  any write through a Git host's MCP server of a protected path to the default branch.
- **After a push** — the pipeline's `force-app-via-mr` job on the default branch fails when a commit on its
  first-parent line that is not a merge changes `force-app/`. It cannot undo the push: whoever sees the red
  pipeline reverts the commit or opens the merge request after the fact.

`git push --no-verify` skips the local check; the pipeline still reports it.

**Deploying by feature.** `tools/deploy-build.sh <alias>` validates, and with `--deploy` deploys, the whole of
`force-app/distributor`, and stays the default. Every component also belongs to one feature, so
`tools/deploy-build.sh <alias> --feature <slug>` validates, and with `--deploy` deploys, that feature alone into an
org that already holds the features it depends on (`release-runbook.md`) — a later release can then leave out a
feature that is not ready.
**Default — adjust per project.** A project that always releases the whole build keeps one feature,
`foundation`, with the glob `**`, and never passes `--feature`; the manifests check still runs.

The features are listed in `project.config.json`, in the order they deploy to an org that has none of them:

```json
"features": [
  { "slug": "foundation", "label": "Foundation", "dependsOn": [],
    "paths": ["classes/Dst*", "triggers/Dst*", "objects/**", "vendor/**",
              "customMetadata/DST_Automation_Switch.*"] },
  { "slug": "invoicing", "label": "Invoicing", "dependsOn": ["foundation"],
    "paths": ["classes/Invoice*", "triggers/InvoiceTrigger*", "lwc/dstInvoice*/**",
              "flows/DST_Invoice_*", "permissionsets/DST_Invoice_*"] }
]
```

| Key | Holds |
|---|---|
| `slug` | The feature's name in commands and in `manifest/features/<slug>.xml`: lower case, hyphens |
| `label` | Its name for people, as the board and the documents use it |
| `dependsOn` | The features that must already be in an org before this one deploys there |
| `paths` | Globs, relative to `force-app/distributor`, that pick the feature's components: `**` any depth, `*` within one folder; a glob that names a folder or a bundle takes everything in it |
| `members` | Optional `Type:FullName` globs for components that share a file with others — custom labels, sharing rules: `"CustomLabel:DST_Invoice_*"` |

When several features match a component, the most specific pattern wins: a `members` pattern before a `paths`
glob, then the pattern with the most literal characters. A new project starts with one feature, `foundation`,
whose `**` takes every component; a later feature names its own components and Foundation keeps the rest. Two
features matching one component equally specifically stop the script, as does a component no feature matches
or a cycle in `dependsOn`.

- **Which feature owns a component.** The one whose story it serves. A component another feature's story changes
  later stays where it is; the commit and the merge request say who changed it and why.
- **Shared components.** A component more than one feature uses goes to the earliest feature that all of them
  deploy after: generic code, shared modules and the data model to Foundation; what joins several features for
  one user — an app, a navigation menu, a permission set group that grants several features — to the last
  feature, which depends on all of them. A custom label goes with the code that reads it. Keeping the data
  model — every new object and field — in Foundation means the test data factory can fill any field without
  depending on a later feature, and a field nobody is granted shows nothing.
- **Tests.** A feature validates with the test classes it owns, with `RunSpecifiedTests` (§1.3), and each of its
  classes must reach the platform's 75 % — and the project's 85 % — from them: a class that only
  another feature's tests cover fails its own feature's validation. So a class one feature uses and only that
  feature's tests cover goes with that feature. The validation of the whole build still runs every test.
- **Foundation stands alone.** Foundation's code and tests refer to no component of another feature, so it deploys
  into an org that holds none of the build. Its tests make what they need — a queue, a permission set group, a
  permission set made for the test (§3 F-6) — and what Foundation still names of other features is text the code
  looks up as it runs and does without, such as a parameter's name. A check a Foundation test made of another
  feature's component goes to that feature's tests.
- **Leaving a feature out.** Only a feature that nothing later in the order refers to. A component that refers to
  the feature to be left out — a page, a permission set group, a menu — is changed first, under `force-app/`, in a
  merge request of its own.
- **Manifests.** `tools/feature-manifests.py` reads `features` and writes `manifest/features/<slug>.xml`.
  `--check` writes nothing and fails when a manifest is out of date, when a component under `force-app/distributor`
  matches no feature, or when it matches two. The manifests are generated, never edited, and committed with the
  change that alters them, so the merge request shows in text what each feature gains or loses;
  `deploy-build.sh --feature` runs the check first, and so does the pipeline.
- **Deploying a manifest.** `sf` resolves a manifest against every package directory, and `force-app` holds the
  snapshot too: an object named in a feature's manifest would take its fields and list views from
  `force-app/main/default` as well. So `deploy-build.sh --feature` deploys from a temporary copy of the project whose
  only package directory is `force-app/distributor`. An object named in a manifest still takes every child it has under
  `force-app/distributor`, including fields that belong to Foundation and are already in the org.
- **What a dry run proves.** A dry run writes nothing, so a feature's dry run passes only in an org that already
  holds the features it depends on, as they are on the branch. It proves the feature's manifest and its own tests.
  Only a dry run in an org that holds none of the build — typically the Full Copy, until the build first goes
  there — proves a first release. The dry runs are in `release-runbook.md`.

### 1.5 Code checks

Five checks run on every merge request and every push to the default branch, and the same five run locally; a
sixth, the Apex validation, runs on a merge request that changes Apex or what Apex reads, when someone starts it,
and locally through `tools/deploy-build.sh`. A failing test or component, an unformatted file, a lint error, a
possible secret, or a Code Analyzer finding of High or above turns its job orange (*passed with warnings*); a Code
Analyzer finding below High leaves the job green and shows in the job log and the platform's code-quality view.
**What matters holds the merge:** Code Analyzer's Critical and High findings and every possible secret open a
thread on the merge request, and the merge waits until each thread is resolved. Formatting, lint, the Jest tests
and the Apex validation only report.

| Check | Tool | Reads | Orange when | Result in the merge request | Holds the merge |
|---|---|---|---|---|---|
| Quality and security — `code-analyzer` | Salesforce Code Analyzer v5 — the `Recommended` rules plus PMD's security rules (Apex, LWC, Flow, JavaScript libraries) and the project's own rules | `force-app/distributor` | a Critical or High finding | new findings in the code-quality view; every finding in the job log, with a link to its line; the HTML report as a download | a thread per Critical or High finding |
| Formatting — `prettier` | Prettier with the Apex plugin | `force-app/distributor` | a file is not formatted | the job log lists the files | no |
| Lint — `eslint` | ESLint with the Salesforce LWC and Aura configurations (`eslint.config.js`) | the JavaScript of `force-app/distributor/lwc` and `force-app/distributor/aura` | an error | the job log lists each finding with its file and line | no |
| Component tests — `lwc-jest` | Jest through `sfdx-lwc-jest`; `jest-junit` writes the report | the `__tests__` folders in `force-app/distributor/lwc` | a test fails | the failing tests in the test summary; a line per test file in the job log, with each failure in full | no |
| Secrets — `secrets` | gitleaks | the commits the pipeline brings, every folder | a possible secret | test summary and job log, redacted | a thread per finding |
| Apex compile and tests — `apex-validate` | `tools/deploy-build.sh`: a validation, nothing written, of the whole of `force-app/distributor` with every test class of the build, in `agentforce-ci` | `force-app/distributor`, when someone starts it on a merge request that changes classes, triggers, objects, flows, permission sets or groups, custom permissions, custom metadata, labels, sharing rules or queues | a component or a test fails | the failing tests in the test summary; the deployment's result in the job log | no |

How each platform runs these jobs — the pipeline files for GitLab, GitHub Actions and Azure Pipelines, the
variables and secrets each needs, and where the threads or the SARIF report appear — is in `ci-cd.md`. All three
call the same scripts in `tools/ci/`.

- **Apex validation.** `apex-validate` signs in to one sandbox with the SFDX auth URL kept in the CI secret
  `SF_CI_AUTH_URL`, and runs `tools/deploy-build.sh` with `SF_CI_DEPLOY_ARGS` when that org needs flags of its own
  (an `--exclude` for a component it cannot take). It is offered only when the merge request touches what Apex
  compiles against or reads, and waits to be started by hand: while the build is in active development, tests run
  only when asked for (§1.3), and a full validation of a large build runs for tens of minutes. A change to a
  component alone is checked by its author's `tools/deploy-changes.sh`. One validation runs at a time; a newer
  pipeline of the same merge request cancels the older one, and the canceled job cancels its validation in the
  org, so the next one does not wait there behind it. Without the secret the job is not created, so it is safe on
  the default branch before anyone sets it. Anyone who can push a branch can read the secret through the pipeline:
  it holds a sandbox user, never a production one, and the job stops when the org it signs in to is not a
  sandbox. Until the CI org and its user exist, the author validates by hand.
- **Threads.** On GitLab, the `review-threads` job opens them after the checks, on the line itself when the merge
  request added it, otherwise on the merge request with a link to the line. A rerun does not open the same thread
  twice; a thread whose finding has gone is resolved by the pipeline. Resolving a thread by hand means *it stays,
  and here is why*: say why in a reply, and the pipeline leaves it resolved. GitHub shows the same findings as
  code-scanning alerts from the SARIF report, and Azure Pipelines publishes the SARIF report as an artifact
  (`ci-cd.md`).
- **What holds the merge.** On GitLab, two project settings, Settings → Merge requests: *All threads must be
  resolved*, and *Pipelines must succeed*, so a merge cannot overtake the threads. The job posts with the token
  `REVIEW_BOT_TOKEN`, a masked CI variable that is not protected, so merge request pipelines on any branch can
  read it. Without it the job fails, and the merge waits. The token's expiry date goes into the team's secret
  store. The settings for the other platforms are in `ci-cd.md`.
- **Scope.** Only the build's own code is analyzed, linted and formatted. `force-app/main/default` is the client's org
  snapshot: `npm run scan:org` reports on it when someone needs that, and Prettier never touches it, so a retrieve
  still diffs cleanly. Secrets are looked for everywhere, documentation included.
- **Locally.** `npm install` once (Node 22.x); it also points git at `.githooks/`. Then
  `npm run scan` (Salesforce CLI with `sf plugins install code-analyzer`, Java 11 or later), `npm run lint`,
  `npm run format` or `npm run format:check`, and `npm run secrets` (`brew install gitleaks`, or the release for
  your platform). The Code Analyzer and ESLint extensions for VS Code show the same findings while typing.
- **Before a commit.** The `pre-commit` hook runs lint-staged on the staged files in `force-app/distributor` — Prettier
  formats them, ESLint checks them, Jest runs the tests related to a changed component — and scans the staged
  changes for secrets with gitleaks. A secret is the one thing that stops a commit: once it reaches the Git host it
  has to be revoked and reissued. `git commit --no-verify` skips the hook.
- **Settings.** `code-analyzer.yml` switches PMD's `ApexDoc` off, because the convention is a header per class
  (§2.3); holds the project's own rules — `DmlOnlyThroughDmlClass` and `LabelShortDescriptionMax80` to start with
  (`code-review-rules.md` §2) — and lists the findings that stay by design under `suppressions`, each with its
  reason. `.gitleaks.toml` adds the known false positives of the org snapshot to the default rules, each with its
  reason. `.prettierrc` holds §2.3: four spaces, 120 characters. Code Analyzer, ESLint and Prettier skip
  `force-app/distributor/vendor/`, third-party code kept as its authors published it (`architecture.md` §5).
- **Jest.** `npm test` runs the Jest tests of the Lightning web components in `force-app/distributor` (`jest.config.js`;
  `architecture.md` §4.5). The `lwc-jest` job runs the same tests with `npm run test:ci`, which also writes
  `reports/jest.xml` for the merge request's test summary. A failing test turns the job orange and the merge does
  not wait for it, so the author still runs `npm test` before opening a merge request that changes a component
  (LWC-05).
- **Review rules.** These checks, and the conventions of §2 that a reviewer or `/code-review` looks for, are
  listed with an ID, a severity and what catches them in `code-review-rules.md`.
- **Where it starts.** Record the first run of every check here once the pipeline is in place — the date, what
  each job found in `force-app/distributor`, and what was fixed or suppressed and why — so a later reader can tell an old
  finding from a new one. Fix a finding of the first run rather than suppress it: a system-mode read or write that
  Code Analyzer reports is usually fixed by naming system mode on the statement, with a comment saying why
  (§2.3). Run `npm run format` over `force-app/distributor` in its own merge request, so the formatting job starts green.
  Scan the history of the default branch for secrets once: `npm run secrets`.

  **First run — 2026-11-24, pull request #1.** Prettier, gitleaks and the secrets job passed. ESLint and Jest
  failed only because the build had no Lightning web component yet; `npm run lint` now passes with
  `--no-error-on-unmatched-pattern` and the Jest scripts with `--passWithNoTests`. Code Analyzer: 105 findings
  in 18 files — 26 High, all `pmd:ApexCRUDViolation` in `SeedData`, fixed by naming system mode on each query
  and write with the reason in the class header; 39 Moderate, left as the baseline: 14
  `regex:DmlOnlyThroughDmlClass` (closed by `DstDml` in M4), 6 `pmd:CognitiveComplexity`, 5
  `pmd:CyclomaticComplexity`, 5 `pmd:AvoidHardcodingId` (fake Ids in tests), 4 `pmd:ExcessiveParameterList`,
  3 `pmd:NcssCount`, 1 `pmd:ProtectSensitiveData`, 1 `pmd:FieldNamingConventions`; 40 Low, all
  `pmd:ApexUnitTestClassShouldHaveRunAs` on tests that run as the test user through a helper method.

---

## 2 · Code conventions

The review rules that check these conventions — each with an ID, what catches it and how strictly — are in
`code-review-rules.md`. A new convention is added here, and its rule there, in the same merge request.

How the conventions fit together — the layers of Apex, the kinds of components, the libraries we test with and
how to use them — is explained in `architecture.md`. The conventions themselves stay on this page.

### 2.1 Where logic goes

**Apex first for logic. Metadata as code for everything else. Clicking only where the platform leaves no
alternative.**

| Concern | Approach |
|---|---|
| Business logic, validation, assignment, matching, sync | Apex: one trigger per object, the trigger thin, logic in classes |
| Screens, for internal users and external ones | LWC with Apex controllers, not screen flows |
| Thresholds, windows, rules that change | Custom Metadata, read from Apex (§3 F-3) |
| An agent: what it handles, when it hands over, which action it may call | Agent Script in the repository, its actions in Apex — flows and prompt templates where `agentforce.md` says (`agentforce.md`) |
| Objects, fields, record types, layouts, permission sets | Source in the repo, deployed — not built in Setup |
| Sharing | Organization-wide defaults, sharing rules and, for external users, sharing sets; Apex managed sharing only where none of them can express the rule |
| Reports and dashboards | Built in the UI, then retrieved into source |
| Experience Builder theme, branding, navigation | Click-work, unavoidably; retrieved into source after each change |

**Flows we add:** only where the design names one, typically where the client's administrators must be able to
change the logic after handover without a developer. A record-triggered flow on an object where we also have a
trigger needs a line in the design saying why both.

**An action shows only where it can succeed.** A quick action or button on a record page, a button in a
component, a link that starts a step: each shows only to the users and on the records where pressing it can
succeed — its visibility comes from the same conditions the server refuses it on: the permission, the status, a
limit such as a number of rounds. On a Lightning record page that is a dynamic-action visibility rule, reading a
field of the record where the condition needs one (a formula over a roll-up, for a count); in a component,
`lwc:if` on what the controller returns. The server still checks every condition, so an action reached another
way — the API, a stale page, another app — is refused as before. A condition no rule can read, such as whether the
user may edit the record, is named in the design as a known limit. An action that suits no one on a page leaves
the page and its layout, which the mobile app reads (GEN-17).

### 2.2 Naming

**Whose names change.** The client's existing components keep their API names when we extend them. Code ported
from an earlier prototype of ours takes the name these rules give wherever its own does not fit. Everything new
follows the rules.

| Element | Rule | Example |
|---|---|---|
| New objects, custom settings, Custom Metadata types, platform events | `DST_` prefix | `DST_Log__c`, `DST_Parameter__mdt` |
| Fields on those objects | No prefix | `DST_Log__c.Source__c` |
| New fields on the client's objects | No prefix; API name follows the label | `Invoice__c.Approved_By__c` |
| Permission sets | `DST_` + capability | `DST_Log_Viewer` |
| Permission set groups | `DST_` + persona | `DST_Billing_Clerk`, `DST_Administrator` |
| Custom permissions | `DST_` + what it allows | `DST_Bypass_Automation` |
| Flows | `DST_` + object + what it does | `DST_Invoice_Remind_Owner` |
| Queues and public groups | `DST_` + team; label in the client's own words | `DST_Accounts_Receivable` · *Accounts Receivable* |
| Custom labels | `DST_` + area + text | `DST_Invoice_Duplicate_Warning` |
| Validation rules, quick actions, field sets — on any object | `DST_` + what it does | `DST_Rejection_Needs_Reason` |
| Custom Metadata records | What the value is | `Approval_Window_Hours` |
| Apex shared by every feature | `Dst` + name | `DstTriggerHandler`, `DstLogger` |
| Apex for an object's logic | Object + role | `InvoiceApprovalService`, `InvoiceSelector` |
| Apex behind one page | `Dst` + page + role | `DstInvoiceController`, `DstInvoiceView` |
| Role suffixes | `TriggerHandler` · `Service` (logic) · `Selector` (queries) · `Controller` (`@AuraEnabled`) · `Batch` · `Job` (Queueable) · `Schedule` · `Action` (`@InvocableMethod`, an agent's actions included) · `Form`, `View` (records to and from what a page shows, §2.7) | `InvoiceReminderBatch` |
| Domain classes | No suffix: object or concept + what it decides (§2.7) | `InvoicePolicy`, `InvoiceNumbers` |
| Agents | Agent Script developer name, words joined by underscores, for whom the agent serves; its subagents in snake_case, for an area | `Customer_Service_Agent` · `invoices` |
| Prompt templates | `DST_` + what the text does | `DST_Explain_Invoice_Dispute` |
| Triggers | Object + `Trigger`, one per object | `InvoiceTrigger` |
| Tests | Class name + `Test`; a feature's own: `Dst` + feature + `FeatureTest`, `BulkTest`, `Cast` or `Steps` (`architecture.md` §4.6) | `InvoiceApprovalServiceTest`, `DstInvoicingFeatureTest` |
| LWC | camelCase. A page is `dst` + page, a part or a module `dst` + what it is (§2.5); a component on an internal record page or behind a quick action is named for what it acts on | `dstSubmitInvoice`, `dstFormSteps`, `invoiceChanges` |

**Every component has a description** that starts with the story key and says why it exists:
`#123 · Warns a clerk that the invoice may already be entered.` That is how a field, a permission
or a flow leads back to the story that asked for it, and how the flows and permission sets already in the org stay
distinguishable from ours. This is the *Description* of a component in Setup; Apex and LWC carry no story key, and
their comments follow §2.3 *Comments*. A custom label's description is its *Short Description*, which Salesforce
keeps to 80 characters, story key included: a longer one fails the deployment (MDT-16).

### 2.3 Apex

- **Triggers.** One per object, every event, one line: `new InvoiceTriggerHandler().run();` (§3 F-1). On an object
  that already carries the client's own trigger, we do not add a second one: the design decides whether our logic
  is called from theirs — moved into `force-app/distributor/` with one added call — or another way, and the collision map
  records it (§3 F-8).
- **Sharing.** `with sharing` by default; `inherited sharing` for classes called from both user and system
  contexts; `without sharing` only with a comment on the class saying why (for example: an external user must read
  an Account their sharing does not show). Queries on behalf of a user use `WITH USER_MODE`; system-mode reads say
  so and why.
- **DML mode.** Records are written only through `DstDml` (§3 F-9), and every call names its
  `DstDmlMode`. DML on behalf of a user runs in user mode, `USER`. Where the design needs a write the
  user's own permissions refuse — a record the process must create that the user may not create themselves — the
  call names `SYSTEM_WITH_SHARING`, or `SYSTEM_WITHOUT_SHARING` when the user does not reach the record either,
  and the line says why. Test classes insert their own records directly.
- **Bulk.** Every method takes and returns collections. No SOQL or DML inside a loop.
- **No hard-coded names or Ids.** Users, queues, groups, profiles and record types are found by developer name;
  windows, thresholds and addresses come from `DST_Parameter__mdt` (§3 F-3).
- **Errors.** Unexpected errors are not swallowed. An error that is handled is logged (§3 F-4). An error the user
  must fix is `addError` with a custom label.
- **Asynchronous work.** Queueable over `@future`; Batch above a few thousand records. Every asynchronous entry
  point respects the bypass (§3 F-2).
- **Switches.** Every automation we build can be turned off in Setup, with no code change (§3 F-10). A trigger
  handler gets its switch from `DstTriggerHandler`, which reads the one named after the handler's
  class. Any other entry point that runs on its own — a step called from another trigger, a Queueable, the service
  a schedule runs, an `@InvocableMethod` a flow calls — asks `DstSwitches.isOn` with its own name next
  to the bypass, and does nothing while it is off. A new automation brings its
  `DST_Automation_Switch__mdt` record — active, with its feature and a description, written for the
  client's administrator, of what turning it off does — and its row in `automation-switches.md`, in the same merge
  request. A step inside a handler gets a switch of its own only when an administrator may want it off while the
  rest of the handler runs, and never when another step needs its result. A test sees every switch on, whatever
  the org it runs in holds, and turns one off through `DstSwitches.overrides`.
- **Static fields.** A static field lives for the whole transaction: every chunk of 200 records a trigger runs,
  every re-entry and every caller see the same value. Outside a test class, a static field is one of three things:
  - a constant, `static final`;
  - a dependency a test replaces, `@TestVisible private`: a selector or a service (§2.7), or a value the test
    cannot arrange in the org — a custom metadata record, an org limit, a license it does not have;
  - state the whole transaction shares — a value read once and kept, a guard against re-entry that tracks record
    Ids, the bypass (§3 F-2).

  A value a test sets and the state of the transaction carry a comment saying why the value is static; a selector
  or a service needs none, since §2.7 says why it is held so. No static field exists only for a test to read what
  the code did: a test checks the records, the result, `Limits`, or a mock of the class that sends (§2.4 *Mocks*).
  Static methods follow §2.7: selectors and services are instances; forms, views, the foundation (§3) and what the
  platform requires — `@AuraEnabled`, `@InvocableMethod`, `@future` — are static.
- **Comments.** A class or trigger opens with a short header, one to three lines: what it does and why it exists.
  Any other comment says why the code is as it is, where the code cannot say it — a platform limit, a business rule
  that looks wrong, an order that matters; none repeats what the code does. No ID and no history in code or its
  comments: no issue key or merge request, no story, requirement, decision, open item, review rule or document
  section, and no record of what changed, who decided it or when. The reason is written out in words; where a
  change came from is told by its branch, commit and merge request (§1.4), which `git blame` leads to, and the rule
  it implements is in the design. Names of components in the org, and an engine rule named in a
  `code-analyzer-suppress` marker, are not IDs in this sense. No commented-out code, and no `TODO` or `FIXME`: work
  left to do is a task on the board. This holds for all code under `force-app/distributor/` outside `vendor/`, LWC
  JavaScript, HTML and CSS included.
- **API version.** Every new component uses the project's `sourceApiVersion` (68.0 at the
  start); it is raised for all of them at once.
- **Formatting.** Four spaces, lines up to 120 characters, applied by Prettier with the Apex plugin (§1.5), so
  formatting is never a review comment.

### 2.4 Tests

- **Coverage.** The platform needs 75 % org-wide to deploy; we aim for 85 % on each
  new class. Coverage is the floor, not the goal: every acceptance criterion of a story has a test that names it.
- **Data.** A record a test inserts comes only from the test data factory (§3 F-6). A record a test needs only in
  memory — with formula, system or relationship fields set — is built with SObject Fabricator
  (`sfab_FabricatedSObject`; `architecture.md` §4.3). Never `SeeAllData=true`.
- **Mocks.** A class a test replaces is held in a `@TestVisible private static` field of the class that uses it
  (§2.7) and replaced with apex-mockery (`Mock.forType`), not with a hand-written `StubProvider`
  (`architecture.md` §4.1, §4.2). The write is the exception: it is replaced with the one shared fake,
  `DstDmlFake`, which answers as the database would, so a test does not configure every write
  (§3 F-9). Access is never mocked: who may read or change a record is tested on inserted records, run as that user
  (*Who runs it* below; `architecture.md` §4.4).
- **Levels.** A feature's tests are on four levels (`architecture.md` §4.6): unit tests in memory for the rules of
  its services, with the selectors, the write and other features' services replaced; selector tests on the
  database, for the contract the replacements answer by; one feature class,
  `Dst<Feature>FeatureTest`, through the entry points as each persona, with
  `Dst<Feature>Cast` and `Dst<Feature>Steps` and the shared `DstTestCast` and
  `DstAccessMatrix`; and `Dst<Feature>BulkTest`, 200 records at once, or ten where a path is
  slow per record by nature (*Speed* below). A test moved to another level keeps its method name, so each
  acceptance criterion keeps its test (TST-02).
- **Names say the behavior:** `routesEveryOverdueInvoiceToTheCollectionsQueue`, not `testMethod1`.
- **Speed.** A deployment runs the tests one after another, so their time adds up, and a test class whose methods
  each build their own users and records is usually the slowest part of a validation. The records the methods of a
  class share are built once, in its `@TestSetup`, and each method reads them back; what a method changes is rolled
  back before the next. A permission set group is recalculated in the method that relies on it as well as in the
  setup, because a deployment that changes one of its permission sets runs the tests before the org recalculates
  the group. The bulk tests of a class whose methods take more than two minutes in a deployment's results are in a
  class of their own, `<Class>BulkTest`. In a deployment this saves nothing, the tests run one after another
  there; it keeps one class from holding up a parallel run (`sf apex run test`).
  A path that is slow per record by nature proves its bulk on ten records, not 200: one that starts or needs each
  record's approval process — a submit, a decision, a recall — since the platform runs each record's approval on
  its own; and one that saves each record through the client's own automation on a heavily automated object, whose
  record-triggered flows and managed-package triggers a test cannot leave out. The test runs the step for one
  record, then for ten, and asserts that ten use no more queries, writes or email sends than one, besides the
  writes the platform makes for each further record (a recalled approval writes its record back, for one). A record
  goes through the step alone first, unmeasured, so what a step reads once and keeps is not counted against the
  step for one. On a heavily automated object the cost read is that of the org's own code in the save, the client's
  automation included, so a test on ten can fail on a change of the client's; managed packages keep limits of their
  own and are not read. The other paths keep their runs of 200 (TST-10). The shared `DstBulkCost`
  (`@IsTest`, Foundation) reads the cost of a test on ten and asserts it, so no test class keeps its own copy
  (`architecture.md` §4.6).
- **Shape.** One behavior per method; `Test.startTest()` / `Test.stopTest()` around the call under test; the
  `Assert` class with a message where the failure would otherwise be unclear.
- **Who runs it.** Behavior of an external user runs as that user (`System.runAs`); internal personas get their
  access through the permission set groups, not through a profile. A test that reads or saves records through a
  controller for external users runs as such a user with their permission sets, so sharing and field access are
  theirs. A test whose outcome does not depend on the running user — system code, logic on records in memory, a
  refusal before any DML, the internal user — needs no `runAs`, and its Code Analyzer finding is suppressed with
  that reason.
- **Licenses.** When the org has no free Salesforce license, tests do not create internal users: a test user still
  needs a license, and an insert fails without one. Users on licenses the org holds in quantity — community or
  portal licenses, for example — are fine. Which licenses are free is in `docs/environments.md` (project-owned).

### 2.5 LWC

- Controllers are thin: they read through a selector and change records through a service (§2.7); reads are
  `@AuraEnabled(cacheable=true)`.
- Text the user sees comes from the metadata, never typed into a component's HTML or JavaScript. A field's name is
  its label on the object — read through Apex describe or `getObjectInfo` — so a new name is made on the field, and
  the form, the record page, list views and reports change together; a custom label carries it only where the
  field cannot: a standard field, or a name longer than the 40 characters a field label holds. Every other text —
  hints, placeholders, steps, buttons, messages, terms — is a custom label. The project's languages are named in
  the design.
- Styling through SLDS and the theme of where the components run; no hard-coded colors. A component's own
  colors, spacing, sizes, type, borders and corners come from one shared CSS module, `c/dstTheme`: its
  CSS starts with `@import 'c/dstTheme';` and uses its custom properties. A value the module lacks is
  added there — spacing and sizes named by their pixels, the type scale by its role — never written into the
  component.
- Built for Lightning Experience, and an Experience Cloud site whose template is chosen in phase 4 (LWC-04).
- **Three kinds of component.** A *page* is exposed — in Lightning App Builder or Experience Builder; it calls
  Apex, holds the page's state and navigates. A *part* is not exposed: it gets its data through `@api` properties,
  reports what the user did through events, and never calls Apex. A *module* is JavaScript or CSS without a
  template (`c/dstPages`, `c/dstTheme`); it may call cacheable Apex for what it shares. Code
  two components share goes into a module, not into a copy (`architecture.md` §2).
- **Jest** tests for the modules, parts and pages that hold logic, in a `__tests__` folder inside the component's
  folder, run with `npm test` (`architecture.md` §4.5); a component that only displays data is covered by the Apex
  tests behind it.

### 2.6 Existing automation and Setup

- **The client's flows are not edited in place.** A flow the new design replaces is switched off at the release
  that brings its replacement; one that stays is left alone. Each decision is a row in the collision map (§3 F-8).
- **Profiles are never deployed.** Access comes from permission sets and groups; a right a user needs goes into
  a permission set of their group, never into a profile.
- **Picklist values** have stable API names; restricted wherever the values are a closed list.
- **A list view filters a standard picklist by the code the UI stores.** Some standard objects store a standard
  picklist's value as a code — `0`, `1`, `2` — and a list view's filter on it holds that code, not the value's
  name: a name deploys, shows in the filter panel as the value, and matches no record. A filter on a standard
  picklist is set once in the UI and retrieved, and its value copied. A custom picklist is filtered by its API name.
- **Help text** on every field an external user sees.
- **Administrators see what we add.** What the build adds under `force-app/distributor/` is granted in the permission set
  `DST_Admin_Access` — held through the group `DST_Administrator` — in the same merge
  request: every field that takes field-level security, read and edit, read only for formula and roll-up summary
  fields; every object, create, read, edit, delete, View All and Modify All; every custom setting and custom
  metadata type. The log is the exception: its fields go to `DST_Log_Viewer`, which the group also
  holds. Platform events, and the fields of custom settings and custom metadata types, take no field access. The
  administrators hold the System Administrator profile, which is never deployed, so without this a new field stays
  invisible to them (MDT-15).

### 2.7 Layers

Apex is written in four layers, and a class calls only the layers below it. Why, with a diagram, a sketch and what
was considered instead: `architecture.md` §1, §6.

| Layer | Classes | Does | Reads and writes |
|---|---|---|---|
| Entry point | `Controller`, `TriggerHandler`, `Action`, `Job`, `Batch`, `Schedule` | Checks what it receives, reads through a selector, changes records through a service, turns an exception into a message the user understands | Nothing itself |
| Service | `Service` | The rules of one use case: decides, changes records, owns the transaction; takes and returns collections | Writes through `DstDml` (§3 F-9); reads through selectors |
| Selector | `Selector`, one per object | Every query on its object, in user mode unless the method says otherwise and why | SOQL only |
| Form, view | `Form`, `View` | Turns records into the data a page receives, and what a page sends into records; those data classes live here, not inside the controller | Nothing |
| Domain | Named for what it decides (`InvoicePolicy`) | A rule that needs no database, as static methods on what the caller passes (`architecture.md` §1) | Nothing |

- **Calls go down.** No class uses a controller or its inner classes, except the controller's own test and a
  feature's `Dst<Feature>Steps`, which runs the entry points for its feature class
  (`architecture.md` §4.6); a service never calls an entry point. The foundation (§3, `Dst*`) is used
  from any layer.
- **Selectors and services are instances.** A class that a test may replace has instance methods and is held in a
  `@TestVisible private static` field of the class that uses it (§2.4 *Mocks*). No service locator, no registry of
  types, no framework. A form or a view may stay static: no test needs to replace it.
- **System mode** as §2.3 says: named on the statement, with a comment saying why. A write names its
  `DstDmlMode`, `SYSTEM_WITHOUT_SHARING` included, and needs no class of its own. When a read has to
  bypass sharing as well, it lives in a small class, or an inner class, `without sharing`, named for what it does
  (`DstCustomerSearch`).
- **Triggers** call the handler, and the handler calls services in a fixed order (§3 F-1). Where our logic is
  called from a trigger the client owns (§2.3 *Triggers*), that trigger calls our services directly and the design
  says so.
- **Third-party code** is a library in `force-app/distributor/vendor/` (§1.2), agreed in the design before it is added
  (`architecture.md` §3, §5).
- **Code written before these layers** — a prototype taken into the build, a class from before this page was
  agreed — is brought to the layers when a story next changes it, or in a task of its own, not in passing in
  another merge request.

---

## 3 · Foundation specification

Ten components. F-1 to F-6 are Apex and metadata, built together in one merge request before the first feature;
F-7 is tooling and a sheet; F-8 is analysis; F-9 is the write; F-10 the switches. Each one says what it is for, how
it behaves, what it consists of, the decisions behind it, and how we know it works. The names below take the
project's prefixes; the code itself is the project's to write, to these descriptions.

### F-1 · Trigger base — `DstTriggerHandler`

**For:** one trigger per object, the logic outside the trigger, one way to switch it off and one guard against
recursion.

**Behavior**
- A handler extends `DstTriggerHandler`; the trigger calls `run()`.
- `run()` calls exactly one overridable method for the operation: `beforeInsert`, `beforeUpdate`, `beforeDelete`,
  `afterInsert`, `afterUpdate`, `afterDelete`, `afterUndelete`.
- It does nothing while automation is bypassed (F-2), while that handler is switched off by class name for the
  transaction (`bypass` / `clearBypass` / `isBypassed` / `clearAllBypasses`), or while its switch in Setup, or its
  feature's, is off (F-10).
- A handler may cap its runs per operation in one transaction (`setMaxRuns`); one run too many raises an error
  naming the handler, the operation and the limit, so a recursion shows up instead of looping.
- Called outside a trigger, it raises an error.

**Done when:** each operation reaches only its method; the bypass, a bypass by name and its switch in Setup each
stop it; the cap raises the named error; calling it outside a trigger fails.

### F-2 · Bypass — `DstBypass`

**For:** data loads and quiet periods. A migration must route nothing and send no message: moving old records to
new statuses must not notify anyone.

**Behavior** — automation is off when any of these is on:

| Switch | For | Set by |
|---|---|---|
| Custom permission `DST_Bypass_Automation`, through permission set `DST_Bypass_Automation` | The user who loads or fixes data, for the duration of the load | Assigning the permission set (a step in `release-runbook.md`) |
| Hierarchy custom setting `DST_Settings__c.Bypass_Automation__c` | A whole sandbox, a profile or a user for a while — a refresh, a rehearsal | Setup → Custom Settings |
| A switch in Apex for the rest of the transaction | Anonymous scripts and tests | `DstBypass.disableAutomation()` |

A second set — `DST_Bypass_Notifications`, `Bypass_Notifications__c`, `disableNotifications()` —
stops only messages; automation still runs. Bypassing automation bypasses notifications too. Flows read the same
switches: `{!$Permission.DST_Bypass_Automation}`,
`{!$Setup.DST_Settings__c.Bypass_Automation__c}`.

The bypass stops everything for a user, a profile or an org. Stopping one feature or one automation for everyone
is F-10.

**Done when:** each switch turns automation off; the notification switches stop messages and nothing else; a user
without any switch runs everything.

### F-3 · Parameters — `DstParameters`, `DST_Parameter__mdt`

**For:** every window, threshold, calendar and address the build uses, held as data. When the client answers an
open question, a record changes, not the code.

**Behavior**
- One record per parameter: `Value__c` (text) and `Source__c` — the decision it comes from, or the open question
  it waits for.
- Set by an administrator in Setup → Custom Metadata Types → *Parameter* → **Manage Records**: the type's layout
  carries both fields. A deployment writes a record as the repository holds it, so a value set only in Setup lasts
  until the next deployment that carries it; a value the client changes in Setup is changed in the repository too.
- Read as text, number, true/false, a list separated by semicolons, or the Id of named business hours.
- **An empty value means not decided:** the reader gets the default the calling code passes, and the rule that
  depends on it does not apply yet. A value of the wrong kind raises an error naming the parameter.

**Interface, in outline:** static readers by kind, each taking the parameter's name and the caller's default —
text, integer, decimal, Boolean, a list, and business hours by name. Records are read from the application cache,
with no query.

**Kinds of parameter a build usually needs** — each with its source and what an empty value does, recorded in its
`Source__c` and in the design:

| Kind | Example name | Empty means |
|---|---|---|
| A window in calendar hours or days | `Approval_Window_Hours`, `Reminder_Days` | No reminder, no overdue flag |
| A window in business days, with the calendar it counts against | `Answer_Business_Days`, `Business_Hours_Name` | No due date; the org's default business hours |
| A threshold and whether it is inclusive | `Second_Approval_Threshold`, `Second_Approval_Inclusive` | No second approval |
| A list the rules match against | `Regions_With_Feature`, `Activity_Types_Without_Venue` | The rule applies to everyone, or to no one — named per parameter |
| An address the build links to | `Policy_URL` | No link; only an `https://` address of a set length is linked |
| The sender of the build's emails | `Org_Wide_Email_Address` | Emails go out as the running user (F-5) |
| A shared mailbox | `Mailbox_<Team>` | The mailbox is not emailed |
| A sandbox-only test mailbox | `Masked_User_Test_Mailbox` | Every user is emailed at their own record (F-5) |

A formula field that reads a parameter makes the record a dependency of the field: the record deploys with the
field's feature, or the field cannot be saved.

**Done when:** each kind reads correctly; an empty value returns the caller's default; a wrong value names the
parameter; empty business hours resolve to the org default.

### F-4 · Error log — `DstLogger`, `DST_Log_Event__e`, `DST_Log__c`

**For:** finding out after the fact what went wrong in automation — during the build, in hypercare, and for the
client's administrator after handover.

**Behavior**
- `error`, `warn` and `info`, each with a source, a message or an exception, and the record concerned.
- `error` also takes a list of messages: one entry each, all published in one call, so a bulk failure split into
  several entries counts once against the transaction's publish limit. A constant names the longest message an
  entry keeps; a caller splits long logs under it.
- An entry is published as the platform event `DST_Log_Event__e` with *Publish Immediately*, so it
  is kept even when the transaction that failed rolls back. A trigger on the event stores it as a
  `DST_Log__c` record.
- A log entry is written even while automation is bypassed or switched off.
- Publishing the event needs Create on `DST_Log_Event__e`, which Apex does not bypass: without it
  the platform refuses the event and the entry is lost. Every user whose actions run our code — external users
  included — gets it in a permission set; without it, no failure in that user's own actions reaches the log.
- For flows: an invocable action, `DstLogAction` (*Log a flow fault*: the flow's API name,
  `$Flow.FaultMessage` and the record), so a flow's fault path writes to the same log; many faults of one save go
  in one call per flow.

| `DST_Log__c` field | Holds |
|---|---|
| Log Number | Auto-number `LOG-000001` |
| Level | Error · Warning · Info |
| Source | The class, flow or process that wrote it |
| Message | What happened; for an exception, its type and message |
| Stack Trace | For an exception |
| Record Id | The record being processed |
| User | Whose transaction it was — the record itself is created by the Automated Process user |
| Request Id | The Salesforce request, to find it in the event log |

Access: private; read through the permission set `DST_Log_Viewer`, which nobody gets by default.
The administrators hold it through the group `DST_Administrator`.

**To decide per project:** how long entries are kept (a scheduled job that deletes entries older than a set number
of days is the usual answer); whether errors also alert someone, and whom, after handover.

**Done when:** an entry written inside a transaction that then fails is still there; levels, source, message,
stack trace, record, user and request are stored; text longer than a field fits is cut, not lost with the entry.

### F-5 · Notifications — `DstNotificationService`

**For:** the single way the build tells someone something — every story that notifies goes through it.

**Behavior**
- Two channels: a bell notification (custom notification type `DST_Notification`) and an email. A
  message uses either or both. Chatter is not a channel unless the design names it.
- Recipients are users, queues or public groups; a queue or group means its direct user members. Each user gets one
  message however many ways they were named. Inactive users are skipped. Resolving them is a helper,
  `DstNotificationRecipients`, run once for every message of a send.
- A queue or group named that has no active direct user member is logged once per send (F-4), by its developer
  name: its messages reach nobody there, and the rest of the send goes out.
- A shared mailbox is named by its `Mailbox_<Team>` parameter (F-3), never typed in code. It gets the email only,
  no bell, and one per message however many times it was named. A parameter without a value is skipped and logged,
  and the rest of the send goes out. An email to an address counts against the org's daily limit for single
  emails, unlike an email to a user record: when the org has no room left today for a send's mailbox emails —
  counting those of earlier sends in the same transaction — they are left out and logged, so the users' emails of
  the same send still go out.
- Emails to users go to the user record (`setTargetObjectId`), so they do not count against the daily external
  email limit. Every email, a mailbox's too, is sent from the org-wide address in F-3 when one is set.
- Without that address an email goes out as the user whose transaction sends it, and the platform sends on a
  user's behalf only when the user's own address is verified. An external user's usually is not, so the emails of
  an external user's own action go out only from the org-wide address: without it the platform drops them after
  `sendEmail` has reported success. Since nothing else shows the loss, a send by a user other than an internal one,
  with no org-wide address to send from, logs one error (F-4) naming the parameter and the number of its emails.
  Every email is sent in UTF-8, whatever the sender's own encoding.
- **In a sandbox only**, a user whose address the sandbox masked — it ends `.invalid`, as every address copied
  from production does — is emailed at the test mailbox `Masked_User_Test_Mailbox` (F-3) instead, as
  `<mailbox>+<first name>`, so a tester receives every role's email and sees whom it was meant for; the bell is
  unchanged. Those emails go to an address, so they count against the daily limit too, after the mailboxes': when
  the room left today does not cover all of a send's test mailbox emails, none is redirected, those users are
  emailed at their record as without the parameter, and that is logged. In a test, the org counts as no sandbox
  unless the test says otherwise, so the value a sandbox holds never changes another test's emails. A deployment
  that carries the record empties it, so it is set again after one (`release-runbook.md`).
- Nothing is sent while notifications are bypassed (F-2). A failed send is logged (F-4); it does not fail the
  transaction that caused it.
- An email is plain text unless its message carries a layout: it then carries the layout's HTML as well, and the
  plain text stays its text-only version and the bell's text. The layout is built when it is attached, inside the
  caller's own handling of an unreadable label.

**Interface, in outline:** a message object built fluently — recipients (users, queues, groups, a mailbox by team),
channels, subject, body, the record it is about, a layout — and one send that takes a list of messages, so a
trigger sends every message of a chunk in one call.

**Not in the foundation:** who is told about what (each feature's story), the wording (agreed with the client), and
the links in a message. Small helpers beside the service build these: one that gives a record's link for the
audience reading it (an internal user's Lightning link, or an external user's site link read from the site
itself), one that names what changed on a record, and one that lays out an email in the client's brand.

**To decide per project:** whether groups inside groups, roles and territories are resolved (the usual answer is
no: teams are queues or groups of users); whether the bell shows where external users work, checked once that
place exists.

**Done when:** a user named twice gets one email and one bell; a bell-only or email-only message uses that channel
only; nothing goes out while bypassed; a message with no active recipient sends nothing; a mailbox parameter
receives the email, and an empty one is skipped; in a sandbox with a test mailbox, a user with a masked address is
emailed there under their first name, and outside a sandbox nobody is.

### F-6 · Test data — `DstTestDataFactory`

**For:** test records that pass the org's own rules, built in one place, so a new rule in the org breaks one test,
not every feature's tests.

**Behavior**
- Before the factory is written, the snapshot's validation rules, required fields, record-triggered flows and
  duplicate rules on each object the build inserts are read, and the factory sets what they require — a required
  industry and website on an Account, a mailing country on a Contact, an open stage on an Opportunity, a role for
  the owner of an account that external users are enabled on. What each method sets, and why, is in its comment.
- A record the client's automation treats differently by state is built in the state the test asks for, with the
  values a record in that state carries.
- A self-test inserts each kind of record. When it fails, the org changed — a new rule, a flow, a renamed profile —
  and the failure says so before any feature's tests do.
- The factory is Foundation's and calls no other feature's code (§1.4 *Deploying by feature*). Where a test needs
  setup a feature deploys — a queue, a permission set group, a permission set — the factory makes one for the
  test, with a unique name: `queue`, `permissionSetGroup`, and `grantForTest`, which grants read on what it is
  given, Create on a platform event, and a custom permission when one is named. A step that runs a feature's own
  code stays in that feature's tests.
- It creates no internal user when the org has no free license (§2.4 *Licenses*): it gives the running user what
  the record needs instead, such as a role.

**Done when:** the self-test passes in every build org.

### F-7 · Release tooling and the manual steps sheet

**For:** the same release every time, and the steps the metadata cannot carry — kept *from the first sandbox
deployment*.

**Tooling**

| Script | Does |
|---|---|
| `tools/deploy-build.sh <alias>` | Validates `force-app/distributor` against the org as a dry run, with every test class in it. Writes nothing. First reads the deployments the org is running or has queued, and asks before queueing behind one: an org runs one deployment at a time. Without a terminal to ask on, it stops. Prints the validation's job ID at once, and at the end the `sf project deploy quick` command that deploys it within 10 days without running the tests again, with the runbook steps that go before and after it |
| `tools/deploy-build.sh <alias> --deploy` | Validates, checks the org's deployments again, asks, then quick-deploys that validation: the tests run once, in the validation. When Salesforce refuses the quick deploy, the script stops; it never falls back to a full deployment |
| `tools/deploy-build.sh <alias> --exclude <path>` | Leaves out a component the org cannot take, by its path under `force-app/distributor`; repeatable, and combines with the others. A path inside a bundle cannot be left out: the bundle is deployed whole |
| `tools/deploy-build.sh <alias> --feature <slug>` | Validates one feature from `manifest/features/<slug>.xml` with the feature's own test classes, after `tools/feature-manifests.py --check`; with `--deploy`, deploys it (§1.4 *Deploying by feature*) |
| `tools/deploy-changes.sh [<alias>]` | While a story is built: deploys to the developer's own org — the default of `sf config` when no alias is named, never production — only the files of `force-app/distributor` changed since the branch left the default branch, its commits, uncommitted edits and new files alike. No test runs unless asked for (§1.3): `--tests` runs those that cover the change, `--all-tests` every one; without them the script says how many `--tests` would run. The tests that cover the change are each changed test class, the test class named after each changed component, and every test class whose code names one. A test that reaches the change only through another class, and a flow or a rule no test names, are not found: the script lists the names no test uses, and the full validation covers the rest. A test class the org has not taken yet is left out, and named. The runbook's steps for a changed file are pointed to before the question and after the deployment. Asks first; a failing test leaves the org as it was. `--dry-run` validates only, `--from <commit>` deploys what the commits since that one changed, without uncommitted edits. A deleted component is listed, not deleted in the org |
| `tools/feature-manifests.py` | Writes the feature manifests from `features` in `project.config.json`; `--check` writes nothing and fails when one is out of date, or a component matches no feature or two |
| `tools/lib/sf-jobs.sh` | Shared by both deploy scripts, sourced, not run: starts a deployment job without waiting so its ID is known at once, follows it to its result, reads the org's running and queued deployments and asks before queueing behind one |

The pipeline runs `tools/deploy-build.sh` with flags of its own — queue without asking, write the test results as
JUnit — described in `ci-cd.md`. The scripts need `sf` and `jq`; `tools/feature-manifests.py` runs through `uv`.

**Before every promotion**, retrieve what the release touches from the target org and diff it against the branch:
the client's administrators change sandboxes, and production may be hotfixed, so the target can hold changes the
repository has never seen. The step is in `release-runbook.md`.

**Why the deployment reuses the validation.** A deployment runs its Apex tests one after another, and in a large
build they are most of a validation's time; a deployment that followed a validation would run the same tests
again. A quick deploy takes the validated build as it is. The Salesforce CLI's help advises `validate` and `quick`
for production only, because a sandbox deployment runs no tests by default; a validation with `RunSpecifiedTests`
runs them, and its quick deploy is accepted in a sandbox too.

**Why `deploy-changes.sh` picks the tests by name.** The CLI also offers `RunRelevantTests` (Beta), where
Salesforce picks the tests. In practice it can pick none for a class whose test exists, and hundreds for a small
foundation class. Picking by name gives a list a reader can predict and check before the job starts.

**Manual steps sheet** — one row per step the day it appears; a tick per org once it has been run there. The sheet
is `release-runbook.md`: steps before deployment, and steps after it.

### F-8 · Collision map — the automation already in the org

**For:** deciding, before any trigger on an object the client already automates is built, what happens to each
piece of automation the new design meets. Built on its own in a sandbox, new logic would run beside the old from
the first deploy, not from the release that replaces it.

**Deliverable:** `automation-collision-map.md` — one row per trigger, flow, process, workflow rule and validation
rule on the objects the build touches: what each does, what replaces it, and the proposed decision (switch off at
the release that replaces it, keep, or decide in a named story's design).

**Done when:** every row is agreed, before the first story that replaces one.

### F-9 · The write — `DstDml`

**For:** testing a service's rules without the database. A service that writes directly can only be tested by
inserting and updating records, and every write runs the build's triggers and the client's flows. Every write goes
through one interface that a unit test replaces.

**Behavior**
- `DstDml` is an interface with one method per operation and outcome. `insertAll`, `updateAll` and
  `upsertAll` save every record or none, and throw `DstDmlException`; `insertEach`, `updateEach` and
  `deleteEach` save — or delete — each record they can and return one `DstDmlResult` per record, in
  the order given. `insertEach` also takes `Database.DMLOptions`, for a duplicate rule's *allow save*. An operation
  is added when a story first needs it.
- Every call names a `DstDmlMode`: `USER`; `SYSTEM_WITH_SHARING`, past the user's object and field
  access but within the sharing rules; `SYSTEM_WITHOUT_SHARING`, past both. A system mode carries a comment at the
  call saying why (SEC-04).
- `DstDatabaseDml` is the implementation on `Database`: an inner `with sharing` writer for the first
  two modes and an inner `without sharing` writer for the third. A refused whole save becomes a
  `DstDmlException` with the first failed record's status code, message and Id; its own message is the
  platform's whole text, and the `DmlException` is its cause.
- `upsertAll` inserts the records without an Id and updates the others, under one savepoint when both are there:
  Apex upserts a `List<SObject>` only when it knows the type when compiling.
- A class holds the write as it holds a selector, in a `@TestVisible private static` field set from
  `DstDmlProvider.get()` (§2.7). The provider chooses the implementation in code, so another one —
  on a DML library, for example — replaces it in one line without a change to its callers.
- `DstDmlFake` (`@IsTest`) answers as the database would: fake Ids for new records, refusals for the
  records a test names, an insert with an Id or an update without one refused, and every call kept with its mode.
  A static helper gives a test a distinct fake Id for a record in memory.
- Nothing outside `DstDatabaseDml` and the test classes writes records: the Code Analyzer rule
  `DmlOnlyThroughDmlClass` reports any other `insert`, `update`, `upsert`, `delete` or `Database.*` write (APX-41).

**Done when:** each mode saves or refuses another user's record as its sharing says; a partial save returns each
refused record's status code and messages; a refused whole save throws with them and keeps nothing; an upsert of
new and saved records keeps both or neither; `regex:DmlOnlyThroughDmlClass` finds no write outside
`DstDatabaseDml`.

### F-10 · Switches — `DstSwitches`, `DST_Automation_Switch__mdt`

**For:** the client's administrators, who may have no Apex developers, stopping an automation we built without a
release. F-2 stops all of it for a user, a profile or an org; a switch stops one feature or one automation for
everyone.

**Decisions behind it**
- **Custom Metadata, not a custom setting.** Records deploy with the code, so each switch's default is in the
  repository and the same in every org; a new switch is a record, not a field; Apex reads them from the
  application cache, with no query. A hierarchy custom setting would give values per user and per profile, but they
  are set by hand in each org, and every switch would be a field of its own.
- **Global, not per user or per profile.** A switch is on or off for everyone. For a user, a profile or the org,
  F-2 already stops all automation at once. A bypass permission per switch is not built until someone needs to
  skip one automation for some users only.

**Behavior**
- One record per feature and one per automation: `Active__c`, checked as delivered; `Feature__c`, the feature an
  automation belongs to — a restricted picklist whose values are the feature records' names, empty on a feature's
  own record; `Description__c`, what turning it off does, for the administrator.
- `DstSwitches.isOn(name)` is true only while the record named and its feature's record are both
  active. Only one level up is read. A name with no record is on, so a record missing from an org never stops
  logic unseen.
- A trigger handler's switch is named after its class, and `DstTriggerHandler.run()` reads it after the
  bypass (F-1), so every handler has one with no code of its own. Every other entry point checks its own (§2.3
  *Switches*). The log's trigger and `DstLogAction` have none, as they ignore the bypass: a log is kept
  whatever is switched off.
- A test sees every switch on, whatever the org it runs in holds, so a switch an administrator turned off in
  production never fails the tests of a deployment there. A test turns one off with
  `DstSwitches.overrides`; the class's own test can read the org's records when it asks to.
- The administrator unchecks *Active* in Setup → Custom Metadata Types → *Automation Switch* → Manage Records,
  which takes *Customize Application*; `DST_Admin_Access` reads the type (MDT-15). The type's layout
  carries *Active*, *Feature* and *Description*: the layout an org makes on its own shows only the label, the name
  and *Protected*, so *Active* could not be changed without it.
- Records saved while a switch is off are not processed again when it is switched back on.
- A deployment that carries a record sets it back to the repository's value, so a switch turned off in an org is
  checked before a release (`release-runbook.md`).

**Records** — the list for the client's administrators is `automation-switches.md`. They deploy with Foundation, a
feature's records included, so a handler already in an org finds its switch whichever feature a release deploys
first. A feature's switch stops only the automations that check a switch under it: an entry point that has none
yet keeps running, and `automation-switches.md` says which.

**To decide per project:** who may change a switch in production, and whether a change needs a change record.

**Done when:** a handler whose switch, or whose feature's switch, is off does nothing, and runs again once it is on;
a feature switched off stops every automation under it, and an automation switched off only itself; every trigger
handler has a switch with a feature; every user whose actions run our code reads the switches; the tests pass
whatever the org's switches say.

---

## 4 · Order of work for a new project

1. The team reads this page, `architecture.md` and `code-review-rules.md`, adjusts the defaults it does not keep,
   and records the agreement in the decisions log.
2. The snapshot is retrieved into `force-app/main/default/` and committed once; the build orgs are created, one per
   developer, and the org's own tests are run once in one of them (§1.3).
3. The local checks and the pipeline are set up (§1.5, `ci-cd.md`), and their first run is recorded.
4. F-1 to F-6 in one merge request, validated in a build org.
5. F-7 scripts in use from the first deployment; the runbook starts with the first manual step.
6. F-8 collision map — can run in parallel with step 4, and is agreed before the first story that replaces a row.
7. F-9 and F-10 before the first service and the first trigger handler of a feature.
8. The data model, in Foundation; then the features, in the order of `project.config.json`.

**Open items** of the project — which org the pipeline validates in and as which user, the sender address of the
build's emails, log retention and alerts after handover, who may change a switch in production — go to the open
questions with an owner, not into this page.
