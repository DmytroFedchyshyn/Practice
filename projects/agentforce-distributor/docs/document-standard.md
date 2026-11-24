# Client document standard

**Internal · Agentforce Distributor delivery team**
**Status:** project standard, delivered by the kit. Change it in a merge request, and record why under the
section it changes.
**Template:** `docs/assets/templates/<project-template>.docx` — the project's Word template (Part III says what
it needs).

## Why this page exists

Documents written by different people, in different tools, drift apart: one rendered by pandoc with no logos,
one typed straight into Word, one restyled by hand with every font and color set as direct formatting. The
hand-restyled one tends to be the one the client approves, and it is the one nobody can rebuild: its section
headings are not real headings, so the navigation pane, the table of contents and the PDF bookmarks are empty,
and nothing about its look is reusable.

The same drift happens to how a document *reads*. A sentence written for the delivery team ends up in the
client's copy, in the register of an internal working note. Part II is the fix for that half.

This page has no build step: the look lives in the template, the content lives in markdown, and the `.docx` is
assembled from the two.

---

# Part I · The pack

## 1 · The four phases

| Phase | When | Produces | Audience |
|---|---|---|---|
| 0 · Prepare | Before the session | `agenda.md` | Client, ahead of the call |
| 1 · Issue | Within 24 hours | `minutes.md`, `open-items.md` → `.docx` | Client |
| 2 · Absorb | Same week | `outcomes.md`, `decisions-log.md`, plus corrections to `glossary.md` and the numbered topics the session contradicted | Delivery team |
| 3 · Hand over | With phase 1 | `handover-email.md` | Client, as the covering note |

Everything lives in the session's folder under `docs/workshops/<session>/` ([`README.md`](README.md)). Phase 1
is the only phase that produces a `.docx`; phase 2 never leaves the repository. A session is not finished until
all four exist.

Anything else a session throws off — a data-request workbook, a question list for a vendor, a demo
walkthrough — sits beside these, never instead of one.

## 2 · Markdown is the source, `.docx` is a copy of it

The markdown file is the document. The `.docx` is a copy made for the client.

This is the rule a hand-edited document breaks, and it costs accuracy: a term corrected in the markdown two days
after the `.docx` was approved leaves two versions of the truth, and the client holds the wrong one.

So:

- **Never correct a `.docx` directly.** The correction goes into the markdown, and the `.docx` is made again
  from it.
- If someone edits the `.docx` — a colleague in Word, the client in review — port the change back into the
  markdown in the same sitting, rebuild, and discard their copy.
- The `.docx` is committed beside its markdown so the team can see exactly what the client received. It is
  replaced, never patched.

**Default — adjust per project.** Only the `.docx` is produced: no `.pdf` is built, delivered or committed, and
a PDF may be rendered outside the repository for the visual check in §19 only, then discarded. A project that
delivers PDFs adds the `soffice` step of §18 and commits the `.pdf` beside the `.docx`, replaced the same way.

## 3 · Frontmatter

Every document that will become a `.docx` opens with:

```yaml
---
title:    "Session 4 — <Subject>"
subtitle: "Minutes and Confirmed Decisions"
date:     "Session 4 · <Client> × <Delivery team> · Tuesday, September 8, 2026 · Issued September 9, 2026"
---
```

Three keys, and only three. `title` and `subtitle` are the cover block; `date` is the metadata line beneath the
rule, carrying the session identity and both dates. The body then starts at `#`. **Never repeat the title as a
heading** — the frontmatter has already set it, and a repeated title is the most common defect in these packs.

**Any other key is silently dropped.** An `issued:` line, for one, is ignored by pandoc, and the document goes
out with no issue date at all. Everything that belongs on the metadata line goes on the `date` line.

Dates are written US-style when the reader is a US client: *Friday, September 18, 2026*, and *Issued
September 21, 2026*. Never `18/09/2026`, which reads as a different day on each side of the Atlantic. A project
for a client elsewhere writes the date in that client's convention, with the month in words.

## 4 · Structure of a minutes document

Follow the previous session's file. Where there is none, use this order:

1. Attendance table — a row per organization, plus apologies.
2. What accompanies this document — the companion files, named.
3. `1 · Decisions Confirmed in the Session` — each decision bold-led, then what it forecloses.
4. `2 · How <the thing> Behaves — for the Record` — the mechanics and the numbers, so the facts are on file for
   whoever joins later.
5. `3 · Feedback on the Demonstration` — accepted in principle, then the changes asked for.
6. `4 · The One Item to Settle Before <the next session>` — a single blocking question.
7. `5 · Deferred by Agreement` — what was consciously not decided, and where it goes.
8. `6 · Actions` — a table of `A-N.M`, action, owner, due. No unowned actions.
9. `7 · New Scope Raised in the Session` — labeled as scope, never buried in a bullet.
10. `8 · Access and Prerequisites`.
11. `9 · Next Sessions` — session, subject, attendance.

Section headings carry a number and a middle dot: `# 1 · Decisions Confirmed in the Session`. Numbering runs
continuously and never restarts. `##` beneath, and nothing deeper in a client document. Headings are in Title
Case; unnumbered structural headings — *Attendance*, *Apologies*, *How to Read This Document* — take the same
style without the number.

---

# Part II · How the documents read

## 5 · US business English

Write in clear, professional US business English: professional but natural, concise, direct without sounding
demanding, confident without overstating what was decided. Business register, not academic, legalistic or
engineering. US spelling throughout, unless an official product name or a client term spells it otherwise.

One sentence normally carries one idea. Lead with the answer — a reader who stops after the first sentence
should still have the point.

Language that fits the register:

> Confirm whether… · Please confirm… · Required to define… · Required to determine… · Required to finalize… ·
> We will share … for review and confirmation. · Confirm the Phase 1 approach… · Define the expected process
> for… · Included here for reference. · Confirmed during the session. · Open item from the previous session.

## 6 · Nothing that reads like an internal note

The most common defect in client text is not an error of fact — it is register. A sentence written for the
delivery team ends up in the client's copy, and it reads as either pressure or improvisation.

Never send:

| Do not write | Write instead |
|---|---|
| We will send the candidate field list; please mark the keys. | We will share a proposed list of matching fields for your review and confirmation. |
| We send the stage list and you return the mapping. | We will share the stage and status values for your review and confirmation of the mapping. |
| We would rather build to a rule than to a named individual. | Required to define consistent, rule-based routing. |
| It would be noise within a week. | Required to define relevant notification triggers and avoid unnecessary notifications. |
| You can change it by hand. | You can update it manually. |
| Recorded here so we do not ask again. | Recorded here for reference. |

The same applies to *we need you to*, *we cannot build this until*, *the build should assume*, *we didn't get to
this*, *not reached in the session*, *the one area we don't know*, *this one answer decides everything* and
*simply leave it as is*. Each of them is either a demand, an apology or a piece of internal reasoning, and none
of them belongs in front of a client.

Where a gap is real, say so neutrally: *To be confirmed*, or *Not covered in this session*.

## 7 · How an open item is phrased

An open item tells the client what to confirm or provide. It does not narrate how we arrived at the question.

The pattern:

> **[Topic]** — confirm / define / provide [the specific decision or information].

For example:

- **Notification triggers** — confirm which record changes should notify the user and what information the
  notification should include.
- **Routing queue structure** — confirm which segments use each queue and whether the current routing approach
  will remain.
- **Renewal process for Phase 1** — confirm who initiates a renewal and whether the customer is notified.

Avoid open-ended headings that name no decision — *What you want to know about…*, *Anything the user should
see…*, *What we need…*, *Things to decide…*. The topic goes in bold at the front of the cell; the rest of the
cell stays in regular weight.

## 8 · "Why it matters"

This column carries the business or design dependency, and nothing else. Not our frustration, not the workshop
history, not our implementation preference.

Prefer: *Required to define…* · *Required to determine…* · *Required to finalize…* · *Defines…* · *Determines
whether…* · *Confirms the Phase 1 scope…* · *Supports…* · *Ensures…*

Avoid: *We cannot build this until…* · *This question was left open.* · *We would rather…* · *We need an answer
because…*

Where the history genuinely helps, state it flatly — *Open from Session 5.* — and let the business rationale
carry the rest of the cell.

## 9 · Decision, proposal, assumption, open item

Four states, never blurred:

| State | Means |
|---|---|
| **Confirmed decision** | Explicitly agreed by the client in the session |
| **Open item** | Requires a confirmation, a decision or information from the client |
| **Proposed approach** | Recommended by the delivery team, not yet confirmed |
| **Assumption** | Used to keep moving, and requiring validation |

A proposal or an assumption is never written up as an agreed decision. Where the source material is ambiguous,
the answer is *To be confirmed* — not the reading that happens to be convenient. Keep the client's numbers
exactly as stated; do not round, convert or tidy a figure. Never invent an attendee, a date, an owner or a due
date to complete a section.

Nothing internal goes into a client document: no repository paths, tracker keys, Git host URLs, internal costs,
org URLs or credentials.

## 10 · The client's terminology

Use the client's words where the client has already established them — the names of its objects, roles,
processes and programs, as `glossary.md` lists them under *The client's own terms*.

Do not coin a new term to sound more precise, and do not replace an established business term with its
Salesforce equivalent. Where the terminology is itself unsettled, keep the client's word and flag it for
confirmation rather than quietly picking one.

---

# Part III · What the project's Word template needs

The look of a client document — fonts, colors, logos, page size — is the project's choice, made once in its
Word template and nowhere else. This part says what that template must provide so the rules of Parts I, II and
IV hold; it does not set the look.

## 11 · The template and the style map

`docs/assets/templates/<project-template>.docx` holds every visual decision and an empty body. Build a document
by running pandoc with the template as its reference document (§18) — never by starting a blank Word file and
formatting it to match.

**Apply styles by name. Never apply direct formatting** — no font, no color, no size, no alignment set on a run
or a paragraph. Everything is in the style, and a document with direct formatting cannot be restyled later,
which is how a hand-restyled document becomes a dead end.

The template defines each of these styles, under exactly these names, since pandoc writes to them:

| Content | Style name |
|---|---|
| Document title | `Title` |
| Subtitle line | `Subtitle` |
| Metadata lines | `Date` |
| Section heading | `Heading 1` |
| Sub-heading | `Heading 2` |
| Body paragraph | `Body Text` |
| First paragraph after a heading | `First Paragraph` |
| List item | `Compact` |
| Text inside table cells | `Table Text` |
| Quote or correction note | `Block Text` |
| Image caption | `Image Caption` |
| Tables | table style `Table` |
| Link | character style `Hyperlink` |

One typeface, set as the theme font, so two fonts never appear in one document except inside a supplied brand
asset. Rules under the subtitle and under each section heading are the paragraph's bottom border in the style,
never typed as underscores or hyphens. `Title` carries clear space after it, so the subtitle does not sit tight
under the title. Each heading style keeps with the next paragraph (`keepNext`), so a heading never sits alone at
the foot of a page. The page size and margins are a template choice, not a per-document one.

## 13 · The title area

On the first page, below the header:

1. **Title** — `Title` style.
2. Clear vertical space beneath it, from the style.
3. **Subtitle** — the document type: *Minutes and Confirmed Decisions*, *Open Items*.
4. A thin rule directly below the subtitle, from the style, separating the title block from what follows.
5. **Metadata lines** — `Date` style, not italic. For example:
   `<Client> × <Delivery team> · Friday, September 18, 2026 · Issued September 21, 2026`, and on a second line
   where it applies, `Companion document: Open Items`.

Nothing else goes in this area.

## 14 · Section headings

Numbered, Title Case, with a middle dot:

```
1 · Leads from Events
2 · Opportunity Management
3 · Renewals and Reporting
```

`Heading 1`, with its rule and `keepNext` from the style.

## 15 · Tables

Two shapes recur. The five columns of an open-items or decision table:

```
# | Required Input / Decision | Why It Matters | Owner | Needed By
```

and the three of a next-steps table:

```
Who | What | When
```

The five roles are fixed even where a document words the labels differently; the labels above say what the
column is for without sounding like a request.

What the `Table` style gives, and what the build checks:

- A header row formatted by the style, body text left-aligned and top-aligned, modest cell padding, no inflated
  row heights.
- The lead-in phrase in the first substantive cell is bold, and the rest of the cell is not. Bolding the whole
  cell destroys the distinction the bold exists to make.
- The header row repeats across a page break — Word's *repeat header row*, set on the row, never a second header
  typed by hand.
- A row does not split across pages where it can reasonably stay whole, and a header row never lands at the foot
  of a page with no row beneath it.

**Three traps.** The `Table` style formats the first row as a header automatically, so a table with no header row
— the attendance block, where the labels are the first *column* — comes out with a header band across the top
unless the first-row look is switched off on that table:

```python
tbl.style = "Table"
tbl._tbl.tblPr.find(qn("w:tblLook")).set(qn("w:firstRow"), "0")   # no header row
```

A numbered list needs its own numbering definition per list, or Word continues the previous list's count into
the next one. For a second numbered list, add a `w:num` of your own pointing at the template's abstract
numbering for numbered lists, with a `startOverride`.

And in every table pandoc builds, pandoc styles each cell paragraph `Compact` and sizes the grid for a narrower
page. When the template turns on Word's `overrideTableStyleFontSizeAndJustification`, the paragraph style beats
the table style — so `Compact`'s body size wins over the table's smaller size, and narrow columns wrap: an ID such
as `A-7.1` breaks across two lines and runs into the next column. After the build, restyle every paragraph inside
a table as `Table Text`, scale each table's `w:gridCol` values to the template's text width, give the `#` column
a minimum width that holds a section-qualified ID, and add `<w:tblLayout w:type="fixed"/>`.

## 16 · Header, footer and page numbers

Every page carries what the template's header and footer hold; a typical arrangement:

| Position | Content |
|---|---|
| Header | The logos the project uses (§17) |
| Below the header | A thin rule separating it from the content |
| Footer left | The confidentiality marking, from a character style |
| Footer right | `Page X of Y`, from real Word `PAGE` and `NUMPAGES` fields |
| Above the footer | A thin rule separating it from the content |

The confidentiality marking appears in the footer and nowhere else — never in the header band, and never typed
into the page body. Page numbers are fields, never numbers typed by hand.

## 17 · Logos

Logos are embedded in the template's header and are copies of the project's own files under `docs/assets/`
(for example `docs/assets/brand/`). Each keeps its own aspect ratio and the width the brand guidelines of its
owner set as the print minimum or more; two logos side by side are balanced on cap height, not on width. Never
stretch, recolor or crop a logo, and never recreate one as text when the file exists. The same size and position
on every page.

To change a logo: replace the file under `docs/assets/`, replace the matching image in the template's header,
and rebuild every pack. Never paste a logo into an individual document.

---

# Part IV · Building and shipping

## 18 · Naming and delivery

Client-facing files are named `<Session or document set> - <Subject> - <Document>.docx`, with the session's
number and subject as the folder shared with the client carries them — spaces, no tracker key, because this is
the name that lands in the client's inbox.

```bash
pandoc <document>.md -o "<Session> - <Subject> - <Document>.docx" \
  --reference-doc=docs/assets/templates/<project-template>.docx
# only where the project delivers PDFs (§2):
soffice --headless --convert-to pdf --outdir <folder> "<Session> - <Subject> - <Document>.docx"
```

The template is a pandoc reference document: its style definitions, header and footer are what pandoc writes
the content into. That is what "no build step" means here — one command, no script to maintain, and the look is
entirely in the template. The table fixes of §15 are the one post-processing step. Never hand-assemble a
document with python-docx instead; it produces a file that only resembles the others.

## 19 · Final quality check

Render the first pages and look at them — from a PDF made outside the repository when the project delivers
`.docx` only (§2):

```bash
soffice --headless --convert-to pdf --outdir /tmp/check "<file>.docx"
pdftoppm -png -r 90 -f 1 -l 2 "/tmp/check/<file>.pdf" /tmp/check/page
```

**Language** — US business English throughout; nothing reads as an internal note; every open item names what to
confirm; proposals are not dressed as decisions; the client's terminology is intact; unknowns say *To be
confirmed*.

**Formatting** — one typeface at the template's sizes; the logos in the header on every page; the
confidentiality marking in the footer and page numbers opposite it; title, space, subtitle, rule, metadata in
that order; section headings in Title Case, ruled, none orphaned; tables styled per §15 with headers repeating
after a break; no hand-drawn rules, no distorted logo, no stray blank page, no markdown syntax left visible.

**Content** — nothing invented, no owner or date unsupported by the source, no figure tidied, nothing internal.

Then open the navigation pane. If it is empty, headings were styled as something other than `Heading 1` — the
defect this standard exists to prevent.

## 20 · Changing the look

The template is the one file in this pipeline whose look is edited directly, and deliberately so. Change the
**style definition** — never a paragraph in its body, which is meant to stay empty — rebuild every pack that
exists, and commit the template and the rebuilt files together. Record the reason here under the section it
changes.

Word is the usual way to do that. Editing the template's own XML (`styles.xml`, the header and footer parts) is
an acceptable alternative where Word is not at hand: the result is the same file, and it opens and edits in Word
normally. Check the change in the template itself, not only in the rule written here — a rule recorded as
delivered is not in the template until a rebuilt document shows it. Editing a built `.docx` by hand is not
acceptable.

A rebuild replaces the record of what the client received. Before rebuilding a pack already sent, keep the copy
as issued under the session's `archive/` folder.
