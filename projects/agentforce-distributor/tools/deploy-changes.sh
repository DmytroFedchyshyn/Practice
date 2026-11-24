#!/usr/bin/env bash
# While a story is built, deploy only what the branch changes in the build folder to the developer's own
# sandbox (docs/engineering/development-foundation.md §1.3). No test runs unless asked for; the whole
# build, with every test, is tools/deploy-build.sh. The build folder, default branch and runbook come
# from project.config.json.
#
#   tools/deploy-changes.sh                    # to the default org of `sf config`, after a yes; no test
#   tools/deploy-changes.sh <alias>            # to the org named
#   tools/deploy-changes.sh --dry-run          # validate only: nothing is written
#   tools/deploy-changes.sh --tests            # with the tests that cover the change
#   tools/deploy-changes.sh --all-tests        # with every test class of the build folder
#   tools/deploy-changes.sh --from <commit>    # what commits brought since that one: on the default branch, what a pull brought
#
# Changed means changed since the branch left the default branch: its commits, uncommitted edits and new files; with
# --from, only what the commits since that one changed. A deployment with tests is all or nothing: when a test
# fails, nothing is written. Needs sf and jq.
set -euo pipefail

USAGE="usage: tools/deploy-changes.sh [org alias] [--dry-run] [--tests | --all-tests] [--from <commit>]"
ORG=""
DRY_RUN=false
TESTS_WANTED=none
FROM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --tests) TESTS_WANTED=covering ;;
    --all-tests) TESTS_WANTED=all ;;
    --from) [[ $# -ge 2 ]] || { echo "$USAGE" >&2; exit 2; }; FROM="$2"; shift ;;
    -*) echo "$USAGE" >&2; exit 2 ;;
    *) [[ -z "$ORG" ]] || { echo "$USAGE" >&2; exit 2; }; ORG="$1" ;;
  esac
  shift
done
QUEUE_WITHOUT_ASKING=false
JUNIT_DIR=""
cd "$(dirname "$0")/.."
# shellcheck source=SCRIPTDIR/lib/sf-jobs.sh
source tools/lib/sf-jobs.sh
SRC="$(jq -r '.buildDir' project.config.json)"
RUNBOOK="$(jq -r '.runbook // "docs/engineering/release-runbook.md"' project.config.json)"
# A project without a release runbook (a practice project) gets no reminders of its steps.
[[ -f "$RUNBOOK" ]] || RUNBOOK=""
DEFAULT_BRANCH="$(jq -r '.defaultBranch // "main"' project.config.json)"

# Each developer builds in a sandbox of their own: the default org of `sf config` on their machine.
if [[ -z "$ORG" ]]; then
  ORG="$(sf config get target-org --json | jq -r '.result[0].value // empty')"
  [[ -n "$ORG" ]] || { echo "No org named and none set as default: sf config set target-org <your sandbox> --global" >&2; exit 2; }
fi

# Production takes the whole build through a release, never a branch's changes.
org_json="$(sf data query --target-org "$ORG" --json --query "SELECT IsSandbox FROM Organization")" \
  || { echo "Could not read $ORG: $(jq -r '.message // empty' <<<"$org_json")" >&2; exit 1; }
[[ "$(jq -r '.result.records[0].IsSandbox' <<<"$org_json")" == "true" ]] \
  || { echo "$ORG is not a sandbox: this script deploys to a developer's sandbox only" >&2; exit 1; }

# Without --from, the working copy as it is; with it, only what commits brought, as on the default branch after a pull,
# where uncommitted edits are no part of that.
WORKING_COPY=true
if [[ -n "$FROM" ]]; then
  WORKING_COPY=false
  [[ -z "$(git status --porcelain -- "$SRC")" ]] || echo "Uncommitted changes in $SRC are left out: --from deploys what commits brought."
else
  FROM="$(git merge-base "origin/$DEFAULT_BRANCH" HEAD)"
fi
git rev-parse --verify --quiet "$FROM^{commit}" >/dev/null || { echo "Not a commit: $FROM" >&2; exit 2; }
SINCE="$(git rev-parse --short "$FROM")"
RANGE=("$FROM")
[[ "$WORKING_COPY" == true ]] || RANGE+=(HEAD)

CHANGED=()
while IFS= read -r path; do CHANGED+=("$path"); done < <(
  {
    git diff --name-only --no-renames --diff-filter=d "${RANGE[@]}" -- "$SRC"
    [[ "$WORKING_COPY" == false ]] || git ls-files --others --exclude-standard -- "$SRC"
  } | sort -u
)

# A file removed from a bundle that is still there changes the bundle, which is deployed whole. Any other
# deletion would need a destructive deployment, which this script does not make.
DELETED=()
while IFS= read -r path; do
  rel="${path#"$SRC"/}"
  case "$rel" in
    lwc/*/* | aura/*/* | experiences/*/* | staticresources/*/*)
      bundle="${rel#*/}"
      bundle="$SRC/${rel%%/*}/${bundle%%/*}"
      if [[ -d "$bundle" ]]; then CHANGED+=("$bundle"); continue; fi ;;
  esac
  DELETED+=("$path")
done < <(git diff --name-only --no-renames --diff-filter=D "${RANGE[@]}" -- "$SRC")

if [[ ${#DELETED[@]} -gt 0 ]]; then
  echo "Deleted since $SINCE and left in $ORG — delete them there by hand where they must go:"
  printf '  %s\n' "${DELETED[@]}"
fi
[[ ${#CHANGED[@]} -gt 0 ]] || { echo "Nothing else in $SRC changed since $SINCE: nothing to deploy."; exit 0; }

# The labels a change to the labels file touches: those whose entry is in or next to a changed line, or every
# label of a file that is new.
changed_labels() {
  local names
  names="$(git diff -U8 "${RANGE[@]}" -- "$1" | grep -o '<fullName>[^<]*' | sed 's/<fullName>//' || true)"
  [[ -n "$names" ]] || names="$(grep -o '<fullName>[^<]*' "$1" | sed 's/<fullName>//' || true)"
  echo "$names"
}

# The names code uses for a changed file, one per line: a bundle's folder; a custom metadata record's type
# and record; a component of an object, and the object; each label touched; otherwise the file name up to its
# first dot.
component_names() {
  local rel="${1#"$SRC"/}" name object
  name="${rel##*/}"
  case "$rel" in
    lwc/* | aura/* | experiences/* | staticresources/*/*) name="${rel#*/}"; name="${name%%/*}"; echo "${name%%.*}" ;;
    customMetadata/*) echo "${name%%.*}__mdt"; name="${name#*.}"; echo "${name%.md-meta.xml}" ;;
    objects/*/*/*) object="${rel#objects/}"; echo "${object%%/*}"; echo "${name%%.*}" ;;
    labels/*) changed_labels "$1" ;;
    *) echo "${name%%.*}" ;;
  esac
}

# While the build is in active development, a deployment runs no test unless asked for (development-foundation.md §1.3); the
# tests that would cover the change are still found, so the person sees what --tests would run.
# The tests that cover the change: each changed test class, the test class named after each changed
# component, and every test class whose code names one. A trigger is reached through its handler as well.
# A class that much of the build uses, such as the test data factory, brings in most of the tests: they are
# the ones it can break. A test that reaches a change only through another class, and a flow or a rule that no
# test names, are not found: the names no test uses are listed, and the full validation covers the rest.
TEST_FILES=()
while IFS= read -r path; do TEST_FILES+=("$path"); done < <(find "$SRC" -name '*Test.cls' | sort)
TESTS=()
UNTESTED=()
if [[ "$TESTS_WANTED" == all ]]; then
  for path in "${TEST_FILES[@]}"; do TESTS+=("$(basename "$path" .cls)"); done
else
  NAMES=()
  for path in "${CHANGED[@]}"; do
    case "${path#"$SRC"/}" in lwc/* | aura/* | experiences/* | staticresources/*) continue ;; esac
    while IFS= read -r name; do [[ -z "$name" ]] || NAMES+=("$name"); done < <(component_names "$path")
    [[ "$path" != *.trigger && "$path" != *.trigger-meta.xml ]] || NAMES+=("$(component_names "$path")Handler")
  done
  if [[ ${#NAMES[@]} -gt 0 ]]; then
    while IFS= read -r name; do TESTS+=("$name"); done < <(
      for name in "${NAMES[@]}"; do
        [[ "$name" != *Test || ! -f "$SRC/classes/$name.cls" ]] || echo "$name"
        [[ ! -f "$SRC/classes/${name}Test.cls" ]] || echo "${name}Test"
        grep -lw -e "$name" -- "${TEST_FILES[@]}" 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.cls$//' || true
      done | sort -u
    )
    for name in "${NAMES[@]}"; do
      [[ "$name" == *Test || -f "$SRC/classes/${name}Test.cls" ]] && continue
      grep -qlw -e "$name" -- "${TEST_FILES[@]}" 2>/dev/null || UNTESTED+=("$name")
    done
  fi
fi

# A test class that the default branch brought and the org has not taken yet cannot run there: it is left out, and named.
if [[ "$TESTS_WANTED" != none && ${#TESTS[@]} -gt 0 ]]; then
  in_list="$(printf "'%s'," "${TESTS[@]}")"
  if org_tests="$(sf data query --target-org "$ORG" --json --query "SELECT Name FROM ApexClass WHERE NamespacePrefix = null AND Name IN (${in_list%,})" | jq -r '.result.records[].Name')"; then
    KEPT=()
    MISSING=()
    for t in "${TESTS[@]}"; do
      if grep -qx -- "$t" <<<"$org_tests" || printf '%s\n' "${CHANGED[@]}" | grep -qx -- "$SRC/classes/$t.cls"; then KEPT+=("$t"); else MISSING+=("$t"); fi
    done
    [[ ${#MISSING[@]} -eq 0 ]] || echo "Not in $ORG yet, so left out: ${MISSING[*]}"
    TESTS=(${KEPT[@]+"${KEPT[@]}"})
  else
    echo "Could not read the test classes in $ORG; every test found is named." >&2
  fi
fi

SOURCE_ARGS=()
for path in "${CHANGED[@]}"; do SOURCE_ARGS+=(--source-dir "$path"); done
TEST_ARGS=(--test-level NoTestRun)
if [[ "$TESTS_WANTED" != none && ${#TESTS[@]} -gt 0 ]]; then
  TEST_ARGS=(--test-level RunSpecifiedTests)
  for t in "${TESTS[@]}"; do TEST_ARGS+=(--tests "$t"); done
fi

echo "==> ${#CHANGED[@]} files of $SRC changed since $SINCE, for $ORG:"
printf '  %s\n' "${CHANGED[@]}"
if [[ "$TESTS_WANTED" == none ]]; then
  echo "    with no test, as none was asked for; --tests would run ${#TESTS[@]} test classes"
elif [[ ${#TESTS[@]} -gt 0 ]]; then
  echo "    with ${#TESTS[@]} test classes: ${TESTS[*]}"
else
  echo "    with no test: none names what changed (--all-tests runs every one)"
fi
if [[ "$TESTS_WANTED" == covering && ${#UNTESTED[@]} -gt 0 ]]; then
  echo "    named by no test: ${UNTESTED[*]}"
fi

# Steps the metadata cannot carry are in the release runbook, by file.
IN_RUNBOOK=()
[[ -z "$RUNBOOK" ]] || for path in "${CHANGED[@]}"; do
  base="${path##*/}"
  ! grep -qF -- "${base%-meta.xml}" "$RUNBOOK" || IN_RUNBOOK+=("$path")
done
if [[ ${#IN_RUNBOOK[@]} -gt 0 ]]; then
  echo "    $RUNBOOK has steps for: ${IN_RUNBOOK[*]}"
fi

check_queue "this job" || { echo "Stopped: nothing was written." >&2; exit 1; }
if [[ "$DRY_RUN" == true ]]; then
  KIND="Validation"
  JOB="$(start_job sf project deploy start "${SOURCE_ARGS[@]}" --target-org "$ORG" --dry-run "${TEST_ARGS[@]}")"
else
  [[ -z "$RUNBOOK" ]] || echo "Before you answer: the steps of $RUNBOOK §1 that these files need in $ORG are done or not needed."
  ask "Deploy them to $ORG?" || { echo "Stopped: nothing was written." >&2; exit 1; }
  KIND="Deployment"
  JOB="$(start_job sf project deploy start "${SOURCE_ARGS[@]}" --target-org "$ORG" "${TEST_ARGS[@]}")"
fi
echo "$KIND $JOB started. To stop it: sf project deploy cancel --job-id $JOB --target-org $ORG"
follow_job "$JOB"
STATUS="$(job_status "$JOB")"
case "$STATUS" in
  Succeeded)
    echo "==> $KIND $JOB passed."
    [[ "$KIND" != Deployment || -z "$RUNBOOK" ]] || echo "Now the steps of $RUNBOOK §2 that these files need in $ORG." ;;
  Pending | InProgress | Unknown)
    echo "$KIND $JOB has not ended, or its status could not be read. Follow it with" >&2
    echo "sf project deploy report --job-id $JOB --target-org $ORG --wait 60" >&2
    exit 1 ;;
  *) echo "$KIND $JOB: $STATUS. Nothing was written." >&2; exit 1 ;;
esac
