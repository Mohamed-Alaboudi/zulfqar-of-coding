---
name: delegating-work
description: "Route substantial independent implementation, investigation, audit, or research work into bounded low-cost readers, Terra workers, or Sol advisors/verifiers and integrate centrally. Use when two or more independent slices reduce wall-clock time or isolate noisy context, or when consequential work needs a fresh verifier. Not for tiny, serial, or overlapping-write tasks."
---

# Delegating work

Use this speed doctrine:

> Three lanes maximum per wave, one root integrator, depth one, and fresh context for bounded workers.

Use the smallest useful fan-out. The root remains the user-facing owner, decision-maker, and integrator.

## Route by work shape

- `luna-reader`: deterministic read-only extraction, classification, comparison, inventory, or transformation.
- `finder`: exact locations and usages.
- `explorer`: code-path or architecture understanding.
- `worker-light`: spec-closed implementation whose approach is already decided.
- `sol-advisor`: one consequential architecture, security, privacy, permission, data, money, concurrency, or release decision.
- `worker-deep`: bounded implementation that still requires significant judgment.
- `verifier`: falsification of a load-bearing completion claim or high-risk integrated change.

Read [references/routing.md](references/routing.md) when escalation is unclear. Read [references/contracts.md](references/contracts.md) when a durable evidence or result packet will reduce context.

## Delegation gate

Delegate only when the lane has a concrete objective, bounded scope, one owner, a deliverable, an acceptance check, and independence from unfinished work elsewhere. Keep short lookups, ordered chains, architecture decisions, shared interfaces, and overlapping writes in the root.

Use no more than three concurrent lanes. Workers never delegate. Prefer fresh/minimal context for research, review, and closed implementation packets.

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

Do not delegate further. Preserve unrelated changes. Stop when scope is insufficient.
```

## Integration

Inspect every result and diff. Do not treat a worker's success statement as proof. Run lane-local checks in the lane and one broad integration check in the root. Permit only one writer per path or worktree.

Use a fresh read-only Sol advisor or verifier for authentication, authorization, privacy, permissions, money, destructive operations, data loss, migrations, concurrency, public contracts, and release-critical behavior.

Escalate Luna to Terra for diagnosis, planning, semantic reasoning, or failed validation. Escalate Terra to Sol for high-blast-radius judgment, conflicting evidence, difficult reversibility, or two focused unclear failures. Escalate once with the smallest relevant evidence.
