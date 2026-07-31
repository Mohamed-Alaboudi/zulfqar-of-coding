---
name: ultrathink
description: "Analyze a difficult decision at maximum depth without edits, delegation, or external side effects. Use only when explicitly invoked as $ultrathink."
---

# Ultrathink

Use the current root agent as the sole decision maker. Do not delegate, edit files, commit, push, deploy, send messages, or cause other external side effects.

A skill cannot raise the native reasoning effort of an already-running session. Start the session at the desired maximum effort before invoking this skill.

1. Frame the exact question.
2. Separate verified facts, assumptions, and unknowns.
3. Identify assumptions that would change the answer.
4. Inspect relevant local evidence and current authoritative sources when needed.
5. Decompose the problem into the smallest decision-relevant parts.
6. Steelman the leading answer and its strongest alternative.
7. Make one recommendation with confidence, non-obvious trade-offs, and the evidence that would change it.

Return a concise decision rationale, not private chain-of-thought. Do not claim maximum native effort merely because this skill was invoked.
