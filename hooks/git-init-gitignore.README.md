# git-init-gitignore.sh

**Defends against** a `.env` secret ever becoming stageable in a brand-new
repository. It is the proactive companion to `git-guardrail.sh`'s reactive
deny: the guardrail blocks a `.env` commit, this seeds the new repo's
`.gitignore` with `.env` / `.env.*` (keeping `!.env.example`) the moment the
repo is created, so the file is ignored from the very first commit and the deny
never has to fire. Fails open everywhere — a seeding error never blocks the
`git init` that triggered it. It parses each `git init [flags] [dir]` segment to
find the target directory (falling back to the call's cwd) and only writes if
`.env` isn't already present, so it's idempotent.

**Wired in Claude Code** as a `PostToolUse` hook with matcher `Bash`: after any
command containing `git init` runs, it reads the tool-call JSON on stdin, locates
the freshly-created repo, and appends the rules. Register it in `settings.json`:

```json
{ "hooks": { "PostToolUse": [ { "matcher": "Bash",
  "hooks": [ { "type": "command", "command": "$CLAUDE_PROJECT_DIR/hooks/git-init-gitignore.sh" } ] } ] } }
```

**Reimplement without any agent** using git's init template: create a template
dir with an `info/exclude` or a starter `.gitignore` containing the `.env`
rules, then `git config --global init.templateDir <dir>` — every `git init` /
`git clone` seeds those ignores automatically, no hook required (this is the
most portable form and works for humans too). **As a Codex hook**, wire the same
logic to Codex's post-command hook: on a command matching `git init`, resolve
the new repo root and append the ignore rules if absent. The seeding shell ports
verbatim; only the trigger registration differs per host.
