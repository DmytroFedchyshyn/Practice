# Research: feature folders and separation of concerns (checked 2026-11-24)

## What the platform allows

- Salesforce DX resolves most metadata by file suffix, not by folder. Apex classes, flows, permission sets and object fields can sit at any depth inside a package directory. `main/default` is a convention, not a requirement.
- Folder names are strict only for bundle types: `lwc`, `aura`, `experiences`, `digitalExperiences`, `staticresources`, `documents`. A custom object's parts must sit under `objects/<Object>/` (`fields/`, `validationRules/`, ...).
- One object can be split across features. `objects/Order/fields/` can exist in several feature folders; the CLI merges them on deploy. The `.object-meta.xml` file must exist once (standard objects do not need it).
- Verified locally with `sf project convert source` on a copy: nested `classes/services/`, `classes/actions/`, `classes/tests/` and `Order` fields split across two features converted into one correct package.
- Folders are not namespaces. Apex class names stay unique per org, whatever folder they are in.
- `sf project retrieve start` updates files where they already are; anything new lands in the default package directory and has to be moved by hand. This includes metadata that `sf agent publish` retrieves.
- `sf project deploy start --source-dir <feature>` deploys one feature, as long as its dependencies are already in the org.

## Folders versus package directories

| Option | What it is | Fits when |
| --- | --- | --- |
| Feature folders inside one package directory | `agentforce/orders`, `agentforce/returns`, ... | Features share objects and permission sets; nothing is packaged |
| One package directory per feature | Each listed in `sfdx-project.json` | The features become unlocked packages later |

Salesforce recommends multiple package directories as the logical grouping and notes they map one to one to unlocked or 2GP packages later. Locally the two options behave the same; package directories only matter once you package. Package boundaries need one-way dependencies; features that share objects in both directions make bad packages.

## Separation of concerns in Apex

Apex Enterprise Patterns (Trailhead, fflib) define the layers:

| Layer | Responsibility | Called by |
| --- | --- | --- |
| Entry point | Trigger, invocable action, LWC or REST controller, batch. Maps inputs and outputs, no business logic | Platform, agent, UI |
| Service | One business operation, transaction boundary, orchestrates the rest | Entry points |
| Domain | Rules and behaviour of one object type (validation, defaults, calculations) | Services, trigger handler |
| Selector | All SOQL for one object: fields, filters, security mode | Services, domain, batch |
| Unit of work (optional) | Collects DML and commits once | Services |

- fflib is a library (`fflib_SObjectDomain`, `fflib_SObjectSelector`, `fflib_SObjectUnitOfWork`) with dependency injection and mocking. The same layering also works as plain classes and naming conventions, without the library.
- Well-Architected (Adaptable, Composable) frames this as separation of concerns, interoperability and packageability: organise by business capability, reach business logic through a service layer, keep package dependencies one-way.

## Agent actions (Salesforce Architecture blog, June 2026)

Guidance for exposing Apex and Flow to Agentforce, and how our actions compare:

| Guidance | Our actions |
| --- | --- |
| Single-purpose invocable with explicit inputs and outputs | Yes, one action per operation |
| Logic outside the entry point; the invocable is a thin wrapper | Yes, wrappers delegate to services |
| Bulkified: `List<Input>` in, `List<Output>` out, same order | Yes, tested with 200 inputs |
| Strongly typed wrappers; `@InvocableVariable` descriptions act as per-parameter prompts | Yes |
| Return explicit error text instead of failing | Yes, error code plus one sentence |
| `with sharing` plus `WITH USER_MODE`; flows run in user context | Yes; the Flow action must be set to user context |
| High risk: DML in system context that a probabilistic tool choice can trigger | Avoided: inserts run in user mode |

## Gaps in the current code

- Services run their own SOQL; there are no selectors yet.
- The return policy lives in the service; a domain class would own it.
- Everything is in `agentforce/main/default` by type, not by feature.

## Sources

- [Salesforce DX Project Structure and Source Format](https://developer.salesforce.com/docs/platform/sfdx-dev/guide/sfdx-dev-source-file-format.html)
- [Multiple Package Directories](https://developer.salesforce.com/docs/platform/sfdx-dev/guide/sfdx-dev-ws-mpd.html)
- [Decomposed Metadata Types](https://developer.salesforce.com/docs/platform/sfdx-dev/guide/sfdx-dev-ws-decomposed-md-types.html)
- [Trailhead: Apex Enterprise Patterns, Domain and Selector Layers](https://trailhead.salesforce.com/content/learn/modules/apex_patterns_dsl)
- [Trailhead: Apex Enterprise Patterns, Service Layer](https://trailhead.salesforce.com/content/learn/modules/apex_patterns_sl)
- [Well-Architected: Composable](https://architect.salesforce.com/well-architected/adaptable/composable) (the site was restructured; the page now redirects to the Architecture Center home)
- [Make Your Existing Automation Agent-Ready](https://www.salesforce.com/blog/agent-ready-automation/)
- [5 Anti-Patterns in Package Dependency Design](https://medium.com/salesforce-architects/5-anti-patterns-in-package-dependency-design-and-how-to-avoid-them-87bb50331cb8)
