# config/

- `orgs.example.json` — the org registry for the fleet deploy (docs/engineering/ci-cd.md, *Fleet deploy*).
  Copy it to `orgs.json` when the project deploys the same build to several orgs. Aliases and group
  names only: usernames, instance URLs and keys live in the CI platform's secrets, never here.
- `overlays/<alias>/package.xml` — optional: an org whose manifest differs from the base one. An overlay
  replaces the base manifest for that org (no merging) and keeps its API version.
