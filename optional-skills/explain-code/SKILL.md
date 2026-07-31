---
name: explain-code
description: Teach a code path, diff, architecture, bug fix, or technical concept using grounded evidence and a concise mental model.
---

# Explain code

Use this skill when the user wants to understand what code does, why a change was made, how data or control flows, or requests a learning-oriented walkthrough. Do not use it merely to summarize files, write repository documentation, or make an adoption decision.

Teach one thing well and ground repository explanations in the actual diff, call sites, tests, and project vocabulary. Label external or model-only claims that are not verified.

1. State the outcome first.
2. Give the smallest useful mental model: entry point, transformation, side effects, and exit condition.
3. Walk one concrete example through real code with path-and-line references.
4. Explain the non-obvious constraint or tradeoff shaping the implementation.
5. Close with the failure mode or invariant worth remembering.

Use a compact flow or table only when it materially clarifies the relationships. For difficult material, offer a brief prediction check before revealing the explanation; for simple requests, explain directly. When useful, end with one transfer question and correct it using evidence.
