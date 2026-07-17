# Handoff

A cold-resume prompt for the *next* agent session on this task — not a status summary for a human. Write this when you're near a context limit, before compaction, or at a natural task boundary, and you want a fresh session to pick up exactly where you left off and start acting immediately, without re-deriving what you already figured out.

The test for a good handoff: a fresh agent with zero prior context reads it once and its first action is correct — not a clarifying question, not re-discovering a dead end you already ruled out.

## When to use

- Context is filling up and you won't finish in this session.
- You're about to compact and don't want the compaction summary to be the only record of *why* you made the choices you made.
- You're handing off to a different agent/model/tool entirely (e.g., Claude session → Codex session) and need the brief to be self-contained.

## Principles

- **Decisions + why, not just what.** "Used X" is useless without the reason — the next agent needs the reason to know if it still holds.
- **Dead ends are load-bearing.** Every approach you tried and abandoned saves the next agent from repeating it. Write the *reason* it failed, not just that it failed.
- **State must be checkable, not narrated.** Point to a command, a file, a URL — something the next agent can independently verify — never "I confirmed X works" as an unverifiable claim.
- **One next action, bookended, at the very end.** Not a task list. The single next concrete step, stated last, in imperative mood, so it's the last thing read before the agent starts acting.

## Skeleton

```
# Handoff: <task name>

## Objective
<what done looks like, one or two sentences>

## Decisions made (and why)
- <decision> — <why this and not the alternative>
- <decision> — <why>

## Dead ends (do not repeat)
- <approach tried> — <why it failed / was abandoned>
- <approach tried> — <why it failed / was abandoned>

## Current state (checkable)
- <file/path>: <what's there and its status>
- <command to run>: <expected output that proves current state>
- <URL/deployment>: <what should be observed there>

## Open questions
- <anything genuinely undecided that the next session needs to resolve>

---

Objective: <repeat the one-sentence objective>

Hard constraints:
- <constraint that must survive the handoff>
- <constraint>

Next action: <the single explicit next step, imperative, last line>
```

## Notes

- This is intentionally close to `bookend.md`'s closing block — a handoff is a bookended prompt with a memory section prepended. If the task is short enough that there's no real decision/dead-end history, you probably don't need a full handoff — a plain bookend suffices.
- Do not pad this with things that went fine. A handoff that lists every success reads like a status report and buries the one thing that matters: what would trip up the next agent.
- If you're handing off to a human teammate instead of a future agent session (onboarding, access, environment setup), that's a different document — write a repo-onboarding doc instead, not this.
