#!/usr/bin/env bash
# Validates the whole build folder against the CI sandbox with every test class in it — a dry run,
# nothing is written (docs/engineering/development-foundation.md §1.5, docs/engineering/ci-cd.md).
#
#   tools/ci/apex-validate.sh run      log in with SF_CI_AUTH_URL and validate
#   tools/ci/apex-validate.sh cancel   cancel the validation in the org (the job was cancelled)
#
# SF_CI_AUTH_URL is the SFDX auth URL of a sandbox user. The credential is readable from any branch's
# pipeline, so it may only ever sign in to a sandbox: any other org stops the job. SF_CI_DEPLOY_ARGS
# takes the org's own flags for tools/deploy-build.sh, such as --exclude <path>; it is split into words.
set -euo pipefail

alias=$(jq -r '.ciOrgAlias' project.config.json)

# Azure Pipelines passes an undefined variable on as its literal macro, "$(NAME)": treat that as unset.
# shellcheck disable=SC2016 # the literal text "$(", not an expansion
case "${SF_CI_DEPLOY_ARGS:-}" in '$('*) SF_CI_DEPLOY_ARGS="" ;; esac

case "${1:-run}" in
    run)
        : "${SF_CI_AUTH_URL:?SF_CI_AUTH_URL is not set; the Apex validation needs a sandbox to validate against.}"
        auth=$(mktemp)
        printf '%s' "$SF_CI_AUTH_URL" > "$auth"
        sf org login sfdx-url --sfdx-url-file "$auth" --alias "$alias" > /dev/null
        rm -f "$auth"
        sandbox=$(sf data query --target-org "$alias" --json --query 'SELECT IsSandbox FROM Organization' |
            jq -r '.result.records[0].IsSandbox')
        if [ "$sandbox" != "true" ]; then
            echo "SF_CI_AUTH_URL signs in to an org that is not a sandbox: stopped." >&2
            exit 1
        fi
        # shellcheck disable=SC2086 # the flags are meant to split into words
        tools/deploy-build.sh "$alias" --queue --junit reports/apex ${SF_CI_DEPLOY_ARGS:-}
        ;;
    cancel)
        if [ -f reports/apex/job-id ]; then
            sf project deploy cancel --job-id "$(cat reports/apex/job-id)" --target-org "$alias" --async || true
        fi
        ;;
    *)
        echo "usage: tools/ci/apex-validate.sh run|cancel" >&2
        exit 2
        ;;
esac
