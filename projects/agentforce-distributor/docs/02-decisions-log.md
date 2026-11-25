# Decisions log

**Internal · Agentforce Distributor**
**Status:** living log. The project has no client sessions, so one project-wide log replaces the kit's
per-session logs (`templates/decisions-log.md`). Every decision was taken by the owner, in this order, from
the options recorded in the build plan's phases.

**How to read it.** One row per decision, with an ID that never changes and is never reused. A decision that
reverses an earlier one names it, and the earlier row gets a pointer to the later one; it is never edited
away. Open questions are in [03-open-questions.md](03-open-questions.md); lessons from the build in
[04-pitfalls.md](04-pitfalls.md).

| ID | Date | Decision | Why |
|---|---|---|---|
| D-1 | 2026-11-24 | Build in this repo, in the `agentforce/` package directory | The directory already exists and is empty; one repo keeps all practice work together *Superseded by D-29.* |
| D-2 | 2026-11-24 | Scenario: fictional distributor with a partner portal (orders, stock, requests) | Covers data access, actions, Data Cloud grounding, and per-account security |
| D-3 | 2026-11-24 | Docs live in `docs/agentforce/`, seed data and scripts in `agentforce/data` and `/scripts` | Keeps non-metadata out of `main/default`; both folders are in `.forceignore` *Superseded by D-29 and D-37.* |
| D-4 | 2026-11-24 | Standard `Order` / `OrderItem` / `Product2`; logistics state in custom `Fulfillment_Status__c` | Realistic, maps to standard DMOs; standard `Status` only has Draft and Activated |
| D-5 | 2026-11-24 | Stock in both places: `Stock_Level__c` snapshot in CRM and an ERP feed in Data Cloud | Lets the agent answer in phase 2 and lets us compare SOQL access with Data Cloud access |
| D-6 | 2026-11-24 | The request is a return / claim: `Return_Request__c` linked to order, product and account | Gives real validation rules for the Apex action and a reason for a returns-policy PDF |
| D-7 | 2026-11-24 | `Return_Request__c` uses lookups to `Account` and `Order`, not master-detail; sharing is Private | Keeps the sharing design open for phase 4, where we decide how a partner gets access |
| D-8 | 2026-11-24 | External ids on `Account`, `Warehouse__c`, `Stock_Level__c` | Idempotent seed upserts now, join keys for the ERP feed in Data Cloud later |
| D-9 | 2026-11-24 | Seed data through an Apex script | Idempotent, dates relative to today, handles price book entries and order activation |
| D-10 | 2026-11-24 | Agent Script; Git keeps the `AiAuthoringBundle` plus Apex, Flow and prompt templates, not the generated runtime metadata | Salesforce's recommended pipeline (deploy, publish, activate); reviews show the readable `.agent` file |
| D-11 | 2026-11-24 | Actions report rule failures as an error code plus one sentence, never as exceptions | The LLM can pass the sentence on; one bad request in a bulk call does not fail the others |
| D-12 | 2026-11-24 | Action outputs are plain text lines, not Apex-defined types | Works with any agent setup today; structured outputs (custom Lightning types) can come later |
| D-13 | 2026-11-24 | Services query and insert in user mode (`WITH USER_MODE`, `AccessLevel.USER_MODE`) and are `with sharing` | The agent user's and, in phase 4, the partner's own permissions decide what is visible |
| D-14 | 2026-11-24 | An order of another partner gets the same answer as a missing order | The agent cannot be used to probe which order numbers exist |
| D-15 | 2026-11-24 | Return policy in code: delivered, within 30 days, product on the order, quantity not above ordered minus open requests | Deterministic rules belong in Apex, not in prompt instructions |
| D-16 | 2026-11-24 | Feature folders inside the one `agentforce` package directory, not one package directory per feature | Features share objects and permission sets; nothing is packaged yet *Superseded by D-30.* |
| D-17 | 2026-11-24 | Layers as plain classes (`actions`, `services`, `domain`, `selectors`), no fflib | Same separation without a library dependency; fflib can be a separate exercise *Amended by D-31.* |
| D-18 | 2026-11-24 | The Flow action returns a `Return_Request__c` record collection: all statuses with an optional status filter, newest 10 | Tries the documented `list[object]` output; the agent picks the fields to show |
| D-19 | 2026-11-24 | Formula fields `Order_Number__c` and `Product_Name__c` on `Return_Request__c` | Flow Get Records cannot read relationship fields; without them the agent would show Ids |
| D-20 | 2026-11-24 | The flow runs in `DefaultMode` | A flow action runs in user context, so sharing and field access of the agent user (and later the partner) apply |
| D-21 | 2026-11-24 | Agent user access lives in the repo: `Distributor_Agent_Access` on the Einstein Agent licence, not the generated `[Agent]_Permissions` set | Versioned and reviewed with the actions it unlocks; the help page requires the Einstein Agent licence for a custom set |
| D-22 | 2026-11-24 | `Return_Request__c` stays Private; a sharing rule gives the `Partner_Service_Agent` role read access to all requests | Recommended by the help page; other internal users keep their access; actions scope results to the session's account |
| D-23 | 2026-11-24 | Two agent users: the first created in Setup, the second with `sf org create agent-user` | Learn both ways; the Einstein Agent licence has 201 seats in the Developer Edition |
| D-24 | 2026-11-24 | Prompt template: Flex `Explain_Return_Request` explains one return request to the partner | Shows a prompt template action next to Apex and Flow actions; tone and wording belong in a prompt, facts and rules in code |
| D-25 | 2026-11-24 | Template inputs are free text (`requestNumber`, `accountId`), not a record | The partner types a number; the account comes from the session; Apex filters by account, so another partner's request looks missing |
| D-26 | 2026-11-24 | Grounding through an Apex class (`GetReturnRequestFactsAction`), no `CapabilityType` | The help page says `CapabilityType` is no longer needed; the class reuses the selector and the return policy and is unit-tested |
| D-27 | 2026-11-24 | Next steps per return status are invented business rules in `ReturnPolicy` | The company is fictional; keeping them in code keeps the prompt free of policy text |
| D-28 | 2026-11-24 | The owner's delivery kit is the project's base: its rules, layers, foundation, tooling and documents | One way of working across projects; the kit gained Agentforce guidance from this project *Amended by D-43: the practice profile.* |
| D-29 | 2026-11-24 | One repository, several projects: this project lives in `projects/agentforce-distributor/` | The owner keeps many projects in this repository; each stays self-contained and can move to a repository of its own |
| D-30 | 2026-11-24 | Metadata flat by type with features as globs, replacing the feature folders | The kit's layout; its tooling works on it; shared objects carry fields of several features *Features and manifests dropped by D-43; the flat layout stays.* |
| D-31 | 2026-11-24 | The kit's layers plus domain classes for rules that need no database | Keeps `ReturnPolicy`-style rules testable without data; offered to the kit as APX-43 |
| D-32 | 2026-11-24 | Prefixes `DST_` for metadata, `Dst` for shared Apex, `dst` for components | The kit's naming; renaming in a Developer Edition is cheap because the seed script rebuilds the data *Superseded by D-45.* |
| D-33 | 2026-11-24 | Tasks in the repository's GitHub issues | The repository is on GitHub and public; the kit now supports GitHub Issues as the tracker *Superseded by D-43: no tracker.* |
| D-34 | 2026-11-24 | Build folder `force-app/distributor`; no org snapshot, `force-app/main/default` stays an empty landing folder for retrieves | The org is a Developer Edition and the build is greenfield: there is no client org to diff against *Amended by D-43: one source folder, no landing folder.* |
| D-35 | 2026-11-24 | The kit's values live in `kit.env` in the project | No secrets in it; a later kit version is taken by running its `init.sh` with the same file |
| D-36 | 2026-11-24 | Deactivated the 17 Developer Edition demo products (`IsActive = false`, not deleted) | The catalogue should be the distributor's; stock search only looks at active products |
| D-37 | 2026-11-24 | Documents in the kit's structure: numbered topics (build plan, decisions log, open questions, pitfalls), `environments.md`, research in `investigation/` | One place per kind of document, as every project built on the kit has it |
| D-38 | 2026-11-24 | Five features in `project.config.json`: foundation (the data model, both permission sets' data side, test data), orders, stock, returns, agent-access | The kit puts the data model in Foundation; `returns` uses `orders` and `stock`; the agent's permission set grants all three, so it deploys last *Superseded by D-43.* |
| D-39 | 2026-11-24 | The seed script lives in `scripts/apex/seed-data.apex` | The kit's place for anonymous Apex the team keeps; it writes, so it runs only after a yes |
| D-40 | 2026-11-24 | The move onto the kit's layout happens on a local branch; pushing it and opening the pull request are decided after M3 | Keeps the public repository unchanged until the owner has reviewed the move *Superseded: the move was merged as PR #1.* |
| D-41 | 2026-11-24 | Every write goes through `DstDml` with a named `DstDmlMode` (kit F-9): `ReturnRequestService` in `USER`, `SeedData` in `SYSTEM_WITH_SHARING`; operations limited to what the build uses (`insertAll`, `insertEach`, `updateAll`, `upsertAll`, `deleteAll`) | A unit test can replace the write with `DstDmlFake`; the access mode of every write is visible at the call; clears the `DmlOnlyThroughDmlClass` findings |
| D-42 | 2026-11-24 | `DstDml` turns a user-mode access refusal (`SecurityException`) into `DstDmlException` with the code `INSUFFICIENT_ACCESS` | An agent action reports a missing permission as a refusal with a code instead of failing with an exception |
| D-43 | 2026-11-24 | The project follows the kit's practice profile (kit 1.2.0): `docs/rules.md` instead of the full catalogue, no tracker, one source folder (`force-app/distributor`), no feature manifests, direct pushes allowed, CI with checks and secrets only, no Claude plugin | It is built to learn, in an org of the owner's own, for no client; the delivery process adds work without adding learning |
| D-44 | 2026-11-24 | The Apex layers, domain classes and `DstDml` stay, as the owner's choice beyond `docs/rules.md`; the rest of the kit's foundation (Parameters, Switches, Logger, test libraries) is not built | They are built, tested and deployed, and they are what the project practises; the rest would delay the agent |
| D-45 | 2026-11-24 | No `DST_` prefixes on the existing metadata; M5 is dropped | The practice profile asks for none; renaming in the org would delete and rebuild data for no gain |
| D-46 | 2026-11-24 | Prompt template `Explain_Return_Request`: Flex, free text inputs `requestNumber` and `accountId`, grounded by `GetReturnRequestFactsAction`, model GPT 5 Mini (the org's default), active; the prompt holds tone and form only (version reworked after three previews) | Facts and rules stay in tested Apex; the first version added an unstated quantity check, repeated internal text and padded the not-found answer |
| D-47 | 2026-11-25 | Partner Service Agent version 2 committed and activated in Builder; the repository keeps only the draft bundle `Partner_Service_Agent`, not the retrieved version snapshots `Partner_Service_Agent_1` and `_2` | Version 2 is identical to the draft in the repository except for the agent user, which the snapshots carry in clear text; only a draft can be edited, so further changes start from New Version in Builder |
