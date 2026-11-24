// Prints Salesforce Code Analyzer findings in the job log, so they can be read where the CI platform
// shows them, without downloading the HTML report (docs/engineering/development-foundation.md §1.5).
//
//   node tools/ci/code-analyzer-log.mjs <code-analyzer.json>
//
// Grouped by severity, worst first; each finding links to its line at the commit the pipeline ran on.
// Critical and High are open; Moderate, Low and Info are folded into sections that expand on click.
import { existsSync, readFileSync } from "node:fs";
import { isAbsolute, relative } from "node:path";

const [input] = process.argv.slice(2);
if (!input || !existsSync(input)) {
    console.log("No Code Analyzer results to print.");
    process.exit(0);
}

const results = JSON.parse(readFileSync(input, "utf8"));
const root = results.runDir ?? process.cwd();
const env = process.env;
// A link to the line on the platform the job runs on: GitLab, GitHub, or plain path:line elsewhere.
const link = (path, line) => {
    if (env.GITLAB_CI && env.CI_PROJECT_URL) return `${env.CI_PROJECT_URL}/-/blob/${env.CI_COMMIT_SHA}/${path}#L${line}`;
    if (env.GITHUB_ACTIONS) return `${env.GITHUB_SERVER_URL}/${env.GITHUB_REPOSITORY}/blob/${env.GITHUB_SHA}/${path}#L${line}`;
    return `${path}:${line}`;
};

const SEVERITY = {
    1: { name: "Critical", colour: "\x1b[1;31m", folded: false },
    2: { name: "High", colour: "\x1b[31m", folded: false },
    3: { name: "Moderate", colour: "\x1b[33m", folded: true },
    4: { name: "Low", colour: "\x1b[36m", folded: true },
    5: { name: "Info", colour: "\x1b[37m", folded: true }
};
const reset = "\x1b[0m";
const bold = "\x1b[1m";

const findings = (results.violations ?? []).map((violation) => {
    const location = violation.locations?.[violation.primaryLocationIndex ?? 0] ?? {};
    const file = location.file ?? "";
    return {
        severity: violation.severity,
        rule: `${violation.engine}:${violation.rule}`,
        path: (isAbsolute(file) ? relative(root, file) : file).split("\\").join("/").replace(/^\.\//, ""),
        line: location.startLine ?? 1,
        message: violation.message.trim().replace(/\s+/g, " ")
    };
});

const counts = Object.entries(SEVERITY)
    .map(([level, { name }]) => [name, findings.filter((finding) => finding.severity === Number(level)).length])
    .filter(([, count]) => count > 0)
    .map(([name, count]) => `${count} ${name}`);
console.log(`\n${bold}Code Analyzer: ${findings.length} finding(s)${counts.length ? ` — ${counts.join(", ")}` : ""}${reset}`);

// Collapsible log sections: GitLab (https://docs.gitlab.com/ci/jobs/job_logs/#custom-collapsible-sections),
// GitHub Actions and Azure Pipelines (##[group]). Elsewhere a plain header.
const section = (name, header, folded, body) => {
    if (env.GITLAB_CI) {
        const now = Math.floor(Date.now() / 1000);
        console.log(`\x1b[0Ksection_start:${now}:${name}${folded ? "[collapsed=true]" : ""}\r\x1b[0K${header}`);
        body();
        console.log(`\x1b[0Ksection_end:${now}:${name}\r\x1b[0K`);
    } else if (folded && (env.GITHUB_ACTIONS || env.TF_BUILD)) {
        console.log(`##[group]${header}`);
        body();
        console.log("##[endgroup]");
    } else {
        console.log(header);
        body();
    }
};

for (const [level, { name, colour, folded }] of Object.entries(SEVERITY)) {
    const group = findings
        .filter((finding) => finding.severity === Number(level))
        .sort((a, b) => a.path.localeCompare(b.path) || a.line - b.line);
    if (group.length === 0) continue;
    section(`ca_${name.toLowerCase()}`, `${colour}${bold}${name} (${group.length})${reset}`, folded, () => {
        for (const finding of group) {
            console.log(`  ${colour}${finding.rule}${reset}  ${finding.path}:${finding.line}`);
            console.log(`      ${finding.message}`);
            console.log(`      ${link(finding.path, finding.line)}`);
        }
    });
}
