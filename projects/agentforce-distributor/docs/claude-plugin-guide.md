# Working with Claude on this project (sf-project-flow)

`sf-project-flow` is the project's Claude plugin. It carries three skills that hold the way we
build and write: a change is planned, approved, built to the review rules and reviewed by rule
ID before it ships; documentation follows one house style; research is sourced and dated.

The rules for the board and the repository — every piece of work starts from a task on the
the repository's issues, every change reaches `master` through a merge request or,
when you ask, a direct push — are not in the plugin: they are in `CLAUDE.md` at the repository
root, which every session in the project loads.

The plugin is scoped to this project — repository `DmytroFedchyshyn/Practice`, tracker
the repository's issues. Pointed at another repository or board it stops and says so.

Prerequisite: your computer must be connected to the repository host and the tracker first —
see [`claude-mcp-setup.md`](claude-mcp-setup.md). Without those local MCP servers Claude cannot
reach the board or open a merge request.

---

## 1 · Install

The plugin ships **in this repository**. There is nothing to download, nothing to package
and nothing to send anyone: it lives in `.claude/plugins/sf-project-flow/`, and
`.claude/settings.json` both registers it — `extraKnownMarketplaces` points the local
marketplace `project-plugins` at `./.claude/plugins` — and switches it on through
`enabledPlugins` as `sf-project-flow@project-plugins`.

1. Clone the repository, or `git pull` if you already have it.
2. Connect the folder to your session: **Add folder** → your local clone. That working copy
   is what the skills read and edit.
3. Reopen the session so the plugin loads. Confirm: **Settings → Plugins** lists
   `sf-project-flow` with its version, and **Settings → Skills** shows three skills prefixed
   `sf-project-flow:`.

A change to a skill therefore reaches everyone the same way any other change does — through
the repository, then `git pull` and reopen. Nobody is sent a file, and nobody ends up running
a version the repository does not have.

### The hooks that come with it

`.claude/settings.json` also holds two `PreToolUse` hooks. They hold whether or not the plugin
is enabled, because they enforce rules of `CLAUDE.md`, not of a skill:

- **An `ask` before any org write.** A `sf` command that deploys or deletes source
  (`project deploy start`, `deploy quick`, `force source deploy/push`, `project delete source`)
  or writes data (`sf data create/update/upsert/delete/import`) stops for your permission,
  unless it is a `--dry-run` (`CLAUDE.md` §3).
- **`.claude/hooks/protected-path-guard.sh`.** It denies `git push --no-verify`, which would
  skip the pre-push check, and denies a write of a protected path (by default anything under
  `force-app/`) straight to `master` through the repository host's MCP server,
  which runs no local hook (`CLAUDE.md` §2, `development-foundation.md §1.4`).

---

## 2 · The three skills

You do not invoke these. Claude matches what you ask against each skill's description and
loads the right one. Naming one explicitly (`/sf-project-flow:plan-build-review`) is only for
when it picks the wrong one. One is worth typing on purpose: `/implement <what>`, when you
want the plan-first flow of `plan-build-review`. `/doc <what>` and `/research <question>`
start the other two.

### `plan-build-review` — a plan before the work, one screen after it

Fires when you ask to implement, fix or change code, metadata or tooling, on "plan it
first", or on `/implement <what>`. Docs-only work stays with `project-docs` unless you ask
for a plan first.

Finds or creates the task as `CLAUDE.md` §1 says, reads it, the code around the change and
[`engineering/code-review-rules.md`](engineering/code-review-rules.md), then shows a plan of
about a dozen lines and one more per acceptance criterion — goal, steps, files, the rules that
shape the work, the features the change touches, and each criterion with the test planned to
prove it — and changes nothing until you say yes, in whatever language you write. If the plan
has to change on the way, it stops and shows you what changes.

A component it creates under `force-app/distributor` that no feature in `project.config.json` covers
gets a glob in the `features` list, and `manifest/features/` is rewritten with
`python3 tools/feature-manifests.py` in the same change (GEN-14,
[`development-foundation.md §1.4`](engineering/development-foundation.md) *Deploying by
feature*).

It builds to every review rule that applies, *Proposed* ones included, then runs the checks
— Prettier, Code Analyzer, Jest when a Lightning web component changed, gitleaks,
`tools/feature-manifests.py --check`, and `tools/deploy-changes.sh --dry-run` — the branch's
changes compiled in your own build org, with no test unless you ask
([`development-foundation.md §1.3`](engineering/development-foundation.md)) — when `sf` can
reach that org — and hands the diff to a separate read-only agent that reviews it against
`code-review-rules.md` and names a rule ID in every finding. What happens to a finding follows
the severity table in `code-review-rules.md §1`: Critical is fixed before the merge; High is
fixed, or stays with its reason in the merge request when the fix lies outside the plan.

It ends with one screen: what was done, why where it is not obvious, the review by rule ID,
each acceptance criterion with the test that proves it (TST-02), how to verify, manual steps
after deploy, up to three SIT or UAT scenarios the change needs that no unit test can show —
a recommendation in the chat, written nowhere else — and one next step. A check that could
not run is reported as not run. It does not commit, push or open the merge request — that
happens when you ask, the way `CLAUDE.md` §2 says.

### `project-docs` — the `docs/` house style

Fires whenever you write or update anything under `docs/`.

Knows where a document belongs ([`README.md`](README.md) describes the tree), the naming of
its neighbours, how an option comparison and a migration are written, the section-scoped
Mermaid diagrams with `[A]`/`[M]` markers, and the rule that every claim carries its source.
Unknowns are recorded as open questions with an owner instead of being filled with a
plausible guess. Anything the client receives also follows
[`document-standard.md`](document-standard.md).

### `discovery-research` — options research you can defend

Fires on "compare these integration options", "what does that licence cost", "is this
feasible on our edition".

Searches before answering, prefers primary sources, separates what is documented from what
practitioners report from what it inferred, and writes the result into
`docs/investigation/` with dated sources and an explicit recommendation. What it could not
confirm is stated as such.

Connecting the MCP servers is **not** a skill — it is a one-time setup a person performs,
documented in [`claude-mcp-setup.md`](claude-mcp-setup.md).

---

## 3 · A normal piece of work, start to finish

> **You:** /implement require a reason when an approver rejects a request.

Claude searches the repository's issues, finds nothing close, proposes a task; you say yes. It creates
it in the active sprint and shows the plan. You say yes again; it moves the task to
*In Progress*, builds the validation rule and its Apex test to the review rules, runs the
checks, has the diff reviewed by a separate agent, fixes a High finding, and reports on one
screen.

You ask for a merge request. Claude creates `feature/42-reject-reason` from an
up-to-date `master`, opens `#42 · Require a reason on rejection`
with What / Why / How to verify and each acceptance criterion with its test, and moves the
task to *In Review*. No comment goes on the task unless you ask for one.

You review the merge request and merge it, or ask Claude to. You move the task to *Done*, or
ask Claude to once the work is in `master`.

---

## 4 · What Claude will not do here

- Push to `master` or merge a merge request unless you ask it to; force-push, ever;
  push with `--no-verify`, ever.
- Approve or close a merge request.
- Mark a task Done unasked, or touch someone else's assignment, sprint, priority or estimate.
- Comment on a task or a merge request unless you ask for that comment.
- Deploy to an org or write org data without your yes for that command.
- Delete anything on the repository host or in the tracker, or change project settings,
  CI/CD variables, webhooks or protected-branch rules — without asking first.
- Invent a fact to close a gap in a document.

These are not just plugin behaviour: `CLAUDE.md` at the repository root states them for
every session in this project, and they hold whether or not the plugin is installed. If
`CLAUDE.md` and the plugin ever disagree, `CLAUDE.md` wins.

---

## 5 · When a skill gets something wrong

A skill firing at the wrong moment, or not firing when it should, is a wording gap in its
description — not something to work around. Two things help:

- **In the moment:** say what you expected. "You should have shown me the plan first" is
  enough for Claude to correct course in that session.
- **For good:** ask Claude to update the skill — "update plan-build-review so that …" — and
  ship the change through the repository like any other, with the plugin's `version` bumped
  in `.claude/plugins/sf-project-flow/.claude-plugin/plugin.json`.

Every gotcha written into these skills should come from something that actually broke. Keep
that going: when a session goes wrong in a way that will repeat, the fix belongs in the
skill, not in someone's memory.
