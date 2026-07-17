# Bookend

Restate the objective and the top hard constraints, then repeat the explicit task, at the **end** of the prompt — task last, right before the model starts generating. Works on any agent: the body carries context, the tail carries orders. Long prompts lose instructions to the middle ("lost in the middle" effect); repeating the ask at the tail fixes recency.

Use this on a prompt someone else generated, or a long spec/brief you're handing to an agent, right before you send it. Skip it on prompts you're writing fresh with the task already at the end — you don't need to bookend your own bookend.

## When to use

- A long spec, ticket, or research doc is going into an agent's context and you need it to end on the actual ask, not fade out on background.
- You're assembling a prompt from multiple pasted sources (docs + code + instructions) and the real task is buried in the middle.
- A subagent/headless run needs to survive context pressure without dropping the objective.

## The transform

1. Keep the original body untouched — don't rewrite or compress the source material.
2. Append a closing block with three parts, in this order:
   - **Objective** — one sentence, what "done" looks like.
   - **Hard constraints** — a short bullet list of the 3-6 constraints that are non-negotiable (scope limits, format, things to never touch, output shape). Not every constraint from the body — only the ones that would silently get dropped or fudged under pressure.
   - **Task** — the explicit, imperative instruction, as the literal last line(s) of the prompt.

## Skeleton

```
<original prompt body — unchanged>

---

Objective: <one sentence — what done looks like>

Hard constraints:
- <constraint 1>
- <constraint 2>
- <constraint 3>

Task: <the explicit instruction, imperative mood, as the last line>
```

## Example

```
[... 400 lines of API docs, existing code, and a rambling ticket description ...]

---

Objective: Add rate limiting to the /upload endpoint without breaking existing callers.

Hard constraints:
- Do not change the endpoint's public request/response shape.
- Limit is per-API-key, not per-IP.
- Must degrade to a 429 with a Retry-After header, not a silent drop.
- No new external dependencies — use what's already in package.json.

Task: Implement the rate limiter, add one test that proves a 6th request in a
window gets a 429, and leave the diff minimal.
```

## Notes

- This is a transform, not a template — apply it to whatever prompt is in front of you.
- If the source already ends with a clear, imperative task and constraints up top, you're done; don't cargo-cult the block onto something that doesn't need it.
- For a from-scratch prompt (not transforming someone else's), just write it task-last to begin with — see `long-horizon-launch-brief.md` for a launch-brief structure that does this natively.
