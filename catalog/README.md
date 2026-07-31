# Skill catalog

[`skills.tsv`](skills.tsv) is the accounting ledger for the local Codex,
Claude Code, and shared skill inventories reviewed on 2026-07-31.

It records every observed installation as one of:

- `default`: a reviewed body shipped in `skills/` and installed by default;
- `optional`: a reviewed body shipped in `optional-skills/` for manual opt-in;
- `pointer`: a third-party body represented by an attributed upstream pointer;
- `superseded`: a duplicate or harness-specific variant consolidated into a
  reviewed repository concept; or
- `excluded`: a backup, runtime-managed, private, disabled, or non-portable
  item that must not be published.

The `sha256` field fingerprints the reviewed body or observed local variant.
It is not a download address and does not make an excluded body recoverable.
`canonical_path` is present only when this repository owns the public body.
Repository-body hashes are recomputed by the validator. Local-source hashes
record the `SKILL.md` bytes observed on the audit date; a public clone cannot
recompute them because the source home directories are intentionally absent.

Run:

```bash
bash scripts/validate-skill-catalog.sh
```

The validator checks the schema, unique body ownership, hashes, provenance
pointers, default manifest, and both public skill trees.
