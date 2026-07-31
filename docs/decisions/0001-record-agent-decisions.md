---
id: 0001
timestamp: 2026-07-31T08:41:32Z
agent: Codex
model: "GPT-5 Codex (exact model ID unavailable)"
trigger: /re-entry init
status: executed
---

# AgDR-0001: Record agent decisions

In the context of a multi-session agent-driven project, facing the risk of repeated dead-ends and undocumented reasoning, I decided to adopt the Agent Decision Record (AgDR) format to achieve durable, queryable decision history, accepting the overhead of writing one document per significant decision.

## Context

This project will be worked on by Codex and possibly other agents across many sessions. Without durable decision records, each session re-derives the same trade-offs.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| Inline decisions in commit messages | Cheap, always present | Hard to query; no structured metadata |
| ADRs in `docs/adr/` | Established format | Designed for humans; lacks agent metadata |
| AgDRs in `docs/decisions/` | Required metadata, Y-statement body | Slightly more overhead |

## Decision

Use AgDR format with YAML frontmatter (`id`, `timestamp`, `agent`, `model`, `trigger`, `status`) and a Y-statement opening.

## Consequences

- Easier: replaying why a decision was made, even months later
- Easier: detecting when a decision has been superseded
- Harder: writing one AgDR per significant choice adds slight ceremony
- Revisit: if AgDRs are not being written, downgrade to plain inline notes in `docs/PROGRESS.md`
