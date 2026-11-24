# Agentforce — how agents, their actions and their access are built

**Internal · delivery team · Agentforce Distributor**
**Status:** template from the delivery kit, written from one build of a Service agent on API 68.0; the team adopts
or adjusts it with `development-foundation.md`. The review rules that check it are AGT-01 to AGT-13 in
`code-review-rules.md`. Agentforce changes with every release: each fact below names its source, and a project
checks the ones it relies on against the documentation of its own API version.
**Sources:** §8.

---

## 0 · The answer

- **An agent is source code.** It is written in Agent Script, a `.agent` file in an `AiAuthoringBundle`, kept in
  Git with the Apex, flows and prompt templates its actions call. The runtime metadata the platform generates
  when the agent is published is not committed.
- **An action is an entry point.** Apex behind an action is an `…Action` class over a service, like any other
  entry point (`architecture.md` §1). The agent's language model chooses which action to run and with what, so an
  action is built for a caller that may be wrong: it checks everything it is given, works on lists, and answers a
  rule it refuses with a code and one sentence instead of an exception.
- **The agent user is a user like any other.** A Service agent that does not know who it talks to runs as its
  agent user; that user's permission sets, role and sharing decide what the agent can read and change. Its
  permission set is in the repository, on the Einstein Agent licence, with the least access the actions need.
- **Who the customer is never comes from the conversation.** The account or contact an action works for comes
  from the session — a context variable, a verified customer — and every query is filtered by it. Another
  customer's record gets the same answer as a record that does not exist.
- **Publishing and activating an agent are org writes**, asked for like a deployment (`CLAUDE.md` §3).

---

## 1 · How an agent is built

Agent Script is the way to build an agent: the builder without it no longer creates new agents, and an agent made
with it is upgraded before the new builder can edit it. The Agentforce Builder's canvas view, script view and chat
all edit the same `.agent` file; a project edits it in the repository and opens the builder to look, not to change.

| Part of the script | Holds |
|---|---|
| `system` | The agent's instructions, welcome and error messages |
| `config` | `developer_name`, `agent_type` (`AgentforceServiceAgent` or `AgentforceEmployeeAgent`) |
| `access` | `default_agent_user`, required for a Service agent (§4) |
| `variables` | Values the session carries, such as the customer's account; the context variables a channel fills in |
| `subagent` | One area the agent handles (formerly a *topic*): its instructions, its actions, and when it hands over |

Inside a subagent, `reasoning.actions` offers actions to the language model as tools, `run @actions.<name>` runs
one every time, `available when` offers a tool only under a condition, and `@utils.transition to
@subagent.<name>` hands over. `->` starts deterministic logic, `|` text for the model.

**An action** names what runs it: `target: "apex://<Class>"`, `"flow://<Flow>"`, or a prompt template (§3.3).
Its inputs and outputs are typed — `string`, `number`, `integer`, `boolean`, `date`, `datetime`, `currency`,
`object`, `list[<type>]`; `id` is deprecated in favour of `string`. An output marked `filter_from_agent` stays out
of the model's context; one marked `is_displayable` is shown to the user.

**Lifecycle.** A draft is deployed as an `AiAuthoringBundle`, published — which compiles it into runtime metadata
and makes a new version that does not change — and activated:

```bash
sf agent generate authoring-bundle --api-name <Agent>      # once, a new bundle
sf agent validate authoring-bundle --api-name <Agent>      # compiles, writes nothing
sf agent preview --api-name <Agent>                        # a conversation; each turn spends LLM requests
sf project deploy start --metadata AiAuthoringBundle:<Agent>
sf agent publish authoring-bundle --api-name <Agent>       # a new version
sf agent activate --api-name <Agent>
```

**Metadata by API version** — check the version before copying a manifest or a blog post's example.

| | API 66–67 | API 68 |
|---|---|---|
| What is written | `AiAuthoringBundle` | `AiAuthoringBundle` |
| The agent | `Bot`, `BotVersion` | `AiAgentDefinition`, `AiAgentDefinitionVersion`; `Bot` is for Einstein Bots only |
| A version's runtime | `GenAiPlannerBundle` | removed |
| Subagents and actions | `GenAiPlugin`, `GenAiFunction` | the same |

**What goes into Git.** The `AiAuthoringBundle` and what its actions call: Apex, flows, prompt templates, the
permission sets. Retrieve an agent as `sf project retrieve start --metadata AiAuthoringBundle`. Committing the
generated runtime metadata as well makes the agent live on a deploy without a publish, at the cost of generated
files in every review. **Default — adjust per project.** A project that needs agents live on deploy alone commits
the runtime metadata and records why.

`tools/feature-manifests.py` knows `AiAuthoringBundle`, `GenAiPromptTemplate`, `GenAiPlugin`, `GenAiFunction`,
`GenAiPlannerBundle` and `AiEvaluationDefinition`, so an agent belongs to a feature like any other component.

---

## 2 · Apex actions

An Apex action is an `@InvocableMethod` in an `…Action` class (APX-25), the entry point of `architecture.md` §1:
it maps the agent's inputs onto a service and the service's results onto outputs, and decides nothing.

```apex
/** Agent action: the open invoices of the customer in the session. Thin wrapper over InvoiceLookupService. */
public with sharing class GetOpenInvoicesAction {
    public class Request {
        @InvocableVariable(label='Customer Account ID' description='ID of the customer account from the session, never from the customer.' required=true)
        public Id accountId;

        @InvocableVariable(label='Invoice Number' description='Optional. The number the customer gave, for example INV-0042 or 42.')
        public String invoiceNumber;
    }

    public class Response {
        @InvocableVariable(label='Success' description='True when the lookup ran; false with an error code otherwise.')
        public Boolean success;

        @InvocableVariable(label='Error Code' description='Set when Success is false: INVOICE_NOT_FOUND, ACTION_SWITCHED_OFF.')
        public String errorCode;

        @InvocableVariable(label='Message' description='One sentence to pass on to the customer.')
        public String message;
    }

    @InvocableMethod(label='Get Open Invoices' description='Lists the open invoices of the customer, newest first, at most 10.' category='Agentforce Distributor')
    public static List<Response> run(List<Request> requests) {
        …
    }
}
```

| Rule | Why |
|---|---|
| **One operation per action.** Reading invoices and disputing one are two actions | The model picks an action by its label and description; one that does two things is picked for both, and its inputs fit neither |
| **Lists in, lists out, in the same order**, one response per request, a fixed number of queries per call (AGT-03) | The platform may call an action for several requests at once; a response out of order answers the wrong customer |
| **Every input and output has a label and a description written for the model** (AGT-05) | The descriptions are the prompt the model reads to fill the inputs and to use the outputs. Say what a value is, its format with an example, and where it must come from |
| **A rule the action refuses is a result, not an exception:** `success = false`, an error code, and one sentence the agent can say (AGT-04) | One refused request in a list does not fail the others, and the agent explains instead of apologising for an error. An unexpected error is still logged (APX-06) |
| **Text outputs first.** A result is a few short lines of text, or primitive outputs | Complex types need a Lightning type to render, and support for record and list outputs differs between the documentation's pages (§7) |
| **`with sharing`, user mode for every query and write** (SEC-03, SEC-04) | The running user's access is the agent's limit (§4) |
| **Another customer's record looks missing** (AGT-06) | The same answer for "not yours" and "does not exist" stops an agent from being used to probe which numbers exist |
| **The customer comes from the session** (AGT-09) | An input the model fills from the conversation can be talked into another value; one the script sets from a variable cannot |
| **An action switched off answers that it is off** (AGT-10) | `DstSwitches.isOn` as APX-42 asks, but a switched-off action returns `ACTION_SWITCHED_OFF` and a sentence for each request rather than nothing: an empty list breaks the agent's turn |
| **Numbers as people type them.** An action that takes a record number accepts `42`, `#42` or `inv 42` and normalises it in a domain class (`architecture.md` §1) | The model passes on what the customer wrote |

---

## 3 · Flows and prompt templates as actions

### 3.1 A flow

An autolaunched flow (no screens) runs as an action when the logic is the administrator's to change after handover
(MDT-05). It runs in the user's context — `runInMode` `DefaultMode` — so the running user's sharing and field
access decide what Get Records returns (AGT-07). Its input and output variables carry descriptions written for the
model, as an Apex action's do.

- Get Records reads the object's own fields only. A value from a related record the agent should show — an order
  number, a product name — comes through a formula field on the object, or the agent shows Ids.
- Get Records has no limit on the number of records; a loop that stops collecting after *n* keeps an output short.
- A flow is tested from Apex with `Flow.Interview.createInterview(...)`, `start()` and `getVariableValue(...)`, as
  the test user (TST-15).
- **Open.** Whether a record collection works as a flow action's output: the Agent Script reference allows
  `list[object]` outputs, and the help page *Agentforce Considerations* says a flow with a collection resource
  cannot be used as an action. A project checks it in its own org before relying on it, and keeps the result here.

### 3.2 A prompt template

A prompt template writes text with the language model from facts it is given: an explanation of a decision, a
summary, a draft. **Facts and rules come from code; tone and wording are the prompt's** (AGT-11).

- **Type.** A Flex template; its inputs may be records or free text. Free text inputs suit an agent: the customer
  gives a number, the session gives the account.
- **Grounding.** An Apex class with one `@InvocableMethod` — no `CapabilityType` needed any more — whose `Request`
  has one `@InvocableVariable` per template input, named exactly as the input's API name, and whose `Response`
  has one `String` named `Prompt`. The class is an entry point (`…Action`) over a service that reads through
  selectors and applies the domain's rules, and it filters by the account like an action (AGT-06).
- The template is built in Prompt Builder, previewed there — each preview spends LLM requests — and retrieved into
  the repository as `GenAiPromptTemplate`. A change of a grounding class's inputs breaks the templates that use it:
  change both in one merge request.

### 3.3 Calling a prompt template from Agent Script

- **Open.** The Agent Script reference lists `prompt://<Template>` as a target; Salesforce's recipe
  *PromptTemplateActions* uses `generatePromptResponse://<Template>`, with inputs named `"Input:<apiName>"` and the
  output `promptResponse`. `sf agent validate authoring-bundle` settles which one the project's version takes.

---

## 4 · Access — the agent user and the customer

**Who the agent runs as.** A Service agent runs as its agent user while the customer is not identified, and also
when the customer is identified (verified) but not logged in: then a context variable names the customer, and
access is still the agent user's. Only a customer logged in to an Experience Cloud site, with credential-based
user verification on the channel, makes the agent run as that site user.

**The agent user** has the Einstein Agent licence and the Einstein Agent User profile. It is created in Setup, or
with `sf org create agent-user`:

| | Setup → Users → New User | `sf org create agent-user` |
|---|---|---|
| Base permission set | Chosen: *Agentforce Service Agent Secure Base* is what the builder gives its own agent users | *Agentforce Service Agent Object Access* (`AgentforceServiceAgentBase`) |
| Other permission sets | *Agentforce Service Agent User*, *Prompt Template User*, and the project's own | The same, without the project's own |
| Permission set licences | Assigned with the permission sets that need them | The same |
| Role | Chosen on the form | None: assigned after |
| Username, email | Typed | Generated, unique; the email is the username |

A user is data, not metadata: creating it, assigning its permission sets and its role are steps of
`release-runbook.md` for each org, and its username never enters the repository.

**Its access** (AGT-08):

- A permission set in the repository, `DST_Agent_Access` or one per agent, associated with the
  **Einstein Agent** licence (`<license>Einstein Agent</license>`), as the help page requires for a set of our own:
  access to the action classes and flows; read on what the actions read, create or edit only where an action
  writes; field access for each field the selectors name. No View All, no Modify All.
- Record access through a role for the agent user and sharing rules to that role — the internal organization-wide
  defaults apply to it — not through a change of the defaults, which would reach every internal user.
- A role's opportunity and case access cannot be lower than the organization-wide default; set them to the default.
- Check the result as the agent user sees it: `SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess
  WHERE UserId = :agentUser AND RecordId IN :ids`.

**The customer** (AGT-09): the account or contact an action serves comes from the session — a variable the channel
or a verification step sets — and every action and grounding class filters by it. A context variable tells the
agent who the customer is; it does not limit what the agent user may read. That limit is the actions' filters.

---

## 5 · Tests

| Level | What | How |
|---|---|---|
| Actions and grounding | Each action and grounding class, as `architecture.md` §4.6 says: unit tests of the service's rules, the entry point through the real service and selectors as the test user | Apex; the test user holds the agent's permission set where the test is about access |
| Flows | Each flow used as an action | Apex through `Flow.Interview`, as the test user |
| The agent | Which subagent and action an utterance reaches, and what the agent answers | `AiEvaluationDefinition` with `sf agent test create` and `sf agent test run` (the Testing Center's metadata); a newer Testing Center is in beta |
| Org data | Each action once, after its first deployment, on the org's own records (AGT-12) | Anonymous Apex or `sf agent preview`; a test's own data never shows the records an org already holds |

Every agent test and every preview turn spends the org's LLM requests; a Developer Edition allows 150 an hour.

---

## 6 · Release

The steps the metadata cannot carry go into `release-runbook.md`, in this order for each org:

1. Deploy the actions, flows, prompt templates, permission sets, role and sharing rules (`tools/deploy-build.sh`).
2. Create the agent user, give it its role, its permission set licences and permission sets (§4).
3. Deploy the `AiAuthoringBundle`, publish it, activate it — each asked for (`CLAUDE.md` §3).
4. Run each action once on the org's own data (§5), then the agent tests.

---

## 7 · Open

Items each project settles once, in its own org and version, and records in its open questions:

1. Whether a record collection works as a flow action's output (§3.1).
2. Which target calls a prompt template from Agent Script: `prompt://` or `generatePromptResponse://` (§3.3).
3. For an agent on an Experience Cloud site: which site template supports credential-based user verification, so
   the agent runs as the logged-in user (§4).

---

## 8 · Sources

Checked against API 68.0.

- [Get Started with Agent Script](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html),
  [Agent Script Blocks](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-blocks.html),
  [Agent Script Reference: Actions](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html)
- [Author an Agent with Agentforce DX](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-nga-author-agent.html),
  [Publish an Agent](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-nga-publish.html),
  [Test an Agent with Agentforce DX](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-test.html)
- [Agentforce Metadata Types (v68 and Later)](https://developer.salesforce.com/docs/ai/agentforce/references/agents-metadata-tooling/agents-metadata.html),
  [Define Agent Metadata (v67 and Earlier)](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-api-v67-earlier.html)
- [Configure Service Agent Access](https://help.salesforce.com/s/articleView?id=ai.agent_user.htm&type=5),
  [org create agent-user](https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_org_create_agent-user.html)
- [Agentforce Considerations](https://help.salesforce.com/s/articleView?id=ai.copilot_considerations.htm&type=5),
  [Flow Run Context](https://help.salesforce.com/s/articleView?id=platform.flow_distribute_context.htm&type=5)
- [Grounding with Apex Merge Fields](https://help.salesforce.com/s/articleView?id=sf.prompt_builder_ground_apex.htm&type=5),
  [Add Free Text Inputs to a Flex Prompt Template](https://help.salesforce.com/s/articleView?id=sf.prompt_builder_add_free_text_input_flex.htm&type=5),
  [Agent Script Recipes: PromptTemplateActions](https://developer.salesforce.com/sample-apps/agent-script-recipes/action-configuration/prompt-template-actions)
- `developer.salesforce.com` refuses scripted fetches; its documentation pages have Markdown twins (`.md` for
  `.html`) that a browser opens.
