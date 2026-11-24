# Working rules for this repository

This repository is **public**. It holds several projects, each in `projects/<project>/` with its own
`CLAUDE.md`, and small exercises in `exercises/`. The rules below hold for all of them; a project's own
`CLAUDE.md` adds to them.

The owner is learning by doing: explain what each step does and why, and give Setup click-paths as
instructions instead of doing them silently.

## How we work

- Work in small phases. Before each phase, describe the plan briefly and ask wherever there is a
  choice. Do not decide for the owner. Stop for review after each phase.
- **Never deploy to an org or change its configuration without an explicit "yes".** Retrieves and
  read-only checks (`sf project deploy validate`, queries, describes) are allowed. Creating users,
  assigning permission sets and publishing or activating an agent count as changes.
- Before any step that depends on a feature, verify the feature exists in the org (Developer Edition
  limits are small).
- If unsure about anything in Salesforce, especially Agentforce and Data Cloud (metadata type names,
  limits, behaviour), check the Salesforce documentation. Do not guess; these features change quickly.
- Run `sf` from the project's folder, where its `sfdx-project.json` is. The Salesforce CLI needs
  Node 22 or later.

## Commits and pull requests

- Small commits, Conventional Commits, in English.
- **No** `Co-Authored-By`, `Claude-Session`, or any other mention of AI in commits or pull requests.
- A change stays inside one project or `exercises/` unless it is about the repository itself.

## Data and language

- No secrets, tokens, Salesforce usernames, org IDs or org URLs anywhere in the repository: it is
  public. The repository's own GitHub path (`owner/Practice`) is public already and may be named, as
  the kit's `REPO_PATH` does.
- All companies, people and data are invented.
- Code, comments and documents in the repository are in English. Talk to the owner in Ukrainian.

## Base

New projects are created from the owner's Salesforce delivery kit (a private repository, copied in by
its `init.sh`). Its rules, architecture and tooling come with the project; improvements found here are
offered back to the kit in project-neutral form.
