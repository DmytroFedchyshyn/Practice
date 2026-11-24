# Research: how agents are built (checked 2026-11-24, org on API v68)

## Ways to edit an agent

One source of truth, three editors. All of them change the same `.agent` file (Agent Script) inside an `AiAuthoringBundle`.

| Editor | Where | For |
| --- | --- | --- |
| Canvas view | Agentforce Builder (UI) | Low-code: blocks, `/` for logic, `@` for subagents, actions, variables |
| Script view | Agentforce Builder (UI) | Editing the script in the browser, with validation |
| Chat | Agentforce Builder (UI) | Describe a rule in plain language, the builder writes the script |
| VS Code + `sf agent` | Local DX project | Source control, review, CI/CD |

Some features exist only in Script view. Invalid script makes Canvas view unavailable until it compiles again.

## Legacy versus new

- The legacy builder (no Agent Script) no longer creates new agents. Existing legacy agents still run but must be upgraded before the new builder can edit them (Help: Agent Migration Guide).
- Topics are called subagents since April 2026. Same thing.

## Lifecycle

1. Draft: `.agent` file in an `AiAuthoringBundle`. Only drafts can be published.
2. Publish: `sf agent publish authoring-bundle` (or Commit Version in the UI) compiles the script into runtime metadata and creates a new immutable version.
3. Activate: `sf agent activate`.

CLI: `sf agent generate agent-spec` (optional) → `sf agent generate authoring-bundle` → `sf agent validate authoring-bundle` → `sf agent preview` → `sf agent publish authoring-bundle` → `sf agent activate`.

## Metadata by API version

| | v66-v67 | v68 (Winter '27) |
| --- | --- | --- |
| Design time | `AiAuthoringBundle` | `AiAuthoringBundle` |
| Agent | `Bot`, `BotVersion` | `AiAgentDefinition`, `AiAgentDefinitionVersion` |
| Version runtime | `GenAiPlannerBundle` | removed |
| Subagent, action | `GenAiPlugin`, `GenAiFunction` | same |

- In v68 `Bot` is for Einstein Bots only.
- Moving v68 agents needs both orgs on v68. The agent version pulls its Apex, Flow and prompt template dependencies in automatically; custom objects and fields still have to be listed.
- Blog posts from spring 2026 describe the v66 model. Check the version before copying a manifest.

## What goes into Git

- Recommended by Salesforce: `AiAuthoringBundle` plus action implementations. Deploy, then publish, then activate.
- Alternative: also commit the generated runtime metadata. The agent is live right after deploy, but the repo carries generated files.

## Agent Script essentials

- Blocks: `system` (instructions, `welcome` and `error` messages), `config` (`developer_name`, `agent_type`: `AgentforceServiceAgent` or `AgentforceEmployeeAgent`), `access` (`default_agent_user`, required for Service agents), `variables`, `subagent`.
- Actions are declared per subagent with `target: "apex://Class"`, `"flow://Flow"` or `"prompt://Template"`.
- `reasoning.actions` exposes actions to the LLM as tools; `run @actions.x` calls one deterministically; `available when` gates a tool on a condition; `@utils.transition to @subagent.x` switches subagent.
- `->` is deterministic logic, `|` is a prompt for the LLM.
- Output parameters: `filter_from_agent` hides a value from the LLM, `is_displayable` shows it to the user.

## Testing

- `sf agent test` with `AiEvaluationDefinition` is the pro-code side of the legacy Testing Center.
- A new Testing Center in Agentforce Studio is in beta; its pro-code docs are not out yet.
- Developer Edition: 150 LLM generation requests per hour.

## Billing and gotchas

- Every action run is billable, deterministic or not. Transitions, setting variables and escalation are not.
- Library subagents and actions are copied into the agent version; later library changes do not reach the agent.
- `developer.salesforce.com` returns 403 to scripted fetches. Docs pages have Markdown twins (`.md` instead of `.html`) that open in a browser.

## Sources

- [Get Started with Agent Script](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html)
- [Agent Script Blocks](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-blocks.html)
- [Agent Script Reference: Actions](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html)
- [Agent Script Reference: Tools](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-tools.html)
- [Author an Agent with Agentforce DX](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-nga-author-agent.html)
- [Publish an Agent](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-nga-publish.html)
- [Agentforce Metadata Types (v68 and Later)](https://developer.salesforce.com/docs/ai/agentforce/references/agents-metadata-tooling/agents-metadata.html)
- [Define Agent Metadata (v67 and Earlier)](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-api-v67-earlier.html)
- [Move an Agent to a New Org](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-deploy-metadata.html)
- [Test an Agent with Agentforce DX](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-test.html)
- [The New Agentforce Metadata and Development Lifecycle (blog, v66)](https://developer.salesforce.com/blogs/2026/05/new-agentforce-metadata-and-development-lifecycle)
- [Build Enterprise-Ready Agents with the New Agentforce Builder](https://help.salesforce.com/s/articleView?id=ai.agent_builder_intro.htm&type=5)
- [Agentforce Builder Considerations](https://help.salesforce.com/s/articleView?id=ai.agent_considerations.htm&type=5)
- Third party, used only for the legacy cut-off date (mid-July 2026): [Salesforce Diary](https://www.salesforcediary.com/stop-describing-your-agent-start-declaring-it/), [Conclo Technologies](https://conclotechnologies.com/the-legacy-builder-is-no-longer-used-for-creating-new-agents/)
