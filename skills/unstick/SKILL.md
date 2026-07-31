---
name: unstick
description: "Use after two corrections of the same issue fail or the work is looping. Freeze edits, expose the repeated assumption, and present three genuinely different pivots before continuing."
---

# Unstick

Pause execution. The next useful output is a reset memo, not another attempt.

## Reset memo

Write:

1. the intended outcome and current observable failure;
2. a table of attempts, evidence produced, and why each failed;
3. the assumption shared by those attempts;
4. state that may have been contaminated by partial edits or stale context;
5. three pivots that change different fundamentals, such as:
   - use a different source of truth;
   - test at a different boundary;
   - remove or replace the disputed mechanism.

Each pivot must name its first falsifiable check, likely cost, and rollback
point. Cosmetic variations of the same command are one approach, not three.

Do not execute a pivot until the user chooses one, unless prior instructions
already establish a clear preferred direction. If context itself is
unreliable, recommend a fresh session with this memo as the handoff.

## Provenance

This condensed Zulfiqar workflow is an independent reimplementation inspired
by the stop-and-change-strategy pattern in
[obra/superpowers](https://github.com/obra/superpowers). It does not reproduce
the upstream skill text. See `THIRD-PARTY-NOTICES.md`.
