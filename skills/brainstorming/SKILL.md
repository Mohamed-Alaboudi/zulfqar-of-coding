---
name: brainstorming
description: "Use before creative implementation to turn an uncertain request into an approved design. Not for prompt writing, mechanical edits, or requirements already fixed by an accepted specification."
---

# Brainstorming

Convert an idea into a decision that is specific enough to plan and test.

## Gate

Do not implement while a decision-changing product or design question remains
open. End this skill with an approved design or an explicit decision to defer.

## Workflow

1. Read the nearest instructions, relevant code, existing decisions, and recent
   changes. Summarize the current constraint in a few sentences.
2. Separate the request into:
   - desired outcome;
   - non-goals;
   - known constraints;
   - unknowns that could change the solution.
3. If the idea contains independent products or subsystems, split it before
   designing. Work on one coherent slice at a time.
4. Ask one decision-changing question at a time. Prefer a short set of
   mutually exclusive answers when that helps the user choose.
5. When the problem is understood, compare two or three viable approaches.
   Recommend one and identify its most important cost.
6. Present the proposed design at the level the work needs:
   - responsibilities and boundaries;
   - inputs, outputs, and state;
   - failure behavior and recovery;
   - security and accessibility constraints;
   - checks that demonstrate success;
   - rollout or compatibility concerns.
7. Resolve objections and record the accepted design under
   `docs/decisions/` unless the repository specifies another location.
8. Review the written design for placeholders, contradictions, ambiguous
   terms, and requirements without acceptance checks.
9. Ask the user to approve the written design. After approval, hand the result
   to `writing-plans`.

## Visual questions

Offer a mockup or diagram only when spatial layout, hierarchy, or a state
transition is materially easier to judge visually. Keep conceptual choices in
text.

## Output

Return the decision, the rejected alternatives and why, unresolved risks, the
design-document path, and the exact next planning action.

## Provenance

This condensed Zulfiqar workflow is an independent reimplementation inspired
by the design-before-coding pattern in
[obra/superpowers](https://github.com/obra/superpowers). It does not reproduce
the upstream skill text. See `THIRD-PARTY-NOTICES.md`.
