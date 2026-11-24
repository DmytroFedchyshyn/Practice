// Turns Salesforce Code Analyzer JSON results into a GitLab Code Quality report, so the findings
// show in the merge request (docs/engineering/development-foundation.md §1.5).
//
//   node tools/ci/code-analyzer-to-codequality.mjs <code-analyzer.json> <gl-code-quality-report.json>
//
// A missing input file gives an empty report: the analyzer failed before writing results, and the
// job's own exit code already says so.
import { createHash } from "node:crypto";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { isAbsolute, relative } from "node:path";

const [input, output] = process.argv.slice(2);
if (!input || !output) {
    console.error(
        "Usage: node tools/ci/code-analyzer-to-codequality.mjs <code-analyzer.json> <gl-code-quality-report.json>"
    );
    process.exit(2);
}

// Code Analyzer: 1 Critical, 2 High, 3 Moderate, 4 Low, 5 Info.
const SEVERITY = { 1: "blocker", 2: "critical", 3: "major", 4: "minor", 5: "info" };

const results = existsSync(input) ? JSON.parse(readFileSync(input, "utf8")) : { violations: [] };
const root = results.runDir ?? process.cwd();
const repeats = new Map();

const report = (results.violations ?? []).map((violation) => {
    const location = violation.locations?.[violation.primaryLocationIndex ?? 0] ?? {};
    const file = location.file ?? "";
    const path = (isAbsolute(file) ? relative(root, file) : file).split("\\").join("/").replace(/^\.\//, "");
    const checkName = `${violation.engine}:${violation.rule}`;
    // No line number in the fingerprint, so a finding keeps its identity when code above it moves;
    // a counter keeps repeats of the same finding in one file apart.
    const key = `${checkName}|${path}|${violation.message}`;
    const occurrence = (repeats.get(key) ?? 0) + 1;
    repeats.set(key, occurrence);
    return {
        description: violation.message.trim(),
        check_name: checkName,
        fingerprint: createHash("md5").update(`${key}|${occurrence}`).digest("hex"),
        severity: SEVERITY[violation.severity] ?? "info",
        location: { path, lines: { begin: location.startLine ?? 1 } }
    };
});

writeFileSync(output, JSON.stringify(report, null, 2));
console.log(`Code Quality report: ${report.length} finding(s) written to ${output}`);
