# Agentforce Distributor — project rules

Agentforce + Data Cloud reference build. The rules of the repository's root `CLAUDE.md` apply; this page
adds what is specific to this project.

Target org alias: `agentforce-dev` (Developer Edition with Agentforce and Data 360). Run `sf` from this
folder.

The project is moving onto the delivery kit. Until that move is done, the structure below holds.

## Project structure (`agentforce/`)

Background and sources: `docs/research-project-structure.md`.

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
