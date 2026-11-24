#!/usr/bin/env bash
# Metadata reaches the default branch only through a merge request
# (docs/engineering/development-foundation.md §1.4). The pre-push hook stops a direct push locally;
# this catches one that got past it (--no-verify, a copy without the hook) and turns the pipeline on
# the default branch red. It cannot undo the push: whoever sees it red reverts it or opens the merge
# request after the fact.
#
#   tools/ci/force-app-via-mr.sh <before-sha> <after-sha>
#
# Needs the full history (fetch depth 0). Paths come from project.config.json protectedPaths.
set -euo pipefail

before=${1:-}
after=${2:?usage: tools/ci/force-app-via-mr.sh <before-sha> <after-sha>}
if [ -z "$before" ] || [ "$before" = "0000000000000000000000000000000000000000" ]; then
    echo "No previous commit to compare with; nothing to check."
    exit 0
fi

read -r -a paths <<< "$(node -p '(require("./project.config.json").protectedPaths || ["force-app/"]).join(" ")')"

# Commits that came through a merge request sit behind its merge commit; anything on the first-parent
# line that is not a merge was pushed directly.
direct=$(git rev-list --first-parent --no-merges "$before..$after" -- "${paths[@]}")
if [ -z "$direct" ]; then
    echo "No direct push changed ${paths[*]}."
    exit 0
fi
echo "Pushed straight to the default branch with changes under ${paths[*]} (docs/engineering/development-foundation.md §1.4):"
for c in $direct; do
    git log -1 --format='  %h %an: %s' "$c"
    git diff-tree --no-commit-id --name-only -r "$c" -- "${paths[@]}" | sed -n '1,5s/^/      /p'
done
exit 1
