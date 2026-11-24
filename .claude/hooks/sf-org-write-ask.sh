#!/bin/sh
# Claude Code PreToolUse hook (CLAUDE.md §3): any command that writes to a Salesforce org asks the
# person first. Read-only work (validate, --dry-run, retrieve, describe, query) runs without asking.
#
# The command is split into its parts at ; & | && || and line breaks, and each part is checked on its
# own, so a deploy chained after `cd x &&` is caught, and a --dry-run in one part does not let a write
# in another part through. A part is a write when it calls `sf` or `sfdx` — after a path, `npx`, `env`,
# `time` or a quote, as in `bash -c "sf …"` — with one of the commands below.
# The kit's deploy scripts ask on their own and refuse to deploy without a terminal.

cmd=$(jq -r '.tool_input.command // ""')

# sf: the command's words after `sf`. Legacy colon commands (sfdx force:source:deploy) are listed too.
sf_call='(^|[[:space:]"'"'"'/(])(sf|sfdx)[[:space:]]+'
writes='(project[[:space:]]+deploy[[:space:]]+(start|quick|resume)|project[[:space:]]+delete[[:space:]]+source|force[[:space:]]+source[[:space:]]+(deploy|push)|force:source:(deploy|push|delete)|force:mdapi:deploy|data[[:space:]]+(create|update|upsert|delete|import)|force:data:(record|tree|bulk):(create|update|upsert|delete|import)|apex[[:space:]]+run|force:apex:execute|org[[:space:]]+assign[[:space:]]+perm|force:user:permset:assign|org[[:space:]]+(create|delete)|agent[[:space:]]+(create|publish|activate|deactivate)|agent[[:space:]]+test[[:space:]]+(create|run)|package[[:space:]]+(install|uninstall)|community[[:space:]]+(create|publish))'
# A REST or GraphQL call through the CLI writes when it names a method other than GET, or sends a mutation.
api='api[[:space:]]+request[[:space:]]+(rest|graphql)'
api_write='(--method|-X)[[:space:]=]+(POST|PUT|PATCH|DELETE)|mutation'

found=""
parts=$(printf '%s\n' "$cmd" | awk '{ gsub(/&&|\|\||[;&|]/, "\n"); print }')
while IFS= read -r part; do
    if printf '%s' "$part" | grep -qE "$sf_call$writes"; then
        # Running Apex tests writes nothing that stays; the other matches do.
        printf '%s' "$part" | grep -qE "$sf_call"'apex[[:space:]]+run[[:space:]]+test' && continue
        printf '%s' "$part" | grep -qe '--dry-run' && continue
        found=1
    elif printf '%s' "$part" | grep -qE "$sf_call$api" && printf '%s' "$part" | grep -qiE "$api_write"; then
        found=1
    fi
done <<EOF
$parts
EOF

if [ -n "$found" ]; then
    printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Writes to a Salesforce org. Claude must have the explicit permission of the person before deploying, publishing an agent or writing data."}}'
fi
exit 0
