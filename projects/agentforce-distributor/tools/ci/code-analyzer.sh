#!/usr/bin/env bash
# Salesforce Code Analyzer on the build folder: Apex, LWC and Flow rules for quality and security
# (docs/engineering/development-foundation.md §1.5). The same on every CI platform; the pipeline file
# installs the Salesforce CLI, the code-analyzer plugin and Java 17 first.
#
#   tools/ci/code-analyzer.sh
#
# Writes reports/code-analyzer.{html,json,sarif}, prints the findings to the log and, on GitLab, the
# Code Quality report. Exits non-zero on a finding of High or above, so the job turns orange.
set -uo pipefail

build=$(node -p 'require("./project.config.json").buildDir')
mkdir -p reports
# Tells review-threads that the analyzer was meant to run, so a crash before it writes results is not
# mistaken for a clean run.
touch reports/code-analyzer.started

status=0
sf code-analyzer run --workspace "$build" \
    --rule-selector Recommended --rule-selector pmd:Security \
    --severity-threshold 2 \
    --output-file reports/code-analyzer.html \
    --output-file reports/code-analyzer.json \
    --output-file reports/code-analyzer.sarif || status=$?

node tools/ci/code-analyzer-log.mjs reports/code-analyzer.json
if [ -n "${GITLAB_CI:-}" ]; then
    node tools/ci/code-analyzer-to-codequality.mjs reports/code-analyzer.json reports/gl-code-quality-report.json
fi
exit "$status"
