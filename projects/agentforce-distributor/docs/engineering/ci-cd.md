# CI/CD

**Audience:** the development team and whoever sets up the repository.
**Status:** kit default, adjusted per project through a merge request.
**Sources:** `tools/ci/`, the pipeline file of the project's platform, `project.config.json`,
`config/orgs.json`.

## 0 · What runs where

Every check is written once — a script in `tools/ci/` or an npm script — and each platform's pipeline
file only decides when it runs and how its result is shown. The project keeps one platform's files;
`init.sh` installs the one `CI_PLATFORM` names.

| Check | Script | GitLab (`.gitlab-ci.yml`) | GitHub (`.github/workflows/`) | Azure (`.azure-pipelines/`) |
|---|---|---|---|---|
| Prettier | `npm run format:check` | `prettier` | `checks.yml` · prettier | `format_lint_jest` |
| ESLint | `npm run lint` | `eslint` | `checks.yml` · eslint | `format_lint_jest` |
| Jest (LWC) | `npm run test:ci` | `lwc-jest` | `checks.yml` · lwc-jest | `format_lint_jest` |
| Code Analyzer | `tools/ci/code-analyzer.sh` | `code-analyzer` | `checks.yml` · code-analyzer | `code_analyzer` |
| Secrets (gitleaks) | `tools/ci/secrets.sh` | `secrets` | `secrets.yml` | `secrets` |
| Apex validation | `tools/ci/apex-validate.sh` | `apex-validate` (manual) | `apex-validate.yml` (run by hand) | `apex-validate.yml` (run by hand) |
| Metadata through an MR | `tools/ci/force-app-via-mr.sh` | `force-app-via-mr` | `force-app-via-mr.yml` | not ported (§6) |
| Review threads | `tools/ci/mr-review-threads.mjs` | `review-threads` | code scanning (SARIF) | SARIF artifact |
| Fleet deploy | `tools/ci/fleet-plan.mjs` | pattern only (§5) | `fleet-deploy.yml` | pattern only (§5) |

The jobs that read code run only when the build folder or the settings of a check change; the secret
scan runs on every change, documentation included.

## 1 · The jobs

- **Prettier, ESLint, Jest** report formatting, lint and failing component tests on the build folder.
  The same commands run locally, and lint-staged runs them on staged files before each commit
  (development-foundation.md §1.5).
- **Code Analyzer** runs the Recommended rules plus PMD's security rules and the project's own regex
  rules (`code-analyzer.yml`) on the build folder. A finding of High or above fails the step; every
  finding is printed to the log with a link to its line and written as HTML, JSON and SARIF.
- **Secrets** scans only the commits the run brings — the merge request's, or a push's — redacted.
  A false positive goes into `.gitleaks.toml` with its reason.
- **Apex validation** validates the whole build folder against the CI sandbox with every test class —
  a dry run, nothing is written. It signs in with `SF_CI_AUTH_URL` and stops unless the org is a
  sandbox: the credential is readable from any branch's pipeline. One runs at a time; a cancelled job
  cancels its validation in the org.
  **Default — adjust per project.** It starts only by hand while the build is in active development,
  because tests run when someone asks for them (development-foundation.md §1.3); a project past that
  stage makes it automatic on merge requests that change Apex.
- **Metadata through an MR** turns the default branch red when a commit that changes a protected path
  (`project.config.json` `protectedPaths`) was pushed straight to it, past the pre-push hook.
  **Default — adjust per project.** Only `force-app/` is protected, so documentation may still go
  straight to the default branch; a project that sends everything through merge requests protects the
  whole branch in the platform's settings and drops this job.
- **Review threads** (GitLab) opens one merge request thread per Code Analyzer finding of Critical or
  High and per possible secret, and resolves the bot's threads whose finding has gone. Threads a person
  resolved stay resolved; a rerun never opens a thread twice (the hidden marker is `reviewMarker` in
  `project.config.json`).

## 2 · What holds the merge

| Platform | What blocks a merge | Where it is set |
|---|---|---|
| GitLab | The bot's unresolved threads, and a running or failed pipeline once *Pipelines must succeed* is on. Jobs marked `allow_failure` turn orange and only report. | Settings → Merge requests: *All threads must be resolved*, *Pipelines must succeed* |
| GitHub | The status checks the branch ruleset requires, and code scanning alerts at the severity the ruleset names. | Settings → Rules → Rulesets on the default branch: *Require a pull request*, *Require status checks*, *Require code scanning results* |
| Azure DevOps | The build-validation policy's result, and the reviewers the policy requires. | Project settings → Repositories → Policies on the default branch: *Build validation* with `.azure-pipelines/azure-pipelines.yml` |

**Default — adjust per project.** Only the review threads (Critical and High findings, secrets) hold a
merge on GitLab; formatting, lint, Jest and the Apex validation report. A project raises a check to
blocking through code-review-rules.md §2: the rule's status moves to Enforced and the job stops being
allowed to fail, or becomes a required check.

## 3 · Variables and secrets

| Name | GitLab | GitHub | Azure DevOps | Needed by |
|---|---|---|---|---|
| `SF_CI_AUTH_URL` | CI/CD variable, masked, not protected | repository secret | secret pipeline variable | Apex validation |
| `SF_CI_DEPLOY_ARGS` | CI/CD variable (optional) | repository variable (optional) | pipeline variable (optional) | Apex validation |
| `REVIEW_BOT_TOKEN` | CI/CD variable, masked, not protected: a project access token with the `api` scope and the Developer role | — | — | Review threads |
| `SF_JWT_KEY`, `SF_CONSUMER_KEY`, `SF_USERNAME`, `SF_INSTANCE_URL` | — | secrets of each org's GitHub Environment | — | Fleet deploy |

- `SF_CI_AUTH_URL` is the SFDX auth URL of a user in a sandbox kept for CI. "Not protected" on GitLab,
  because merge request pipelines run on unprotected branches; the sandbox check is what keeps it safe.
- Without `SF_CI_AUTH_URL` the Apex validation is not created (GitLab) or stops with a message.
- Without `REVIEW_BOT_TOKEN` the review-threads job fails, so a merge request is never let through
  unreviewed by a missing token.
- Tool versions (Node, Salesforce CLI, Code Analyzer, gitleaks) are pinned in the pipeline file; raise
  them together, after running the new versions locally.

## 4 · Setting up a repository

1. Copy the kit with `init.sh` and commit; run `npm install` (it points git at `.githooks`).
2. Create the CI sandbox user and set `SF_CI_AUTH_URL` (§3). Leave it unset until the sandbox exists.
3. GitLab: create the project access token for `REVIEW_BOT_TOKEN`; turn on *All threads must be
   resolved* and *Pipelines must succeed*.
   GitHub: turn on code scanning (it needs GitHub Advanced Security on a private repository; without
   it the SARIF upload step fails and the job log still lists every finding); add the ruleset.
   Azure DevOps: create a pipeline from `.azure-pipelines/azure-pipelines.yml` and one from `.azure-pipelines/apex-validate.yml`; add the
   build-validation policy.
4. Open a merge request that changes a file in the build folder and check that every job runs.

## 5 · Fleet deploy

For a build that goes to several orgs — a product installed in many production orgs, or a release
rolled out in waves.

- **Registry.** `config/orgs.json` (copied from `config/orgs.example.json`) lists each org by alias,
  the CI environment that holds its secrets, whether it is production, and the groups it belongs to.
  Aliases and group names only: usernames, URLs and keys live in the platform's secrets.
- **Plan.** `tools/ci/fleet-plan.mjs <group> <mode> <test-level>` resolves a group into the list of
  orgs, stops on an unknown or empty group, and refuses `NoTestRun` for a group that holds a
  production org — Salesforce refuses it there anyway, and failing first stops the run before any org
  is touched.
- **Per org.** Each org runs as its own job, bound to its environment, so its secrets and approvals
  are its own: a run for one org cannot read another's key, and production environments carry
  required reviewers. Login is JWT with a key written to a temporary file and removed in a step that
  always runs. Validate first, then deploy; `max_parallel` keeps the load on shared services low.
- **Source.** `config/overlays/<alias>/package.xml` when that org needs a different manifest (it
  replaces the base one, no merging, same API version); else a feature's manifest; else the whole
  build folder.
- **Waves.** Groups such as `wave-1`, `wave-2` roll a release out in stages; the second waits for the
  first to be checked.
- **Profiles last.** When a project deploys profiles at all (code-review-rules.md SEC-06), they go in a
  separate, last deployment: a profile aggregates permissions across features, and deploying it with
  one feature overwrites what the others granted.
- **On GitLab and Azure** the same plan feeds a `parallel:matrix` job or a generated child pipeline
  (GitLab, with protected environments for approvals), or a `deployment` job per environment (Azure,
  with approvals and checks on each environment). The kit ships the GitHub workflow only.

The connected app for JWT: create it in each org (or one per environment), upload the public
certificate, pre-authorize the deploying user's profile or permission set, and store the private key,
consumer key, username and instance URL in that org's environment.

**Default — adjust per project.** One build org per developer and the Apex validation against a CI
sandbox (development-foundation.md §1.3); the fleet deploy is the option for multi-org delivery.

## 6 · Patterns not built

Seen to work on other Salesforce projects, described here so a project can adopt them when it needs
them. Each becomes a script in `tools/ci/` called from every platform, not a platform-only job.

- **Delta deploys with last-success tags.** After each successful deploy to an org, a git tag per org
  and kind (`<alias>_delta_LastSuccess`) moves to the deployed commit; the next deploy takes the
  changes since that tag (for example with the `sfdx-git-delta` plugin), so a failed run never loses
  changes. A merge request's delta is taken from the merge base with its target branch. A full deploy
  also moves the delta tag.
- **Destructive changes** in their own step, with a dry run first.
- **Separate approvals for validate and deploy to production**, so the people who may check a release
  are not necessarily the ones who may ship it.
- **A production pipeline whose choices leave out `NoTestRun`**, so the menu itself cannot pick it.
- **One wrapper for the Salesforce CLI** in pipelines: an allow-list of actions, a check of the auth
  URL's format before login, distinct exit codes per kind of failure, failing tests pulled from the
  deploy report into the log, and logs named by action, run and commit so they sort in time order.
- **Module dependencies as a graph** — each feature with `dependsOn`, its entry points, its tests and
  a coverage target — validated for cycles in CI. The kit's `features` list with `dependsOn` is the
  first step; `tools/feature-manifests.py` already stops on a cycle.
- **Deploy notifications** to the team's chat, for failures as well as successes; a notice of success
  alone hides the runs that need someone.
- **Scheduled deploys** to sandboxes only. Production is never deployed by a schedule without a person
  approving the run.

Not ported, and why:

- **Review threads on GitHub and Azure.** The bot uses GitLab's merge request API. GitHub annotates
  pull requests from the SARIF upload instead; on Azure the SARIF files are published for the SARIF
  SAST Scans Tab extension.
- **Metadata through an MR on Azure.** Azure Pipelines has no "commit before the push" for a CI run, so
  the check cannot tell a direct push from a merge. An Azure Repos branch policy on the default branch
  blocks direct pushes altogether; a project that wants documentation pushed straight sets a path
  filter on the build-validation policy instead.
