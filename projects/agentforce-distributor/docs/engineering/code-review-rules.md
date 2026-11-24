# Code review rules — what a merge request is checked against

**Internal · Agentforce Distributor delivery team**
**Status:** this page changes only through a merge request, and a rule moves only through the steps of §2.
A rule is *Proposed* unless its row says otherwise.
**Sources:** [`development-foundation.md`](development-foundation.md) §0, §1.1, §1.4, §1.5, §2, §3 —
in the tables below a bare `§` means that page; [`architecture.md`](architecture.md), which explains
the layers and the libraries those rules refer to; [`agentforce.md`](agentforce.md), for the AGT rules; `CLAUDE.md`; `code-analyzer.yml`, the CI file for your
platform ([`ci-cd.md`](ci-cd.md)), `tools/ci/`. Salesforce Code Analyzer v5 documentation on [regex rules](https://developer.salesforce.com/docs/platform/salesforce-code-analyzer/guide/engine-regex.html),
[PMD custom rulesets](https://developer.salesforce.com/docs/platform/salesforce-code-analyzer/guide/engine-pmd.html)
and [suppressing violations](https://developer.salesforce.com/docs/platform/salesforce-code-analyzer/guide/suppress-violations.html).
Rules taken from published rule sets and guidance name them by label; §11 lists them.

---

This page is the list a merge request is reviewed against — by its author before it opens, by
`/code-review`, by a reviewer and by the pipeline. Each rule has an ID, the convention it checks, what
catches it, how serious a violation is, and whether it is in force.

development-foundation.md §2 says how we write code and why; this page says what we check and how
strictly. A convention is written once, in that §2, and each rule here links to it. A review comment that
keeps coming back becomes a rule (§2 below), and a rule a tool can check moves into Code Analyzer one rule
at a time.

---

## 0 · How to use this page

| Who | When | What |
|---|---|---|
| Author | Before opening the merge request | `npm run scan`, `npm run format:check` and, when a component changed, `npm test` (development-foundation.md §1.5), then `/code-review` in Claude Code. Fix what is found, or say in the merge request why it stays |
| `/code-review`, any AI review | When asked | Checks the diff against every rule not *Retired*, the `ai` rows first. Names the rule ID in each finding. Does not repeat what Code Analyzer already reports |
| Reviewer | During review | Reads the diff for the `ai` and `human` rows; the automated rows are already in the pipeline |
| Pipeline | Every merge request, every push to the default branch | Runs the automated rows (development-foundation.md §1.4, §1.5; [`ci-cd.md`](ci-cd.md)) |

Code Analyzer's `Recommended` and `pmd:Security` rules are in force through development-foundation.md §1.5
whether or not they have a row here. A built-in rule gets a row only when it checks one of our
conventions, when we change its severity, or when we switch on a rule outside those two sets.

---

## 1 · Severity, status and what holds the merge

**Severity** — how serious a violation is. For an automated check it is the severity the check reports,
set in `code-analyzer.yml` when it differs from the rule's default.

| Severity | Automated check (development-foundation.md §1.5) | `ai` or `human` check |
|---|---|---|
| Critical | A thread on the merge request; the merge waits until it is resolved | Fixed before the merge |
| High | A thread on the merge request; the merge waits until it is resolved | Fixed before the merge, or a reply in the merge request saying why it stays |
| Moderate | Code Analyzer: the job stays green, as it turns orange only from High up; a finding the merge request adds shows in the merge request's code-quality report, and every finding in the job log. Prettier and Jest: the job turns orange | A comment; the author decides |
| Low | The job log | Raised only alongside other findings |
| Info | The job log | Not raised |

The thread, the orange job and the code-quality report are GitLab's; on GitHub a Critical or High finding
goes to code scanning, and on Azure Pipelines to the SARIF artifact. [`ci-cd.md`](ci-cd.md) says what holds
the merge on each platform.

**Status** — whether the rule is in force. In a project, each change of status carries its date and who
decided.

| Status | Meaning |
|---|---|
| Default | The kit ships the rule enforced: its automated check — a hook, a failing job, or a High finding — is in place from the first day. A project that changes it says so in the row |
| Proposed | Written down, not yet agreed by the team |
| Reporting | Agreed. Its check — automated, `ai` or `human` — looks for it and reports; the merge does not wait |
| Enforced | An automated check holds the merge: a Critical or High finding, a hook that stops the push, or a job that fails |
| Retired | No longer applied. The row stays and its ID is never reused |
| Open | The rule is wanted, but its check is still to be designed |

The kit ships three rules as *Default* — GEN-01 (the pre-push hook, the Claude hook and the job
`force-app-via-mr`), GEN-03 (gitleaks in the pre-commit hook and the job `secrets`) and SEC-03 (Code
Analyzer's `pmd:ApexCRUDViolation`) — and every other rule as *Proposed*. From there a project moves its
own rules through §2.

Only an automated check can make a rule *Enforced*. An `ai` or `human` rule stops at *Reporting*, because
the author may merge their own merge request (development-foundation.md §1.4).

On GitLab, a thread holds the merge only once the CI variable `REVIEW_BOT_TOKEN` exists and the two merge
request settings — *All threads must be resolved* and *Pipelines must succeed* — are on
([`ci-cd.md`](ci-cd.md)). Until then a Critical or High finding of Code Analyzer is reported, not held.

**Check** — what catches it. Several values mean several checks share the rule; a value in *italics* is
planned and not yet built.

| Check | Meaning |
|---|---|
| `pmd:<Rule>`, `eslint:<rule>`, `flow:<Rule>`, `retire-js`, `cpd` | A Code Analyzer rule or engine — built in, or ours when it is defined in `code-analyzer.yml` or `tools/rules/` |
| `regex:<Rule>` | A regex rule of ours in `code-analyzer.yml` |
| `gitleaks`, `prettier`, `hook`, `job:<name>` | The other checks of development-foundation.md §1.4 and §1.5 |
| `script` | A check across files that Code Analyzer cannot express, kept in `tools/ci/` |
| `ai` | `/code-review` or another AI review |
| `human` | Only a reviewer can judge it |

---

## 2 · How a rule is added, raised and retired

This is the process a project follows to move its own rules; a *Default* rule starts at the end of it.

1. **Candidate.** A review comment that comes back in a second merge request goes to §10, with links to
   both.
2. **Proposed.** It gets the next free ID in its area, a source, a check — planned if not yet built — and
   a severity. The source is the development-foundation.md §2 bullet when the rule checks one of our
   conventions — a new convention of ours is added to that §2 in the same merge request, so it is still
   written once — or the published rule or guidance it is taken from, listed in §11.
3. **Reporting.** The team agrees it. An automated check lands at Moderate in the same merge request that
   changes the row, so a new check never holds a merge on its first day.
4. **Enforced.** After a week of merge requests without a false positive, its severity is raised to High
   in `code-analyzer.yml`, and the row says when and who.
5. **Retired.** The row stays, with the date and the reason. Its ID is never reused.

**Where our checks live — Proposed.** Regex rules in `code-analyzer.yml` under `engines.regex.custom_rules`.
PMD XPath rules, for Apex and for metadata XML, in `tools/rules/*.xml`, listed under
`engines.pmd.custom_rulesets`. Checks across files in `tools/ci/`, reporting so that `review-threads`
([`ci-cd.md`](ci-cd.md)) can open threads for them. A name says what the rule checks, with no prefix:
`DmlOnlyThroughDmlClass`, `LabelShortDescriptionMax80`, and planned ones such as `NoFuture`, `NoProfile`.

**Exceptions.** A finding that stays is suppressed where Code Analyzer reads it: in the code, with a
`code-analyzer-suppress(<engine>:<rule>)` marker and a comment saying why, or in `code-analyzer.yml` under
`suppressions:` with a `reason`. A thread resolved by hand needs a reply saying why
(development-foundation.md §1.5). This page does not copy the suppressions; the code and
`code-analyzer.yml` are their register.

---

## 3 · GEN — Repository and merge request

| ID | Rule | Source | Check | Severity | Status |
|---|---|---|---|---|---|
| GEN-01 | Every change under `force-app/` reaches the default branch through a merge request | §1.4 *Default branch* | `hook` (pre-push, Claude `PreToolUse`), `job:force-app-via-mr` | Critical | Default |
| GEN-02 | Every component we create or change is under `force-app/distributor/`. Nothing under `force-app/main/default/` is edited: an existing component of the org is moved with `git mv` before it is changed | §1.1 | `human`; *`script`* | High | Proposed |
| GEN-03 | No secret in any commit, in any folder | §1.5 *Secrets* | `gitleaks` (pre-commit hook and pipeline job `secrets`) | Critical | Default |
| GEN-04 | Code in `force-app/distributor/` is formatted by Prettier | §1.5 *Formatting*; §2.3 *Formatting* | `prettier` (pre-commit hook and pipeline) | Moderate | Proposed |
| GEN-05 | One concern per merge request; it is split before review when it grows past a reviewable size | §1.4 *Merge request* | `human` | Moderate | Proposed |
| GEN-06 | The title reads `#123 · what changed`; the description has **What**, **Why**, **How to verify** and the issue link | §1.4 *Merge request* | `human`; *`script`* | Low | Proposed |
| GEN-07 | A manual step needed after the deploy is named in the description and added to [`release-runbook.md`](release-runbook.md) | §1.4 *Merge request*; §3 F-7 | `ai`, `human` | High | Proposed |
| GEN-08 | Documentation ships in the same merge request as the change it describes | §1.4 *Documentation* | `ai`, `human` | Moderate | Proposed |
| GEN-09 | An Apex class, trigger or component is committed together with its `-meta.xml` | `CLAUDE.md` | `human` | Moderate | Proposed |
| GEN-10 | No tool attribution in commits, merge request titles or descriptions | §1.4 *Commits* | `human` | Low | Proposed |
| GEN-11 | A new component uses the project's `sourceApiVersion` (68.0); the version is raised for all components at once | §2.3 *API version* | *`regex:ApiVersion`* | Moderate | Proposed |
| GEN-12 | The change compiles and deploys against the org it is meant for: no field, object, method or API version that does not exist there | radix2 | *`job:apex-validate`, shared with TST-01* | High | Proposed |
| GEN-13 | No `TODO` or `FIXME` is merged: work left to do is a task on the board | §2.3 *Comments*; Sonar | *`regex:NoTodo`* | Low | Proposed |
| GEN-14 | A new component is covered by a feature in `project.config.json`, and the regenerated manifests ship in the same merge request | §1.4 *Deploying by feature* | `ai`, `human`, *`script`* | Moderate | Proposed |
| GEN-15 | A comment says why the code is as it is, where the code cannot say it; none repeats what the code does | §2.3 *Comments* | `ai` | Moderate | Proposed |
| GEN-16 | No ID and no history in code or its comments: no tracker key or merge request, no story, requirement, decision, open item, review rule or document section, no record of what changed, who decided it or when. Where a change came from is in its branch, commit and merge request | §2.3 *Comments*; §1.4 | `ai`; *`regex:NoIssueKey`* (tracker keys and merge requests) | Moderate | Proposed |
| GEN-17 | An action — a quick action or button on a record page or layout, a button or link in a component — shows only to the users and on the records where it can succeed: a dynamic-action visibility rule or `lwc:if` on the same conditions the server refuses it on; the server still checks them. A condition no rule can read is a known limit in the design | §2.1 *An action shows only where it can succeed* | `ai`, `human` | Moderate | Proposed |

**Notes**

- **GEN-01.** **Default — adjust per project.** A project that also sends documentation through merge
  requests adds its paths to the protected paths in `project.config.json`; one that lets `force-app/` go
  straight to the default branch retires GEN-01 and removes the hook and the `force-app-via-mr` job.
- **GEN-02.** Until the `script` exists, the check is that
  `git diff --diff-filter=AM origin/master...HEAD -- force-app/main/default` is empty on the branch,
  unless the merge request is a deliberate refresh of the snapshot from the org. It is the obvious first
  `script`.
- **GEN-11, and our conventions in third-party code.** Code in `force-app/distributor/vendor/` keeps its authors'
  API version, sharing declarations, headers, comments, static fields, names and `TODO`s: GEN-11, GEN-13,
  GEN-15, GEN-16, SEC-01, APX-10, APX-12 and APX-40 do not apply inside it, and APX-39 does
  ([`architecture.md`](architecture.md) §5, with the versions). The planned `script` and `regex` checks skip
  the folder, as Code Analyzer does.
- **GEN-12.** Generated code names fields, methods and API versions that look right and do not exist in
  the org; only a compile catches them. The author compiles the change before opening the merge request,
  `tools/deploy-changes.sh --dry-run` in their own build org. While the build is in active development,
  tests run only when asked for (development-foundation.md §1.3): `--tests` adds those that cover the
  change, and `apex-validate` or `tools/deploy-build.sh` runs every one on the whole build (TST-01).
  **Default — adjust per project.** A project that runs Apex tests on every change makes `--tests` part of
  the author's check and runs `apex-validate` on every merge request.
- **GEN-14.** Deploying by feature is driven by the `features` list in `project.config.json`; each feature's
  `paths` are globs relative to `force-app/distributor`. A merge request that adds a component no glob covers adds
  it to a feature, and commits the manifests that `tools/feature-manifests.py` rewrites in
  `manifest/features/`; the reviewer checks the diff of both against the changed files. Until a `script` in
  `tools/ci/` runs in the pipeline, `tools/feature-manifests.py --check` is the author's check: it fails when
  a manifest is stale, or when a component matches no feature or two. `tools/deploy-build.sh --feature` runs
  it before a feature is validated. **Default — adjust per project.** A project that always deploys the whole
  build keeps no `features` list and retires GEN-14.
- **GEN-13, GEN-15, GEN-16.** A finding in a class the merge request does not change is not that merge
  request's: the class is brought to the rules when a story next changes it.
- **GEN-16.** A comment that needs a source writes out the reason instead: not *"(decision 6)"* but *"so a
  case is escalated only after its owner has replied"*. The planned regex finds tracker keys and merge
  requests (`#\d+`, `MR \d+`, `!\d+`); the other IDs have too many shapes to match without
  noise, so they are the `ai` check. Names of components in the org, and an engine rule named in a
  `code-analyzer-suppress` marker, are not IDs in this sense.
- **GEN-17.** Whether each visibility rule matches the server is read from the diff: the permission and
  status in the rule against the checks of the service the action calls. A finding in a component the
  merge request does not change is not that merge request's.

---

## 4 · SEC — Security and access

| ID | Rule | Source | Check | Severity | Status |
|---|---|---|---|---|---|
| SEC-01 | A class declares its sharing: `with sharing` by default, `inherited sharing` when it is called from both user and system contexts | §2.3 *Sharing* | `pmd:ApexSharingViolations` | High | Proposed |
| SEC-02 | `without sharing` only with a comment on the class saying why | §2.3 *Sharing* | `ai`; *`pmd:WithoutSharingReason`* | High | Proposed |
| SEC-03 | Every query and DML statement runs in user mode, or names system mode explicitly: `WITH SYSTEM_MODE`, `AccessLevel.SYSTEM_MODE` | §2.3 *Sharing*, *DML mode*; §1.5 | `pmd:ApexCRUDViolation` | High | Default |
| SEC-04 | A read or write in system mode carries a comment saying why | §2.3 *Sharing*, *DML mode* | `ai` | High | Proposed |
| SEC-05 | No hard-coded record Ids, or names of users, queues, groups, profiles or record types: they are found by developer name, or read from `DST_Parameter__mdt` | §2.3 *No hard-coded names or Ids*; §3 F-3 | `pmd:AvoidHardcodingId` (Ids); `ai` (names) | High | Proposed |
| SEC-06 | Profiles are never deployed; access comes from permission sets and permission set groups. A profile the build itself owns (for example, the one an external-user license requires) may be deployed when the project records it here. Profiles the build owns: none | §2.6 | *`regex:NoProfile`* | High | Proposed |
| SEC-07 | An `@AuraEnabled` method that receives a record Id from the browser reads or changes that record only after checking the caller may reach it — for an external user, that it belongs to the caller's account — by running in user mode, or with an explicit check | Experience Cloud guide; SR top 20 #1, #3 | `ai`, `human` | High | Proposed |
| SEC-08 | Dynamic SOQL uses bind variables (`Database.queryWithBinds`); user input never goes into the query string | SR top 20 #10 | `pmd:ApexSOQLInjection` | High | Proposed |
| SEC-09 | No user data through `innerHTML` or `lwc:dom="manual"`; no `addError` with escaping turned off | SR top 20 #8 | `pmd:ApexXSSFromEscapeFalse`, `pmd:ApexXSSFromURLParam`; *`regex:NoInnerHtml`* | High | Proposed |
| SEC-10 | No personal data or secrets in `System.debug` or `DstLogger` entries; the user never sees a stack trace | SR top 20 #6, #13 | `ai` | High | Proposed |
| SEC-11 | A flow that runs in system context without sharing does not let user input choose or change records | Flow Scanner | `flow:PreventPassingUserDataIntoElementWithoutSharing` | High | Proposed |
| SEC-12 | Third-party JavaScript is loaded from a static resource and has no known vulnerability | SR top 20 #2, #9 | `retire-js` | High | Proposed |

**Notes**

- **SEC-01.** `pmd:ApexSharingViolations` already runs, through the `pmd:Security` selector
  (development-foundation.md §1.5). The severity it reports is *to be verified* before the row moves on.
- **SEC-02, SEC-04.** The comment says why the user's own access is not the right one. For example:

  ```apex
  // System mode: business hours are setup data, read the same way whoever runs the code.
  [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE AND IsActive = TRUE WITH SYSTEM_MODE LIMIT 1]
  ```
- **SEC-03.** The kit ships this check enforced: `pmd:ApexCRUDViolation` reports High, and a High finding
  holds the merge (§1; development-foundation.md §1.5).
- **SEC-07.** External users must never reach each other's records. An external user who calls the method
  with another account's record Id must get nothing back; a method in system mode skips the sharing that
  would otherwise stop them.
- **SEC-08, SEC-09, SEC-11, SEC-12.** These checks already run, through `pmd:Security` or `Recommended`
  (*to be verified* for RetireJS). The rows tie them to a severity we chose.

---

## 5 · APX — Apex and triggers

| ID | Rule | Source | Check | Severity | Status |
|---|---|---|---|---|---|
| APX-01 | One trigger per object, handling every event | §2.3 *Triggers* | *`script`* (our triggers and the org snapshot) | High | Proposed |
| APX-02 | A trigger's body is one line: `new <Object>TriggerHandler().run();` | §2.3 *Triggers*; §3 F-1 | `pmd:AvoidLogicInTrigger`; *`pmd:TriggerOneLine`* | High | Proposed |
| APX-03 | No SOQL or DML inside a loop | §2.3 *Bulk* | `pmd:OperationWithLimitsInLoop` | High | Proposed |
| APX-04 | Methods take and return collections | §2.3 *Bulk* | `ai` | High | Proposed |
| APX-05 | Thresholds, windows and addresses come from `DST_Parameter__mdt`, not from literals | §2.3 *No hard-coded names or Ids*; §3 F-3 | `ai` | Moderate | Proposed |
| APX-06 | No empty `catch`; an error that is handled is logged through `DstLogger` | §2.3 *Errors*; §3 F-4 | `pmd:EmptyCatchBlock`; *`pmd:CatchLogs`* | High | Proposed |
| APX-07 | An error the user must fix is raised with `addError` and a custom label | §2.3 *Errors* | `ai` | Moderate | Proposed |
| APX-08 | Queueable rather than `@future`; Batch above a few thousand records | §2.3 *Asynchronous work* | *`regex:NoFuture`*; `ai` (Batch) | Moderate | Proposed |
| APX-09 | Every asynchronous entry point respects the bypass (`DstBypass`, `DST_Settings__c`) | §2.3 *Asynchronous work*; §3 F-2 | `ai` | High | Proposed |
| APX-10 | Every class and trigger opens with a short header comment, one to three lines: what it does and why it exists | §2.3 *Comments* | *`regex:ClassHeader`*; `ai` (length) | Moderate | Proposed |
| APX-11 | No commented-out code | §2.3 *Comments* | `ai` | Low | Proposed |
| APX-12 | Names follow §2.2: `Dst` + name for shared classes; object + role for an object's logic, `Dst` + page + role behind one page; roles `TriggerHandler`, `Service`, `Selector`, `Controller`, `Batch`, `Job`, `Schedule`, `Action`, `Form`, `View`; a domain class has no role suffix and is named for what it decides (`InvoicePolicy`, `InvoiceNumbers`, APX-43); object + `Trigger` for triggers; class + `Test` for tests, and for a feature's tests `Dst` + feature + `FeatureTest`, `BulkTest`, `Cast` or `Steps` | §2.2; §2.4 *Levels* | *`script`* | Moderate | Proposed |
| APX-13 | Every new Apex component is named in the feature's design before it is built | §0; `docs/technical-design.md` (project-owned) | `ai`, `human` | High | Proposed |
| APX-14 | New automation on an object that already has automation is named in the collision map ([`automation-collision-map.md`](automation-collision-map.md)), and does not write the fields that automation writes | §3 F-8; Apex Hours | `ai`, `human` | High | Proposed |
| APX-15 | A recursion guard tracks the record Ids already processed, not a static Boolean | Practitioner (dev.to) | `ai` | High | Proposed |
| APX-16 | `User`, `GroupMember` and `PermissionSetAssignment` are not changed in the same transaction as Account, Contact or other records; the second part runs in a Queueable | SF: mixed DML | `ai` | High | Proposed |
| APX-17 | A query expected to return one record is assigned to a `List`, which is checked before use | Sonar | *`pmd:SingleRowQueryToList`* | High | Proposed |
| APX-18 | After a partial-success DML (`Database.insert(records, false)` and the like) every result is checked and every failure logged | Team inference | `ai` | High | Proposed |
| APX-19 | A `catch` catches a specific exception, and DML inside it does not hide the original error | Sonar | `ai`; *`pmd:NoDmlInCatch`* | Moderate | Proposed |
| APX-20 | Record types are found with `getRecordTypeInfosByDeveloperName`; picklist values are compared by API name, in Apex and in flow decisions | Sonar; Clientell | *`regex:RecordTypeByDeveloperName`*; `ai` | Moderate | Proposed |
| APX-21 | No absolute Salesforce URL (`*.my.salesforce.com`, `*.force.com`, `*.site.com`) in Apex or in components | Sonar | *`regex:NoAbsoluteSalesforceUrl`* | Moderate | Proposed |
| APX-22 | A batch over child records is ordered by the parent Id; a mass update of one record's children runs asynchronously | Xappex | `ai` | Moderate | Proposed |
| APX-23 | No `@future` call and no email send inside a loop; a `@future` method that makes a callout declares `callout=true` | Sonar | *`pmd:NoAsyncOrEmailInLoop`* | High | Proposed |
| APX-24 | A Queueable attaches a Finalizer; a stateful Batch keeps no `Database.*Result` in its fields; a Batch scope is at most 2,000 | PMD; Sonar | `pmd:QueueableWithoutFinalizer`, `pmd:AvoidStatefulDatabaseResult` | Moderate | Proposed |
| APX-25 | One `@InvocableMethod` per class, with a label and a description; an invocable variables class has a no-argument constructor | Sonar; PMD | `pmd:InvocableClassNoArgConstructor`; *`regex:InvocableLabel`* | Moderate | Proposed |
| APX-26 | Every SOQL query has a `WHERE` or a `LIMIT` | PMD; Sonar | `pmd:AvoidNonRestrictiveQueries` | Moderate | Proposed |
| APX-27 | A query selects only the fields the code uses | ApexGuru | `ai` | Low | Proposed |
| APX-28 | No describe call inside a loop; `SObjectType` tokens rather than eager describes | ApexGuru; PMD | `pmd:EagerlyLoadedDescribeSObjectResult`, `pmd:OperationWithHighCostInLoop` | Moderate | Proposed |
| APX-29 | No `System.debug` in deployed code | PMD | `pmd:AvoidDebugStatements` | Low | Proposed |
| APX-30 | Two collections are joined through a `Map` keyed by Id, not a nested loop | Team inference | `ai` | Moderate | Proposed |
| APX-31 | A count uses `SELECT COUNT()`, not `.size()` on a query result | Sonar | `ai` | Low | Proposed |
| APX-32 | No unused methods, unused variables or duplicated blocks | PMD | `pmd:UnusedMethod`, `pmd:UnusedLocalVariable`, `cpd` | Low | Proposed |
| APX-33 | Methods stay readable: cognitive complexity, length and parameter count under the thresholds set in `code-analyzer.yml` | PMD; Sonar | `pmd:CognitiveComplexity`, `pmd:NcssCount`, `pmd:ExcessiveParameterList` | Low | Proposed |
| APX-34 | An entry point — `Controller`, `TriggerHandler`, `Action`, `Job`, `Batch`, `Schedule` — runs no SOQL and no DML: it reads through a selector and changes records through a service | §2.7 | `ai`; *`pmd:NoQueryInEntryPoint`* | Moderate | Proposed |
| APX-35 | `@AuraEnabled` methods are only in `Controller` classes; the data classes a page receives live in its `Form` or `View`, not inside the controller | §2.7 | `ai`; *`pmd:AuraEnabledInController`* | Moderate | Proposed |
| APX-36 | Calls go down the layers: no class uses a controller or its inner classes, except the controller's own test and a feature's `Dst<Feature>Steps`, which runs the entry points for its feature class; a service never calls an entry point; a domain class calls only other domain classes | §2.7 | `ai`; *`script`* | Moderate | Proposed |
| APX-37 | A `Selector` holds the queries on its object and runs no DML; a `Form`, `View` or domain class runs no SOQL and no DML | §2.7 | `ai`; *`pmd:LayerDataAccess`* | Moderate | Proposed |
| APX-38 | A selector or service a test may replace has instance methods and is held in a `@TestVisible private static` field of the class that uses it; no service locator or registry of types | §2.7; §2.4 *Mocks* | `ai` | Low | Proposed |
| APX-39 | Third-party Apex comes as a library in `force-app/distributor/vendor/`, listed in [`architecture.md`](architecture.md) §3 and unchanged from its release; none is copied into `classes/` or edited in place | §1.2; §2.7 | `ai`; *`script`* | Moderate | Proposed |
| APX-40 | Outside a test class, a static field is a constant (`static final`); a dependency a test replaces — a selector, a service, or a value the test cannot arrange in the org (APX-38); or state the whole transaction shares — a value read once, a re-entry guard, the bypass. A value a test sets and the state of the transaction carry a comment saying why; a selector or a service needs none. None exists only for a test to read | §2.3 *Static fields* | `ai`; *`pmd:StaticFieldShape`* | Moderate | Proposed |
| APX-41 | Records are written only through `DstDml`, and every call names its `DstDmlMode`: no `insert`, `update`, `upsert`, `delete` or `Database` write outside `DstDatabaseDml` and the test classes | §2.3 *DML mode*; §3 F-9 | `regex:DmlOnlyThroughDmlClass`; `ai` (the mode, and the comment a system mode carries) | Moderate | Proposed |
| APX-42 | Every automation we build can be turned off in Setup: a trigger handler through `DstTriggerHandler`; any other entry point that runs on its own — a step an existing trigger of the org calls, a Queueable, a schedule's service, an `@InvocableMethod` — through `DstSwitches.isOn` with its own name, doing nothing while it is off. Its `DST_Automation_Switch__mdt` record — active, with its feature and a description for the administrator — and its row in [`automation-switches.md`](automation-switches.md) come in the same merge request | §2.3 *Switches*; §3 F-10 | `ai` | High | Proposed |
| APX-43 | A rule that needs no database — a policy, a calculation, the normalising of what a user typed — lives in a domain class: static methods on what the caller passes, parameter values included; no SOQL, no DML, no read of `DstParameters`; tested without records or users | §2.7 | `ai` | Low | Proposed |

**Notes**

- **APX-02.** `DstLogEventTrigger` is the known exception: it stores log events outside
  `DstTriggerHandler` and the bypass on purpose, and its header says why. An exception of this
  kind is suppressed with a reason (§2), not left to fail the check.
- **APX-10.** The header carries no key and no history (GEN-16): no class names its story or its foundation
  F-number. The planned regex checks that a header is there; whether it stays short and says why is the
  `ai` check.
- **APX-13.** Design first. Generated code tends to add helpers nobody designed, so each new class in the
  diff is looked up in `docs/technical-design.md` (project-owned) or the feature's spec. A class the design
  does not name is raised before it is built, and the design is updated in the same merge request.
- **APX-14, APX-15.** An object that already carries the org's own triggers, managed-package triggers and
  record-triggered flows — some of them without a recursion guard — is where new automation collides with
  old; the collision map lists what is there before anything is added.
- **APX-16.** External users are created together with their Contact and Account, and queue or group
  membership changes with them.
- **APX-24, APX-26, APX-28, APX-29, APX-32, APX-33.** Built-in PMD rules. Whether each is already in
  `Recommended` is *to be verified* with `sf code-analyzer rules --rule-selector Recommended`; the
  thresholds of APX-33 are set when it is switched on.
- **APX-33 — what the defaults report in Code Analyzer v5.** A method at cyclomatic complexity 10 or more, or
  cognitive 15 or more; a class whose methods add up to cyclomatic 40 or cognitive 50, inner classes
  included; a method over 40 NCSS lines; four parameters or more; a Boolean parameter on a public method
  only. PMD counts a call to a method of the same name — an overload, or a method of another class — as
  recursion, which can add more cognitive complexity than the code itself: name helpers apart
  (`missingLabels`, not `missing`, in a class that `missing` calls).
- **APX-34 to APX-38.** A finding in a class the merge request does not change is not that merge request's:
  the class is brought to the layers when a story next changes it (development-foundation.md §2.7). The
  planned PMD checks land at Moderate (§2), so they report existing code without holding a merge.
- **APX-38.** The Stub API that apex-mockery builds on replaces instance methods only, not static ones —
  *to be verified* against the Apex Developer Guide (SF: Stub API) before the row moves on.
- **APX-40.** The planned PMD rule reports a static field that is not `final` and is not initialized with
  `new <Class>()`, so a person or `/code-review` judges the rest. A static field that does not follow the
  rule is brought to it when a story next changes its class.
- **APX-41.** The regex skips a file once `@IsTest` appears before the match, so the test classes and
  `DstTestDataFactory` write their own records; `DstDatabaseDml` is suppressed in
  `code-analyzer.yml`. `EventBus.publish` in `DstLogger` and `Approval.lock` are not writes in
  this sense. Code Analyzer's own rules on DML (SEC-03) do not see through the interface, so the mode is a
  parameter with no default, and whether it and its comment are right is the `ai` check.
- **APX-42.** `DstSwitchesTest` fails when a class that extends `DstTriggerHandler`
  has no switch record, or one without a feature. An entry point that has no switch yet gets one when its
  feature is next changed; a finding on it in a merge request that does not change it is not that merge
  request's. High, because an administrator must be able to turn off any automation the team builds without
  a code change.

---

## 6 · TST — Tests

| ID | Rule | Source | Check | Severity | Status |
|---|---|---|---|---|---|
| TST-01 | Every new class is covered at 85 % or more, and the org as a whole at 75 % or more (the platform's minimum is 75 %) | §2.4 *Coverage* | *`job:apex-validate` — validation with every test class of the build* | High | Proposed |
| TST-02 | Every acceptance criterion of the story has a test whose name says it | §2.4 *Coverage* | `ai` | High | Proposed |
| TST-03 | A record a test inserts comes only from `DstTestDataFactory`; a record it needs only in memory is built with SObject Fabricator (`sfab_FabricatedSObject`) | §2.4 *Data*; §3 F-6 | `ai`; *`pmd:TestDataFromFactory`* | Moderate | Proposed |
| TST-04 | Never `SeeAllData=true` | §2.4 *Data* | `pmd:ApexUnitTestShouldNotUseSeeAllDataTrue` | High | Proposed |
| TST-05 | A test's name says the behavior: `routesEveryNewCaseToTheSupportQueue`, not `testMethod1` | §2.4 *Names* | `ai`; *`regex:TestName`* | Low | Proposed |
| TST-06 | One behavior per test method, with `Test.startTest()` and `Test.stopTest()` around the call under test; a row of the access matrix may try one step as several personas, through `DstAccessMatrix` | §2.4 *Shape*, *Levels* | `ai` | Moderate | Proposed |
| TST-07 | Every test asserts, through the `Assert` class, with a message where the failure would otherwise be unclear | §2.4 *Shape* | `pmd:ApexUnitTestClassShouldHaveAsserts`, `pmd:ApexAssertionsShouldIncludeMessage` | Moderate | Proposed |
| TST-08 | Behavior an external user sees runs as an external user with `System.runAs`; internal personas get their access through permission set groups, not a profile | §2.4 *Who runs it* | `pmd:ApexUnitTestClassShouldHaveRunAs`; `ai` | Moderate | Proposed |
| TST-09 | Where the org has no spare licenses of a type, tests create no users of that type; the project lists such types here. Types listed: none yet | §2.4 *Licenses* | `ai` | High | Proposed |
| TST-10 | A trigger, batch or bulk service has a test with 200 records. A path too heavy to run for 200 records in a test — one that starts or needs each record's approval, or that saves each record through automation already in the org, which no test can leave out — has one with ten records instead, after one: ten use no more queries, writes or email sends than one, read and asserted with the shared `DstBulkCost`. The other paths keep their runs of 200 | Apex Hours; Clientell; §2.4 *Speed* | `ai` | High | Proposed |
| TST-11 | Each feature has negative tests: invalid input, and a user without access — including an external user of another account | Apex Hours | `ai` | High | Proposed |
| TST-12 | Callouts are mocked with `HttpCalloutMock`; SOSL uses `Test.setFixedSearchResults` | Sonar | `ai` | Moderate | Proposed |
| TST-13 | One `@TestSetup` per class; `@TestVisible` rather than widening access for a test; assertions take the expected value first | Sonar | `ai`; *`regex:OneTestSetup`* | Low | Proposed |
| TST-14 | A test replaces a class with apex-mockery (`Mock.forType`, `Expect.that`), not with a hand-written `StubProvider`; the write is replaced with the shared `DstDmlFake` | §2.4 *Mocks*; §3 F-9 | `ai`; *`regex:NoHandWrittenStub`* | Low | Proposed |
| TST-15 | Access is never mocked: a test of who may read or change a record inserts the records and runs as that user | §2.4 *Mocks*, *Who runs it* | `ai` | High | Proposed |
| TST-16 | The bulk tests of a test class whose methods take more than two minutes in a deployment's results are in a class of their own, `<Class>BulkTest`; a feature class over about 90 seconds is split by scenario, each part building its records through the same `Dst<Feature>Cast`. Both thresholds are defaults: a project that sets its own writes them here | §2.4 *Speed*, *Levels* | `human` | Low | Proposed |
| TST-17 | Every entry point of a feature — controller, trigger, schedule — runs at least once through the real services and selectors in its feature class, `Dst<Feature>FeatureTest`, as the persona who uses it | §2.4 *Levels* | `ai` | Moderate | Proposed |

**Notes**

- **TST-01.** Coverage is measured only by running the tests in an org. The pipeline job `apex-validate`
  ([`ci-cd.md`](ci-cd.md)) validates the whole of `force-app/distributor` with every test class of the build — with
  `RunSpecifiedTests`, so tests outside the build that already fail in the org do not fail the validation —
  and changes nothing in the org. It runs in a sandbox only, is started by hand, and needs the CI variable
  `SF_CI_AUTH_URL`. Which org it validates in, as which user, and where the credential's original lives
  (the team's secret store, referenced from `docs/environments.md`, project-owned) is each project's call.
  The job does not check coverage per class yet.
- **TST-07.** Whether the two PMD rules recognize the `Assert` class as well as `System.assert` is *to be
  verified* before the row moves on. `pmd:ApexUnitTestClassShouldHaveAsserts` does not know apex-mockery's
  `Expect.that`, so a test that checks calls also asserts its result with `Assert` (TST-14,
  [`architecture.md`](architecture.md) §4.2).
- **TST-08.** `pmd:ApexUnitTestClassShouldHaveRunAs` flags every test method without `System.runAs`,
  including those whose outcome does not depend on the running user. Those are suppressed in
  `code-analyzer.yml`, per test class, with the methods and the reason; the `ai` check is whether a
  controller test that reads or saves records runs as the persona who uses the controller — an external
  user where the page is theirs (development-foundation.md §2.4).

---

## 7 · LWC — Lightning web components

| ID | Rule | Source | Check | Severity | Status |
|---|---|---|---|---|---|
| LWC-01 | The Apex controller is thin: it reads through a selector and changes records through a service (APX-34); reads are `@AuraEnabled(cacheable=true)` | §2.5 | `ai` | Moderate | Proposed |
| LWC-02 | Text the user sees comes from the metadata: a field's name from its label on the object (a custom label only for a standard field or a name over 40 characters), every other text from a custom label; none typed into HTML or JavaScript | §2.5 | `ai` | Moderate | Proposed |
| LWC-03 | Styling through SLDS and the org's or site's theme; no hard-coded colors, spacing, sizes or type: a component's own values come from `c/dstTheme` | §2.5 | `eslint:@salesforce-ux/slds/no-hardcoded-values-slds2` (reports Low); *`regex:NoHardcodedColor`* | Moderate | Proposed |
| LWC-04 | A component is built for Lightning Experience, and an Experience Cloud site whose template is chosen in phase 4 | §2.5 | `human` | Moderate | Proposed |
| LWC-05 | A component that holds logic has Jest tests, in `__tests__` inside its folder, run with `npm test` | §2.5 | `ai`; `job:lwc-jest` | Moderate | Proposed |
| LWC-06 | Component names are camelCase: a page is `dst` + page, a part or a module `dst` + what it is, a component on an internal record page or behind a quick action is named for what it acts on | §2.2 | *`script`* | Low | Proposed |
| LWC-07 | A long list is paginated or loaded on demand | LWC performance | `ai` | Moderate | Proposed |
| LWC-08 | Record data is read through Lightning Data Service with named fields, or through cacheable Apex, and refreshed after a write | LWC performance | `ai` | Moderate | Proposed |
| LWC-09 | A listener added to `window` or `document` is removed in `disconnectedCallback` | LWC performance | `ai`; *`regex:ListenerRemoved`* | Low | Proposed |
| LWC-10 | No jQuery, Bootstrap, React or other UI framework inside a component | LWC performance | *`regex:NoUiFramework`* | Moderate | Proposed |
| LWC-11 | An error from Apex reaches the user as a message they understand, from a custom label | Team inference | `ai` | Moderate | Proposed |
| LWC-12 | A component is a page, a part or a module: only a page is exposed, holds state and navigates; a part gets its data through `@api`, reports through events and never calls Apex; a module may call cacheable Apex for what it shares | §2.5 | `ai`; *`script`* | Moderate | Proposed |
| LWC-13 | Code two components share lives in a module (`c/dst…`), not in a copy | §2.5 | `ai`; `cpd` | Low | Proposed |

**Notes**

- **LWC-05.** The `lwc-jest` job runs the Jest tests on every merge request and push to the default branch
  that changes `force-app/distributor` or the Jest set-up. It shows that the tests pass; whether a component that
  holds logic has tests at all stays the `ai` check. A failing test turns the job orange and the merge does
  not wait for it (§1, *Moderate*; §2, step 3), so the author still runs `npm test` before opening a merge
  request that changes a component (development-foundation.md §1.5).
- **LWC-12, LWC-13.** A finding in a component the merge request does not change is not that merge
  request's: the component is brought to the kinds of [`architecture.md`](architecture.md) §2 when a story
  next changes it.

---

## 8 · MDT — Metadata and flows

| ID | Rule | Source | Check | Severity | Status |
|---|---|---|---|---|---|
| MDT-01 | New objects, custom settings, Custom Metadata types and platform events start with `DST_`; their fields have no prefix | §2.2 | *`script`* | Moderate | Proposed |
| MDT-02 | A new field on the org's existing objects has no prefix, and its API name follows its label | §2.2 | *`pmd:FieldNameFollowsLabel`* | Low | Proposed |
| MDT-03 | Permission sets, permission set groups, custom permissions, flows, queues, public groups, custom labels, validation rules, quick actions and field sets that we add start with `DST_` | §2.2 | *`script`* | Moderate | Proposed |
| MDT-04 | The org's existing components keep their API names when we extend them | §2.2 *Whose names change* | `human` | High | Proposed |
| MDT-05 | Logic goes in Apex. A flow is added only where the design names one; a record-triggered flow on an object that also has our trigger needs a line in the design saying why | §2.1 | `ai`, `human` | Moderate | Proposed |
| MDT-06 | The org's existing flows are not edited in place: one the design replaces is switched off in the release that replaces it, as a step in [`release-runbook.md`](release-runbook.md); one that stays is left alone; and each decision is a row in the collision map ([`automation-collision-map.md`](automation-collision-map.md)) | §2.6; §3 F-8 | `human`; GEN-02 | High | Proposed |
| MDT-07 | Every field an external user sees has help text | §2.6 | `ai` | Moderate | Proposed |
| MDT-08 | Picklist values have stable API names; a picklist is restricted when its values are a closed list | §2.6 | `ai`; *`pmd:RestrictedPicklist`* | Low | Proposed |
| MDT-09 | Reports, dashboards and Experience Builder changes made in the UI are retrieved into source after each change | §2.1 | `human` | Moderate | Proposed |
| MDT-10 | No Get, Create, Update or Delete Records element inside a flow loop | Flow Scanner; Clientell | `flow:DbInLoop` | High | Proposed |
| MDT-11 | Every flow element that can fail — DML, subflow, action — has a fault path | Flow Scanner; Clientell | `flow:MissingFaultHandler` | High | Proposed |
| MDT-12 | A record-triggered flow has entry conditions; one that updates its own record does it before save, or checks `ISCHANGED` | Clientell | `ai`, `human` | High | Proposed |
| MDT-13 | No hard-coded Id in a flow; no subflows that call each other in a cycle | Flow Scanner | `flow:HardcodedId`, `flow:CyclicSubflow` | High | Proposed |
| MDT-14 | A scheduled flow filters the records it runs on | Clientell | `human` | Moderate | Proposed |
| MDT-15 | What we add — a field that takes field-level security, an object, a custom setting, a custom metadata type — is granted in `DST_Admin_Access` (group `DST_Administrator`) in the same merge request, at the access §2.6 gives it; a field of the log in `DST_Log_Viewer` | §2.6 *Administrators see what we add* | `ai`; *`script`* | Moderate | Proposed |
| MDT-16 | A custom label's short description — its description, §2.2 — is at most 80 characters: it becomes the label's `MasterLabel`, which Salesforce keeps to 80, and a longer one fails the deployment along with every class that reads the label | §2.2 *Every component has a description* | `regex:LabelShortDescriptionMax80` | Moderate | Proposed |
| MDT-17 | A list view's filter on a standard picklist whose stored code differs from its label — `Case.Status` can be one — holds the code the UI stores, not the value's name | §2.6 *A list view filters a standard picklist by the code the UI stores* | `human`; *`script`* | Moderate | Proposed |

**Notes**

- **MDT-08.** Whether a list of values is closed is a design decision, so the planned check only reports
  unrestricted picklists, and a person decides.
- **MDT-11.** `flow:MissingFaultHandler` is High by default but not in `Recommended`, so it runs only once
  `code-analyzer.yml` selects it.
- **MDT-17.** The planned `script` reads the `<filters>` of the list views under `force-app/distributor/objects/` and
  reports a standard picklist whose value is not a number. The deploy accepts a name and the filter panel
  shows it, so only the list's records tell the two apart.
- **MDT-15.** The planned `script` compares the `*.field-meta.xml` files under `force-app/distributor/objects/` with the
  two permission sets, and skips platform events, the fields of custom settings and custom metadata types, and
  required fields, none of which take field-level security.
- **MDT-16.** A description over 80 characters is found only when the deployment refuses the label, and the
  classes that read it then fail to compile with it. The regex counts the description as Salesforce stores it,
  so an entity such as `&apos;` is one character, and expects `<fullName>` before `<shortDescription>`, the
  order Salesforce writes. The finding sits on the label's `<fullName>` line, so the line the job log and the
  merge request's code-quality report link to is the label's name. At Moderate the job stays green: the
  finding shows as new in the merge request's code-quality report and in the job log.

---

## 9 · AGT — Agentforce

Agents, their actions, prompt templates and the agent user ([`agentforce.md`](agentforce.md); `AF` below means
that page). An action is an entry point, so the APX, SEC and TST rules apply to it as well.

| ID | Rule | Source | Check | Severity | Status |
|---|---|---|---|---|---|
| AGT-01 | An agent is written in Agent Script and kept as its `AiAuthoringBundle`, with the Apex, flows, prompt templates and permission sets its actions use; the runtime metadata a publish generates is not committed unless the design says why | AF §1; SF: Agentforce DX | `human` | Moderate | Proposed |
| AGT-02 | An action does one operation; its Apex is an `…Action` entry point over a service, and decides nothing itself | AF §2; SF: agent actions | `ai` | Moderate | Proposed |
| AGT-03 | An action takes a list and returns a list of the same length and order, one response per request, with a number of queries that does not grow with the list | AF §2; SF: agent actions | `ai`; a test with 200 requests (TST-10) | High | Proposed |
| AGT-04 | A rule an action refuses is returned as `success = false`, an error code and one sentence the agent can say; no exception leaves an action for a refusal it expects | AF §2; SF: agent actions | `ai` | High | Proposed |
| AGT-05 | Every input and output of an action — `@InvocableVariable`, flow variable, prompt template input — has a label and a description written for the language model: what the value is, its format with an example, and where it must come from | AF §2; SF: agent actions | `ai`; *`script`* (description present) | Moderate | Proposed |
| AGT-06 | An action or grounding class filters every read by the customer of the session, and answers a record of another customer exactly as one that does not exist | AF §2, §4 | `ai`; a test as one customer on another's record (TST-15) | High | Proposed |
| AGT-07 | A flow used as an action is autolaunched and runs in the user's context (`runInMode` `DefaultMode`); system mode needs a line in the design saying why | AF §3.1; SF: flow run context | *`script`* (`runInMode`); `ai` | High | Proposed |
| AGT-08 | The agent user's access is a permission set in the repository on the Einstein Agent licence: the action classes and flows, read where actions read, create or edit only where they write, field access for each field selected; no View All or Modify All. Record access comes from a role and sharing rules, not from wider organization-wide defaults | AF §4; SF: agent user | `ai`, `human` | High | Proposed |
| AGT-09 | The customer an action works for comes from the session — a variable the channel or a verification step sets, bound in the script — never from an input the model fills from the conversation | AF §4 | `ai`, `human` | Critical | Proposed |
| AGT-10 | An action switched off (APX-42) returns `ACTION_SWITCHED_OFF` and a sentence for each request, not an empty list | AF §2 | `ai` | Moderate | Proposed |
| AGT-11 | A prompt template's facts and rules come from its grounding class, built in the layers of [`architecture.md`](architecture.md) §1; the prompt holds tone and wording only. A grounding class's inputs change in the same merge request as the templates that use them | AF §3.2; SF: Apex grounding | `ai`, `human` | Moderate | Proposed |
| AGT-12 | After an action's first deployment to an org, it is run once on that org's own records before its tests are trusted there | AF §5 | `human` | Moderate | Proposed |
| AGT-13 | Publishing and activating an agent, and creating an agent user, are org writes: asked for, and steps of the release runbook | AF §6; `CLAUDE.md` §3 | `hook` (`.claude/hooks/sf-org-write-ask.sh`) | High | Proposed |

---

## 10 · Candidates

Review comments that came back in a second merge request and are not a rule yet (§2, step 1).

| Seen in | What keeps coming back | Area | Next step |
|---|---|---|---|
| — | None yet | — | — |

---

## 11 · Published sources

Rules taken from outside the project name their source by these labels. An inference is ours, and needs
a real finding before it moves past *Proposed*.

| Label | Source | Read |
|---|---|---|
| Sonar | [SonarSource Apex rules](https://rules.sonarsource.com/apex/RSPEC-8126) — 97 rules; used where PMD has no equivalent | 22 Oct 2026 |
| PMD | [PMD Apex rules index](https://docs.pmd-code.org/latest/pmd_rules_apex.html) | 22 Oct 2026 |
| Flow Scanner | [Code Analyzer — Flow Scanner rules](https://developer.salesforce.com/docs/platform/salesforce-code-analyzer/guide/rules-flow.html) | 22 Oct 2026 |
| SR top 20 | [The top 20 vulnerabilities found in the AppExchange security review](https://developer.salesforce.com/blogs/2023/08/the-top-20-vulnerabilities-found-in-the-appexchange-security-review), Salesforce, August 2023 | 22 Oct 2026 |
| Experience Cloud guide | [Experience Cloud Developer Guide — securing guest user access](https://developer.salesforce.com/docs/atlas.en-us.communities_dev.meta/communities_dev/communities_dev_security_guest_user_guidelines.htm) | 22 Oct 2026 |
| LWC performance | [Lightning Web Components performance best practices](https://developer.salesforce.com/blogs/2020/06/lightning-web-components-performance-best-practices), Salesforce, June 2020 | 22 Oct 2026 |
| ApexGuru | [Performance-first Apex development with ApexGuru](https://developer.salesforce.com/blogs/2026/04/performance-first-apex-development-with-apexguru-in-salesforce-dx-mcp-server), Salesforce, April 2026 | 22 Oct 2026 |
| SF: mixed DML | [sObjects That Can't Be Used Together in DML Operations](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_dml_non_mix_sobjects.htm), Apex Developer Guide | Found 22 Oct 2026, not read in full |
| Apex Hours | Apex Hours: catching what AI-generated code gets wrong in Salesforce code reviews (apexhours.com), April 2026 | 22 Oct 2026 |
| radix2 | [How to avoid AI hallucinations in Salesforce work](https://www.radix2.tech/blog/how-to-avoid-ai-hallucinations-salesforce), June 2026 | 22 Oct 2026 |
| Clientell | [15 Salesforce flows quietly tanking your org](https://www.getclientell.com/salesforce-resources/checklists/15-salesforce-flows-quietly-tanking-your-org), May 2026 | 22 Oct 2026 |
| Xappex | [Unable to lock row in Salesforce: causes, fixes and prevention](https://www.xappex.com/blog/unable-to-lock-row-salesforce/), June 2026 | 22 Oct 2026 |
| Practitioner (dev.to) | [Why every Salesforce developer should avoid recursive triggers](https://dev.to/salesforce_corner_a9d57c7/why-every-salesforce-developer-should-avoid-recursive-triggers-ded) | Found 22 Oct 2026, not read in full |
| SF: Stub API | [Build a Mocking Framework with the Stub API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexref/apex_testing_stub_api.htm), Apex Developer Guide | Found 23 Oct 2026, not read in full |
| SF: Agentforce DX | [Author an Agent with Agentforce DX](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-nga-author-agent.html) and [Publish an Agent](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-nga-publish.html) | 24 Nov 2026 |
| SF: agent actions | Salesforce Architects blog on exposing Apex and flows to Agentforce, June 2026: single-purpose, bulk, typed invocables with descriptions, explicit error text, user context | 24 Nov 2026 |
| SF: agent user | [Configure Service Agent Access](https://help.salesforce.com/s/articleView?id=ai.agent_user.htm&type=5) | 24 Nov 2026 |
| SF: flow run context | [Flow Run Context](https://help.salesforce.com/s/articleView?id=platform.flow_distribute_context.htm&type=5) | 24 Nov 2026 |
| SF: Apex grounding | [Grounding with Apex Merge Fields](https://help.salesforce.com/s/articleView?id=sf.prompt_builder_ground_apex.htm&type=5) | 24 Nov 2026 |
| Team inference | Our own reasoning, not taken from a published source | — |
