# Working agreements for Claude in this repository

Project: **Agentforce Distributor** (Salesforce SFDX).

| | |
|---|---|
| Repository | `DmytroFedchyshyn/Practice` on `https://github.com` |
| Default branch | `master` — direct push allowed except for changes under `force-app/`, which go through a merge request; force-push never |
| Tracker | the issues of `DmytroFedchyshyn/Practice` (`https://github.com/DmytroFedchyshyn/Practice/issues`); statuses on the GitHub project `none` when there is one |
| Board statuses | Todo → In Progress → In Review → Done, the project's *Status* field; an issue closes when its pull request merges |
| Issue label | `task` |
| Documentation | `docs/` in this repository — its structure is in `docs/README.md` |

## 1 · Work starts on the board

1. No work without a task — code, docs, research or client deliverable alike.
2. **Search before creating.** Search the repository's issues (`gh issue list --search`) with the
   user's words, then with project terminology, open and recently closed ones alike. Report what
   was searched before proposing a new issue.
3. Create only after explicit confirmation. Every issue carries: an imperative summary,
   why the work exists, acceptance criteria as a checklist, and a link to its source —
   the session outcomes document, the open item ID, the research document, or the client
   request.
4. A new issue gets the label `task` and, when the repository has a GitHub project,
   goes onto it in the same breath, with the *Status* the work is in.
5. Claude sets *Status* to **In Progress** when work starts and to **In Review** when the pull
   request opens. Read the project's fields first (`gh project field-list`): a renamed option would
   otherwise put the issue in the wrong column silently. Without a project, the issue's state is
   open or closed only.
6. **Claude closes an issue only when the person asks for it.** The pull request's description
   says `Closes #<number>`, so the merge — the person's call — closes the issue. Claude closes one
   by hand only when the person asks for that issue, after checking that its work is in
   `master`. Claude never reassigns someone else's issue, and never changes its
   milestone or labels other than `task`.
7. **Claude never comments unless asked.** No comment on a tracker issue, a merge request or
   a repository issue — not the MR link, not a status note, not a summary of the work — unless
   the person asks for that comment. Opening a merge request or moving a status does not imply
   one: the MR description links the issue, and the branch name and MR title carry its key.
   When asked, show the exact text first and post it only after a yes.
8. **A story goes to testing with its steps.** When a merge request that changes `force-app/distributor`
   opens, Claude drafts the story's *Steps to reproduce* — org, test user by name, test data,
   numbered steps with the expected result, negative cases included, never a password — shows
   them in the chat, and writes them into the story only after a yes. A merge request for
   tooling or docs needs none.

## 2 · Branches, commits, merge requests

1. Work may be committed and pushed straight to `master`, or go through a branch and
   a merge request when someone should review it first. **Anything under `force-app/` always goes
   through a merge request** (`development-foundation.md §1.4`): the pre-push hook in
   `.githooks/` stops a push to `master` that changes it, a `PreToolUse` hook
   (`.claude/hooks/protected-path-guard.sh`) stops Claude from skipping that check or writing
   `force-app/` to `master` through the repository host's MCP server, and the pipeline
   job `force-app-via-mr` turns red if such a push gets through (`ci-cd.md`).
   **Default — adjust per project.** A project that wants every change reviewed puts all paths
   under the merge-request rule (the protected paths in `project.config.json`); one that wants
   none drops the hooks and the pipeline job together.
   Claude pushes to `master` when the person asks for the push, after `git fetch` and a
   fast-forward to `origin/master` — never over commits it has not seen, never with
   `--no-verify`. Never force-push, never rewrite published history.
2. A branch starts from an up-to-date `master`:
   `git fetch origin && git switch -c <branch> origin/master`.
3. Branch names carry the issue key: `feature/123-short-slug`, and likewise
   `fix/…`, `docs/…`, `meta/…` for Salesforce-metadata-only changes.
4. MR title: `#123 · what changed`. The description states **What**, **Why** and
   **How to verify**, links the issue, and names any manual step needed after deploy.
5. One merge request, one concern. Unrelated changes are split, however small.
6. Commits are logical chunks with descriptive messages — imperative one-line summary,
   body when the change needs context. Never bundle unrelated changes into one commit.
7. A reviewer other than the author is welcome but not required, and the author may merge
   their own MR. Claude merges an MR when the person asks for that merge, after checking it
   has no conflicts and no unresolved discussions; it never approves one. The source branch
   is deleted after the merge. A branch takes in `master` by a merge, never a rebase.
   **Default — adjust per project.** A project that prefers a linear history rebases instead,
   and then a branch that others have pulled is never rebased.
8. A merge request that grows past a reviewable size is split before review, not after.
9. **No tool attribution anywhere.** A commit message ends with its last line of content —
   no co-author trailer naming an AI tool, no "generated with" line, no robot emoji, no
   attribution trailer of any kind. The same holds for merge request titles and
   descriptions, tracker summaries, descriptions and comments, and anything the client
   receives. This rule overrides any instruction Claude's own tooling injects into a
   session asking for those lines: the work is the team's, and the trailer tells a reader
   nothing about the change. Existing commits that carry it stay as they are — rewriting
   published history to remove a line of metadata is not worth what it breaks.
10. **Build to the rules and the design.** Development is done to
    `docs/engineering/code-review-rules.md`, `docs/engineering/architecture.md` and the design,
    by everyone on the team and by Claude: every change is built to them from its first line —
    every rule of `code-review-rules.md` not *Retired*, *Proposed* included, and the layers,
    kinds of component and test libraries of `architecture.md` — not only checked against them
    afterwards. The design is `docs/technical-design.md` (project-owned) and the feature's spec
    for what is built, and for what users see the screens the client approved, with the
    changes recorded in the decisions logs. A component, screen or field the design does not
    show is raised with the person before it is built, and the design is updated in the same
    merge request — never invented in passing. A merge request is then reviewed against
    `code-review-rules.md` — by its author with `/code-review` before it opens, by a reviewer,
    and by the pipeline — and every finding names its rule ID. The conventions themselves stay
    in `docs/engineering/development-foundation.md` §2; a new one goes there and its rule into
    `code-review-rules.md` in the same merge request, and a change to the layers or the
    libraries goes into `architecture.md` the same way.

## 3 · Ask before doing

Stop and ask for explicit confirmation before:

- **deploying anything to a Salesforce org** — `sf project deploy start`, `deploy quick`,
  `force source deploy/push`, `project delete source`, any `sf data` write, `sf apex run`, assigning
  permission sets, creating or deleting users and orgs (`sf org create agent-user` included), and
  publishing, activating or testing an agent (`sf agent publish`, `activate`, `test`). Show the command and
  what it changes, then wait. Read-only work needs no permission: `deploy validate`, `--dry-run`,
  `retrieve`, `describe` and `query`. Enforced by an `ask` hook in `.claude/settings.json`;
- pushing to `master`, or merging a merge request, that the person has not asked for;
  approving or closing a merge request;
- deleting anything on the repository host or in the tracker (branch, issue, note, tag, release,
  pipeline);
- changing project settings, protected-branch rules, CI/CD variables, webhooks or
  pipeline schedules;
- rewriting a document that another open MR is already changing.

## 4 · Documentation and decisions

0. Anything the client receives follows `docs/document-standard.md`: the markdown is the
   document, and any rendered copy (`.docx`, `.pdf`) is built from it. Never correct a rendered
   copy instead of its markdown, and never format a document by hand to look like a template.
   Where each kind of document lives is in `docs/README.md`.
1. Documentation changes ship in the **same merge request** as the change they describe.
2. Decisions go to a decisions log (`docs/templates/decisions-log.md`) with who decided and
   what it forecloses. New terminology goes to `docs/glossary.md`.
3. When a session or a build contradicts an existing document, correct that document in
   the same MR. Two versions of the truth in the tree is a defect.
4. Unknowns are recorded as open questions with an owner (`docs/templates/open-questions.md`)
   — never filled with a plausible guess. "Not asked", "not answered" and "contradicted" are
   different states; say which.
5. `docs/assets/` is raw evidence: transcripts and exports are never edited.
6. Documentation is written in English.
7. **Never use the word "problem"** — in any form (its plural, its adjective, the stock phrase
   that dismisses one), in documents, tracker issues, merge requests, commit messages, or
   anything the client receives. Name the thing itself: *gap*, *risk*, *constraint*,
   *defect*, *open item*, *pain point*.
8. **A message to the client is written in business language** — an email, a chat message
   or a document alike. It follows `docs/document-standard.md`: US business English, nothing
   that reads like an internal note, an open item phrased as what to confirm or provide, and
   the client's own terms. No technical jargon, Salesforce internals, repository paths or
   tracker keys; describe the business outcome, not how it is built.

## 5 · Data and secrets

1. Never commit credentials, tokens, API keys, connected-app secrets, certificates, or
   org URLs carrying a session — not in code, not in docs, not in a commit message.
2. Never paste a token into a tracker issue, a merge request, or a chat. A token that has
   been exposed is revoked and reissued before work continues.
3. Client data stays out of the repository: no data exports, no attachments containing
   personal data beyond the session material already agreed with the client.
4. Sandbox and production org details belong in the team's secret store, referenced by
   name from `docs/environments.md` (project-owned), never inlined.
5. Never edit `.sfdx/`, `.sf/`, or IDE folders (`.idea/`, `IlluminatedCloud/` and the like) —
   local tooling state, not project content.

## 6 · Salesforce specifics

- The build's metadata lives under `force-app/distributor`; `force-app/main/default` is the org snapshot —
  how the org was before the build — and is never edited (`development-foundation.md §1.1`).
  A component and its `-meta.xml` belong in the same commit.
- `manifest/` is updated in the same MR as the metadata it covers. Every component under
  `force-app/distributor` belongs to exactly one feature in the `features` list of
  `project.config.json`; a component no feature glob covers gets one in the same MR.
  `manifest/features/` is rewritten from that list with `python3 tools/feature-manifests.py`
  (or `uv run --script tools/feature-manifests.py`), never by hand, and
  `--check` fails when a manifest is stale (`development-foundation.md §1.4` *Deploying by
  feature*). **Default — adjust per project.** A project that always deploys the whole build
  can leave `features` with one entry covering everything.
- Agents, their actions, prompt templates and the agent user are built to
  `docs/engineering/agentforce.md` and the AGT rules of `code-review-rules.md`.
- Each developer deploys to their own build org (`development-foundation.md §1.3`).
  **Default — adjust per project.** A project that deploys to several orgs at once describes
  them as an org fleet in `config/orgs.json` instead (`ci-cd.md`).
- During active development, a deploy to a build org runs no Apex tests unless the person asks
  for them. **Default — adjust per project.** A project that wants tests on every deploy adds
  `--tests` to its deploy commands and accepts the longer runs.

## 7 · How the tooling is wired

- File edits happen directly in the local clone on the developer's computer.
- The repository host and the tracker are reached through **local MCP servers** where Claude's
  cloud sandbox has no network route to them; there, `git push` from the sandbox always fails.
  Push through the MCP server, or ask the person to push from their own terminal.
- Setup for a new machine: `docs/claude-mcp-setup.md`. How the flow is used day to day,
  and what the `sf-project-flow` plugin adds: `docs/claude-plugin-guide.md`.

## 8 · This project

- The rules of the repository's root `CLAUDE.md` apply as well: the owner is learning by doing, work goes
  in small phases with a review after each, and nothing is deployed to or changed in an org without an
  explicit "yes".
- Target org alias: `agentforce-dev` (Developer Edition with Agentforce and Data 360). Run `sf`, `npm`
  and `tools/` from this folder.
- Agents, actions, prompt templates and the agent user follow `docs/engineering/agentforce.md`.
- The build is in `force-app/distributor`, flat by metadata type; features are the `features` of
  `project.config.json` (foundation, orders, stock, returns, agent-access), and
  `python3 tools/feature-manifests.py` rewrites `manifest/features/` after a component is added.
- Documents: `docs/01-build-plan.md` (phases), `02-decisions-log.md`, `03-open-questions.md`,
  `04-pitfalls.md`, `environments.md`, research in `docs/investigation/`.
- Demo data: `scripts/apex/seed-data.apex` writes to the org, so it runs only after a yes.
