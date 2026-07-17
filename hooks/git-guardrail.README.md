# git-guardrail.sh

**Defends against** the three shell actions that are irreversible or leak
secrets and that a model is otherwise only *trusted* to avoid: staging or
committing a `.env`-style secret file (while still allowing
`.env.example/.sample/.template`), force-pushing to `main`/`master`, and
`rm -rf` targeting the filesystem root or home root. It is deliberately narrow
— it prefers to miss an edge case (false negative) over blocking a legitimate
command (false positive) — and fails open, so any parse error lets the command
through rather than wedging the agent. On a blocked `.env` commit it also
auto-appends `.env` rules to the repo's `.gitignore` before denying, so the
mistake can't recur.

**Wired in Claude Code** as a `PreToolUse` hook with matcher `Bash`. It reads
the tool-call JSON on stdin, and to block a command it prints a JSON object
with `hookSpecificOutput.permissionDecision: "deny"` and a
`permissionDecisionReason` that is fed back to the model, then exits 0. Register
it in `settings.json`:

```json
{ "hooks": { "PreToolUse": [ { "matcher": "Bash",
  "hooks": [ { "type": "command", "command": "$CLAUDE_PROJECT_DIR/hooks/git-guardrail.sh" } ] } ] } }
```

**Reimplement as a git `pre-commit` hook** (catches the `.env`/secret case at
the commit boundary regardless of which agent staged it): in
`.git/hooks/pre-commit`, block when any staged path matches `\.env` but not
`\.env\.(example|sample|template)` —
`git diff --cached --name-only | grep -E '\.env(\.|$)' | grep -vE '\.env\.(example|sample|template)'`
— and `exit 1` if it matches. A `pre-push` hook similarly rejects a force-push
to a protected branch. **As a Codex hook**, wire the same stdin-JSON→deny
contract into Codex's tool-gate hook: parse the proposed command, return a deny
decision for the three patterns. The regexes in the script port verbatim; only
the deny-signalling mechanism (JSON vs. exit code) differs per host.
