# Automation collision map — what happens to each piece of existing automation the build meets

**Internal · Agentforce Distributor delivery team**
**Status:** empty template. Each row is *Proposed* until the client agrees it; nothing is switched off until its
row is agreed. Record each agreement with its decision ID from the session's decisions log.
**Sources:** the automation inventory of the org as it is (`force-app/main/default`: flows, workflow rules, approval
processes, validation rules, triggers, Custom Metadata read by automation); the design
(`docs/technical-design.md`, project-owned); the stories named in each row.
**Companions:** [`development-foundation.md`](development-foundation.md) §3 (F-8) · the switch-off checklist in
[`release-runbook.md`](release-runbook.md) §1.1, which these rows feed.

---

## 0 · The answer

Fill in once the rows exist: how many automation components the new design meets, by type and by object, and
the count of rows per decision.

| Decision | Rows | Rows by number |
|---|---|---|
| **Switch off at <release>** — the new design replaces it | | |
| **Keep unchanged** | | |
| **To decide** — in a story's design, or with the client | | |
| **Already inactive** — no action | | |
| **Goes with its parent** | | |

**The rule that matters in the sandbox:** a replacement and the switch-off of what it replaces ship in
the **same release**, in every org. In a build org the old automation is active from the start. If a new
routing is deployed while an old flow still assigns the same records, both write `OwnerId` on the same save; if
new notifications arrive while an old flow still emails on every update, every save sends two messages instead
of one. So the switch-off of a row goes into the release of the story that replaces it, not into a clean-up at
the end.

---

## 1 · How to read the rows

| Decision | Means |
|---|---|
| Switch off at <release> | Deactivated in the release of its replacement — in the build orgs when the story is built, in production at the cutover of the named release. The replacing story is named |
| Keep unchanged | Not touched. The row says why, and what in the new build it must still work with |
| To decide | The choice belongs to a story's design or to a document still being written; the row names which |
| Already inactive | Off today (*Obsolete* or *Draft*). Not reactivated; where the new design picks the idea up again, the row says where |
| Goes with its parent | An email alert or field update used only by another component; it follows that component |

**Collision before <release>** is what goes wrong if the old component and its replacement both run on
the same record — in a build org from the first deploy, and in production if the two were ever live together.

**Row IDs.** One section per object, each with a letter, given in the order the sections are added — `A-` for
the first object, `B-` for the next — and a number per row: `A-1`, `A-2`. An ID never changes and is never
reused, so the runbook, the design and the decisions log can cite it; a section added later takes the next free
letter, wherever it sits in the page.

---

## 2 · `<Object API name>`

| # | Component | Type · when it fires | What it does today | New design | Proposed decision | Collision before <release> |
|---|---|---|---|---|---|---|
| A-1 | *Example:* `Order_Owner_Assignment` | Flow · after save, create and update | *Example:* Reads a routing Custom Metadata type and sets `OwnerId` by region; one email to the new owner | *Example:* Every submitted order goes to the review queue (the routing story) | **Switch off at <release>**, with its routing records kept until hypercare ends (runbook SO-4) | *Example:* Two writers of `OwnerId` on one save |

Add a section per object the build touches. Where the object's existing automation is not part of the
design — the build only creates records that it then runs on — keep the section, mark every row **Keep
unchanged**, and say what the automation does to the records the build creates.

---

## 5 · How a switch-off happens

1. **Same release as the replacement.** The deactivation is metadata in `force-app/distributor`: the flow's
   definition is moved there from `force-app/main/default` ([`development-foundation.md`](development-foundation.md)
   §1.1, *one component, one place*) and set to no active version. An approval process is deactivated the same
   way. **To be verified in a build org** before the first row relies on it: that deploying the flow definition
   with no active version deactivates a flow of the org's API version.
2. **Build orgs:** each row is switched off in the release of the story that replaces it, so the sandbox
   always shows the target behavior and never both.
3. **Production:** all *Switch off* rows of a release in one deployment, in the cutover order of the project's
   plan: release deployed → old automation off → data loads under the bypass
   ([`development-foundation.md`](development-foundation.md) §3 F-2) → users invited. The bypass stops only the
   build's automation, so the old automation going off first is what keeps a bulk change of records from
   emailing users ([`release-runbook.md`](release-runbook.md) SO-3).
4. **Rolling back** one row means reactivating its previous flow version, which Salesforce keeps. Plan it
   only if the release is not fix-forward: old automation running beside the new one is usually worse than
   either alone.

---

## 6 · Open

| Item | Owner | Blocks |
|---|---|---|
| Agreement of the *Switch off* and *Keep* rows | Delivery team, then the client's business owner and administrator | The first story that replaces a row |
| The deactivation mechanism in §5 step 1 | First validate in a build org | Every *Switch off* row |
