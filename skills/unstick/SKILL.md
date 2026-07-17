---
name: unstick
description: Break a stuck loop — stop, list what has been tried and why each failed, propose 3 fundamentally different approaches, do not execute yet. Invoke when the agent is retrying variations of the same failing approach.
---

# Unstick

**You are stuck. Stop and do NOT write or run anything yet.**
1. STOP. Do not attempt another fix.
2. List every distinct step/approach you have tried in the last ~10 messages.
3. For each one, write ONE sentence on why it failed.
4. Propose 3 FUNDAMENTALLY DIFFERENT approaches, not variations of what already failed. Different strategy, different assumption, or different layer of the problem.
5. Do NOT execute. Present the three approaches and let the user choose.

## When this fires

Use it as a strategy reset when the whole approach is looping — distinct from bug-specific root-cause
debugging, which digs into one concrete failure rather than resetting the whole plan. A useful house
rule to pair with this skill: after 2 failed corrections on the same issue, stop and run this skill
before trying a 3rd variation.

An agent can rarely clear its own context mid-task. If the context itself looks poisoned (contradictory
partial edits, a derailed plan, confusion about what was already tried), recommend the user start a
fresh session and restate the task with what was learned — that reset is usually the user's call, not
something to do unilaterally.
