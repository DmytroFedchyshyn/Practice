# Agentforce Distributor

A fictional distributor runs a partner portal on Experience Cloud. A logged-in partner asks an agent about order status, stock levels and their return requests; the agent answers from org data and Data Cloud, and performs actions. All companies and data are invented.

The phases and their status are in [docs/plan.md](docs/plan.md), decisions and pitfalls in [docs/notes.md](docs/notes.md).

## Structure

```
agentforce/                       # package directory (default), one folder per feature
├── partners/                     Partner fields on Account, contact selector
├── orders/                       Order fields, order lookups for the agent
├── stock/                        Warehouses, stock levels, product matching, stock checks
├── returns/                      Return requests, return policy, return actions, flow, prompt grounding
├── access/                       Permission sets and the agent user's role
└── seed-data/                    Demo data loader, test data factory, scripts (not deployed)

                                  Apex inside a feature: classes/{actions,services,domain,selectors,tests}

docs/                             Plan with per-phase checklists, decisions, pitfalls and research
```

The project is moving onto the Salesforce delivery kit (flat metadata by type, features in `project.config.json`); this layout changes with that move.

## Run it

Needs an org with Agentforce and Data Cloud enabled, for example an Agentforce Developer Edition, and the Salesforce CLI on Node 22 or later. Run the commands from this folder.

```bash
sf org login web --alias agentforce-dev
sf project deploy start --source-dir agentforce --target-org agentforce-dev
sf apex run --file agentforce/seed-data/scripts/seed.apex --target-org agentforce-dev
```

Metadata retrieved from an org that is new to the project lands in `agentforce/main/default`; move it into its feature folder. Agents are retrieved as authoring bundles:

```bash
sf project retrieve start --metadata AiAuthoringBundle --target-org agentforce-dev
```
