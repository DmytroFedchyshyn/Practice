# Rules for the code

The rules this project's code is written to, and the only ones `/code-review` checks it against. They
are the core of the delivery kit's rule catalogue, simplified for a practice project, and keep the
catalogue's IDs so a finding reads the same everywhere. What the catalogue adds for a delivery project —
Apex layers, the shared foundation classes, feature manifests, the release process — does not apply here.

A rule the project adds takes the ID of the catalogue's rule it comes from, or `PRC-01`, `PRC-02`… when
it is the project's own.

`npm run format`, `npm run lint`, `npm run scan` and `npm test` run the automated checks; the pre-commit
hook formats, lints and scans for secrets on every commit.

## General

| ID | Rule |
|---|---|
| GEN-03 | No secret in any commit: no password, token, key or session URL. The repository may be public, so no Salesforce username, org ID or org URL either |
| GEN-04 | Code in `force-app/distributor` is formatted by Prettier |
| GEN-09 | An Apex class, trigger or component is committed together with its `-meta.xml` |
| GEN-11 | A new component uses the project's `sourceApiVersion` (68.0) |
| GEN-15 | A comment says why the code is as it is, where the code cannot say it; none repeats what the code does |

## Security

| ID | Rule |
|---|---|
| SEC-01 | A class declares its sharing: `with sharing` by default, `inherited sharing` when it is called from both user and system contexts |
| SEC-02 | `without sharing` only with a comment on the class saying why |
| SEC-03 | Every query and DML statement runs in user mode (`WITH USER_MODE`, `AccessLevel.USER_MODE`), or names system mode explicitly |
| SEC-04 | A read or write in system mode carries a comment saying why |
| SEC-05 | No hard-coded record Ids, or names of users, queues, groups, profiles or record types: they are found by developer name |
| SEC-08 | Dynamic SOQL uses bind variables (`Database.queryWithBinds`); user input never goes into the query string |
| SEC-09 | No user data through `innerHTML` or `lwc:dom="manual"`; no `addError` with escaping turned off |

## Apex

| ID | Rule |
|---|---|
| APX-01 | One trigger per object, handling every event; its logic lives in a handler class, not in the trigger's body |
| APX-03 | No SOQL or DML inside a loop |
| APX-04 | Methods take and return collections, so a trigger of 200 records works as one of one |
| APX-06 | No empty `catch`: an error is handled, shown to the user, or thrown on |
| APX-11 | No commented-out code |
| APX-26 | Every SOQL query has a `WHERE` or a `LIMIT` |

## Tests

| ID | Rule |
|---|---|
| TST-01 | Every class is covered at 75 % or more |
| TST-04 | Never `SeeAllData=true`: a test creates the records it needs |
| TST-05 | A test's name says the behavior: `routesEveryNewCaseToTheSupportQueue`, not `testMethod1` |
| TST-07 | Every test asserts, through the `Assert` class |
| TST-10 | A trigger or a batch has a test with 200 records |

## Lightning web components

| ID | Rule |
|---|---|
| LWC-03 | Styling through SLDS; no hard-coded colors, spacing or sizes |
| LWC-09 | A listener added to `window` or `document` is removed in `disconnectedCallback` |
| LWC-10 | No jQuery, Bootstrap, React or other UI framework inside a component |

## Flows and metadata

| ID | Rule |
|---|---|
| MDT-10 | No Get, Create, Update or Delete Records element inside a flow loop |
| MDT-11 | Every flow element that can fail — DML, subflow, action — has a fault path |
| MDT-12 | A record-triggered flow has entry conditions; one that updates its own record does it before save, or checks `ISCHANGED` |
| MDT-16 | A custom label's short description is at most 80 characters: a longer one fails the deployment (checked by `npm run scan`) |

## Agents — when the project has one

| ID | Rule |
|---|---|
| AGT-03 | An action takes a list and returns a list of the same length and order, one response per request |
| AGT-04 | A request an action refuses is returned as `success = false` and one sentence the agent can say; no exception leaves an action for a refusal it expects |
| AGT-05 | Every input and output of an action has a label and a description written for the language model: what the value is, its format with an example, and where it must come from |
| AGT-06 | An action filters every read by the customer of the session, and answers a record of another customer exactly as one that does not exist |
| AGT-09 | The customer an action works for comes from the session, never from an input the model fills from the conversation |
