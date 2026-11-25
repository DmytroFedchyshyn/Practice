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

## Closed

| ID | Question | Answer | Closed |
|---|---|---|---|
| OQ-2 | Record collections as Flow action outputs | Yes: `List_Return_Requests` returns `returnRequests` as `list[object]` with `complex_data_type_name: "lightning__recordInfoType"`, and the agent read the records in the live test (2026-11-25) | 2026-11-25 |
| OQ-3 | Prompt template action target | `generatePromptResponse://Explain_Return_Request`, with inputs `"Input:requestNumber"` and `"Input:accountId"` and the output `promptResponse`, works in the live test (2026-11-25) | 2026-11-25 |
| OQ-4 | The technical design | Not needed: the practice profile does not ask for one (D-43); the build plan and the decisions log describe the build | 2026-11-24 |
