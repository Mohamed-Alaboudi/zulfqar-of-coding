# Prompts

Portable, copy-paste prompt templates. Each file is self-contained — plain Markdown, no tool-specific syntax — so it works pasted into Claude Code, Codex, Cursor, Gemini CLI, Aider, or any chat interface. No installation step; just open the file, fill in the skeleton, paste.

| File | Use it when |
|---|---|
| [`bookend.md`](bookend.md) | You have a long prompt (someone else's spec, a research doc, a multi-source paste) and need the actual task to land at the *end*, not fade out in the middle. Apply to the prompt right before sending. |
| [`handoff.md`](handoff.md) | You're ending a session mid-task and want the *next* agent session to resume correctly — decisions + why, dead ends, checkable state, one next action, task last. Not a status report for a human. |
| [`long-horizon-launch-brief.md`](long-horizon-launch-brief.md) | You're launching a long-running autonomous agent (or several parallel agents) and need a success condition precise enough that the agent can't talk itself into "done" early — plus stop/return rules and a mandatory adversarial check before it reports back. |
| [`spinner-brief.md`](spinner-brief.md) | You want a fresh, uncorrelated reviewer to stress-test a decision or artifact before you trust it — default-reject, gets only the artifact and the spec, never the artifact's own reasoning about why it's fine. |

## How to use these per agent

- **Any chat-based agent (Claude, ChatGPT, Cursor chat, Gemini):** open the `.md` file, fill in the skeleton, paste the whole thing as your prompt.
- **Claude Code:** paste directly, or drop into a subagent spawn brief — these compose naturally with `Agent`/`Workflow`-style fan-out since each is self-contained and carries its own constraints.
- **Codex / CLI agents:** paste as the initial prompt to `codex exec` or equivalent; the bookend and launch-brief templates work well as the tail of a longer piped-in spec.
- **Headless / scripted runs:** these are plain text — `cat template.md | your-agent-cli` after filling in the blanks works as-is.

## Composition

`long-horizon-launch-brief.md`'s adversarial audit gate *is* a `spinner-brief.md` call, scoped to that task's specific success predicate. `handoff.md`'s closing block is a `bookend.md` transform with a memory section prepended. Use them together rather than picking one in isolation when the task calls for it.
