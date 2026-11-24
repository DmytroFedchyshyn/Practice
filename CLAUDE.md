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
