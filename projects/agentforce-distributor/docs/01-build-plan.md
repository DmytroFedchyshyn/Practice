# Agentforce + Data Cloud reference build: plan

A hands-on reference build in a Developer Edition org with Agentforce and Data 360.

**Scenario.** A fictional distributor runs a partner portal on Experience Cloud. A partner logs in and asks an agent about order status, stock levels, and their requests. The agent answers from org data and Data Cloud, and performs actions. All companies and data are invented.

**Working mode.** Small steps, a review stop after every phase, nothing deployed without explicit approval. Decisions go to [02-decisions-log.md](02-decisions-log.md), open questions to [03-open-questions.md](03-open-questions.md), pitfalls to [04-pitfalls.md](04-pitfalls.md). The code follows [rules.md](rules.md) and the owner's choices in `CLAUDE.md` §6.

## Phase 0: Preparation

- [x] Choose the repository (this repo, `agentforce/` package directory)
- [x] Confirm the scenario
- [x] Verify the org connection and API version (68.0)
- [x] Check licences and metadata types needed for the portal and the agent
- [x] Project skeleton: package layout, plan, notes, README, `.forceignore`
- [ ] Resolve which site template supports running the agent as the logged-in user (before phase 4)

## Phase 1: Data model and test data

- [x] Decide: standard `Order` / `OrderItem` / `Product2` with custom fields
- [x] Decide: stock lives in both CRM (`Stock_Level__c` snapshot) and Data Cloud (ERP feed, phase 3)
- [x] Decide: the request is a return / claim (`Return_Request__c`)
- [x] Decide: seed data through an idempotent Apex script
- [x] Metadata: `Warehouse__c`, `Stock_Level__c`, `Return_Request__c`, custom fields on `Order` and `Account`, tabs
- [x] Permission set `Distributor_Data_Admin`
- [x] Check-only deploy passes
- [x] Deploy the data model
- [x] Assign `Distributor_Data_Admin` to the admin user
- [x] Seed script: partner accounts and contacts, products and price book entries, warehouses and stock, orders in every fulfillment status, return requests
- [x] Apex test for the seed script
- [x] Deploy `SeedData` and `SeedDataTest`
- [x] Load data: 3 partners, 6 contacts, 8 products, 2 warehouses, 16 stock levels, 18 orders, 36 order lines, 3 return requests

## Phase 2: Agentforce

- [x] Decide: Service agent from the start, with a dedicated agent user
- [x] Decide: the partner account comes from a session variable in phase 2; the portal sets it from the logged-in user in phase 4
- [x] Decide: "list my return requests" is the Flow action, the rest are Apex
- [x] Decide: Agent Script; Git holds the `AiAuthoringBundle` and the action implementations, not generated runtime metadata (see [research](investigation/01-agent-authoring.md))
- [x] Agent user access in the repo: permission set `Distributor_Agent_Access` (Einstein Agent licence), role `Partner_Service_Agent`, read sharing rule on `Return_Request__c` (deployed)
- [x] First agent user, created by hand in Setup (Partner Service Agent; role, four permission sets, read access to all return requests confirmed)
- [x] Second agent user, created with `sf org create agent-user`, to compare the two ways (role and `Distributor_Agent_Access` assigned afterwards; same record access as the first)
- [x] Apex service layer and invocable wrappers: order status, stock availability, create return request (validated, not deployed)
- [x] Flow action: list the partner's return requests (`List_Return_Requests`, record collection output, Apex test; deployed and smoke-tested)
- [ ] Confirm in the agent that a record collection works as a Flow action output; if not, switch to a text output
- [x] Apex grounding for the prompt template: `GetReturnRequestFactsAction` with service, selector and domain rules (26 returns tests, validated, not deployed)
- [x] Flex prompt template `Explain_Return_Request`, built by hand in Prompt Builder, previewed on three cases, activated and retrieved into the repo
- [x] Apex tests for the service layer and wrappers (28 tests with the seed tests)
- [x] Reorganize into feature folders with selector and domain layers (40 tests, validated)
- [x] Deploy the Apex actions (61 components, 40 tests) and smoke-test the read-only actions on org data
- [ ] Agent Script: system block, subagents (orders, stock, returns), instructions, actions
- [ ] Validate and preview locally, then publish and activate (after approval)
- [ ] Agent tests (`AiEvaluationDefinition` / Testing Center)

## Move onto the delivery kit (inside phase 2)

The project adopts the owner's Salesforce delivery kit as its base, since kit 1.2.0 with its practice profile. Phase 2 resumes with M6.

- [x] M0: extend the kit — hook fixes, Agentforce metadata types, several projects in one repository, GitHub Issues as the tracker, Agentforce guidance and AGT rules, domain classes (kit 1.1.0, 1.1.1)
- [x] M1: repository layout — `projects/agentforce-distributor/`, `exercises/`, root README and shared CLAUDE.md
- [x] M2: copy the kit into this project with `init.sh` (prefixes `DST_` / `Dst` / `dst`, GitHub, the repository's issues; kit 1.1.1, values in `kit.env`)
- [x] M3: move the metadata into the kit's layout (flat by type, features in `project.config.json`), docs into the kit's documents (validated with 53 tests; on the local branch `meta/kit-layout`)
- [x] M4a: `DstDml`, every write through it (PR #2, deployed). The rest of M4 — Parameters, Switches, Logger, test libraries — is not done: the practice profile does not ask for it (D-44)
- [x] ~~M5: prefixed metadata in the org~~ — dropped: the practice profile asks for no prefixes; names stay as they are (D-45)
- [x] Practice profile: the project moves from the kit's delivery profile to its practice profile (kit 1.2.0, D-43)
- [ ] M6: resume phase 2 — prompt template (done), Agent Script (draft in Builder, live test passed on seven scenarios), agent tests

## Phase 3: Data Cloud

- [ ] Agree on scope (minimum versus optional parts)
- [ ] Data stream from a CSV that imitates an ERP export
- [ ] DLO to DMO mapping
- [ ] Unstructured data: PDF reference documents, search index, retriever for the agent
- [ ] Optional: identity resolution
- [ ] Optional: calculated insights
- [ ] Optional: segments

## Phase 4: Portal

- [ ] Enable Digital Experiences (irreversible, manual, after approval)
- [ ] Experience Cloud site and partner login
- [ ] Enhanced Chat channel and the agent embedded in the site
- [ ] Verify the agent sees only the partner's own account data: sharing, agent user permissions, guest versus authenticated

## Phase 5: Wrap-up

- [ ] What works, Developer Edition limitations, what to do differently
- [ ] Skills that can honestly be claimed in a portfolio
- [ ] Blog post candidates
