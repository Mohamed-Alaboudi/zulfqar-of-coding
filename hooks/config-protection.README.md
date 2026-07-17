# config-protection.js

**Defends against** an agent silently weakening a linter/formatter config to
make a failing check pass instead of fixing the underlying code. When told
"make the lint errors go away," a model will often reach for the easy path —
disabling a rule in `.eslintrc`, loosening `.prettierrc`, editing `biome.json`
or `ruff.toml` — which hides the real problem and rots the codebase's standards.
This hook blocks edits to an *existing* config file in that protected set while
still allowing first-time creation (scaffolding a config into a repo that has
none is legitimate), steering the agent back to fixing the source. It fails
*closed* on any stat error other than "file not found," and treats a dangling
symlink at a protected path as present, so the guard can't be sidestepped by a
race or a broken link. `pyproject.toml` is deliberately excluded because it
mixes project metadata with linter config and blocking it would break
legitimate dependency edits.

Derived from **affaan-m/ECC** (MIT, Affaan Mustafa); see `THIRD-PARTY-NOTICES.md`.

**Wired in Claude Code** as a `PreToolUse` hook with matcher `Edit|Write|MultiEdit`.
It reads the tool-call JSON on stdin, extracts `tool_input.file_path`, and exits
`2` (with an explanatory message on stderr) to block, or `0` to allow. Register
it in `settings.json`:

```json
{ "hooks": { "PreToolUse": [ { "matcher": "Edit|Write|MultiEdit",
  "hooks": [ { "type": "command", "command": "node $CLAUDE_PROJECT_DIR/hooks/config-protection.js" } ] } ] } }
```

**Reimplement as a git `pre-commit` hook**: reject the commit when a staged path
whose basename is in the protected set is *modified* (not added) —
`git diff --cached --name-status | awk '$1=="M"{print $2}'` filtered against the
`PROTECTED_FILES` list — and `exit 1`. **As a Codex hook**, wire the exported
`run()` (or the stdin/exit-code path) into Codex's file-write gate: block a write
whose target basename is protected and already exists on disk. The
`PROTECTED_FILES` set and the exists-check logic port verbatim; only the
block-signalling mechanism (exit 2 vs. host-specific deny) changes.
