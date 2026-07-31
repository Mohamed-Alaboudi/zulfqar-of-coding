---
name: delegating-work
description: "Route substantial independent implementation, investigation, audit, or research work into bounded readers, workers, advisors, or verifiers and integrate centrally. Use when two or more independent slices reduce wall-clock time or isolate noisy context, or when consequential work needs a fresh verifier. Not for tiny tasks, tightly coupled serial work, overlapping edits, or when user or project instructions forbid delegation."
---

# Delegating work

Use this speed doctrine for substantial work:

> Three lanes maximum per wave, one root integrator, depth one, checkpoint before 75% context, and a fresh session after each major verified milestone.

Use the smallest useful fan-out. The root remains the user-facing owner, decision-maker, and integrator.

## Route by work shape

- Use a deterministic reader for read-only extraction, classification, comparison, inventory, or transformation.
- Use a finder for exact locations and an explorer for code-path or architecture understanding.
- Use a light worker for spec-closed implementation whose approach and acceptance check are already decided.
- Use an advisor for one consequential architecture, security, privacy, permission, data, money, concurrency, or release decision.
- Use a deep worker only when a bounded implementation itself still requires significant judgment.
- Use a verifier to falsify a load-bearing completion claim or high-risk integrated change.

Map those work shapes to the agents and model tiers the current harness actually exposes. Read [references/routing.md](references/routing.md) when escalation is unclear. Read [references/contracts.md](references/contracts.md) when a durable evidence or result packet will reduce context.

## Delegation gate

Delegate only when the lane has a concrete objective, bounded scope, one owner, a deliverable, an acceptance check, independence from unfinished work elsewhere, and enough work to repay dispatch and integration cost. Keep short lookups, ordered chains, architecture decisions, shared interfaces, and overlapping writes in the root.

Use no more than three concurrent lanes. Workers never delegate. Prefer fresh, minimal context for research, review, and closed implementation packets. Assign one writer per path and serialize overlapping scopes.

## Packet

```text
OBJECTIVE
<one bounded result>

SCOPE
Read: <paths or sources>
Write: <exclusive paths, or none>
Out of scope: <explicit exclusions>

CONSTRAINTS
<binding rules and interfaces>

DELIVERABLE
<changed files or concise cited evidence>

ACCEPTANCE
<focused command or falsifiable done condition>

Do not delegate further. Preserve unrelated changes. Stop and report when scope or authority is insufficient.
```

## Dispatch and integration

- Launch only lanes that can run concurrently; do not create workers merely to fill slots.
- Keep shared interfaces, dependent chains, broad verification, and final acceptance with the root.
- Continue useful root work while lanes run, but do not edit a worker's owned paths.
- If a worker is blocked, change scope, context, sequencing, or approach before retrying.

Inspect every result and diff. Do not treat a worker's success statement as proof. Run lane-local checks in the lane and one broad integration check in the root. Permit only one writer per path or worktree.

Use a fresh read-only Sol advisor or verifier for authentication, authorization, privacy, permissions, money, destructive operations, data loss, migrations, concurrency, public contracts, and release-critical behavior.

Escalate Luna to Terra for diagnosis, planning, semantic reasoning, or failed validation. Escalate Terra to Sol for high-blast-radius judgment, conflicting evidence, difficult reversibility, or two focused unclear failures. Escalate once with the smallest relevant evidence.

## Checkpoint

At or before 75% context utilization, stop expanding scope and write a compact handoff with decisions, evidence, changed paths, verification status, remaining work, and one exact next action. Treat each major verified milestone as a session boundary instead of repeatedly resuming an oversized thread.
