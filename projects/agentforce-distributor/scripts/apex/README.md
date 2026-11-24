# scripts/apex

One-off anonymous Apex for diagnosis and data fixes, run with `sf apex run --file <script> --target-org <alias>`.

- A script that only reads (queries, `System.debug`) may be run in any org the person names.
- A script that writes is a data change: it is shown to the person and run only after their yes
  (the Claude hook asks for every `sf apex run`).
- Never commit a script that holds client data, record IDs or personal data in its text, nor its
  output. Keep such scripts and their results outside the repository.
- A script that stays useful gets a header comment: what it checks or changes, and whether it writes.
