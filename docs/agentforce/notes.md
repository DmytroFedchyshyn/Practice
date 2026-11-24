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

## Pitfalls

### Salesforce CLI fails silently on Node 20 (2026-11-24)

`sf` 2.159 requires Node 22 or later. On Node 20 every org command crashed inside `undici` (`createZstdDecompress` is undefined) and wrote nothing to stdout, so `sf ... --json | jq` looked like an empty result rather than an error. Fix: switch the default Node to 22+. Lesson: when a CLI pipeline returns nothing, look at stderr before debugging the query.

### Product2 rejects required lookups (2026-11-24)

A custom lookup to `Product2` with `required=true` (delete constraint Restrict) fails with "Cannot add a lookup relationship child with cascade or restrict options to Product2". The check-only deploy caught it. Fix: optional lookup with `SetNull` plus a validation rule (`Product_Required`). Side effect: the field is no longer universally required, so it needs explicit field-level security in permission sets.

### Fields deployed through the Metadata API have no field-level security (2026-11-24)

After the data model deploy the System Administrator saw only the required custom fields; all five new `Order` fields were invisible. Fields created through the Metadata API get no FLS in any profile, while the Setup wizard sets it for you, so this never shows up when you build by clicks. Required fields are always visible, which hides the problem until you look for an optional one. Fix: grant FLS in a permission set that lives in the repo and assign it.

### Apex is case-insensitive, including for names (2026-11-24)

The seed class had a constant `PRODUCTS` and a method parameter `products`. In Apex these are the same identifier, so inside the method the parameter (a `Map`) shadowed the constant (a `List`), and compilation failed with "Loop must iterate over collection" and "Expression must be a list type". Fix: constants named `*_ROWS`. Lesson: never reuse a name that differs only by case.

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

## Open questions

- **Agent identity on the site.** One help page says credential-based user verification makes a Service agent on an Experience Cloud site run as the logged-in site user. Another says user verification is supported only on an external website and a few Aura templates (Build Your Own Aura, Help Center, Customer Service). Resolve before phase 4: it drives the template choice and how we prove a partner sees only their own account.

## References

- [Developer Edition with Agentforce and Data Cloud](https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.overview_developer_edition_agentforce_datacloud.htm&type=5)
- [Agent Execution Context and Data Access by Type](https://help.salesforce.com/s/articleView?language=en_US&id=ai.agent_execution_data.htm&type=5)
- [Deploy the Agent to Your Experience Cloud Site](https://help.salesforce.com/s/articleView?language=en_US&id=experience.support_deploy_agent_to_site.htm&type=5)
- [Add User Identification to Agentforce Actions](https://help.salesforce.com/s/articleView?language=en_US&id=ai.service_agent_secure_actions_implement.htm&type=5)
- [Data 360 Limits and Guidelines](https://help.salesforce.com/s/articleView?language=en_US&id=sf.c360_a_limits_and_guidelines.htm)
- [Agent Metadata](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-metadata.html)
- [The New Agentforce Metadata and Development Lifecycle](https://developer.salesforce.com/blogs/2026/05/new-agentforce-metadata-and-development-lifecycle)
