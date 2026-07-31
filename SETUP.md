# Setup

Full install walkthrough for Zulfiqar.

## Prerequisites

- `git`
- `bash` (installer is POSIX-ish bash; works on macOS/Linux, and on Windows under WSL or Git Bash)
- Optional: [`gitleaks`](https://github.com/gitleaks/gitleaks) as an independent second scanner. The required `scripts/scan-secrets.sh` gate is a dependency-free Bash pattern scanner.

## Clone

```bash
git clone https://github.com/Mohamed-Alaboudi/zulfiqar.git
cd zulfiqar
```

## `install.sh` flags

```bash
./install.sh --agent=<name>     # claude | codex | cursor | all
./install.sh --dry-run          # print planned actions, write nothing
./install.sh --skills-only      # install skills only, skip config/hook wiring
./install.sh --symlink          # opt-in: symlink skills instead of copying
./install.sh --no-symlink       # default: copy files (safe on Windows)
./install.sh --write-mcp        # also write a starter MCP server config
./install.sh --force            # overwrite existing same-named files/skills
```

`--dry-run` combines with any other flag to preview it. Nothing is written to disk unless `--dry-run` is absent.

## Per-agent install

### Claude Code

```bash
./install.sh --agent=claude
```

Skills land in `~/.claude/skills/`. If you'd rather scope them to one project, copy the relevant `skills/<name>/` directory into `<project>/.claude/skills/` yourself — the installer targets the user-global location by default.

### Codex

```bash
./install.sh --agent=codex
```

Skills land in `~/.codex/skills/`. For repository-scoped installation, copy selected skills into `<project>/.agents/skills/` yourself. Codex reads `AGENTS.md` natively at the project root; no extra step is needed there.

### Cursor / other AGENTS.md-native agents

```bash
./install.sh --agent=cursor
```

Cursor and most other `AGENTS.md`-native agents need no skill installation step — they read `AGENTS.md` directly. The installer's job here is mostly copying `templates/AGENTS.md` into your project if you don't already have one. Path convention: keep `AGENTS.md` at the project root; nested `AGENTS.md` files in subdirectories are supported by several agents (Codex, Cursor) as directory-scoped overrides.

## Optional skills

The installer and plugin manifests intentionally expose only the reviewed
default set in `skills/`. Additional first-party workflows under
`optional-skills/` are manual opt-ins so specialized triggers do not inflate
the default discovery payload.

Inspect the selected body and confirm that its name does not collide with an
existing installation. Then copy only that directory:

```bash
skill_name=concise
test ! -e "${HOME}/.codex/skills/${skill_name}"
cp -R "optional-skills/${skill_name}" "${HOME}/.codex/skills/${skill_name}"
```

Use `${HOME}/.claude/skills/` for Claude Code. Do not bulk-copy the optional
tree or overwrite a same-named skill without reviewing the collision. See
[`catalog/skills.tsv`](catalog/skills.tsv) for every imported, superseded,
pointer-only, and excluded local entry.

## MCP setup (BYO key)

`./install.sh --write-mcp` writes a starter MCP server config with placeholder entries. It never writes a real credential — every field that expects a secret is a `${ENV_VAR}` placeholder. Set the corresponding environment variable yourself, or point the config at your existing secrets manager. Never commit the resulting config if you hand-edit it to contain a literal key.

## Using `templates/AGENTS.md` in your own project

1. Copy the template in:
   ```bash
   cp templates/AGENTS.md /path/to/your-project/AGENTS.md
   ```
2. Fill in the `## Commands` section with your project's real build/test/lint commands.
3. Leave `## Project Learnings` empty — append one line each time you correct the agent on something project-specific. It compounds.
4. If you also drive that project with Claude Code or Gemini CLI, mirror the file:
   ```bash
   cd /path/to/your-project
   { printf '> This repository uses AGENTS.md as its canonical instruction file. This file mirrors it for Claude Code (which reads CLAUDE.md, not AGENTS.md).\n\n'; cat AGENTS.md; } > CLAUDE.md
   { printf '> This repository uses AGENTS.md as its canonical instruction file. This file mirrors it for Gemini CLI (which reads GEMINI.md, not AGENTS.md).\n\n'; cat AGENTS.md; } > GEMINI.md
   ```
   Re-run the two commands any time you edit `AGENTS.md` to keep the mirrors current. Commit real files, not symlinks.

## Troubleshooting

**Windows symlinks fail silently.** If you used `--symlink`, Windows clones without Developer Mode or admin rights will check out broken symlink files (small text files pointing at a path, not the real content). Fix: re-run with `--no-symlink` (the default), or `git config core.symlinks true` and re-checkout on a system with symlink support enabled.

**Skill-name collisions.** If a skill you're installing shares a name with one already present, the installer skips it by default and reports the conflict — pass `--force` to overwrite. Check what you're overwriting first; a same-named skill from a different source may have different behavior.

**Codex doesn't pick up skills.** Confirm that the skill landed in `~/.codex/skills/`. Run `./install.sh --agent=codex --dry-run` to preview the target before installation.

**Agent isn't reading `AGENTS.md` at all.** Confirm the file is at the project root (not nested, unless your agent explicitly supports directory-scoped overrides), and that it's committed — some agents only read tracked files.
