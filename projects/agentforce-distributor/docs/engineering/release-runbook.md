# Release runbook — manual deployment steps

**Internal · Agentforce Distributor delivery team**
**Status:** living sheet. Empty as delivered by the kit: the example rows below show the format and the steps
most Salesforce builds meet; keep those that apply, mark the others *—*, and add the project's own.
**Used with:** `tools/deploy-build.sh`, which validates the build in `force-app/distributor`, or one feature of it (§4),
and with `--deploy` quick-deploys that validation, and `tools/deploy-changes.sh`, which deploys a branch's
changes to the developer's own build org; both point here for the steps after a deploy. The tooling itself is
described in [`development-foundation.md`](development-foundation.md) §1.4 and §3 (F-7).

Everything a deployment needs that metadata cannot carry. One row per step, added the day the step
appears; a tick per org once it has been run there, with the date. A step that is not yet verified
in an org says so in its row rather than being ticked.

Org aliases follow `docs/environments.md` (project-owned); instance URLs and credentials are not written here.

## How to use this sheet

**Before a deployment** read §1 and §1.1 for the target org: every row whose *When* names a component the
release carries, and every row marked *Before every deployment*. **After it** run §2 the same way. A release by
feature runs both per feature (§4).

**Step IDs** never change and are never reused, so a merge request, a story or another document can cite one:

| Prefix | Section | Holds |
|---|---|---|
| `P-n` | §1 | A step before deployment |
| `SO-n` | §1.1 | A check that the org's existing automation the build replaces is off |
| `S-n` | §2 | A step after deployment |
| `R-n` | §1 or §2 | A release or operational step that belongs to no single deployment: a data load, a test of email, a value the client provides later, a daily check during hypercare |
| `X-n` | named in a row | A milestone the steps hang on — the first release into an org with none of the build, the go-live cutover — kept in the project's plan and cited here by ID |

**Columns:** `# | When | Step | Why | <one column per org>`. *When* names the trigger precisely — *Once per
machine and org*, *Before the first deployment of …*, *Before every deployment that includes …*, *After every
sandbox refresh*. *Step* says where to click or what to run, with the exact command. *Why* says what goes wrong
without it, so a reader can judge a case the row did not foresee.

**Org columns** are the orgs on the release path, in promotion order. The kit's headers are generic — rename
them to the aliases in `docs/environments.md` (project-owned) and add a column per org. An org that is not on the
release path, such as a demo sandbox, gets no column; a note under the table says which steps were run there.

**Ticks:**

| Mark | Means |
|---|---|
| ☑ *date* | Done in that org on that date; add who, and what was found, when it matters |
| ☐ | Not done yet |
| ◐ *date* | Partly done; the cell says what is left |
| — | Does not apply to that org; the cell says why when it is not obvious |

**Rows are never removed.** A step that stops being needed stays, its *Step* opening with **No longer needed**
since *date*: *the reason*. Kept for the record. A step not yet verified in an org says so in that org's cell
(*☐ dry run passed, not yet opened as a user*) rather than being ticked.

## 1 · Before deployment

| # | When | Step | Why | Build orgs | UAT | Production |
|---|---|---|---|---|---|---|
| P-1 | Once per machine and org | Authorize the Salesforce CLI for the org: `sf org login web --instance-url <org URL> --alias <alias>`, then check with `sf org display --target-org <alias>` | Every script targets the org by alias | ☐ | ☐ | ☐ |
| P-2 | Before the first deployment of an Experience site — only when a site is in scope | Setup → **Digital Experiences → Settings** → tick **Enable ExperienceBundle Metadata API** → Save | Without it the org neither returns nor accepts the site's pages (`ExperienceBundle`); a retrieve ends with *"ExperienceBundle isn't enabled"* | ☐ | ☐ | ☐ |
| P-3 | Before every deployment that includes a dashboard run as the viewer, until the org has a free slot for it | Count the dashboards that run as the viewer, of both kinds — as the logged-in user (`LoggedInUser`) and as the logged-in user's team (`MyTeamUser`): `sf data query --query "SELECT Title, Type FROM Dashboard WHERE Type != 'SpecifiedUser'" --target-org <alias>`. If the org is at its limit, either free a slot — another of these dashboards is set to run as a specified user, with its owner's agreement — or leave the dashboard out with `tools/deploy-build.sh <alias> --exclude <path>` and keep it in the org set to run as a specified user, under the same API name and folder, since a page that embeds a dashboard finds it by that name | Salesforce caps how many dashboards of the two kinds an org holds, by edition, and a deployment that adds one more fails as a whole, before any test runs (*"You reached the limit for dashboards run as the logged-in user"*). Both kinds count. A dashboard set to a specified user cannot be set back while the org is at the limit | ☐ | ☐ | ☐ |
| P-4 | Before the first deployment of third-party source code — the vendor folder of [`architecture.md`](architecture.md) §5 — to an org | Check that the org has no class of its own with a library's name: `sf data query --query "SELECT Name FROM ApexClass WHERE NamespacePrefix = null AND Name IN (<the library's class names>)" --target-org <alias>` returns no row. If it returns one, stop and raise it before deploying | A deployment replaces a class of the same name without warning. Names checked against one org's snapshot say nothing about another org | ☐ | ☐ | ☐ |
| P-5 | Before every deployment that includes a layout, a Lightning record page or a list view the org's own administrators also maintain, to an org other than the one the copy was taken from | Retrieve the component from the target org into a folder outside the repository — `sf project retrieve start --metadata "<Type>:<Name>" --target-org <alias> --output-dir <folder>` — and compare it with the copy in `force-app/distributor`. Carry over any change made there before deploying, through the merge request. For a record page, also check its assignment: Object Manager → the object → **Lightning Record Pages** — the page is the default, and no app, record type or profile is assigned another | A deployment replaces the org's layout, page or list view as a whole, so a change an administrator made there since the copy was taken is lost without anyone seeing it. A page assigned elsewhere hides what the build added to this one | ☐ | ☐ | ☐ |
| P-6 | Before every deployment that carries Apex classes but not the whole build — a feature, a branch's changes, a quick deploy of a partial validation | **Warning.** Check Setup → **Apex Settings** → **Perform Synchronous Compile on Deploy** (`ApexSettings.enableCompileOnDeploy`). If it is off, turn it on (an org setting, so ask first), or deploy the whole build, or run S-2 straight after the deployment | With the setting off, every class that uses a deployed class but is not in the deployment is left uncompiled (`IsValid` false). An administrator never notices, because such a class compiles on its first internal use, but a user without *Author Apex*, such as an external user, is answered *You do not have access to the Apex class*. Salesforce documents production as always compiling on deploy; check it there once | ☐ | ☐ | ☐ |
| P-7 | Before every deployment that carries a class an Apex job is scheduled for, in an org where the job is scheduled (S-3) | Setup → **Deployment Settings**: when *Allow deployments of components when corresponding Apex jobs are pending or in progress* is ticked, nothing to do. Otherwise Setup → **Scheduled Jobs** → delete the job, deploy, and schedule it again (S-3) | Salesforce refuses a deployment that carries a class an Apex job is scheduled for, unless that setting is on. A scheduler that creates its service by name (`Type.forName`) keeps the service and the classes it uses deployable whether the job is scheduled or not | ☐ | ☐ | ☐ |
| P-8 | Before every deployment that carries a record of `DST_Automation_Switch__mdt` to an org where an administrator may have turned a switch off — production, and any sandbox the client administers | List the switches that are off there: `sf data query --target-org <alias> --query "SELECT DeveloperName FROM DST_Automation_Switch__mdt WHERE Active__c = false"`. For each, ask the administrator whether it stays off. If it does, uncheck `Active__c` in its record in the repository, through a merge request, before the release. A release of the whole build may instead leave the record out with `--exclude <path to the record>` | A deployment sets every switch record it carries back to the repository's value, so a switch the administrator turned off would run again without anyone seeing it ([`automation-switches.md`](automation-switches.md); [`development-foundation.md`](development-foundation.md) §3 F-10) | ☐ | ☐ | ☐ |
| R-1 | Before every data load | Assign **`DST_Bypass_Automation`** to the user who loads; remove it afterwards | A load routes nothing and sends nothing of the build's ([`development-foundation.md`](development-foundation.md) §3 F-2). The bypass stops only the build's own automation: the org's existing automation still runs until it is off (§1.1) | ☐ | ☐ | ☐ |

### 1.1 Switching off the org's existing automation — what not to forget

Read before every deployment, with the steps above. Where the build replaces automation the org already runs,
[`automation-collision-map.md`](automation-collision-map.md) decides what happens to each piece; this list is
what to check in each org so the old and the new never run together. A row is ticked per org with the date, or
marked *—* where it does not apply to that org. When this list and a copy kept elsewhere (a tracker comment, a
cutover plan) differ, this one is corrected first.

| # | Check | Why | Build orgs | UAT | Production |
|---|---|---|---|---|---|
| SO-1 | Every row of the collision map marked *Switch off at <release>* whose replacement this deployment carries is off in the target org — in the same release as its replacement, never in a clean-up later | Two writers of the same field on one save, or two messages for one event, from the first deployment on ([`automation-collision-map.md`](automation-collision-map.md) §0) | ☐ | ☐ | ☐ at go-live |
| SO-2 | Where the collision map names an order between two old automations — one refuses a save the other's removal makes possible, say — they go off in that order, or together, never the other way round | With the wrong one still on, every save it guards is refused, and users can no longer complete the process | ☐ | ☐ | ☐ |
| SO-3 | Before any bulk change of records the old automation reacts to — a data load, a status clean-up at the cutover, a rehearsal of it in a full sandbox: the old automation marked *Switch off* is off | The load runs under `DST_Bypass_Automation` (R-1), which stops only the build's automation; an old flow still on sends its emails for every record loaded | ☐ | ☐ | ☐ |
| SO-4 | The data an old automation reads — the records of a routing Custom Metadata type, say — stay until hypercare ends, then are removed | A rollback of the old automation needs them | ☐ | ☐ | ☐ after hypercare |
| SO-5 | The people who test in an org know when an old automation goes off there | Its emails and updates stop; until the replacement reaches that org, nobody receives them | ☐ | — | — |

## 2 · After deployment

| # | When | Step | Why | Build orgs | UAT | Production |
|---|---|---|---|---|---|---|
| S-1 | After every deployment that includes an Experience site — only when a site is in scope | Experience Builder → **Publish** | A deployment changes the draft; the site's users see nothing until it is published | ☐ | ☐ | ☐ |
| S-2 | After every deployment that does not carry every Apex class using a class it changes — a partial deployment — in an org that does not compile on deploy (P-6) | Setup → **Apex Classes** → **Compile all classes**; or, before deploying, add to the deployment every class that refers to a changed one. Then open a page that calls the changed classes as a user without *Author Apex* | A class that uses a changed one is left uncompiled until it next runs, and the first such user to call it is refused. Not needed in an org that compiles on deploy | ☐ | ☐ | ☐ |
| S-3 | After the first deployment of a schedulable class, in each org that runs the job | Signed in as an administrator who holds neither `DST_Bypass_Automation` nor any other bypass, run in Anonymous Apex: `System.schedule(<Class>.JOB_NAME, <Class>.CRON, new <Class>());` Check Setup → **Scheduled Jobs**: the job is there with its next run. In production, schedule it as one of the client's administrators, not a delivery-team account — name who in the row | A job runs as the user who scheduled it: under a bypass it does nothing, its emails go out as that user, and it should not hang on an account that goes at handover. A later deployment of its class may need the job deleted first (P-7) | ☐ | ☐ | ☐ |
| S-4 | After the first deployment of `DST_Settings__c`, and after every sandbox is created or refreshed | Setup → **Custom Settings** → the setting → **Manage** → the org default (create it if there is none) → set each value that differs per org — addresses, the org's own domain — to this org's | The org default of a custom setting is data, not metadata: no deployment sets it, and a refreshed sandbox carries production's values, so links built from them point at production | ☐ | ☐ | ☐ |
| S-5 | After the first deployment of a permission set group, and whenever someone joins the role it serves | Assign the group to the users the row names, by role, never by a person's name alone: Setup → **Users** → the user → **Permission Set Group Assignments** | A deployment creates the group but assigns it to nobody, and a user without it sees none of what the group grants | ☐ | ☐ | ☐ |
| R-2 | While notifications are tested in a sandbox | Setup → **Deliverability**: *All email*; back to *System email only* afterwards. Before turning it on, check which real addresses the org's users, queues and email alerts hold | A sandbox sends no email by default. With *All email* on, every user, queue member and alert recipient whose address the refresh did not mask receives the build's messages, the client's own included | ☐ | ☐ | — |

## 3 · Deploying an Experience site

Only for a project whose build includes an Experience Cloud site; otherwise mark this section *—*. The site's
source is its bundle under `force-app/distributor/experiences/` and its menu under `force-app/distributor/navigationMenus/`.
Take the source from a site in a build org, and remove any component that exists only in that org, so the
target needs nothing outside the build.

```bash
# validate only — nothing is written
sf project deploy start --source-dir force-app/distributor/experiences --source-dir force-app/distributor/navigationMenus --target-org <alias> --dry-run --test-level NoTestRun
# deploy — only after the dry run and a yes
sf project deploy start --source-dir force-app/distributor/experiences --source-dir force-app/distributor/navigationMenus --target-org <alias> --test-level NoTestRun
```

Then §2 S-1, and the site rows the project adds — typically, after the first site deployment:

- the site's members are the profiles and permission sets the access model names, and self-registration,
  member visibility and guest access are as the design says;
- the guest profile has no object permission, when the site's users always sign in. The guest profile is not
  in the build, so a deployment neither sets nor checks it.

A menu is matched to its site by name: the file is named `SFDC_Default_Navigation_<site API name>` and its
`container` is the site name. A site renamed in Experience Builder also renames its menu, site and bundle API
names, so the files are renamed with it, or a deployment fails with *"no Network named … found"*.

## 4 · Deploying one feature at a time

**Default — adjust per project.** The build deploys by feature, as `project.config.json` lists them; a project
that always releases the whole build keeps only the whole-build command and drops this section.

The whole build is the default release, and the only one into an org that holds none of it: a feature's tests
may rely on components of a feature listed after it. Into an org that already holds the build, a release that
leaves out a feature that is not ready deploys the features one by one, each validated before it is deployed,
in the order of the `features` list in `project.config.json` — every feature after the features its
`dependsOn` names ([`development-foundation.md`](development-foundation.md) §1.4 *Deploying by feature*):

| # | Feature | Validate — nothing is written | Can be left out |
|---|---|---|---|
| 1 | *e.g.* `foundation` | `tools/deploy-build.sh <alias> --feature foundation` | No: every feature depends on it |
| 2 | *a feature whose `dependsOn` is `foundation`* | `tools/deploy-build.sh <alias> --feature <slug>` | Only when no feature that deploys after it names it in `dependsOn` |

For each feature:

1. §1 for that org: every row whose *When* names a component of the feature, and P-6 — a feature is a
   partial deployment.
2. Validate, read the result, then run the same command with `--deploy`; it validates again and asks before
   it writes.
3. §2 for the feature's components, then S-2. If the feature carries a site, S-1.

A feature left out goes later with the same command, followed by §2 for its components.

`tools/deploy-build.sh` checks the feature manifests first (`tools/feature-manifests.py --check`), so a
component added without its row in `features`, or claimed by two features, stops the release before anything
is sent. `--exclude` works on the whole build only, so an org that cannot take a component of a feature (P-3, P-8)
receives that feature with a release of the whole build.

Record each dry run of a feature against an org under this section — the org, what it held, passed or failed,
and on what — so the next release knows which orders have been proven.
