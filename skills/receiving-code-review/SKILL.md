---
name: receiving-code-review
description: "Use before acting on code-review feedback or PR comments: verify each suggestion technically, implement valid findings, and push back on incorrect ones. Not for producing a review."
---

# Receiving Code Review

Treat review comments as claims to test against the repository, not as patches
to apply automatically.

## Intake

Read the complete review before changing anything. Build a small ledger:

| Comment | Claimed problem | Evidence needed | Verdict | Action |
|---|---|---|---|---|

Group comments that share a root cause so one correction does not fight
another.

## Evaluate each comment

1. Locate the named code and its callers.
2. Reproduce the behavior or inspect the contract the comment relies on.
3. Check project instructions, compatibility promises, and tests.
4. Classify the comment:
   - **valid** — evidence confirms the problem;
   - **partly valid** — the concern is real but the proposed change is wrong;
   - **unsupported** — repository evidence contradicts it;
   - **unclear** — a missing decision prevents a safe conclusion.
5. Record the evidence and chosen response.

Ask for clarification only when the missing information changes the solution.
For unsupported feedback, reply with the concrete contract, test, or caller
that disproves it and offer the smallest valid alternative when one exists.

## Apply accepted findings

- Fix the shared cause, not each visible instance.
- Order work by security/data-loss risk, then correctness, then cleanup.
- Keep unrelated improvements out of the review diff.
- Add or update a runnable check for non-trivial behavior.
- Verify each coherent correction before starting the next.

## Close the loop

For every comment, report one of: fixed with evidence, superseded by a shared
fix, declined with evidence, or awaiting a named decision. Reply in the
original review thread when the platform supports it.

## Provenance

This condensed Zulfiqar workflow is an independent reimplementation inspired
by the verify-before-accepting-review pattern in
[obra/superpowers](https://github.com/obra/superpowers). It does not reproduce
the upstream skill text. See `THIRD-PARTY-NOTICES.md`.
