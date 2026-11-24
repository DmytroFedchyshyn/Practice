# Environments

**Internal · Agentforce Distributor**
**Status:** project-owned page beside the practice profile's four documents. Credentials and usernames
never go here: the repository is public.

## Orgs

| Org | Alias | Type | What it is for |
|---|---|---|---|
| Build org | `agentforce-dev` | Developer Edition with Agentforce and Data 360, API 68.0 | Everything: build, data, the agent, Data Cloud and the portal. One org, one developer |
| CI | `agentforce-ci` | — | Not set up: the pipeline's Apex validation needs a sandbox, which a Developer Edition does not have. Validation runs by hand |

## Users the build relies on

| User | How it is made | Access |
|---|---|---|
| Admin (the owner) | The org's own | `Distributor_Data_Admin` |
| Partner Service Agent | Setup → Users (agent user, Einstein Agent licence) | Role Partner Service Agent; Agentforce Service Agent Secure Base, Agentforce Service Agent User, Prompt Template User, `Distributor_Agent_Access` |
| Partner Agent CLI | `sf org create agent-user` | Role Partner Service Agent; Agentforce Service Agent Object Access, Agentforce Service Agent User, Prompt Template User, `Distributor_Agent_Access` |

## Org data changed by hand

- The Developer Edition's 17 demo products (GenWatt, Installation, SLA) are inactive (`IsActive = false`), not
  deleted (decision D-36).

## Findings at the start (phase 0)

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

## References

- [Developer Edition with Agentforce and Data Cloud](https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.overview_developer_edition_agentforce_datacloud.htm&type=5)
- [Agent Execution Context and Data Access by Type](https://help.salesforce.com/s/articleView?language=en_US&id=ai.agent_execution_data.htm&type=5)
- [Deploy the Agent to Your Experience Cloud Site](https://help.salesforce.com/s/articleView?language=en_US&id=experience.support_deploy_agent_to_site.htm&type=5)
- [Add User Identification to Agentforce Actions](https://help.salesforce.com/s/articleView?language=en_US&id=ai.service_agent_secure_actions_implement.htm&type=5)
- [Data 360 Limits and Guidelines](https://help.salesforce.com/s/articleView?language=en_US&id=sf.c360_a_limits_and_guidelines.htm)
- [Agent Metadata](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-metadata.html)
- [The New Agentforce Metadata and Development Lifecycle](https://developer.salesforce.com/blogs/2026/05/new-agentforce-metadata-and-development-lifecycle)
