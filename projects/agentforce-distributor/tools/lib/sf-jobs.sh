# Deployment jobs in one org, shared by tools/deploy-build.sh and tools/deploy-changes.sh. Sourced, not run:
# the caller sets ORG and runs with set -euo pipefail. It may set QUEUE_WITHOUT_ASKING=true, to queue behind
# a running deployment without a question, and JUNIT_DIR, to keep the test results there as JUnit. Needs sf
# and jq.

QUEUE_WITHOUT_ASKING="${QUEUE_WITHOUT_ASKING:-false}"
JUNIT_DIR="${JUNIT_DIR:-}"
command -v jq >/dev/null || { echo "jq not found: the scripts read the org's answers with it" >&2; exit 1; }

# Starts a job without waiting for it, so its ID is known before the long wait: prints the ID, or says
# why the job did not start.
start_job() {
  local out
  out="$("$@" --async --json)" || { jq -r '.message // "it did not start"' <<<"$out" >&2; return 1; }
  jq -er '.result.id' <<<"$out"
}

# Shows a job's progress and result until it ends. The report's exit code is 0 for a failed job too,
# so the job's status is read separately before anything depends on it. The report matches the org's
# answer against the whole project, where the org snapshot holds a second CustomLabels file, and warns
# once for every label of the build folder; those warnings are dropped.
follow_job() {
  local junit=()
  [[ -z "$JUNIT_DIR" ]] || junit=(--junit --results-dir "$JUNIT_DIR")
  sf project deploy report --job-id "$1" --target-org "$ORG" --wait 60 ${junit[@]+"${junit[@]}"} \
    2> >(grep -v 'returned from org, but not found in the local project' >&2) || true
}

# Unknown when the org cannot be asked, so that a failed read never ends the script without the job's ID.
job_status() {
  local out
  out="$(sf project deploy report --job-id "$1" --target-org "$ORG" --json)" || true
  jq -r '.result.status // "Unknown"' <<<"$out" 2>/dev/null || echo Unknown
}

# Without a terminal nobody can answer: the script stops rather than wait on a pipe or take an answer
# nobody gave.
ask() {
  [[ -t 0 ]] || { echo "No terminal to ask on: $1" >&2; return 1; }
  local answer=""
  read -r -p "$1 [y/N] " answer || true
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

# An org runs one deployment at a time: a job started behind another one waits until it ends, which after
# a full validation is half an hour. Someone else may start one while a script waits for an answer, so a
# script checks again before each job it starts.
check_queue() {
  local busy_json busy
  busy_json="$(sf data query --use-tooling-api --target-org "$ORG" --json --query "SELECT Id, Status, CheckOnly, CreatedDate, CreatedBy.Name FROM DeployRequest WHERE Status IN ('Pending', 'InProgress', 'Canceling') ORDER BY CreatedDate")" \
    || { echo "Could not read the deployments in $ORG: $(jq -r '.message // empty' <<<"$busy_json")" >&2; return 1; }
  busy="$(jq -r '.result.records[] | "  \(.Id)  \(.Status)  \(if .CheckOnly then "validation" else "deployment" end) by \(.CreatedBy.Name), started \(.CreatedDate[0:16] | sub("T"; " ")) UTC"' <<<"$busy_json")"
  [[ -n "$busy" ]] || return 0
  echo "$ORG is already running a deployment; $1 would wait until it ends:"
  echo "$busy"
  if [[ "$QUEUE_WITHOUT_ASKING" == true ]]; then
    echo "Queueing behind it, as asked."
    return 0
  fi
  ask "Queue behind it?"
}
