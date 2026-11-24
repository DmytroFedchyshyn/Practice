# Project constants — Agentforce Distributor

Every skill in this plugin is scoped to this one project. These are the only values it
should ever act against, and this is the only file in the plugin that holds them.

| | |
|---|---|
| Repository | `DmytroFedchyshyn/Practice` on `https://github.com` |
| Default branch | `master` — direct push allowed except for changes under `force-app/`, which go through a merge request; force-push never |
| Tracker | the issues of `DmytroFedchyshyn/Practice`; GitHub project `none` for statuses when there is one |
| Board statuses | Todo → In Progress → In Review → Done, the project's *Status* field |
| Issue label | `task` |
| Build folder | `force-app/distributor` — everything the team builds |
| Org snapshot | `force-app/main/default` — read-only, never edited |
| Documentation | `docs/` in the repository; its structure in `docs/README.md` |
| Review rules | `docs/engineering/code-review-rules.md` |
| Conventions | `docs/engineering/development-foundation.md` §2 |
| Architecture | `docs/engineering/architecture.md` |
| Design | `docs/technical-design.md` and the feature specs (project-owned) |
| Release runbook | `docs/engineering/release-runbook.md` |
| Features | the `features` list in `project.config.json` |
| Local folder | the project's local clone on the engineer's computer |

## Language

Everything this plugin writes is in English — tracker summaries, descriptions and comments,
branch names, commit messages, merge request titles and descriptions, and everything under
`docs/`. This holds regardless of the language the conversation is in: reply to the user in
their language, but the artefact that lands on the board, in the repository or in the merge
request is English.

When the user dictates content in another language, translate it rather than transcribing
it, and keep proper nouns, product names and client terminology spelled as the vendor or
the project glossary spells them.

## Scope check — run before acting

Confirm the session is actually working on this project before any write:

```
git remote -v          # must resolve to DmytroFedchyshyn/Practice
```

Continue only if it does. If the repository is something else, or the user asks to point a
skill at another repository or another tracker, **stop**: say that this plugin is
scoped to Agentforce Distributor and that another project needs its own copy or an explicit change
here. Do not generalise the skill on the fly, and do not fall back to a different project key.

Read-only exceptions are fine — answering "what does our flow look like" needs no repo.

## Where these values come from

They are also recorded in the repository's own `CLAUDE.md`. If the two ever disagree,
`CLAUDE.md` in the repository wins, because it ships with the code; fix this file to match
and say so.
