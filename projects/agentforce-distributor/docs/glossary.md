# Glossary

Every abbreviation and term that appears anywhere in this project — the SOW, the offers, the estimation pack,
the client's own material, the org, and these notes. Platform terms every Salesforce engineer already knows
(OWD, FLS, LWC, SOQL and the rest) are not repeated here.

**Format.** One table per section, `Term | Expansion | What it means here`. The term is bold. *Expansion* is the
spelled-out form, or *—* when there is none. *What it means here* says what the term means **in this project**,
with its source — a session and speaker, a document, an object or field by API name — not a dictionary
definition.

`?` before an expansion marks one inferred rather than confirmed. Those are worth asking about rather than
assuming; the question goes to the open questions with an owner.

A new term goes here in the same merge request as the document that first uses it. When a term's meaning is
corrected, the row says so with the date and the source, and the documents that used the old meaning are
corrected in the same merge request.

## The client's own terms

The words the client uses for its own business, objects, systems and programs. Client documents use these
words, not their Salesforce equivalents ([`document-standard.md`](document-standard.md) §10).

| Term | Expansion | What it means here |
|------|-----------|--------------------|

## Roles

The client's roles and teams, as the client names them.

| Term | Expansion | What it means here |
|------|-----------|--------------------|

## Salesforce products

| Term | Expansion | What it means here |
|------|-----------|--------------------|
| **SFDC** | Salesforce.com | Often used in client material to mean the client's own org |
| **CPQ** | Configure, Price, Quote | Salesforce's quoting product; note whether it is present in the client's org |
| **Experience Cloud** | — | Salesforce's product for sites and portals for customers and partners; a site is built from a template in Experience Builder |
| **S2S** | Salesforce-to-Salesforce | The legacy org-to-org record-sharing mechanism |
| **MuleSoft** | — | Salesforce's integration platform |
| **Agentforce** | — | Salesforce's agentic AI layer |
| **Einstein** | — | Salesforce's AI features |
| **Agent Script** | — | The language an Agentforce agent is written in: a `.agent` file in an `AiAuthoringBundle` (`docs/engineering/agentforce.md` §1) |
| **Subagent** | — | One area an agent handles, with its instructions and actions; called a *topic* before April 2026 |
| **Agent action** | — | What an agent can run: an Apex invocable method, a flow or a prompt template (`agentforce.md` §2, §3) |
| **Agent user** | — | The user a Service agent runs as while the customer is not logged in; its permission sets limit what the agent reads and changes (`agentforce.md` §4) |
| **Grounding** | — | The facts a prompt template is given from the org — here through an Apex class — so the model writes from data, not from what it guesses |

## Delivery and estimating

| Term | Expansion | What it means here |
|------|-----------|--------------------|
| **SOW** | Statement of Work | The contract document that sets the scope; say whether it is preliminary or binding |
| **ROM** | Rough Order of Magnitude | An estimate given before discovery, not a commitment |
| **MSA** | Master Service Agreement | The contract the SOW hangs off |
| **CR** | Change Request | Where work outside the agreed scope or design goes |
| **HLD** | High-Level Design | A discovery deliverable |
| **SIT** | System Integration Testing | End-to-end testing across the build and the systems it connects to |
| **UAT** | User Acceptance Testing | The client's own testing before go-live |
| **NRT** | Non-Regression Testing | |
| **ST** | Sanity Testing | |
| **HC** | Hypercare | The support period right after go-live; say how long it runs |
| **FTE** | Full-Time Equivalent | |
| **pd** | person-day | 8 hours; the unit of the estimates |
| **EOW** | End of Week | |
| **SLA** | Service Level Agreement | Say what the time is measured from and to, and whether it is enforced or only reported |
| **CI/CD** | Continuous Integration / Continuous Delivery | The pipeline the merge requests run through ([`engineering/ci-cd.md`](engineering/ci-cd.md)) |
| **OOTB** | Out of the Box | Standard platform behavior, no build |
| **OOS** | Out of Scope | |
| **PO** | Product Owner | The client's nominated owner of the backlog |
| **SME** | Subject Matter Expert | |
| **PM** | Project Manager | |
| **BA** | Business Analyst | |
| **SA** | Solution Architect | |
| **QE / QA** | Quality Engineer / Quality Assurance | |
| **Feature** (of the build) | — | One of the parts the build deploys in, as the `features` list in `project.config.json` names them, each with the features it depends on. Every component belongs to exactly one; `tools/deploy-build.sh --feature` validates and deploys one ([`engineering/release-runbook.md`](engineering/release-runbook.md) §4) |
| **Automation switch** | — | A record of `DST_Automation_Switch__mdt` with an *Active* checkbox that an administrator unchecks in Setup to stop one feature of the build, or one automation within it, for every user, with no code change ([`engineering/automation-switches.md`](engineering/automation-switches.md)). Not the bypass |
| **Bypass** | — | The permission set `DST_Bypass_Automation`, or the hierarchy custom setting `DST_Settings__c`, that stops all of the build's automation for one user, a profile or a whole org — for a data load or a quiet period. It does not stop the org's existing automation |

## Regions and territories

The client's regions, as each field that carries them spells them. Where two fields carry the same region with
different values, list the values per field under the table, with the date they were read from the org.

| Term | Expansion | Where it appears |
|------|-----------|------------------|

## Pairs worth never mixing up

Two terms that sound alike and mean different things — a client system and a Salesforce feature of almost the
same name, two license tiers, two products sold separately. One short paragraph per pair: what each is, and where
the confusion starts.
