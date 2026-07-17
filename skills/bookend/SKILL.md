---
name: bookend
description: Apply the "bookend" transform to a prompt — keep its body, then restate the objective + top hard constraints + the explicit task at the very END, task LAST. For prompts you didn't generate; other skills that already compose their own output (a plan writer, a handoff writer) should bookend it themselves rather than have this run on top.
---

# bookend

Bookend the target prompt: keep the body unchanged, append a closing restatement so the model
reads the objective first AND last. Long-context models attend best to the start and end of a
prompt and worst to the middle (the "lost in the middle" effect); putting the actual ask at the
very end, after all the context, measurably improves instruction-following on long prompts.

**Target** (resolve in order): explicit prompt text given → a reference it names ("the last
prompt") → else the most recent prompt-like artifact in this conversation. Ambiguous → ask.

**The transform**: leave the body as-is, append after a bridge:

```
---
**Reminder — restated:**
- Role / objective: <one line>
- Hard constraints: <the 2–5 that must not be violated>
- Your task now: <the explicit ask — stated LAST>
```

**Rules:**
- Condense, don't duplicate: closing block ≲15% of body length. (Near-verbatim is fine if the opening is only a few lines.)
- No NEW instructions at the end: only restate. Something missing? Add it to the *opening* too, never end-only (that recreates the conflict bookending avoids).
- Task is the **last thing** in the prompt. Nothing follows it.
- Skip if the whole prompt is under ~6 lines (middle-loss is negligible, say so).
- **TTS / voice-agent prompt:** no `---` dividers or em-dashes (they read as pauses); use a plain "Reminder of your task:" bridge.

**Output:** the full bookended prompt in one fenced code block, copy-paste clean. Outside it, 1–2 lines on what you restated or why you skipped.

Note: some prompt-writing skills (a meta-prompt writer, a handoff writer) already bookend their
own output as a final step — don't re-bookend a prompt that's already structured that way; use
this skill for arbitrary prompts/text that weren't generated with the pattern built in.
