---
name: discovery-research
description: Research a platform, vendor, integration or licensing question for this project and write the findings into docs/investigation with sources, dated facts and a recommendation. Use when asked to compare options, evaluate vendors, check platform limits or pricing, or investigate feasibility.
---

# Discovery research

## Scope

This plugin serves one project, named in `${CLAUDE_PLUGIN_ROOT}/project.md` with its
repository and tracker. Read that file for the constants and run the scope check there before
any write. If the session is working on a different repository or board, stop and say so
rather than adapting this skill to it.

The deliverable is a document a solution architect can defend in front of a client — not
a list of links, and not a summary of vendor marketing.

## Ground rules

- **Search before answering.** Prices, limits, product names, licence tiers and
  deprecations change; training data is not a source. Anything presented as current fact
  gets a link and the date it was checked.
- **Prefer primary sources**: official product documentation, release notes, the vendor's
  own pricing page, platform limit tables. Blog posts and comparison sites are leads to
  verify, not evidence.
- **Separate the three registers explicitly**: what is documented, what practitioners
  report, and what you infer. An inference stated as documentation is the failure mode
  that costs a project money.
- **Vendor claims are claims.** Attribute them ("Vendor X states…") until an independent
  source or the documentation confirms them.
- Record what you could **not** confirm. A named gap is a finding; silence reads as
  "checked and fine".

## Output

`docs/investigation/NN-topic.md`, continuing the existing numbering (`docs/README.md`).
Shape:

1. **Question** — the decision this research has to support, in one or two sentences, and
   who needs it by when.
2. **Short answer** — the recommendation, up front, with the main trade-off named.
3. **Options** — one section each: what it is, what it costs (licence model, per-user vs
   platform, hidden costs), what it requires (licences, environments, skills), where it
   breaks. A comparison table only after the prose, never instead of it; its columns,
   wording and the before-and-after for any migration follow `project-docs`, *Option
   comparisons and informational notes*.
4. **Constraints found** — hard platform limits, governor limits, API quotas, contractual
   or regional restrictions, with links.
5. **Open questions** — what must be confirmed with the client, the vendor or the
   platform's own admin console before this decision is safe.
6. **Sources** — every URL used, with the date checked, as markdown links.

## Fitting it to the project

Generic research is worthless here. Anchor every option against what the project already
knows: existing licences and editions (`docs/environments.md`, project-owned), the client's
stated constraints from session outcomes, the as-is architecture, and the decisions already
logged. When an option contradicts a logged decision, say so and name the decision.

Cost work states its assumptions — user counts, tiers, term, region — because the number
will be quoted back later without them.

## Delivery

Write into `docs/investigation/`, add the open questions to the project's open-questions
document, and ship it the way `CLAUDE.md` §2 says — straight to the default branch when the
person asks, or through a branch and a merge request. In a merge request description, say
what decision the document unblocks.

## Never

- Never present a figure without a source and a date.
- Never let a vendor's comparison table stand as the analysis.
- Never resolve an open question by assuming the convenient answer; leave it open and
  say who can close it.
