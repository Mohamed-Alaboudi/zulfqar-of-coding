---
id: 0002
timestamp: 2026-07-31T08:59:51Z
agent: Codex
model: "GPT-5 Codex (exact model ID unavailable)"
trigger: local Codex and Claude skill import
status: executed
---

# AgDR-0002: Separate default and optional skills

In the context of importing the local Codex, Claude Code, and shared skill
inventories into a public repository, facing duplicate variants, an 8,000
character default discovery budget, private integrations, and third-party
license boundaries, I decided to use one catalog-backed default/optional/
pointer model to represent every observed item without treating the
repository as a home-directory backup.

## Context

The reviewed inventories contain default-worthy portable skills, useful
first-party workflows with narrow triggers, duplicate Claude/Codex variants,
runtime-managed system skills, local backups, private integrations, and
third-party or proprietary packages. Loading every redistributable body from
`skills/` would exceed the existing discovery budget and make specialized
workflows fire by default.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| Copy every local directory | Literal snapshot | Publishes private/runtime state, duplicates concepts, violates third-party boundaries, exceeds discovery budget |
| Keep only the existing curated set | Small and simple | Fails to account for useful local work and excluded items |
| Catalog plus default and optional trees | Complete public accounting, explicit collisions, bounded default payload | Adds a ledger and one validation contract |

## Decision

Keep the reviewed default set under `skills/`. Put additional portable,
first-party bodies under `optional-skills/`, outside plugin and installer
discovery. Record every observed installation in `catalog/skills.tsv` as a
default, optional, upstream pointer, superseded variant, or explicit
exclusion. Permit exactly one public body owner per concept and validate its
path and SHA-256 hash.

Third-party bodies remain upstream pointers. Runtime-managed skills, backups,
the disabled watcher, host-bound workflows, and private messaging integration
remain explicit exclusions. Harness-specific aliases are consolidated under
capability names instead of publishing parallel Claude/Codex copies.

## Consequences

- Easier: audit what was found, what ships, and why something does not ship.
- Easier: preserve a lean default trigger payload while publishing useful
  opt-ins.
- Easier: prevent duplicate owners, stale hashes, and untracked skill bodies
  with one runnable validator.
- Harder: optional skills require deliberate per-skill installation.
- Harder: source changes require refreshing the catalog fingerprint.
- Revisit: promote an optional skill to default only when usage evidence
  justifies its discovery-budget cost.
