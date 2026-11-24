# Documentation — how `docs/` is organized

**Internal · Agentforce Distributor delivery team**
**Status:** house structure, delivered by the kit. Change it in a merge request.

Documentation is a deliverable, not a byproduct: it is what the client reads, what the next consultant
inherits, and what the build is checked against. This page says where each kind of document lives, how a page
opens, and where decisions, open questions and terms are recorded.

## 1 · Where things live

```
docs/
  README.md                this page
  NN-slug.md               the project's own topics, two-digit prefix, kebab-case
  technical-design.md      what is built (project-owned)
  environments.md          orgs, aliases, licenses (project-owned)
  document-standard.md     how client documents read, look and are built
  glossary.md              client, platform and delivery terminology
  claude-mcp-setup.md      connecting Claude Code to the tracker and the Git host on a new machine
  claude-plugin-guide.md   how the project's Claude plugin is used day to day
  engineering/             the kit's engineering docs, unnumbered and stable
  templates/               starting points to copy, never edited in place for a project
  features/<NN-slug>/      one folder per feature of the design: spec, its open questions, as-built notes
  investigation/           research into options, vendors, platform limits and licensing
  workshops/<session>/     one folder per client session, with its decisions log
  assets/                  raw evidence: transcripts, exports, screenshots, the Word template
```

**Numbered topic files** — `NN-slug.md`, such as `03-open-questions.md` — hold the project's own topics: scope,
the as-is analysis, the data and access models, the build plan. Numbers are given in order and **never reused**:
two files never share a number, and a file is never renumbered, because links point at it. A topic that ends is
marked *superseded by …* at its top, not deleted and its number given to another. `features/`,
`investigation/` and `workshops/` number their own children the same way where order matters.

**`engineering/`** holds the engineering docs the kit ships. They are unnumbered so every project cites them by
the same name:

| File | Holds |
|---|---|
| [`development-foundation.md`](engineering/development-foundation.md) | Repository layout, orgs, Git and merge requests, deploying by feature, code checks, conventions, and the foundation the build stands on (F-1…F-10) |
| [`architecture.md`](engineering/architecture.md) | The layers and domain classes, the kinds of LWC component, the test libraries and how to use them, third-party code |
| [`agentforce.md`](engineering/agentforce.md) | Agents in Agent Script, their actions, prompt templates and grounding, the agent user and its access |
| [`code-review-rules.md`](engineering/code-review-rules.md) | Every review rule by ID, its severity and status, and how an exception is granted |
| [`ci-cd.md`](engineering/ci-cd.md) | The pipeline jobs, the variables per CI platform, and the fleet deploy |
| [`release-runbook.md`](engineering/release-runbook.md) | The manual steps before and after a deployment, ticked per org |
| [`automation-collision-map.md`](engineering/automation-collision-map.md) | What happens to each piece of the org's existing automation the build meets |
| [`automation-switches.md`](engineering/automation-switches.md) | The switches that turn the build's automation off, written for the client's administrators |

A project changes these files when its own rules change — they are the project's from the day the kit is
installed — but keeps their names and section numbers, which other documents cite (`development-foundation.md
§1.4`).

**`templates/`** holds starting points: [`decisions-log.md`](templates/decisions-log.md) for each session's log
and [`open-questions.md`](templates/open-questions.md) for the project's open-questions register, copied once to
a numbered topic file.

**`features/<NN-slug>/`** — one folder per feature of the design, numbered in the order the design lists them:
the spec, the feature's own open questions, and `as-built.md` where the build departs from a document the client
owns (a SOW is never edited; its departures are recorded beside it).

**`workshops/<session>/`** — one folder per client session, named as the folder shared with the client names it.
Each holds the session's pack ([`document-standard.md`](document-standard.md) §1) and a `decisions-log.md` built
from [`templates/decisions-log.md`](templates/decisions-log.md). A subfolder with more than a handful of files
gets a `README.md` index.

**`assets/`** is raw evidence — transcripts, exports, screenshots, the client's own files, the Word template. It
is **never edited**: a transcript with an error stays as it is, and the correction goes into the document that
cites it. Client data stays out of it beyond the session material agreed with the client.

## 2 · How a page opens

Every non-trivial page opens with a header block, under its title:

```markdown
# 07 · Data model — the objects the build adds

**Internal · Agentforce Distributor delivery team**
**Status:** draft for team review. Each row is **Agreed** (decision ID), **Proposed** or **To be confirmed**.
**Sources:** `force-app/main/default` (the org as it was) · [Session 4 decisions log](workshops/<session>/decisions-log.md)
**Companions:** [`technical-design.md`](technical-design.md)
```

- **Audience** — the first line says who the page is for: *Internal · … delivery team*, or, for a page the
  client receives, the frontmatter of [`document-standard.md`](document-standard.md) §3 instead of this block.
- **Status** — one of the status words below, and what a reader may rely on.
- **Sources** — where the facts come from: transcripts, documents, the org snapshot, an investigation. A sentence
  with no traceable origin is either common knowledge or does not belong.
- **Companions** — the pages read with this one. A page that supersedes another says so here and links to it.

**Section numbering.** Sections are `## N · Title`, numbered from 0 or 1 and never renumbered once other pages
cite them; subsections are `### N.M Title`. A section that goes is removed and its number left free. Cite a
section as `development-foundation.md §1.4`.

**Status words.**

| For | Words |
|---|---|
| A page | *draft for team review* · *proposed* · *agreed* (with the decision ID) · *living sheet* (rows added as they appear) · *current* · *superseded by …* |
| An item on a page | **Agreed** (decision ID) · **Proposed** · **To be confirmed** (with the open question's ID) · *to be verified* — a platform behavior not yet checked in the documentation or in a sandbox, never stated as fact |
| A rule | *Active* · *Proposed* · *Retired* ([`code-review-rules.md`](engineering/code-review-rules.md) §1) |

**"Forecloses:" lines.** A decision written into a page ends with what it rules out, on a line of its own:
*Forecloses: email-only requests in the first release.* A reader then sees which alternatives are closed without
reading the session that closed them. The decisions log carries the same in its *Forecloses / opens* column.

## 3 · Where decisions, questions and terms go

| What | Where | Rule |
|---|---|---|
| A decision | The decisions log of the session that took it: `workshops/<session>/decisions-log.md` | With who decided, the source and what it forecloses. A decision taken outside a session goes into the log of the session it answers, under *After the session* |
| An open question | The project's open-questions register (`NN-open-questions.md`, from [`templates/open-questions.md`](templates/open-questions.md)) | With an owner. *Not asked*, *not answered* and *contradicted* are different states; say which |
| A term | [`glossary.md`](glossary.md) | In the merge request of the document that first uses it |
| A fact a session or a build contradicts | The document it contradicts, corrected in the same merge request | Two versions of the truth in the tree is a defect |
| What is built | `technical-design.md` (project-owned) and the feature's spec | A component the design does not show is raised before it is built, and the design updated in the same merge request |
| Orgs, aliases, licenses | `environments.md` (project-owned) | Aliases and names only; URLs with a session, credentials and secrets never go into the repository |

## 4 · Keeping it current

- Documentation changes ship in the **same merge request** as the change they describe.
- **Default — adjust per project.** A change that touches only `docs/` may be pushed straight to the default
  branch, while anything under `force-app/` reaches it only through a merge request; a project that reviews every
  document change sends docs through merge requests too.
- Documentation is written in US English, plain and specific. Lead with the answer; tables for structured facts,
  prose for reasoning, bullets only for genuine lists.
- Diagrams are Mermaid, inline, each showing the mechanism its section describes.
