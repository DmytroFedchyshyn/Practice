---
title:    "Agentforce Distributor — Automation Switches"
subtitle: "What Each Switch Turns Off, for Administrators"
date:     "<Client> × <Delivery team> · <Weekday, Month D, YYYY>"
---

<!--
For the delivery team, not the client — remove this comment before the document is built.

This page is written for the client's administrators and follows document-standard.md: the markdown is the
source and the .docx is built from it; US business English, no repository paths, no tracker keys, the client's
own terms. Fill the frontmatter's date line as document-standard.md §3 says. One section per feature in the
`features` list of project.config.json that has switches, in the same order; one row per record of
DST_Automation_Switch__mdt. A switch added in a merge request gets its row in the same merge
request. The design behind the switches is development-foundation.md §3 F-10; the bypass is F-2.
-->

# How the switches work

Administrators can turn off the automation built for Agentforce Distributor from Setup, without a code change and
without a release. Each switch is a record with an *Active* checkbox.

- **Two levels.** A feature switch turns off every automation listed under it. An automation switch turns off
  that one automation and leaves the rest of its feature running.
- **For every user.** A switch is on or off for everyone. To pause all of the automation for one user, for
  example during a data load, assign the permission set *DST_Bypass Automation* to that user
  instead.
- **Active as delivered.** Every switch is delivered checked.
- **From the next save.** A change applies to the next record saved. Records saved while a switch is off are not
  processed again when it is turned back on.
- **Kept through releases.** A release resets each switch it carries to its delivered setting. Before each
  release, the delivery team checks which switches are off in the org and keeps them off. Please let the
  delivery team know when you turn a switch off.
- **Always recorded.** The error log has no switch, so failures are still recorded while automation is off.

# How to turn a switch off

1. In Setup, open **Custom Metadata Types**.
2. Next to **DST_Automation Switch**, click **Manage Records**.
3. Click **Edit** next to the switch.
4. Uncheck **Active**, then click **Save**.

To turn the switch back on, check **Active** again. Changing a switch requires the *Customize Application*
permission. Each record also carries its own description and the feature it belongs to.

# The switches

Each switch is listed by its label in Setup, with its name beside it. One section per feature; the first row of
each section is the feature switch, and each row after it one automation of that feature. The row below is a
fictional example of the wording — replace it.

## <Feature label> — <what the feature covers, in the client's words>

| Switch | What it does | While it is off |
|---|---|---|
| **<Feature label>** · `<Feature_Name>` | Every automation listed in this section | <Records> save with none of the automation below |
| **<Feature label> · Order trigger** · `<Apex class name>` | *Example:* On every save of an order: checks each status change, records when the order was submitted, and notifies the account owner by bell notification and email | *Example:* Any status can be set, the submission date stays empty, and nobody is notified. Orders saved meanwhile are not notified when the switch is back on |

Write *What it does* as what a user or an administrator sees, from the trigger point — *On every save of …*,
*Every hour: …*, *When … closes: …* — and *While it is off* as what happens instead, including what is not caught
up once the switch is turned back on. Where turning off one switch leaves another automation unable to finish
its work, say so under the table and name the switch to use instead.

# Still running, and switches still to come

A feature switch covers the automation listed under it today. Until their own switches are added, these keep
running when their feature is off:

- **<Feature label>:** <the automation that has no switch yet, in business words>.

Flows are activated and deactivated in Setup, as today.

# Items to confirm

| # | Required Input / Decision | Why It Matters | Owner | Needed By |
|---|---|---|---|---|
| 1 | **Changing a switch in production** — confirm who may change a switch in production, and whether a change needs a change record. | Defines who can stop part of the automation, and how the team is informed when they do. | <Client role> | To be confirmed |
