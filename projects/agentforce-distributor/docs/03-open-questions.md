# Open questions and risks

**Internal · Agentforce Distributor**
**Status:** living register, from the kit's template (`templates/open-questions.md`). **Checked against the
evidence on** 2026-11-24: the Salesforce documentation linked in each row and the project's own tests.

**How to read it.** One row per question; the ID never changes. Never fill an unknown with a plausible guess:
it goes here with an owner. A question that closes moves to *Closed*, with its answer and source.

## Open

| ID | Question | Owner | Raised | Detail |
|---|---|---|---|---|
| OQ-1 | Agent identity on the site | Developer (this project) | 2026-11-24 | One help page says credential-based user verification makes a Service agent on an Experience Cloud site run as the logged-in site user. Another says user verification is supported only on an external website and a few Aura templates (Build Your Own Aura, Help Center, Customer Service). Resolve before phase 4: it drives the template choice and how we prove a partner sees only their own account. |
| OQ-2 | Record collections as Flow action outputs | Developer (this project) | 2026-11-24 | The Agent Script reference allows `list[object]` outputs with a `complex_data_type_name` ([Actions](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html)). The help page [Agentforce Considerations](https://help.salesforce.com/s/articleView?id=ai.copilot_considerations.htm&language=en_US&type=5) says custom actions on Apex or Flow support only primitive types and that a flow with a collection resource cannot be used. `List_Return_Requests` tests this; check it when the action is added to the agent. |
| OQ-3 | Prompt template action target | Developer (this project) | 2026-11-24 | The Agent Script reference lists `prompt://<Template>`; the [PromptTemplateActions recipe](https://developer.salesforce.com/sample-apps/agent-script-recipes/action-configuration/prompt-template-actions) uses `generatePromptResponse://<Template>` with inputs named `"Input:<apiName>"` and the output `promptResponse`. Check with `sf agent validate`. |
| OQ-4 | The technical design | Owner | 2026-11-24 | The kit expects `docs/technical-design.md` naming every component before it is built (APX-13). The build plan and the decisions log stand in for it until the owner decides whether the project writes one. |

## Closed

None yet.
