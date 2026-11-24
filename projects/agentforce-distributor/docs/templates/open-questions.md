# Open questions and risks

<!--
How to use this template — remove this comment in the copy.

Copy this file to a numbered topic file, docs/NN-open-questions.md, once per project. It is the canonical
register of what is still open. Other documents that raise a question — a workshop record, an investigation, a
feature's own register — keep its wording and history, and point here; this register keeps one line per
question. When a question closes, close it here and in its source in the same merge request.

Never fill an unknown with a plausible guess: it goes here as a question with an owner.
-->

**Internal · Agentforce Distributor delivery team**
**Status:** living register. **Checked against the evidence on** *date*: *which transcripts, write-ups and
written answers* — add a dated line each time the register is reconciled with new material.

**How to read it.** One line per question, sorted by area. The wording, the reasoning and the history stay in
the source each section links. Every question keeps the ID it was raised with, so links elsewhere stay valid:
the register's own numbered questions, a prefix per register (*ORG-n*, *LIC-n* …), and session items as their
decisions logs number them (*A-S4.1*). Where two IDs ask the same thing they share a row. Closed items are
listed once, at the end (§9).

**Owner.** Every question names its owner — the person who answers it, by name and organization once known, or
by role until then (*Client — Salesforce administrator*). A question with no owner is not yet in the register.

## States

A question is in exactly one state. **Not asked**, **Not answered** and **Contradicted** are different states,
and the difference decides what happens next: ask it, chase it, or reconcile two answers.

| State | Means | Next step |
|---|---|---|
| **Not asked** | Known to the delivery team, never put to its owner | Put it to the owner; name the session or channel |
| **Not answered** | Put to its owner — when and where is in the cell — and no answer yet | Chase it; say since when it is waiting |
| **Partly answered** | An answer covers part of the question; the cell says which part is still open | Ask the open part only |
| **Contradicted** | Two answers, or an answer and the evidence (the org, a document), disagree; the cell names both | Put both to the owner and record which stands |
| **Closed** | Answered, decided or made moot; moved to §9 with the answer and where it is recorded | — |

Write the state in bold with the session or date it was last recorded in: **Not answered** — asked in Session 3,
*date*.

## Register index

Every register in the project, so nothing is open in a file nobody reads.

| § | Area | Prefix | Source register |
|---|---|---|---|
| 1 | Program, licenses and platform | `ORG`, `LIC` | `docs/environments.md` (project-owned) |
| 2 | <Area of the design> | `<PREFIX>` | `docs/features/<NN-slug>/open-questions.md` |
| 9 | Closed — for reference | | |

## 0 · The shortlist — what to chase first

Everything below matters eventually. These are the ones where waiting costs the most.

| # | Question | Why it is first | Owner |
|---|---|---|---|

---

# 1 · Program, licenses and platform

| ID | Question | Owner | State |
|---|---|---|---|
| **ORG-1** | *Example:* Which sandboxes are on the release path, and who refreshes them? | <Client — Salesforce administrator> | **Not asked** |

## Technical risks

| Risk | Description | Mitigation |
|------|-------------|------------|
| *Example:* Security model | A mistake in sharing gives one external user another's records | Architect review before configuration, mandatory |

# 2 · <Area of the design>

| ID | Question | Owner | State |
|---|---|---|---|

---

# 9 · Closed — for reference

| ID | Question | Answer | Where |
|---|---|---|---|

Corrections found along the way — a status label, a field's real behavior in the org — are facts, not questions,
and go into the document they correct.
