---
name: project-docs
description: Write and maintain the docs/ tree of this project — engineering standards, as-is analysis, feature specs, investigations, session records — following the house structure in docs/README.md, its tone and its diagram conventions. Use when adding or updating project documentation or asking where a document belongs.
---

# Project documentation

## Scope

This plugin serves one project, named in `${CLAUDE_PLUGIN_ROOT}/project.md` with its
repository and tracker. Read that file for the constants and run the scope check there before
any write. If the session is working on a different repository or board, stop and say so
rather than adapting this skill to it.

Documentation is a deliverable, not a byproduct. It is what the client reads, what the
next consultant inherits, and what the build is checked against.

## Where things live

`docs/README.md` describes the tree and is the authority on it; read it before creating a
file. Its usual shape:

```
docs/
  README.md              the structure of docs/ and what goes where
  engineering/           development foundation, architecture, review rules, runbook, CI/CD
  document-standard.md   how anything the client receives is written and built
  glossary.md            client and platform terminology
  templates/             decisions log, open questions
  as-is/                 how the client's current system actually works today
  features/              to-be feature specs
  investigation/         research into options, vendors, platform questions
  workshops/             one folder per client session
  assets/                raw source material: transcripts, exports, screenshots
```

Before creating a file: list the directory and read the neighbours. Match their naming —
a numbered prefix where the folder uses one — and heading style instead of inventing a new
one. **Never renumber or rename existing files** — links point at them. A subfolder with more
than a handful of files gets a `README.md` index.

## How the documents read

- **English**, plain and specific. No filler, no marketing register, no "leverage".
- Lead with the answer. A reader who stops after the first paragraph should have the point.
- **Attribute every claim.** Facts from a session carry the speaker; facts from a system
  carry the object or automation name; facts from research carry a link. A sentence with
  no traceable origin is either common knowledge or does not belong.
- Preserve **verbatim quotes** for anything judgemental or contested — a user's own words
  with their name and role are evidence; your paraphrase that "the current tool is poor" is
  your opinion.
- Tables for structured facts (participants, field maps, option comparisons). Prose for
  reasoning. Bullets only for genuine lists.
- A document that supersedes another says so at the top and links to it.

## Option comparisons and informational notes

A comparison of approaches, in `docs/`, in a shared document or in any note shared outside
the working session, reads as a solution architect's recommendation, not as a working note.
The reader may be the client, so write every one as if it were.

**Columns, in this order:** `#` · `Approach` · `How it works` · `Challenges` ·
`Recommendation`. Never `Cons`, `Issues`, `Verdict` or a column that names faults: a
challenge is something the approach has to handle, not a fault we are pointing at.

**Register.** Neutral, specific consulting language. A judgement is a recommendation with its
condition, never a one-word verdict.

| Do not write | Write instead |
|---|---|
| Cons | Challenges |
| Verdict: **No** | **Not recommended**, with the reason in one clause |
| Simplest. | Lowest implementation effort |
| Not clean | Requires cleanup of … (name what) |
| Degraded old pages | Limited functionality in the current application during the transition |
| Thrown away after the move | Decommissioned after the move |
| Everyone trained at once | All users trained before a single go-live date |
| Every deploy can break the old app | Each release requires regression testing of the current application |
| One big day | A single cutover window |

**Technical precision.** Name the mechanism, not only its effect:

- the object and field by API name (`Invoice__c.Approver__c`), the automation by its name,
  access by its component (profile, permission set, sharing set, sharing rule);
- identity by its parts: user, Contact, Account, username, Federation ID, SSO provider;
- who or what runs a step: a person and their role, a Flow, Apex in system context, a
  scheduled job.

A vague verb (*move*, *remap*, *tidy*, *handle*, *switch*) is followed by what exactly changes
on which record, or replaced by it.

**Any move or migration** is written as a before and after, never as one sentence. State:

1. what moves, from where to where: records, users, access, links;
2. what stays as it is, and why it can (same org, same object, sharing by Account);
3. the order of the steps where order matters (a Federation ID cleared before it is set
   again);
4. who or what triggers it, and when;
5. whether it can be reversed, and what a rollback would take.

The usual shape is a table `Item · Before · After · What changes`, with a numbered list for the
sequence.

**States, explicitly.** Each statement is a confirmed decision (with its ID in the decisions
log), a proposal, or *To be confirmed* with the open question named. A platform behaviour not
checked in the documentation or in a sandbox is marked *to be verified*, never stated as fact.

## Header block

Open every non-trivial document with the source and its companions:

```markdown
# 01 · Order intake — as it works today

**Discovery session 1 · <client> x <delivery team>**
Source: `docs/assets/<transcript>.vtt` · Companion: [`known-facts.md`](known-facts.md)
```

## Documents the client receives

Anything that leaves for the client — a session pack, a rendered `.docx` or `.pdf` —
follows `docs/document-standard.md`, not this skill alone. The markdown is the document; the
rendered file is disposable and is never hand-edited.

## Diagrams

Mermaid, inline, **section-scoped** — each diagram shows the mechanism its section
describes, so the process can be followed without reading a table. Full end-to-end
versions go in `diagrams/*.mermaid` as separate files for import into a diagramming tool.

House notation for process flows: `[A]` a step performed by named, active automation,
`[M]` a step performed by a person, amber for where it goes wrong. State the legend in
the document rather than assuming the reader knows it.

## Unknowns

Never fill a gap with a plausible guess. An unknown goes to the open-questions document
(`docs/templates/open-questions.md` is its shape) as a numbered item with an owner and why it
matters. "Not asked", "not answered" and "contradicted by X" are three different states —
say which.

## Keeping it current

- Update the document in the **same merge request** as the change it describes.
- When a session or a build contradicts an earlier document, correct that document and
  note what changed — do not leave two versions of the truth in the tree.
- Never edit anything under `assets/` — raw material is evidence and stays untouched.
- Client-sensitive material (credentials, org URLs with tokens, personal data) never goes
  into the repository, in any file.

Docs changes reach the default branch the way `CLAUDE.md` §2 says: pushed straight to it
when the person asks, or through a branch and a merge request when someone should review
them first.
