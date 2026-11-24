# Working agreements for Claude in this project

Project: **Agentforce Distributor**, a practice project (Salesforce SFDX). It is built to learn, not for a
client, so it follows a short set of rules — the ones below and `docs/rules.md` — and nothing more. A
`CLAUDE.md` higher up in the repository holds too; where the two differ, that one wins.

| | |
|---|---|
| Repository | `DmytroFedchyshyn/Practice` on `https://github.com` |
| Default branch | `master` — direct push allowed, force-push never |
| Metadata | `force-app/distributor` — everything the project builds; a retrieve lands here too |
| Org | `agentforce-dev`, an org of the owner's own |
| Plan and notes | `docs/01-build-plan.md`, `02-decisions-log.md`, `03-open-questions.md`, `04-pitfalls.md` |
| Rules for the code | `docs/rules.md` |

## 1 · How we work

1. The owner is learning by doing. Work in small phases: before each, say briefly what it will do and
   ask wherever there is a choice — never decide for the owner. Stop for review after each phase.
2. Explain what each step does and why. A step in Setup is given as a click-path for the owner to
   follow, not done silently.
3. The plan's phases and their status are kept current in `docs/01-build-plan.md`. A decision goes to
   the decisions log with its reason, an unknown to the open questions, and a trap the build fell into —
   with how it was got out of — to the pitfalls.
4. Before a step that depends on a Salesforce feature, check that the org has it: a Developer Edition's
   features and limits are small. When unsure how a feature, a metadata type or a limit behaves, check
   the Salesforce documentation instead of guessing.

## 2 · Code

1. Code is written to `docs/rules.md` from its first line, and only to it: no layers, framework or
   pattern beyond what those rules ask, unless the owner chooses one. `/code-review` checks a change
   against the same rules and names the rule ID in each finding.
2. An Apex class, trigger or component is committed together with its `-meta.xml`.
3. Code, comments and documents are in English.

## 3 · Ask before doing

Stop and ask for an explicit yes before:

- **anything that writes to an org** — `sf project deploy start`, `deploy quick`, `project delete source`,
  any `sf data` write, `sf apex run`, assigning permission sets, creating or deleting users and orgs, and
  publishing, activating or testing an agent. Show the command and what it changes, then wait.
  Read-only work needs no permission: `deploy validate`, `--dry-run`, `retrieve`, `describe` and
  `query`. Enforced by an `ask` hook in `.claude/settings.json`;
- pushing or merging that the owner has not asked for;
- deleting anything on the repository host (a branch, an issue, a tag, a release);
- changing the repository's settings, secrets or workflows' triggers.

## 4 · Git

1. Small commits, each one logical change, with a one-line summary in English and a body when the change
   needs context. The repository's own commit convention, where it has one, wins.
2. Work may go straight to `master`, or through a branch and a pull request when the owner
   wants a review. Claude pushes when the owner asks, after `git fetch` and a fast-forward — never over
   commits it has not seen, never with `--no-verify`, never a force-push.
3. No tool attribution: no co-author trailer naming an AI tool, no "generated with" line, in commits or
   pull requests.

## 5 · Data and secrets

1. No secrets anywhere: no password, token, key, connected-app secret or session URL — not in code,
   docs, commit messages or chat. The repository may be public, so no Salesforce usernames, org IDs or
   org URLs either.
2. Every company, person and record is invented.
3. Never edit `.sf/`, `.sfdx/` or IDE folders: local tooling state, not project content.

## 6 · This project

- Agentforce and Data Cloud practice: a fictional distributor's partners ask an agent about orders, stock and
  return requests. Org alias `agentforce-dev` (Developer Edition with Agentforce and Data 360). Run `sf`,
  `npm` and `tools/` from this folder.
- **Chosen by the owner beyond `docs/rules.md`** (decisions D-17, D-31, D-41, D-44): Apex in layers —
  `…Action` entry points that only map inputs and outputs, services, domain classes with rules and no
  database, selectors with every query in user mode — and every write through `DstDml` with a named
  `DstDmlMode`. New code follows them too.
- Agent actions follow the AGT rules of `docs/rules.md`, and also: a rule failure is returned as an error
  code plus one sentence; flows used as actions run in user context.
- Demo data: `scripts/apex/seed-data.apex` writes to the org, so it runs only after a yes.
- Beside the four documents: `docs/environments.md` (the org, its users, data changed by hand) and research
  in `docs/investigation/`.

