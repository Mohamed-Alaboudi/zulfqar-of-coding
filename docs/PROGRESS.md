# Progress log

Append-only. Most recent first. Date stamps as `## YYYY-MM-DD`.
Never edit past entries — supersede with a new one if facts change.
This is portable long-term memory: track failed approaches so future sessions don't re-attempt them.

---

## 2026-07-31
- Initialized the missing project-memory structure via `/re-entry init`.
- Decisions: [`docs/decisions/0001-record-agent-decisions.md`](decisions/0001-record-agent-decisions.md)
- Dead-ends: None.
- Reconciled 136 observed Codex, Claude Code, shared, system, and backup skill entries into 20 reviewed defaults, 22 manual opt-ins, 58 attributed pointer records, 67 superseded variants, and 11 explicit exclusions.
- Added the catalog validator, portable skill-evaluation bundle, optional-skill routing docs, provenance boundaries, and a Python-enabled Dev Container.
- Renamed the public source, plugin metadata, and documentation to Zulfiqar while preserving the legacy installer marker and timeout variable as compatibility inputs.
- Hardened the secret scanner against SHA-256 and timestamped-backup false positives without suppressing its synthetic card-number detection.
- Verification: `bash tests/run.sh` passed in the Dev Container; the default skill budget passed at 6,528 / 8,000 characters with the expected warning above 6,400.
- Decisions: [`docs/decisions/0002-separate-default-and-optional-skills.md`](decisions/0002-separate-default-and-optional-skills.md)
- Dead-ends: a static-only skill-eval fallback masked missing Python and was removed after the Dev Container supplied the runtime; raw scratch inventories were consolidated into the public-safe catalog and deleted.
- Adversarial review replaced six Superpowers-derived defaults and the copied
  Stop Slop bundle with independent condensed workflows, removed their copied
  helpers, pinned upstream provenance, and corrected all 29 stale Claude
  fingerprints.
- Final evidence: the independent reviewer passed the full Dev Container suite
  3 / 3 times; all 134 live source fingerprints matched; scanner adversarial
  cases passed; the root suite passed; and the final default discovery payload
  fell to 5,682 / 8,000 characters.
