#!/usr/bin/env bash
# Validate, and on request deploy, the build folder to one org: all of it, or one feature
# (docs/engineering/development-foundation.md §1.3, §1.4). The build folder and the runbook come from
# project.config.json.
#
#   tools/deploy-build.sh <alias>                            # validate only: a dry run, nothing is written
#   tools/deploy-build.sh <alias> --deploy                   # validate, then quick-deploy that validation after a yes
#   tools/deploy-build.sh <alias> --exclude <path>           # leave out a component the org cannot take (repeatable)
#   tools/deploy-build.sh <alias> --feature <slug>           # one feature, from manifest/features/<slug>.xml (runbook §4)
#   tools/deploy-build.sh <ci alias> --queue --junit reports/apex   # the pipeline: no questions, test results as JUnit
#
# Runs every *Test class of the build folder, or with --feature the feature's own, once: the deployment reuses
# the validation's test run instead of running the tests again. After a deploy, run the post-deployment steps
# of the release runbook for that org. Needs sf, jq and python3.
set -euo pipefail

USAGE="usage: tools/deploy-build.sh <org alias> [--feature <slug>] [--deploy] [--exclude <path>]... [--queue] [--junit <dir>]"
[[ $# -ge 1 && "$1" != -* ]] || { echo "$USAGE" >&2; exit 2; }
ORG="$1"
shift
MODE=""
EXCLUDES=()
QUEUE_WITHOUT_ASKING=false
JUNIT_DIR=""
FEATURE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --deploy) MODE="--deploy" ;;
    --feature) [[ $# -ge 2 && "$2" =~ ^[a-z][a-z0-9-]*$ ]] || { echo "$USAGE" >&2; exit 2; }; FEATURE="$2"; shift ;;
    --exclude) [[ $# -ge 2 && "$2" != -* ]] || { echo "$USAGE" >&2; exit 2; }; EXCLUDES+=("${2%/}"); shift ;;
    --queue) QUEUE_WITHOUT_ASKING=true ;;
    --junit) [[ $# -ge 2 && "$2" != -* ]] || { echo "$USAGE" >&2; exit 2; }; JUNIT_DIR="$2"; shift ;;
    *) echo "$USAGE" >&2; exit 2 ;;
  esac
  shift
done
cd "$(dirname "$0")/.."
# shellcheck source=SCRIPTDIR/lib/sf-jobs.sh
source tools/lib/sf-jobs.sh
SRC="$(jq -r '.buildDir' project.config.json)"
RUNBOOK="$(jq -r '.runbook // "docs/engineering/release-runbook.md"' project.config.json)"
# A project without a release runbook (a practice project) gets no reminders of its steps.
[[ -f "$RUNBOOK" ]] || RUNBOOK=""

# A component an org cannot take refuses the whole deployment with it: a dashboard run as the viewer in an
# org at its limit of such dashboards, site settings in an org that lacks what they name. Leaving one out,
# every folder of the build is named on its own, and a folder that holds a left-out path file by file, so
# nothing outside the build folder is picked up. A path inside a bundle cannot be left out: the bundle is
# deployed whole.
SOURCE_ARGS=(--source-dir "$SRC")
WHAT="$SRC"
RUN_DIR="."
if [[ -n "$FEATURE" ]]; then
  # One feature, as tools/feature-manifests.py wrote it from project.config.json (development-foundation.md
  # §1.4). A manifest older than the config or the build folder would deploy the wrong components, so the
  # check runs first.
  MANIFEST="manifest/features/$FEATURE.xml"
  [[ -f "$MANIFEST" ]] || { echo "No feature $FEATURE. Features: $(find manifest/features -name '*.xml' -exec basename {} .xml \; | sort | tr '\n' ' ')" >&2; exit 2; }
  python3 tools/feature-manifests.py --check
  [[ ${#EXCLUDES[@]} -eq 0 ]] || { echo "--exclude works on the whole build, not with --feature: take the component out of the feature in project.config.json instead" >&2; exit 2; }
  WHAT="feature $FEATURE"
  # A manifest is resolved against every package directory, and the org snapshot is one too: an object of
  # the build would take along its fields and list views from the snapshot. So the feature deploys from a
  # copy of the project that has the build folder alone.
  RUN_DIR="$(mktemp -d)"
  trap 'rm -rf "$RUN_DIR"' EXIT
  mkdir -p "$RUN_DIR/$(dirname "$SRC")"
  cp -R "$SRC" "$RUN_DIR/$(dirname "$SRC")/"
  cp .forceignore "$RUN_DIR/"
  python3 -c 'import json, sys; p = json.load(open("sfdx-project.json")); p["packageDirectories"] = [{"path": sys.argv[2], "default": True}]; json.dump(p, open(sys.argv[1], "w"), indent=2)' "$RUN_DIR/sfdx-project.json" "$SRC"
  cp "$MANIFEST" "$RUN_DIR/$FEATURE.xml"
  MANIFEST="$RUN_DIR/$FEATURE.xml"
  SOURCE_ARGS=(--manifest "$FEATURE.xml")
elif [[ ${#EXCLUDES[@]} -gt 0 ]]; then
  for e in "${EXCLUDES[@]}"; do
    [[ -e "$e" && "$e" == "$SRC"/* ]] || { echo "$e is not in $SRC: nothing to leave out" >&2; exit 1; }
  done
  left_out() {
    local e
    for e in "${EXCLUDES[@]}"; do [[ "$1" == "$e" || "$1" == "$e"/* ]] && return 0; done
    return 1
  }
  SOURCE_ARGS=()
  while IFS= read -r dir; do
    holds=false
    for e in "${EXCLUDES[@]}"; do [[ "$e" != "$dir" && "$e" != "$dir"/* ]] || holds=true; done
    if [[ "$holds" == false ]]; then
      SOURCE_ARGS+=(--source-dir "$dir")
      continue
    fi
    while IFS= read -r path; do left_out "$path" || SOURCE_ARGS+=(--source-dir "$path"); done < <(find "$dir" -type f ! -name '.*' | sort)
  done < <(find "$SRC" -mindepth 1 -maxdepth 1 ! -name '.*' | sort)
  names="$(printf '%s, ' "${EXCLUDES[@]##*/}")"
  WHAT="$SRC without ${names%, }"
fi

TEST_ARGS=(--test-level NoTestRun)
TESTS=()
if [[ -n "$FEATURE" ]]; then
  # The feature's own test classes: the ApexClass members of its manifest whose names end in Test.
  while IFS= read -r name; do TESTS+=("$name"); done < <(awk '/<types>/ { n = 0 } /<members>/ { gsub(/ *<\/?members>/, ""); m[++n] = $0 } /<name>ApexClass<\/name>/ { for (i = 1; i <= n; i++) if (m[i] ~ /Test$/) print m[i] }' "$MANIFEST" | sort)
else
  while IFS= read -r name; do TESTS+=("$name"); done < <(find "$SRC" -name '*Test.cls' -exec basename {} .cls \; | sort)
fi
if [[ ${#TESTS[@]} -gt 0 ]]; then
  TEST_ARGS=(--test-level RunSpecifiedTests)
  for t in "${TESTS[@]}"; do TEST_ARGS+=(--tests "$t"); done
fi

deploy_later() {
  if [[ -n "$RUNBOOK" ]]; then
    echo "The validation can be deployed within 10 days, without running the tests again, once the steps of"
    echo "$RUNBOOK §1 for $ORG and the switch-off checklist in §1.1 are done or not needed:"
  else
    echo "The validation can be deployed within 10 days, without running the tests again:"
  fi
  echo "  sf project deploy quick --job-id $VALIDATION --target-org $ORG"
  [[ -z "$RUNBOOK" ]] || echo "Then the post-deployment steps of §2."
}

check_queue "this validation" || { echo "Stopped: nothing was validated." >&2; exit 1; }

echo "==> Validating $WHAT against $ORG — nothing is written (${#TESTS[@]} test classes)"
VALIDATION="$(cd "$RUN_DIR" && start_job sf project deploy start "${SOURCE_ARGS[@]}" --target-org "$ORG" --dry-run "${TEST_ARGS[@]}")"
echo "Validation $VALIDATION started. To stop it: sf project deploy cancel --job-id $VALIDATION --target-org $ORG"
# The pipeline cancels the validation from this file when the CI platform cancels the job.
[[ -z "$JUNIT_DIR" ]] || { mkdir -p "$JUNIT_DIR"; echo "$VALIDATION" > "$JUNIT_DIR/job-id"; }
follow_job "$VALIDATION"
STATUS="$(job_status "$VALIDATION")"
case "$STATUS" in
  Succeeded) ;;
  Pending | InProgress | Unknown)
    echo "Validation $VALIDATION has not ended, or its status could not be read; this script stops here." >&2
    echo "Follow it with: sf project deploy report --job-id $VALIDATION --target-org $ORG --wait 60" >&2
    deploy_later
    exit 1 ;;
  *) echo "Validation $VALIDATION: $STATUS. Nothing was deployed." >&2; exit 1 ;;
esac

if [[ "$MODE" != "--deploy" ]]; then
  echo "Validation $VALIDATION passed."
  deploy_later
  exit 0
fi

check_queue "the deployment" || { echo "Stopped: nothing was deployed." >&2; deploy_later; exit 1; }
[[ -z "$RUNBOOK" ]] || echo "Before you answer: the steps of $RUNBOOK §1 for $ORG, and the switch-off checklist in §1.1, are done or not needed."
[[ -z "$FEATURE" || -z "$RUNBOOK" ]] || echo "A feature is a partial deployment: the features it depends on (dependsOn in project.config.json) are already in $ORG ($RUNBOOK §4)."
ask "Validation passed. Deploy $WHAT to $ORG for real?" || { echo "Stopped: nothing was deployed." >&2; deploy_later; exit 1; }

echo "==> Deploying validation $VALIDATION to $ORG — its tests are not run again"
DEPLOYMENT="$(start_job sf project deploy quick --job-id "$VALIDATION" --target-org "$ORG")" \
  || { echo "Salesforce refused the quick deploy (above). Nothing was deployed and nothing else is tried." >&2; exit 1; }
echo "Deployment $DEPLOYMENT started. Should this script stop, follow it with: sf project deploy report --job-id $DEPLOYMENT --target-org $ORG --wait 60"
follow_job "$DEPLOYMENT"
STATUS="$(job_status "$DEPLOYMENT")"
case "$STATUS" in
  Succeeded) echo "==> Done.${RUNBOOK:+ Now the post-deployment steps for $ORG: $RUNBOOK §2}" ;;
  Pending | InProgress | Unknown)
    echo "Deployment $DEPLOYMENT has not ended, or its status could not be read. Follow it with" >&2
    echo "sf project deploy report --job-id $DEPLOYMENT --target-org $ORG --wait 60${RUNBOOK:+; once it has succeeded, the post-deployment steps of $RUNBOOK §2}" >&2
    exit 1 ;;
  *) echo "Deployment $DEPLOYMENT: $STATUS. See the result above." >&2; exit 1 ;;
esac
