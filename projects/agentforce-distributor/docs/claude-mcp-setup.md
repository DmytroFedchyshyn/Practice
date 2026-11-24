# Connecting Claude to the repository host, the tracker and test management (Mac setup)

With the repository on GitHub and its issues as the tracker, Claude reaches both through the GitHub
CLI: install `gh`, run `gh auth login` once, and add the `project` scope (`gh auth refresh -s project`)
if a GitHub project holds the statuses. The GitHub MCP server is an alternative to the CLI; the
protected-path guard in `.claude/hooks/` covers its writes. The rest of this page is for a
self-hosted repository host and Jira, and does not apply.
