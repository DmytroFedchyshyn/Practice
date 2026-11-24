# sf-project-flow

How this Salesforce project runs inside Claude: a change planned, built and reviewed against
the project's own rules; documentation written to one house style; platform and vendor
questions researched with sources.

This plugin is scoped to one project. It acts only on the repository and tracker named in
`project.md`, which holds the constants and the scope check. Point it at another repository
or board and it will stop and say so — another project needs its own copy with its own
constants.

---

## 1 · What it holds

| Path | What |
|---|---|
| `project.md` | The project's constants — the only file with project values — and the scope check |
| `skills/plan-build-review/` | Plan → yes → build → independent review by rule ID → one-screen report |
| `skills/project-docs/` | Where a document belongs in `docs/`, how it reads, diagrams, unknowns |
| `skills/discovery-research/` | Sourced, dated research written into `docs/investigation/` |
| `commands/` | `/implement`, `/doc`, `/research` — one line each, pointing at the skill |

The rules for the board, branches, commits and merge requests are not in this plugin: they
are in the repository's `CLAUDE.md`, which every session in the project loads, plugin or not.

---

## 2 · Why the tooling is wired this way

Where the repository host and the tracker are unreachable from Claude's cloud sandbox, both
run as **local MCP servers on your own computer**, using your network and your access.

The consequence worth internalising: in that setup `git push` from Claude's cloud sandbox
never works. Everything reaching the repository host goes through the MCP server as an API
call, or is pushed by you from your own terminal.

---

## 3 · One-time setup

Setup lives in the repository, not in this plugin: **`docs/claude-mcp-setup.md`** walks a new
machine through the local MCP servers — prerequisites, tokens, the config block,
verification, and the failures seen so far.

That document is the single source of truth for connecting; nothing here duplicates it.
In short: the servers for the repository host and the tracker run locally without a `Failed`
badge in Settings → Developer, and your local clone is connected to the session.

The plugin itself needs no install step: `.claude/settings.json` registers the
`project-plugins` marketplace at `./.claude/plugins` and enables `sf-project-flow@project-plugins`.

---

## 4 · The flow, end to end

Say you want to add a validation that stops an order without an approver.

1. **You:** `/implement block orders without an approver`.
2. **Claude** finds or creates the task on the board as `CLAUDE.md` §1 says — searching first,
   creating only on your confirmation — then reads the review rules, the design and the code
   around the change, and shows a plan of about a dozen lines.
3. **You** say yes. **Claude** moves the task to *In Progress*, builds the change to the review
   rules, runs the checks, and has a separate read-only agent review the diff by rule ID.
4. **Claude** fixes what the severity requires and reports on one screen: what was done, the
   review, each acceptance criterion with its test, how to verify.
5. **You** decide the next step: the change goes to the default branch the way the project
   does it (`CLAUDE.md` §2), and the task moves to *In Review* when the merge request opens.
   **You** move the task to *Done*, or ask Claude to.

---

## 5 · The skills

| Skill | Fires when | Does |
|---|---|---|
| `plan-build-review` | Implementing, fixing or changing code, metadata or tooling; "plan it first"; `/implement` | Short plan, nothing changed before your yes, the change built to `docs/engineering/code-review-rules.md`, an independent review by rule ID, a one-screen report |
| `project-docs` | Writing or updating anything in `docs/`; `/doc` | Where a document belongs, house tone, option comparisons, diagram conventions, how unknowns are recorded |
| `discovery-research` | "compare these options", "what does X cost", "is this feasible"; `/research` | Sourced, dated research written into `docs/investigation/` with a recommendation |

You never invoke them by name — they load themselves from what you ask. The command worth
knowing is `/implement <what>`, which starts `plan-build-review` on purpose.

---

## 6 · What Claude will not do here

- Push to the default branch or merge a merge request unless you ask it to; force-push, ever.
- Approve or close a merge request.
- Mark a task Done unasked, reassign someone else's task, or change its sprint, priority or
  estimate.
- Delete anything on the repository host or in the tracker, or change project settings,
  CI/CD variables, webhooks or protected-branch rules, without asking first.
- Invent a fact to fill a gap in a document — unknowns are recorded as open questions with
  an owner.

The repository's own `CLAUDE.md` is the authority on these rules and applies to every
session in the project, plugin or not. If `CLAUDE.md` and this plugin ever disagree,
`CLAUDE.md` wins.

---

## 7 · When something breaks

Connection failures — a server showing `Failed`, tools missing after a restart, tokens
expiring — are covered in `docs/claude-mcp-setup.md`, which carries the full
troubleshooting table.

Flow defects belong here: a plan that grows without a second yes, a review finding without
a rule ID, a skill firing at the wrong moment. Those are fixed in the skills, not in the
setup.

---

## 8 · Working with skills day to day

A skill is a written procedure Claude loads when it recognises the situation — not a
button and not a macro. Each has a `description` in its front matter; Claude matches what
you ask against those descriptions and pulls in the matching instructions.

**You normally do nothing.** Say "document the approval states" and `project-docs` loads
itself. Naming a skill is unnecessary.

**Invoke one explicitly** when Claude picks the wrong one or none:
`/sf-project-flow:plan-build-review`. The `/` menu lists what is installed.

**See what is loaded**: ask "which skills do you have here?" — Claude lists them with what
each covers. Settings → Skills shows the same, and lets you turn individual ones off.

Things worth knowing:

- Skills are instructions, not enforcement. They shape what Claude does; the rules that
  must hold regardless live in the repository's `CLAUDE.md` and its hooks.
- `CLAUDE.md` in the repository loads automatically for every session in that folder and
  outranks a skill when they disagree.
- If a skill misfires — triggers when it should not, or misses when it should — the gap is
  in its `description`, not in Claude. Fix the description.
- A skill that no longer matches how the team actually works is worse than no skill,
  because Claude follows it confidently. Retire it or fix it.

## 9 · Changing a skill or adding one

The skills live in `skills/<name>/SKILL.md` — plain markdown with a front matter block:

```markdown
---
name: project-docs
description: Write and maintain the docs/ tree of the project … Use when adding or updating
  project documentation or asking where a document belongs.
---

# Project documentation
…
```

Conventions that make a skill work:

- **Description = when, not what.** It is the only thing Claude sees before loading the
  skill, so it has to carry the trigger phrases people actually say. Two sentences: what
  the skill does, then "Use when …".
- **Body = instructions to Claude**, written as directives ("Search before creating",
  "Never merge"), not as documentation for a human to read.
- **Keep it under roughly 3,000 words.** Long reference material goes in a
  `references/` folder next to `SKILL.md` and is read on demand.
- **Say what must never happen.** The prohibitions carry as much weight as the steps, and
  they are what stops an autonomous run from doing something irreversible.
- **Record real failures.** A gotcha written into a skill should come from something that
  actually broke — a task created into the backlog instead of the sprint, an absolute path
  the desktop app needs, a check reported as passed that never ran. That is what makes a
  skill worth more than generic advice.
- **Project constants belong in `project.md`**, not scattered through prose — changing
  projects should mean editing one file.
- **Approval is a yes in any language.** A skill never lists approval phrases in one
  language; a question or an edit is not a yes.

To change one: edit the file, bump `version` in `.claude-plugin/plugin.json`, and ship the
change like any other — through the repository. Everyone gets it with `git pull` and a
reopened session, so nobody runs a version the repository does not have.
