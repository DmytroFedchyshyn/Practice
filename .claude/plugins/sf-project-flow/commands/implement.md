---
description: Plan a change, wait for approval, build and review it against the code review rules, report on one screen
argument-hint: [what to implement]
---

Follow the `plan-build-review` skill for: $ARGUMENTS

Read `docs/engineering/code-review-rules.md` first. Show the short plan and change nothing until
the person approves it. Build to the rules, and keep the `features` list in `project.config.json`
and the regenerated `manifest/features/` in step with every component created under the build
folder. Have a separate read-only agent review the change against the rules by rule ID, fix what
the severity requires, and finish with the one-screen report. Never commit, push, deploy or
comment as part of this command.
