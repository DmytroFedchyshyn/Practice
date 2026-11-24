#!/bin/sh
# gitleaks on the commits a pipeline brings (docs/engineering/development-foundation.md §1.5).
#
#   tools/ci/secrets.sh <base-sha> <head-sha>
#
# The pipeline file passes the range: the merge request's diff base, or the commit before a push.
# An empty or all-zero base scans the head commit only. Writes reports/gitleaks.{json,xml,sarif},
# redacted; exits non-zero when it finds a possible secret. POSIX sh: the gitleaks image has no bash.
set -u

base=${1:-}
head=${2:?usage: tools/ci/secrets.sh <base-sha> <head-sha>}
if [ -n "$base" ] && [ "$base" != "0000000000000000000000000000000000000000" ]; then
    range="$base..$head"
else
    range="-1 $head"
fi
echo "Scanning commits: $range"
mkdir -p reports

status=0
gitleaks git --redact --no-banner --verbose --log-opts="$range" --report-format json --report-path reports/gitleaks.json . || status=$?
# The same scan for the platform's test summary (JUnit) and code scanning (SARIF).
gitleaks git --redact --no-banner --log-opts="$range" --report-format junit --report-path reports/gitleaks.xml . > /dev/null 2>&1 || true
gitleaks git --redact --no-banner --log-opts="$range" --report-format sarif --report-path reports/gitleaks.sarif . > /dev/null 2>&1 || true
exit "$status"
