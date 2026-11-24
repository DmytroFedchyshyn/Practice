# <CODE> · Decisions log — <session name>

<!--
How to use this template — remove this comment in the copy.

One decisions log per session, in the session's folder: docs/workshops/<session>/decisions-log.md, written in
phase 2 of document-standard.md §1, the same week as the session. A decision taken outside a session — a written
reply, a design review by email, a team decision while applying feedback — goes into the log of the session it
answers, under "After the session", with its date and source.

IDs. Each session has a short code of letters and a number: S4 for session 4, DS2 for design session 2, DM1 for
the first sprint demo. Decisions are <CODE>-N (S4-1, DS2-1), numbered on in the order they are recorded,
across every table of the log; an ID never changes and is never reused, so the documents, the design and the
tracker can cite it. Actions and open items are A-<CODE>.N (A-S4.1, A-DS2.3).

Every row names who decided, with the source: the speaker and the time in the recording, the written reply and
its date. A decision that changes or reverses an earlier one names it, and the earlier row gets a pointer to the
later one in its Standing cell ("reversed by S6-2"); it is never edited away.

A decision forecloses something, or opens something, or both. Say what: the alternatives it rules out, and the
questions or work it opens. A decision that forecloses nothing is probably a preference, not a decision.

When a decision contradicts an existing document, that document is corrected in the same merge request. New
terms go to docs/glossary.md, open questions to the project's open-questions register (a copy of
docs/templates/open-questions.md).
-->

Session of **<Weekday, D Month YYYY>**. Full record: [`outcomes.md`](outcomes.md). Transcript:
`docs/assets/<session>/<file>`.

Standing: ✅ confirmed by the client · 🔵 direction agreed, detail open · 🟡 proposed, not contested.

## Decisions

| # | Decision | Standing | Who | Forecloses / opens |
|---|---|---|---|---|
| <CODE>-1 | **The decision in one bold sentence** — then its detail | ✅ Confirmed | <Name or role>, <time in the recording or source> | Forecloses … Opens … |

## After the session

Decisions taken after the session that answer it — a written reply, a follow-up call.

| # | Decision | Standing | Who, when | Forecloses / opens |
|---|---|---|---|---|

## Not decided

What was discussed and consciously left open, with where it goes next and the action that carries it
(A-<CODE>.N).

- **<Topic>** — <who leans which way, and what settles it> (A-<CODE>.N).

## Added scope named in the session

Scope that goes beyond the agreed baseline, named so it is never buried in a bullet — each with who asked.

- <Scope item> — <who asked>.

## Actions and open items

| # | Item | Owner | State |
|---|---|---|---|
| A-<CODE>.1 | What is to be done or answered | <Named person, or role and organization> | Open |

State is one of: **Open** · **Answered** *date*: *where* · **Closed** *date*: *how* · **Dropped** *date*: *why*.
No action without an owner.
