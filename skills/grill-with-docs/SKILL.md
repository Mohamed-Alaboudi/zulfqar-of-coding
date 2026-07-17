---
name: grill-with-docs
description: A relentless requirements interview that sharpens a plan or design by attacking its weak points, and produces docs (decision records, a glossary) as it goes so the plan is grounded rather than assumed.
---

# Grill With Docs

A requirements interview that treats the user's stated plan or design the way a skeptical senior engineer would in a design review: not hostile, but relentlessly unwilling to let a vague term, an unexamined assumption, or a hand-waved edge case pass without being pinned down. Where `brainstorming` explores an idea from a blank page, this skill takes an idea that already has some shape and stress-tests it — the input is a rough plan, not a rough hunch.

Two things distinguish this from an ordinary Q&A session:

1. **It's adversarial toward the plan, not the user.** The interviewer's job is to find the plan's weak points before reality does — ambiguous terms, silent assumptions, missing failure paths, contradictions between stated goals. Every hard question is in service of a better plan, never a test of the user.
2. **It produces artifacts as it goes**, not just at the end. Every term that gets defined goes into a running glossary. Every real decision (not every answer — every point where a genuine choice got made between alternatives) gets its own short decision record. By the end of the interview, the docs exist; there's no separate "now write it up" step.

## When to Use

Use this when a plan or design already has rough shape and needs pressure-testing before it goes to `writing-plans` — the requirements are murky enough that writing a plan against them now would just encode the murkiness into code later. Prefer `brainstorming` when there's no plan yet, just an idea or a problem to explore from scratch.

## The Interview

**Setup:** Read whatever exists already — the rough plan/design as stated, any related code, any existing docs in `docs/decisions/`. Don't ask about anything answerable by reading.

**One question at a time**, same discipline as brainstorming: never stack multiple questions in one message, never let the user answer three things at once because it's convenient for you.

**Question types, roughly in priority order:**

1. **Definitional.** Any term load-bearing enough that two readers could mean different things by it gets pinned down before anything else. "When you say 'the job is done,' does that mean the record is written, or written *and* the downstream consumer has acknowledged it?" A term that survives this gets added to the glossary immediately, in the interviewer's own words, not left for later.
2. **Assumption-surfacing.** What is the plan quietly relying on that nobody has actually verified? "This assumes the upstream API is idempotent — has that been confirmed, or is it inherited from how a similar API used to behave?" (This is the same category of gap the `common-ground` skill tracks longer-term; a `grill-with-docs` session is a good place to seed that ledger's first entries.)
3. **Edge-case and failure-path.** What happens when the happy path doesn't hold — empty input, the network call times out, two of these run concurrently, the user does the thing twice? A plan that has never been asked "what if this fails halfway through" usually hasn't decided.
4. **Contradiction-hunting.** Does anything stated earlier in the conversation conflict with what's being stated now? Point it out directly and ask which one is actually true — don't silently pick one and move on.
5. **Scope-boundary.** What is explicitly *not* being built here? An unstated scope boundary is where creep happens later; making it explicit now is cheap.

**Tone calibration:** Relentless means *thorough*, not combative. Ask the hard question, but ask it as a genuine attempt to understand, not as a gotcha. If the user's answer resolves the ambiguity cleanly, say so and move on — don't manufacture more friction than the plan actually has.

## Docs Produced

**Glossary** (`docs/glossary.md`, append if it exists): every load-bearing term defined during the interview, one entry each, in plain language:

```markdown
### <term>
<one or two sentence definition, in the terms this project actually uses,
not a generic dictionary definition>
```

**Decision records** (`docs/decisions/YYYY-MM-DD-<topic>.md`, one per real decision): only for points where a genuine choice was made between alternatives — not every question-and-answer pair. A definitional question that just clarified existing intent isn't a decision; a moment where the user picked approach A over approach B is.

```markdown
# <decision title>

**Date:** YYYY-MM-DD
**Status:** Decided (from grill-with-docs interview)

**Context:** <what prompted this decision — the question that surfaced it>

**Decision:** <what was decided>

**Alternatives considered:** <what else was on the table, and why it lost>

**Consequences:** <what this commits the project to, what it forecloses>
```

Write these incrementally, right after each decision lands in conversation — not reconstructed from memory at the end of the session, where details get lost or smoothed over.

## Ending the Interview

Stop when new questions stop surfacing genuinely new ground — when the last two or three questions produced answers that were already implied by earlier ones. Don't manufacture additional questions to hit some target count.

**Handoff:** Summarize what got pinned down (list the glossary terms and decision records written this session), then hand off the same way `brainstorming` does: if the sharpened plan is ready for implementation, invoke `writing-plans` next. If the interview surfaced that the plan needs more design exploration before it's ready to be planned, go back to `brainstorming` instead of forcing it forward.

## Key Principles

- **Adversarial toward the plan, collaborative toward the user** — every hard question serves a better outcome, stated that way.
- **One question at a time**, same as brainstorming.
- **Docs as you go, not a summary pass at the end** — the glossary and decision records are written incrementally, in real time.
- **Only real decisions get a decision record** — don't inflate every answered question into an artifact.
- **Read before asking** — never interview the user on something answerable from the existing code or docs.
- **Stop when genuinely done** — no manufactured questions to pad the session.
