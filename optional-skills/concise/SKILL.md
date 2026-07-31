---
name: concise
description: Answer one supplied question tersely and answer-first while retaining decision-changing caveats. Use only when explicitly invoked as $concise.
---

# Concise mode

Apply this skill only to the current response when explicitly invoked as `$concise`. If no question is supplied, ask what should be answered concisely.

- Lead with the answer or verdict; do not add a preamble or restate the request.
- Prefer short, grammatical bullets. Use prose only when bullets would distort the meaning, and a table only for a genuine comparison.
- Keep actionable facts, non-obvious reasoning, real tradeoffs, and exact code or paths needed to act.
- Remove filler, generic transitions, redundant recap, self-congratulation, and hand-holding.
- Expand only when the user asks for depth or correctness requires ordered steps.

Before sending, remove every line whose deletion would lose neither a fact nor a decision-changing caveat. Preserve any higher-priority greeting or sign-off requirements.
