# Agentforce + Data Cloud reference build: plan

A hands-on reference build in a Developer Edition org with Agentforce and Data 360.

**Scenario.** A fictional distributor runs a partner portal on Experience Cloud. A partner logs in and asks an agent about order status, stock levels, and their requests. The agent answers from org data and Data Cloud, and performs actions. All companies and data are invented.

**Working mode.** Small steps, a review stop after every phase, nothing deployed without explicit approval. Decisions and pitfalls go to [notes.md](notes.md).

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
- [x] Decide: Agent Script; Git holds the `AiAuthoringBundle` and the action implementations, not generated runtime metadata (see [research](research-agent-authoring.md))
- [ ] Agent user, created by hand in Setup, plus a permission set for it in the repo
- [x] Apex service layer and invocable wrappers: order status, stock availability, create return request (validated, not deployed)
- [x] Flow action: list the partner's return requests (`List_Return_Requests`, record collection output, Apex test; validated, not deployed)
- [ ] Confirm in the agent that a record collection works as a Flow action output; if not, switch to a text output
- [ ] Prompt template grounded on org data
- [x] Apex tests for the service layer and wrappers (28 tests with the seed tests)
- [x] Reorganize into feature folders with selector and domain layers (40 tests, validated)
- [x] Deploy the Apex actions (61 components, 40 tests) and smoke-test the read-only actions on org data
- [ ] Agent Script: system block, subagents (orders, stock, returns), instructions, actions
- [ ] Validate and preview locally, then publish and activate (after approval)
- [ ] Agent tests (`AiEvaluationDefinition` / Testing Center)

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
