#!/bin/sh
# Claude Code PreToolUse hook (docs/engineering/development-foundation.md §1.4): metadata reaches the
# default branch only through a merge request. Branch and paths come from project.config.json.
#
# The pre-push hook in .githooks covers `git push`. This covers the ways Claude could go around it:
#  - `git push --no-verify`, or `git -c core.hooksPath=… push`, which skip the pre-push hook;
#  - a GitLab or GitHub MCP server writing files under a protected path straight to the default
#    branch (push_files, create_or_update_file), which never runs a local hook. A GitHub write that
#    names no branch goes to the default branch, so it counts as one.

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')

root="${CLAUDE_PROJECT_DIR:-.}"
config="$root/project.config.json"
branch=main
paths='["force-app/"]'
if [ -f "$config" ]; then
    branch=$(jq -r '.defaultBranch // "main"' "$config")
    paths=$(jq -c '.protectedPaths // ["force-app/"]' "$config")
else
    # Several projects in one repository: each project's protected paths, under its folder.
    configs=$(cd "$root" && find . -name node_modules -prune -o -name project.config.json -print 2>/dev/null | sed 's|^\./||' | sort)
    if [ -n "$configs" ]; then
        first=$(printf '%s\n' "$configs" | head -1)
        branch=$(jq -r '.defaultBranch // "main"' "$root/$first")
        paths=$(for c in $configs; do
            jq -c --arg dir "$(dirname "$c")/" '(.protectedPaths // ["force-app/"]) | map($dir + .)' "$root/$c"
        done | jq -cs 'add')
    fi
fi

# No protected paths anywhere (a practice project): nothing to guard.
[ "$(printf '%s' "$paths" | jq -c '. // []')" != "[]" ] || exit 0

deny() {
    jq -n --arg reason "$1" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
    exit 0
}

push='git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+push([[:space:]]|$)'

case "$tool" in
    Bash)
        cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
        # Each part of a chained command on its own, so a --no-verify on a commit does not count against a push.
        parts=$(printf '%s\n' "$cmd" | awk '{ gsub(/&&|\|\||[;&|]/, "\n"); print }')
        while IFS= read -r part; do
            printf '%s' "$part" | grep -qE "$push" || continue
            if printf '%s' "$part" | grep -qe '--no-verify' || printf '%s' "$part" | grep -q 'core\.hooksPath'; then
                deny "This push skips the pre-push check that keeps protected paths off $branch (docs/engineering/development-foundation.md §1.4). Push without it; if the check stops the push, push a branch and open a merge request."
            fi
        done <<EOF
$parts
EOF
        ;;
    mcp__*gitlab__push_files | mcp__*gitlab__create_or_update_file | mcp__*github__push_files | mcp__*github__create_or_update_file)
        target=$(printf '%s' "$input" | jq -r '.tool_input.branch // ""')
        case "$tool" in
            *gitlab*) [ "$target" = "$branch" ] || exit 0 ;;
            *) [ -z "$target" ] || [ "$target" = "$branch" ] || exit 0 ;;
        esac
        hits=$(printf '%s' "$input" | jq -r --argjson paths "$paths" '
            [.tool_input.file_path, .tool_input.previous_path, .tool_input.path,
             (.tool_input.files // [] | .[] | .file_path, .previous_path, .path)]
            | map(select(. != null) | ltrimstr("/"))
            | map(select(. as $f | any($paths[]; . as $p | $f | startswith($p))))
            | unique | join(", ")')
        if [ -n "$hits" ]; then
            deny "Writing protected paths straight to $branch ($hits). Metadata reaches $branch only through a merge request (docs/engineering/development-foundation.md §1.4): push to a branch and open one."
        fi
        ;;
esac

exit 0
