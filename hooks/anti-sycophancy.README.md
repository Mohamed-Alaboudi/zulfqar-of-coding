# anti-sycophancy.sh

**Defends against** reflexive agreement — the failure mode where a leading or
loaded prompt ("this is the best approach, right?", "you'd agree, wouldn't
you?") pulls the model toward confirming the user's framing instead of
evaluating the claim on its merits. When the prompt is phrased as *seeking
confirmation*, this hook injects a short reframing note telling the model to
steelman the point first, judge it from facts/logic/research rather than the
framing, and — critically — to agree plainly if the user is actually right
rather than manufacturing disagreement. Its scope is intentionally narrow: it
scans for a small set of confirmation-seeking phrasings and stays completely
silent on every other turn, so it adds no noise to normal requests. Fails open —
missing `jq`, empty stdin, or malformed JSON all result in nothing being
injected.

Reimplemented from the **0xcjl/anti-sycophancy** pattern; see `THIRD-PARTY-NOTICES.md`.

**Wired in Claude Code** as a `UserPromptSubmit` hook. It reads the event JSON on
stdin, extracts `.prompt`, and if the confirmation-seeking regex matches, prints
a JSON object with `hookSpecificOutput.additionalContext` (the reframing note),
which Claude Code injects into the model's context for that turn. Register it in
`settings.json`:

```json
{ "hooks": { "UserPromptSubmit": [ { "hooks": [
  { "type": "command", "command": "$CLAUDE_PROJECT_DIR/hooks/anti-sycophancy.sh" } ] } ] } }
```

**Reimplement outside Claude Code**: this is a prompt-preprocessing hook, not a
git-boundary check, so it has no `pre-commit` analogue. **As a Codex hook** (or
in any agent that lets you preprocess the user turn / inject system context),
wire the same match-then-inject logic: scan the incoming message for the
confirmation-seeking phrasings and prepend the reframing note to the system or
context channel for that turn. The phrase list and the alternation-regex shell
port verbatim; only the injection mechanism (host-specific "additionalContext"
vs. a system-message prepend) differs. The same idea also works as a static line
in a `CLAUDE.md` / `AGENTS.md`, but a hook can't be diluted away the way a
buried instruction can.
