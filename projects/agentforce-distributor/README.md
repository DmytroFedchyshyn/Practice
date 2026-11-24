# Agentforce Distributor

A practice project for Agentforce and Data Cloud. A fictional distributor runs a partner portal on Experience
Cloud; a logged-in partner asks an agent about order status, stock levels and their return requests, and the
agent answers from org data and Data Cloud and performs actions. All companies, people and data are invented.

The phases and their status are in [docs/01-build-plan.md](docs/01-build-plan.md), decisions in
[docs/02-decisions-log.md](docs/02-decisions-log.md), open questions and pitfalls beside them. The code is
written to the rules in [docs/rules.md](docs/rules.md).

## Structure

```
force-app/distributor/    the metadata, flat by type; a retrieve lands here too
docs/             plan, decisions, open questions, pitfalls, rules, environments, research
scripts/          anonymous Apex and SOQL kept for reuse; scripts/apex/seed-data.apex loads the demo data
tools/            deploy and CI scripts
```

## Run it

Needs the Salesforce CLI on Node 22 or later and an org of your own, for example a Developer
Edition. Run the commands from this folder.

```bash
sf org login web --alias agentforce-dev
npm install
tools/deploy-build.sh agentforce-dev            # validate with the tests; nothing is written
tools/deploy-build.sh agentforce-dev --deploy   # then deploy that validation, after a yes
```

`tools/deploy-changes.sh` deploys only what the current branch changed. `npm run format`, `npm run lint`,
`npm run scan` and `npm test` run the code checks.

Demo data, and agents as authoring bundles:

```bash
sf apex run --file scripts/apex/seed-data.apex --target-org agentforce-dev   # writes demo data
sf project retrieve start --metadata AiAuthoringBundle --target-org agentforce-dev
```
