# inject-core-rules.sh

**Defends against** instruction dilution. A `CLAUDE.md` / `AGENTS.md` file is
soft: models reliably attend to only ~150-200 instructions, and a rule buried in
a long instruction file gets crowded out and quietly ignored — exactly the rules
you least want forgotten (don't commit secrets, don't force-push a protected
branch, use placeholders for credentials). This hook injects a *tiny* set of
must-never-fail rules directly into the model's context at the start of every
session, where they can't be diluted away by everything else competing for
attention. Keep the injected list short — it works precisely because it's small
and unmissable. Fails open: any error injects nothing and the session proceeds
normally.

> The version shipped here is **genericized** — edit the `CORE_RULES` block to
> your project's real must-never-fail rules. The defaults (no secrets,
> placeholders only, no force-push to protected branches, epistemic honesty,
> build-lean) are safe, generic starting points.

**Wired in Claude Code** as a `SessionStart` hook. It reads the session JSON on
stdin (the model id is available if you want to branch rules per-model) and
prints a JSON object with `hookSpecificOutput.additionalContext`, which Claude
Code injects at session start. Register it in `settings.json`:

```json
{ "hooks": { "SessionStart": [ { "hooks": [
  { "type": "command", "command": "$CLAUDE_PROJECT_DIR/hooks/inject-core-rules.sh" } ] } ] } }
```

**Reimplement outside Claude Code**: this is a context-injection hook with no git
analogue. **As a Codex hook**, wire it to Codex's session-start / prompt-preamble
hook and emit the same rules into the system or context channel. Where no
session hook exists, the fallback is to put the same short rule block at the very
*top* of your `AGENTS.md` (and, for Codex, keep the merged instruction file well
under its 32 KiB cap so nothing important is truncated) — a hook is strictly
better because it can't be edited out or diluted, but a top-of-file block is a
reasonable degraded mode. The rules text ports verbatim; only the emit mechanism
differs per host.
