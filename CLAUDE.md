# Working rules for this repo

## Agentforce + Data Cloud reference build (`agentforce/`)

Target org alias: `agentforce-dev` (Developer Edition with Agentforce and Data 360).
The owner is learning by doing: explain what each step does and why, and give
Setup click-paths as instructions instead of doing them silently.

- Work in small phases. Before each phase, describe the plan briefly and ask
  wherever there is a choice. Do not decide for the owner. Stop for review after
  each phase.
- **Never deploy to the org or change its configuration without an explicit
  "yes".** Retrieves and read-only checks (`sf project deploy validate`,
  queries, describes) are allowed.
- Before any step that depends on a feature, verify the feature exists in the
  Developer Edition org (DE limits are small).
- Commits: small, Conventional Commits, in English. **No** `Co-Authored-By`,
  `Claude-Session`, or any other mention of AI in commits or pull requests.
- No secrets, tokens, usernames, or org URLs in the repo.
- Code, comments, and documents in the repo are in English. Talk to the owner
  in Ukrainian.
- If unsure about anything in Agentforce or Data Cloud (metadata type names,
  limits, behaviour), check the Salesforce documentation. Do not guess; these
  features change quickly.

## Project structure (`agentforce/`)

Background and sources: `docs/agentforce/research-project-structure.md`.

- Split by feature, one folder each, all inside the single `agentforce`
  package directory: `partners`, `orders`, `stock`, `returns`, `agent`,
  `access` (permission sets that span features), `seed-data` (demo data and
  test data factory). Add a feature folder when a new capability appears.
- Inside a feature, use the standard metadata folder names (`objects`, `tabs`,
  `flows`, `lwc`, ...). Fields on a shared object (`Order`, `Account`) live in
  the feature that owns them, under `objects/<Object>/fields/`.
- Apex lives in `classes/` with one subfolder per layer. No fflib; plain
  classes and these rules:
  - `actions`: entry points (invocable actions, controllers, trigger
    handlers). Map inputs and outputs only, no business logic.
  - `services`: one business operation each; the transaction boundary.
  - `domain`: rules and calculations for one object. No SOQL, no DML.
  - `selectors`: all SOQL for one object. `inherited sharing`,
    `WITH USER_MODE`.
  - `tests`: tests for the feature's classes.
- Dependencies point one way. A feature may use another feature's selectors,
  domain and services, never its actions. Current direction:
  `returns -> orders -> stock`, `returns -> partners`.
- Folders are not namespaces: Apex class names are unique org-wide and named
  after the object or capability (`OrderSelector`, `ReturnPolicy`).
- Metadata retrieved from the org that is new to the project lands in
  `agentforce/main/default`. Move it into its feature folder before
  committing; `main/default` stays empty in Git.
- Agent actions: bulk-safe (`List` in, `List` out, same order), `with sharing`
  plus user mode, rule failures returned as an error code and one sentence,
  descriptive `@InvocableVariable` texts. Flows used as actions run in user
  context.
