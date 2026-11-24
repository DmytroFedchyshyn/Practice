# Agentforce + Data Cloud reference build: notes

Decisions, pitfalls, and open questions, logged as they happen. Raw material for the wrap-up and for blog posts.

## Decisions

| Date       | Decision                                                                                     | Why                                                                                 |
| ---------- | -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| 2026-11-24 | Build in this repo, in the `agentforce/` package directory                                   | The directory already exists and is empty; one repo keeps all practice work together |
| 2026-11-24 | Scenario: fictional distributor with a partner portal (orders, stock, requests)              | Covers data access, actions, Data Cloud grounding, and per-account security          |
| 2026-11-24 | Docs live in `docs/agentforce/`, seed data and scripts in `agentforce/data` and `/scripts`   | Keeps non-metadata out of `main/default`; both folders are in `.forceignore`         |
| 2026-11-24 | Standard `Order` / `OrderItem` / `Product2`; logistics state in custom `Fulfillment_Status__c` | Realistic, maps to standard DMOs; standard `Status` only has Draft and Activated |
| 2026-11-24 | Stock in both places: `Stock_Level__c` snapshot in CRM and an ERP feed in Data Cloud | Lets the agent answer in phase 2 and lets us compare SOQL access with Data Cloud access |
| 2026-11-24 | The request is a return / claim: `Return_Request__c` linked to order, product and account | Gives real validation rules for the Apex action and a reason for a returns-policy PDF |
| 2026-11-24 | `Return_Request__c` uses lookups to `Account` and `Order`, not master-detail; sharing is Private | Keeps the sharing design open for phase 4, where we decide how a partner gets access |
| 2026-11-24 | External ids on `Account`, `Warehouse__c`, `Stock_Level__c` | Idempotent seed upserts now, join keys for the ERP feed in Data Cloud later |
| 2026-11-24 | Seed data through an Apex script | Idempotent, dates relative to today, handles price book entries and order activation |
| 2026-11-24 | Agent Script; Git keeps the `AiAuthoringBundle` plus Apex, Flow and prompt templates, not the generated runtime metadata | Salesforce's recommended pipeline (deploy, publish, activate); reviews show the readable `.agent` file |
| 2026-11-24 | Actions report rule failures as an error code plus one sentence, never as exceptions | The LLM can pass the sentence on; one bad request in a bulk call does not fail the others |
| 2026-11-24 | Action outputs are plain text lines, not Apex-defined types | Works with any agent setup today; structured outputs (custom Lightning types) can come later |
| 2026-11-24 | Services query and insert in user mode (`WITH USER_MODE`, `AccessLevel.USER_MODE`) and are `with sharing` | The agent user's and, in phase 4, the partner's own permissions decide what is visible |
| 2026-11-24 | An order of another partner gets the same answer as a missing order | The agent cannot be used to probe which order numbers exist |
| 2026-11-24 | Return policy in code: delivered, within 30 days, product on the order, quantity not above ordered minus open requests | Deterministic rules belong in Apex, not in prompt instructions |
| 2026-11-24 | Feature folders inside the one `agentforce` package directory, not one package directory per feature | Features share objects and permission sets; nothing is packaged yet |
| 2026-11-24 | Layers as plain classes (`actions`, `services`, `domain`, `selectors`), no fflib | Same separation without a library dependency; fflib can be a separate exercise |
| 2026-11-24 | The Flow action returns a `Return_Request__c` record collection: all statuses with an optional status filter, newest 10 | Tries the documented `list[object]` output; the agent picks the fields to show |
| 2026-11-24 | Formula fields `Order_Number__c` and `Product_Name__c` on `Return_Request__c` | Flow Get Records cannot read relationship fields; without them the agent would show Ids |
| 2026-11-24 | The flow runs in `DefaultMode` | A flow action runs in user context, so sharing and field access of the agent user (and later the partner) apply |
| 2026-11-24 | Agent user access lives in the repo: `Distributor_Agent_Access` on the Einstein Agent licence, not the generated `[Agent]_Permissions` set | Versioned and reviewed with the actions it unlocks; the help page requires the Einstein Agent licence for a custom set |
| 2026-11-24 | `Return_Request__c` stays Private; a sharing rule gives the `Partner_Service_Agent` role read access to all requests | Recommended by the help page; other internal users keep their access; actions scope results to the session's account |
| 2026-11-24 | Two agent users: the first created in Setup, the second with `sf org create agent-user` | Learn both ways; the Einstein Agent licence has 201 seats in the Developer Edition |
| 2026-11-24 | Deactivated the 17 Developer Edition demo products (`IsActive = false`, not deleted) | The catalogue should be the distributor's; stock search only looks at active products |

## Pitfalls

### Salesforce CLI fails silently on Node 20 (2026-11-24)

`sf` 2.159 requires Node 22 or later. On Node 20 every org command crashed inside `undici` (`createZstdDecompress` is undefined) and wrote nothing to stdout, so `sf ... --json | jq` looked like an empty result rather than an error. Fix: switch the default Node to 22+. Lesson: when a CLI pipeline returns nothing, look at stderr before debugging the query.

### Product2 rejects required lookups (2026-11-24)

A custom lookup to `Product2` with `required=true` (delete constraint Restrict) fails with "Cannot add a lookup relationship child with cascade or restrict options to Product2". The check-only deploy caught it. Fix: optional lookup with `SetNull` plus a validation rule (`Product_Required`). Side effect: the field is no longer universally required, so it needs explicit field-level security in permission sets.

### Fields deployed through the Metadata API have no field-level security (2026-11-24)

After the data model deploy the System Administrator saw only the required custom fields; all five new `Order` fields were invisible. Fields created through the Metadata API get no FLS in any profile, while the Setup wizard sets it for you, so this never shows up when you build by clicks. Required fields are always visible, which hides the problem until you look for an optional one. Fix: grant FLS in a permission set that lives in the repo and assign it.

### Apex is case-insensitive, including for names (2026-11-24)

The seed class had a constant `PRODUCTS` and a method parameter `products`. In Apex these are the same identifier, so inside the method the parameter (a `Map`) shadowed the constant (a `List`), and compilation failed with "Loop must iterate over collection" and "Expression must be a list type". Fix: constants named `*_ROWS`. Lesson: never reuse a name that differs only by case.

### User-mode queries need a known test user (2026-11-24)

The services query `WITH USER_MODE`, so a test that runs as the deploying admin depends on whatever permission sets that admin happens to have. The tests create their own user with only `Distributor_Data_Admin` and run as that user. Inserting a user and a permission set assignment in the same transaction as data causes `MIXED_DML_OPERATION`; wrapping the setup-object inserts in `System.runAs` avoids it.

### A test helper can blow the SOQL limit that the code under test respects (2026-11-24)

The bulk test for return requests failed with "Too many SOQL queries: 101" although the service itself uses four. The test's own input helper looked up the account on every call, 180 times. Fix: look up once outside the loop. Lesson: measure the code under test with `Limits.getQueries()` before and after, and keep test helpers out of loops too.

### Bind variables work in a subquery LIMIT (2026-11-24)

`(SELECT Id FROM Orders ORDER BY EffectiveDate DESC LIMIT :RECENT_ORDER_LIMIT)` compiles and runs, so the per-account limit can be a named constant instead of a magic number.

### Permission set licences are assigned with the permission set (2026-11-24)

When creating the agent user in Setup, the "Einstein Prompt Templates" permission set licence did not need a separate step: assigning the `Prompt Template User` permission set assigned its licence automatically. Look for permission sets, not licences, in the assignment list. Check afterwards with `UserRecordAccess`: the agent user reads every return request and order but cannot edit orders, because the permission set grants read only even though the org-wide default is Read/Write.

### Agent user in Setup versus `sf org create agent-user` (2026-11-24)

| | Setup (by hand) | `sf org create agent-user` |
| --- | --- | --- |
| Licence and profile | Einstein Agent, Einstein Agent User | Same |
| Permission set licences | Agentforce Service Agent User, Einstein Prompt Templates (assigned with the permission sets) | Same |
| Base permission set | Agentforce Service Agent Secure Base: read and create Case, read and edit Contact, read MessagingEndUser, read and edit MessagingSession | Agentforce Service Agent Object Access (`AgentforceServiceAgentBase`): no object permissions in this org |
| Other permission sets | Agentforce Service Agent User, Prompt Template User, plus our own | Agentforce Service Agent User, Prompt Template User |
| Role | Chosen on the form | None; assign it afterwards |
| Username and email | Typed by hand | Generated, globally unique; email = username |
| Password | None if "notify user" is unchecked | None |

The CLI is one repeatable command, good for scripts and scratch orgs; it still leaves the project's permission set and role to assign. Setup shows every choice, which helps when learning. Neither stores the user in the repo: users are data, not metadata.

### Role and permission set metadata have tight limits (2026-11-24)

A permission set description is at most 255 characters and a role description at most 80. A role's opportunity and case access levels cannot be below the org-wide default (here `Edit`, because both objects are Public Read/Write). A sharing rule that targets a role in the same deploy fails with "no Role named ... found" when the role itself fails; fix the role first.

### Test data hides what the real org contains (2026-11-24)

All tests passed, but the first run against the org showed the stock action's "too many matches" message listing 20 products: the Developer Edition ships 17 demo products (GenWatt generators, installation and SLA products) that the isolated test data never sees. Fixes: the message now lists at most five matches plus "and N more", and the demo products are deactivated (reactivate them by setting `IsActive = true` on products whose code does not start with `DST-`). Lesson: after deploying an agent action, run it once against real org data before trusting the tests.

## Phase 0 findings (Developer Edition, API 68.0)

- Licences are present for the whole plan: Partner Community and Customer Community (5 each), Agentforce Service Agent User, Enhanced Chat User, Data Cloud, Prompt Templates.
- The org exposes the metadata types we need: `Bot`, `GenAiPlannerBundle`, `GenAiPlugin`, `GenAiFunction`, `GenAiPromptTemplate`, `AiAuthoringBundle`, `AiEvaluationDefinition`, `MessagingChannel`, `EmbeddedServiceConfig`, `DigitalExperienceBundle`, `DataStreamDefinition`.
- Digital Experiences is not enabled yet (the `Network` object is unavailable). Enabling it is irreversible and fixes the site domain.
- "Messaging for In-App and Web" is now called Enhanced Chat.
- Developer Edition allows 150 LLM generation requests per hour. Expect this to matter for Testing Center runs.
- Data 360 developer org limits per the docs: one data space, 100 data streams, ruleset runs are not scheduled.
- Agent metadata has two models. Agent Script keeps a design-time `AiAuthoringBundle` (`.agent` file) that `sf agent publish authoring-bundle` turns into runtime metadata. Building an agent without Agent Script is now labelled legacy in the docs.
- **Correction (phase 2 research):** in API v68 (Winter '27) the runtime types are `AiAgentDefinition` and `AiAgentDefinitionVersion`, plus `GenAiPlugin` (subagent) and `GenAiFunction` (action). `Bot`/`BotVersion` are used only by Einstein Bots and `GenAiPlannerBundle` no longer exists. The earlier note that a deploy needs `Bot`/`BotVersion` came from v67-era sources. Both orgs must be on v68 to move agents with the new types.
- In Agent Script, topics are called subagents. Actions point straight at their implementation with `target: "apex://Class"`, `"flow://Flow"` or `"prompt://Template"`; `reasoning.actions` exposes them to the LLM as tools, `run @actions.x` calls them deterministically, `available when` gates them.
- `sf agent test` and `AiEvaluationDefinition` are documented as the pro-code side of the legacy Testing Center; a new Testing Center in Agentforce Studio is in beta and its pro-code docs are not out yet.
- `developer.salesforce.com` refuses scripted fetches (HTTP 403). The docs pages have Markdown twins (`.md` instead of `.html`) that load fine in a browser.

## Research

- [How agents are built](research-agent-authoring.md): editors, lifecycle, v68 metadata, Agent Script essentials, testing.
- [Feature folders and separation of concerns](research-project-structure.md): what SFDX allows, folders versus package directories, Apex layers, agent action guidance.

## Open questions

- **Agent identity on the site.** One help page says credential-based user verification makes a Service agent on an Experience Cloud site run as the logged-in site user. Another says user verification is supported only on an external website and a few Aura templates (Build Your Own Aura, Help Center, Customer Service). Resolve before phase 4: it drives the template choice and how we prove a partner sees only their own account.
- **Record collections as Flow action outputs.** The Agent Script reference allows `list[object]` outputs with a `complex_data_type_name` ([Actions](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html)). The help page [Agentforce Considerations](https://help.salesforce.com/s/articleView?id=ai.copilot_considerations.htm&language=en_US&type=5) says custom actions on Apex or Flow support only primitive types and that a flow with a collection resource cannot be used. `List_Return_Requests` tests this; check it when the action is added to the agent.

## References

- [Developer Edition with Agentforce and Data Cloud](https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.overview_developer_edition_agentforce_datacloud.htm&type=5)
- [Agent Execution Context and Data Access by Type](https://help.salesforce.com/s/articleView?language=en_US&id=ai.agent_execution_data.htm&type=5)
- [Deploy the Agent to Your Experience Cloud Site](https://help.salesforce.com/s/articleView?language=en_US&id=experience.support_deploy_agent_to_site.htm&type=5)
- [Add User Identification to Agentforce Actions](https://help.salesforce.com/s/articleView?language=en_US&id=ai.service_agent_secure_actions_implement.htm&type=5)
- [Data 360 Limits and Guidelines](https://help.salesforce.com/s/articleView?language=en_US&id=sf.c360_a_limits_and_guidelines.htm)
- [Agent Metadata](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-metadata.html)
- [The New Agentforce Metadata and Development Lifecycle](https://developer.salesforce.com/blogs/2026/05/new-agentforce-metadata-and-development-lifecycle)
