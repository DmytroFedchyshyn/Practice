# Agentforce Distributor

A fictional distributor runs a partner portal on Experience Cloud. A logged-in partner asks an agent about order status, stock levels and their return requests; the agent answers from org data and Data Cloud, and performs actions. All companies and data are invented.

The phases and their status are in [docs/01-build-plan.md](docs/01-build-plan.md), decisions in
[docs/02-decisions-log.md](docs/02-decisions-log.md), open questions and pitfalls beside them. The project is
built on the owner's Salesforce delivery kit: its rules, architecture and Agentforce guidance are in
[docs/engineering](docs/engineering).

## Structure

```
force-app/distributor/            the build, flat by metadata type (the only folder that is deployed)
force-app/main/default/           where a retrieve lands; moved into the build before it is committed
manifest/features/                one generated manifest per feature: foundation, orders, stock, returns, agent-access
project.config.json               build folder, protected paths, features
scripts/apex/seed-data.apex       demo data loader (writes to the org)
tools/                            deploy, feature manifests and CI scripts from the kit
docs/                             plan, decisions, open questions, pitfalls, environments, engineering rules
```

## Run it

Needs an org with Agentforce and Data Cloud enabled, for example an Agentforce Developer Edition, and the Salesforce CLI on Node 22 or later. Run the commands from this folder.

```bash
sf org login web --alias agentforce-dev
npm install
tools/deploy-build.sh agentforce-dev            # validate the whole build with its tests
sf apex run --file scripts/apex/seed-data.apex --target-org agentforce-dev
```

Metadata retrieved from the org lands in `force-app/main/default`; move it into `force-app/distributor` and give it a feature in `project.config.json`. Agents are retrieved as authoring bundles:

```bash
sf project retrieve start --metadata AiAuthoringBundle --target-org agentforce-dev
```
