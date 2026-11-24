# manifest/

- `features/<slug>.xml` — one package.xml per feature, written by `tools/feature-manifests.py` from the
  `features` list in `project.config.json`. Never edited by hand: change `features`, run the script,
  and commit both in the same merge request (docs/engineering/development-foundation.md §1.4).
- `tools/feature-manifests.py --check` fails when a manifest is stale, or when a component of the build
  folder matches no feature or more than one.
