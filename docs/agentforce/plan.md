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

- [ ] Decide: standard `Order` / `Product2` versus custom objects for orders and stock
- [ ] Partner accounts and contacts
- [ ] Orders and order lines
- [ ] Products and stock levels
- [ ] Custom request object (partner request / claim)
- [ ] Permission set for the data model
- [ ] Repeatable seed script for test data
- [ ] Deploy and load data (after approval)

## Phase 2: Agentforce

- [ ] Decide: Agent Script (`AiAuthoringBundle`) versus classic planner metadata
- [ ] Agent, topics, instructions
- [ ] Apex custom actions: invocable, bulk-safe, clear errors, logic in a service layer with a thin wrapper
- [ ] One Flow action, for comparison with Apex
- [ ] Prompt template grounded on org data
- [ ] Apex tests for actions
- [ ] Agent tests in Testing Center (`AiEvaluationDefinition`)
- [ ] Agent and its parts live in the repo as metadata and deploy through `sf`

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
