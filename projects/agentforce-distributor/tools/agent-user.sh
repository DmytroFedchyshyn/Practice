#!/usr/bin/env bash
# The agent user's username goes into an agent's Agent Script (access: default_agent_user), and the repository is
# public, so the .agent files in Git hold the placeholder AGENT_USER instead. This script swaps it for the real
# username, read from AGENT_USER in the environment or in this project's .env (never committed), and back.
#
#   tools/agent-user.sh fill               # placeholder -> username, before a deploy, validate or publish
#   tools/agent-user.sh strip              # username -> placeholder, after a retrieve and before a commit
#   tools/agent-user.sh run <command...>   # fill, run the command, strip again even when it fails
#
# A gitleaks rule in .gitleaks.toml stops a commit of an .agent file that still holds a username.
set -euo pipefail
cd "$(dirname "$0")/.."

PLACEHOLDER=AGENT_USER
files=$(find force-app -path '*/aiAuthoringBundles/*' -name '*.agent' 2>/dev/null || true)

username() {
    local value="${AGENT_USER:-}"
    if [[ -z "$value" && -f .env ]]; then
        value=$(sed -n 's/^AGENT_USER=//p' .env | head -1)
    fi
    [[ -n "$value" ]] || { echo "Set AGENT_USER in the environment or in .env (see .env.example)." >&2; exit 2; }
    printf '%s' "$value"
}

fill() {
    local user
    user=$(username)
    for f in $files; do
        sed -i.bak "s|default_agent_user: \"$PLACEHOLDER\"|default_agent_user: \"$user\"|" "$f" && rm -f "$f.bak"
    done
}

strip() {
    for f in $files; do
        sed -i.bak -E "s|default_agent_user: \"[^\"]*@[^\"]*\"|default_agent_user: \"$PLACEHOLDER\"|" "$f" && rm -f "$f.bak"
    done
}

case "${1:-}" in
    fill) fill ;;
    strip) strip ;;
    run)
        shift
        [[ $# -gt 0 ]] || { echo "usage: tools/agent-user.sh run <command...>" >&2; exit 2; }
        fill
        trap strip EXIT
        "$@"
        ;;
    *) echo "usage: tools/agent-user.sh fill | strip | run <command...>" >&2; exit 2 ;;
esac
