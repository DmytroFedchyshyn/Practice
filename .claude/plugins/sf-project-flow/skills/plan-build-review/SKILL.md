---
name: plan-build-review
description: Run a change in this project's repository in a fixed order — a short plan the person approves, the change built to the review rules in docs/engineering/code-review-rules.md, an independent review against those rules by rule ID, and a one-screen report. Use when someone asks to implement, fix or change code, metadata or tooling in this repository, says "plan it first" or "show me the plan", or types /implement. Docs-only work stays with project-docs unless the person asks for a plan first.
---

# Plan, approve, build, review, report

## Scope

This plugin serves one project, named in `${CLAUDE_PLUGIN_ROOT}/project.md` with its
repository and tracker. Read that file for the constants and run the scope check there before
any write. If the session is working on a different repository or board, stop and say so
rather than adapting this skill to it.

Five steps, always in this order: understand, plan, build, review, report. Apart from what
finding the task asks of the person (`CLAUDE.md` §1), the person reads two messages from this
skill — the plan and the report. Both fit on one screen; everything between them is work, not
narration.

## Language

The plan and the report are written in the person's language: translate the headings of
the templates below, keep their order. Everything that lands in the repository, on the
board or in a merge request is English (`project.md`, *Language*).

## The rules this skill works to

`docs/engineering/code-review-rules.md` is the list a change is checked against;
`docs/engineering/development-foundation.md` §2 says how we write code and why. Both apply
twice: while the change is built, and when it is reviewed.

- **Read code-review-rules.md from the working copy at the start of every run.** Rules are
  added and change status; a version remembered from an earlier session is stale.
- **Cite, never copy.** Name rules by ID in the plan, the review and the report. Restating a
  rule's text — or its severity table — creates the second version of the truth that
  code-review-rules.md exists to prevent.
- **Every rule not *Retired* applies, *Proposed* included.** Building to a rule the review
  then flags is wasted work. Severity decides what happens to a finding (step 4), not
  whether the rule is followed.
- If code-review-rules.md is missing — an old branch — work to development-foundation.md §2
  and say so in the report.

Which areas apply:

| The change touches | Areas in code-review-rules.md |
|---|---|
| anything | GEN, and TST-02 for the trace of the criteria |
| Apex classes or triggers | SEC, APX, TST |
| Lightning web components | LWC, plus SEC for their Apex controllers |
| objects, fields, permissions, flows, other metadata | MDT, plus SEC for access |
| only `docs/` | GEN-08, and the `project-docs` skill |

## 1 · Understand — read first

- **The task.** Find or create it as `CLAUDE.md` §1 says, and those asks come first: report
  what was searched, confirm the match or let the person choose, and get a yes before
  creating. Its acceptance criteria define done. If it has none, draft them in the plan, say
  so, and offer to add them to the task.
- **The rules.** code-review-rules.md, for the areas the change touches.
- **The design.** `docs/technical-design.md` (project-owned) or the feature's spec. A new Apex
  component is named there before it is built (APX-13); one that is not is raised in the plan,
  not invented.
- **The code around it.** The files the change touches and their neighbours: an existing
  pattern beats a new one.
- **The baseline.** Run `git status --porcelain -uall` and keep the result — `-uall`,
  because without it a new folder shows as one line and a new file inside it cannot be told
  apart. The working copy usually carries other uncommitted work; the review and the report
  cover only what this task changed. Before editing a file that is already modified, copy it
  to scratch space outside the connected folder and diff against that copy later.

Read without commentary in the chat. Ask a question only when the answer changes the plan,
and ask one. Otherwise make the assumption and write it into the plan.

## 2 · Plan — then stop

```
**Plan · <task key> <what will change>**
Goal: <one sentence — what is true after the change>
1. <verb + what + where>
2. …
Files: <paths, grouped> · Rules: <only the IDs that shape the work>
Features: <slugs the changed components fall in; + the glob added for a new one no feature covers> | none
Done when:
- <acceptance criterion, shortened> → <test planned for it | manual: why>
Risks, assumptions, not included: <only if any>
Task: <task key> (found by "<search terms>") → In Progress once approved
Approve?
```

- The whole plan is about thirteen lines, template lines included, plus a line for each
  criterion — which leaves room for five steps. No code, no restating the request, no rule
  text.
- **Done when** traces every acceptance criterion of the task to the test that will prove
  it (TST-02): an Apex test method, or a Jest test for logic in a component (LWC-05), named
  for the behaviour (TST-05). Mark a criterion no unit test can prove — what a user sees,
  an email that arrives, a change to tooling or docs — `manual: <why>`; it is proven under
  *How to verify*.
- **Rules** names only the rules that change *what* gets built or added — a test with 200
  records (TST-10), a runbook entry (GEN-07), a line in the design (APX-13), a collision-map
  row (APX-14), a Queueable for mixed DML (APX-16). The rest are followed without being
  listed; listing all of them is noise.
- **Features** names the features of `project.config.json` the change touches, so the person
  sees which manifests it rewrites (GEN-14; development-foundation.md §1.4 *Deploying by feature*).
  "none" when nothing under the build folder is created or changed; a component deleted is
  raised in the plan.
- Anything that needs its own permission — a deploy, a data write, a push — is named and
  stays outside this approval.
- Two concerns are two plans and two merge requests (GEN-05). Say so instead of planning
  both.

Then **stop**. No file is created or changed before an explicit yes, in whatever language the
person writes. A question or an edit to the plan is not a yes: answer it, show the revised
plan, stop again. Silence is not a yes; in an unattended run, leave the plan and end.

The yes covers the plan as shown and the board move on its Task line — nothing more.

If the person asks to skip the approval, still show the plan in two or three lines, then
carry on. Skipping the plan does not approve the board move: ask for it in one line, or
report it as drafted and not made.

## 3 · Build — to the rules

- Edit with the Edit tool where the session has one; in the shell on the person's computer,
  with `sed -i` or a short Python read-modify-write. Never retype a file from earlier tool
  output — it may have been cut short.
- Build to every applicable rule from the first line. code-review-rules.md is the source;
  these are only where generated code goes wrong most often:
  - fields, methods or API versions that do not exist in the org (GEN-12);
  - a component created or changed outside the build folder (GEN-02);
  - a helper nobody designed (APX-13);
  - a system-mode read or write without a comment saying why (SEC-04);
  - a record Id from the browser used without checking that the caller may act on that
    record (SEC-07);
  - tests that cover lines rather than acceptance criteria (TST-02). Write each test the
    plan's *Done when* names that does not exist yet.
- What ships with the change ships in the same change: documentation (GEN-08, through
  `project-docs`), a manual step after deploy in `docs/engineering/release-runbook.md`
  (GEN-07), a component with its `-meta.xml` (GEN-09), `manifest/` with the metadata it
  covers, and — when a new component matches no feature glob — the glob added to `features`
  in `project.config.json` with `manifest/features/` rewritten by
  `python3 tools/feature-manifests.py` (GEN-14, `CLAUDE.md` §6).
- A new convention is not invented inside a task. If the change needs one, stop and say so:
  it goes into development-foundation.md §2 and its rule into code-review-rules.md in the
  same merge request (`CLAUDE.md` §2), and that is the person's decision.

**When the plan has to change** — files in another area, a different approach, more scope,
a rule that cannot be met — stop, show only what changes in two or three lines, and wait for
a yes. A helper's name or the order of two edits is not a change of plan.

Never as part of this skill: deploy to an org, write org data, commit, push, open a merge
request, comment anywhere, or touch the local tooling folders of `CLAUDE.md` §5. Validating,
`describe` and `query` need no permission (`CLAUDE.md` §3). A retrieve does: it writes into
the working copy and can overwrite this task's edits, someone else's uncommitted work or the
org snapshot. Run it only with `--output-dir` pointing outside the connected folder, or ask
first.

## 4 · Review — independent, by rule ID

This is the author's review before a merge request opens (`CLAUDE.md` §2;
code-review-rules.md §0, the *Author* and *`/code-review`* rows).

### a. Checks

Run what applies, from the repository root:

| Check | Command | When |
|---|---|---|
| Formatting (GEN-04) | `npm run format:check` | something in the build folder changed |
| Code Analyzer | `npm run scan` | something in the build folder changed |
| Jest (LWC-05) | `npm test` | a Lightning web component, `jest.config.js` or the package files changed |
| Secrets (GEN-03) | `gitleaks dir -c .gitleaks.toml --redact --no-banner <path>`, once per changed path | always |
| Feature manifests (GEN-14) | `python3 tools/feature-manifests.py --check` | something in the build folder or the `features` list changed |
| Compile and tests (GEN-12, TST-01) | `tools/deploy-changes.sh --dry-run` — the branch's changes compiled in the person's own build org, nothing written, no test; add `--tests` only when the person asks for the tests (development-foundation.md §1.3) | Apex or metadata changed; with no default org (`sf config get target-org`; it is set with `--global`, development-foundation.md §1.3), report it as *not run* with the command |

- `npm run format:check`, `npm run scan`, `npm test` and the validation cover the whole build
  folder. A finding or a failure in a file this task did not change is not this task's: leave
  it out of triage, and give its count in one line of the report if there is any.
- `npm run secrets` scans commits, so it misses an uncommitted change — use `gitleaks dir`
  until the change is committed. Pass `-c .gitleaks.toml`: pointed at a single file,
  gitleaks does not find the repository's config and reports its known false positives.
- Validate with the project's script, not a hand-made command. It targets the person's own
  build org, the default of `sf config` (development-foundation.md §1.3); name the alias when
  the default is not theirs. It runs no test unless the person asks: while the build is in
  active development, tests run only when asked for (development-foundation.md §1.3). With
  `--tests` it runs only the build's own tests, those that cover the change, with
  `RunSpecifiedTests`: `RunLocalTests` also runs the org's existing tests, which can fail for
  reasons that have nothing to do with the change (development-foundation.md §1.3).
  The whole build is validated, when someone asks, by the pipeline job `apex-validate` once its
  credential is set (`ci-cd.md`), otherwise with `tools/deploy-build.sh <org>`. A full
  validation of a large build runs for tens of minutes — far longer than the shell on the
  person's computer or a Bash tool call allows. Start it only where it can run to the end;
  otherwise do not start it, and give the person the command. A run cut off midway leaves its
  job running in the org with the result unread; the script prints the job ID first, so the
  result can still be read. When the org is already running a deployment, the script asks
  before queueing behind it, and without a terminal it stops without validating: report that,
  never wait in the queue unasked.
- Check that the org is reachable by the exit code only. `sf org display` prints a live
  access token; it must never reach the chat, the transcript or a file (`CLAUDE.md` §5).
- The shell Claude gets on the person's computer may have no `gitleaks`, `sf`, Java or
  `node_modules`. A check that cannot run is reported as *not run*, with the command for the
  person to run before the merge request opens — never left out, never reported as passed.
  Never run `npm install` for Jest: its `prepare` script changes the git configuration (the
  hooks path). Report `npm install && npm test` for the person instead.

### b. The reviewer

Start a separate agent for every change. Give it inputs, not conclusions — an agent handed
your view of the code tends to confirm it:

- the approved plan and the task's acceptance criteria;
- the changed files against the baseline, and their diff. `git diff` leaves out untracked
  files, so pass each new file as `git diff --no-index /dev/null <file>`; a file that was
  already modified is diffed against the copy kept in step 1;
- the path to `docs/engineering/code-review-rules.md`, the areas that apply, and the output of
  the checks above;
- this instruction:

  > Read docs/engineering/code-review-rules.md from the repository. Review the diff against
  > every rule not *Retired* in areas <areas>: the `ai` rows first, then any other row a
  > reader can judge from the diff. Do not repeat what the Code Analyzer output already
  > reports. Check the diff against the plan and each acceptance criterion, and look for
  > defects no rule covers. For each acceptance criterion, find the test that proves it —
  > `Class.method` for Apex, the file and `it` for Jest: a criterion with no such test, or
  > with a test that does not check what the criterion says, is a TST-02 finding, unless the
  > plan marked it manual — and a criterion marked manual that an Apex or Jest test could
  > prove is a TST-02 finding too. You are read-only: do not edit, create or delete any file.
  > Return at most fifteen findings, most severe first, one line each: rule ID or "no rule" ·
  > severity from the rule's row · file:line · what is wrong · the fix. Return "no findings"
  > if there are none. Then list each acceptance criterion with its test, or "none", one line
  > each. Then list the `human` rows that apply to this diff, by ID only.

### c. Triage

Check every finding yourself before acting on it — the reviewer can be wrong. Then do what
code-review-rules.md §1 says for its severity, with this skill's own handling on top:

- **Inside the plan** — Critical and High are fixed. A Moderate one is fixed when it is
  small; otherwise it goes to the person, who decides.
- **Outside the plan** — the fix follows step 3: show it, wait. Until then the finding is
  reported as open. A Critical one blocks the merge until it is fixed; a High one may stay,
  with its reason in the merge request (code-review-rules.md §1).
- **"No rule"** — a defect, such as wrong behaviour or an acceptance criterion not met, is
  fixed; a matter of taste is dropped.
- **A finding that stays** is never hidden. A Code Analyzer finding is suppressed only after
  the person agrees, as code-review-rules.md §2 *Exceptions* says; a gitleaks false positive
  goes into `.gitleaks.toml`, also after a yes; an `ai` or `human` finding is not suppressed —
  it stays, with its reason in the merge request.
- After fixing, rerun the checks that failed. Run the reviewer again only when a Critical or
  High fix changed logic, not wording.
- A "no rule" finding likely to come back is named in the report as a candidate for
  code-review-rules.md §10. Adding it there is the person's call and its own change.

## 5 · Report — one screen

```
**Summary · <task key> <what changed>**

**Done**
- <result, not activity>

**Why this way**
- <only decisions a reader would question>

**Review**
- Fixed: <ID — what, where> | —
- Open: <ID — what, and why it stays> | —
- Checks: Prettier ✓ · Code Analyzer ✓ · Jest ✓ · gitleaks ✓ · manifests ✓ · validate — not run: <reason>
- For the reviewer: <human rule IDs that apply>

**Acceptance criteria → tests**
- <criterion, shortened> → <`Class.method` | Jest `file › it` | manual: why> · <passed | not run | manual>

**How to verify**
1. <action → expected result>

**Manual steps after deploy:** none | <step — added to release-runbook.md>

**For SIT/UAT (recommendation)**
- — | <scenario: who does what, and what they should see>

Next: <one step, usually "open the merge request?">
```

- About twenty lines at most, not counting the criteria; one line per bullet.
- *Acceptance criteria → tests*: every criterion of the task, in its order, shortened to fit
  the line, with the test's name as in the code; one without a test says why.
- *For SIT/UAT*: up to three scenarios no unit test can show — a page as a given user sees
  it, a flow across users, an email that arrives. "—" when the tests cover it all.
- Results, not activity: "A user cannot reject a request without a reason", not "Added a
  validation rule after reading the files".
- Rule IDs, not rule text.
- *Why this way* appears only when there is such a decision, *For the reviewer* only when a
  `human` rule applies. Every other heading stays, with "—" when empty, so the reader finds
  things in the same place every time.
- What was not done, not checked or is still open is said plainly.
- No pasted diffs, tool output or file contents, and no list of every file — at most the two
  or three a reader needs to find the change.
- Anything drafted but not written — a board move, a task — is named as not written.

## 6 · After the report

Offer one next step and stop. The change reaches the default branch the way the project does
it (`CLAUDE.md` §2): for a merge request, its description reuses the report in English —
What, Why, How to verify, manual steps, the features touched, and each acceptance criterion
with its test — and every High finding that stays goes into it with its reason. An open
Critical finding means the merge request is not ready to merge; say so instead of offering to
merge it. The task moves to In Review when the merge request opens (`CLAUDE.md` §1), with its
*Steps to reproduce* drafted from *How to verify* and the criteria marked manual, written only
after a yes (`CLAUDE.md` §1 item 8).

## What must never happen

- A file changed before the plan is approved.
- The plan growing after approval without a second yes.
- A commit, push, merge request, deploy, org data write or comment made by this skill.
- A task marked Done, or a board move made without its yes.
- A component created under the build folder that no feature covers, or feature manifests
  left stale (GEN-14).
- A finding with neither a rule ID nor an explicit "no rule", or a rule restated instead of
  cited.
- An acceptance criterion left out of the report, or a test named there that does not exist.
- A SIT/UAT recommendation written to the board, a document or the merge request. The
  story's own *Steps to reproduce* are not one: they go to the story after a yes.
- A check that did not run reported as passed, or left out of the report.
- The reviewer editing files, or reviewing changes that are not this task's.
- A report longer than one screen — activity logs, pasted output, everything-I-did lists.
