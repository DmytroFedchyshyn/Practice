// Opens a merge request thread for each finding that has to be dealt with before a merge
// (docs/engineering/development-foundation.md §1.5), and resolves the threads whose finding has gone.
//
//   node tools/ci/mr-review-threads.mjs [code-analyzer.json] [gitleaks.json]
//
// Threads are opened for Code Analyzer findings of Critical or High severity and for every gitleaks
// finding. The project setting "All threads must be resolved" then holds the merge until each one is
// fixed or resolved by someone who says why it stays.
//
// Each thread carries a hidden marker made from the finding, so a rerun does not open it twice. A
// thread resolved by a person stays resolved. Code Analyzer runs only when code changed: with no
// report and no sign that it started, its threads are left as they are. A job that started and wrote
// no report, or a missing gitleaks report (that job always runs), fails this one, so a crashed check
// never reads as a clean one.
//
// Needs REVIEW_BOT_TOKEN: a project access token with the api scope and the Developer role,
// stored as a masked CI/CD variable that is not protected, so merge request pipelines can read it.
import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { isAbsolute, relative } from "node:path";

const [analyzerFile = "reports/code-analyzer.json", gitleaksFile = "reports/gitleaks.json"] = process.argv.slice(2);
const env = process.env;
const token = env.REVIEW_BOT_TOKEN;
const iid = env.CI_MERGE_REQUEST_IID;

if (!iid) {
    console.log("Not a merge request pipeline; nothing to comment on.");
    process.exit(0);
}
if (!token) {
    console.error(
        "REVIEW_BOT_TOKEN is not set, so no review threads were opened. Add it under Settings → CI/CD → Variables (docs/engineering/development-foundation.md §1.5)."
    );
    process.exit(1);
}

// The marker names the bot's threads: REVIEW_MARKER, else reviewMarker in project.config.json.
const config = existsSync("project.config.json") ? JSON.parse(readFileSync("project.config.json", "utf8")) : {};
const MARKER = env.REVIEW_MARKER || config.reviewMarker || "code-review";
const escaped = MARKER.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const markerPattern = new RegExp(`<!-- ${escaped}:(\\S+) (\\S+) -->`);
const api = `${env.CI_API_V4_URL}/projects/${env.CI_PROJECT_ID}/merge_requests/${iid}`;
const blob = (path, line) => `${env.CI_PROJECT_URL}/-/blob/${env.CI_COMMIT_SHA}/${path}#L${line}`;

async function gitlab(method, path, body) {
    const response = await fetch(`${api}${path}`, {
        method,
        headers: { "PRIVATE-TOKEN": token, "Content-Type": "application/json" },
        body: body ? JSON.stringify(body) : undefined
    });
    if (!response.ok) {
        const error = new Error(`${method} ${path}: ${response.status} ${await response.text()}`);
        error.status = response.status;
        throw error;
    }
    return { data: await response.json(), next: response.headers.get("x-next-page") };
}

const id = (key) => createHash("sha1").update(key).digest("hex").slice(0, 16);

// --- What this pipeline found -------------------------------------------------------------------

const sources = new Set();
const findings = [];

const analyzerStarted = analyzerFile.replace(/[^/]*$/, "code-analyzer.started");
if (existsSync(analyzerStarted) && !existsSync(analyzerFile)) {
    console.error("Code Analyzer started but wrote no results; its job log says why. Rerun it, then this job.");
    process.exit(1);
}
if (!existsSync(gitleaksFile)) {
    console.error(`No gitleaks report at ${gitleaksFile}; the secrets job did not finish. Rerun it, then this job.`);
    process.exit(1);
}

if (existsSync(analyzerFile)) {
    sources.add("code-analyzer");
    const results = JSON.parse(readFileSync(analyzerFile, "utf8"));
    const root = results.runDir ?? process.cwd();
    const severityName = { 1: "Critical", 2: "High" };
    const repeats = new Map();
    for (const violation of results.violations ?? []) {
        if (!(violation.severity in severityName)) continue;
        const location = violation.locations?.[violation.primaryLocationIndex ?? 0] ?? {};
        const file = location.file ?? "";
        const path = (isAbsolute(file) ? relative(root, file) : file).split("\\").join("/").replace(/^\.\//, "");
        const line = location.startLine ?? 1;
        const rule = `${violation.engine}:${violation.rule}`;
        // No line number in the key, so a finding keeps its thread when code above it moves.
        const base = `${rule}|${path}|${violation.message.trim()}`;
        const occurrence = (repeats.get(base) ?? 0) + 1;
        repeats.set(base, occurrence);
        const help = violation.resources?.[0] ? ` · [rule](${violation.resources[0]})` : "";
        findings.push({
            source: "code-analyzer",
            key: id(`code-analyzer|${base}|${occurrence}`),
            path,
            line,
            text:
                `**Code Analyzer · ${severityName[violation.severity]} · \`${rule}\`**${help}\n\n` +
                `${violation.message.trim()}\n\n[\`${path}\` line ${line}](${blob(path, line)})\n\n` +
                "Fix it, or resolve this thread with a reply saying why it stays (docs/engineering/development-foundation.md §1.5)."
        });
    }
}

{
    sources.add("gitleaks");
    for (const leak of JSON.parse(readFileSync(gitleaksFile, "utf8") || "[]")) {
        const path = leak.File;
        const line = leak.StartLine ?? 1;
        findings.push({
            source: "gitleaks",
            key: id(`gitleaks|${leak.RuleID}|${path}|${line}`),
            path,
            line,
            text:
                `**gitleaks · possible secret · \`${leak.RuleID}\`**\n\n` +
                `${leak.Description ?? ""} in commit \`${String(leak.Commit).slice(0, 8)}\`.\n\n` +
                `[\`${path}\` line ${line}](${blob(path, line)})\n\n` +
                "If it is real: revoke and reissue it first, then remove it. If it is not: add it to " +
                "`.gitleaks.toml` with the reason, and resolve this thread (docs/engineering/development-foundation.md §1.5)."
        });
    }
}

// --- The bot's threads already on the merge request ---------------------------------------------

const existing = new Map();
for (let page = "1"; page; ) {
    const { data, next } = await gitlab("GET", `/discussions?per_page=100&page=${page}`);
    for (const discussion of data) {
        const match = discussion.notes?.[0]?.body?.match(markerPattern);
        if (match) existing.set(match[2], { id: discussion.id, source: match[1], resolved: discussion.notes[0].resolved });
    }
    page = next;
}

// --- Open what is new, resolve what has gone ----------------------------------------------------

const { data: versions } = await gitlab("GET", "/versions");
const diff = versions[0];
let opened = 0;
let resolved = 0;

for (const finding of findings) {
    if (existing.has(finding.key)) continue;
    const body = `<!-- ${MARKER}:${finding.source} ${finding.key} -->\n${finding.text}`;
    try {
        // On the line itself when the merge request added it; otherwise on the merge request.
        await gitlab("POST", "/discussions", {
            body,
            position: {
                position_type: "text",
                base_sha: diff.base_commit_sha,
                start_sha: diff.start_commit_sha,
                head_sha: diff.head_commit_sha,
                new_path: finding.path,
                new_line: finding.line
            }
        });
    } catch (error) {
        if (!(error.status >= 400 && error.status < 500)) throw error;
        await gitlab("POST", "/discussions", { body });
    }
    opened++;
}

const current = new Set(findings.map((finding) => finding.key));
for (const [key, thread] of existing) {
    if (thread.resolved || current.has(key) || !sources.has(thread.source)) continue;
    await gitlab("POST", `/discussions/${thread.id}/notes`, {
        body: `Gone in ${env.CI_COMMIT_SHORT_SHA}: resolved by the pipeline.`
    });
    await gitlab("PUT", `/discussions/${thread.id}?resolved=true`);
    resolved++;
}

const open = findings.filter((finding) => !existing.get(finding.key)?.resolved).length;
console.log(`Review threads: ${opened} opened, ${resolved} resolved by the pipeline, ${open} finding(s) to deal with.`);
