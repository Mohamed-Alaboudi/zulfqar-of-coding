# AGENTS.md

Portable agent operating rules + toolkit — the Zulfiqar doctrine.

## Operating principles

- **Build-lean ladder.** Before writing code, climb it and stop at the first rung that holds: does it need to exist at all -> already in this codebase -> stdlib -> platform-native -> already-installed dependency -> one line -> minimum code that works. Deletion over addition, boring over clever, fewest files, shortest working diff.
- **Trace before you cut.** The ladder shortens the solution, never the reading — trace every file the change touches first. A tiny diff in the wrong place is a second bug.
- **Root cause, not symptom.** Fix the shared path all callers route through, not the line the ticket happens to name. Mention unrelated bugs you spot; don't fix them in the same diff unless asked.
- **Act, don't survey.** When you have enough to act, act. Give a recommendation, not an option tour. Don't narrate paths you won't take, don't take unrequested defensive actions (backup branches, extra passes) nobody asked for.
- **Epistemic honesty.** Understand an approach fully before evaluating it — steelman before critique, never blind-agree, never reflex-dismiss. Reason from facts and logic; if something's missing, say so plainly with the why. Separate verified / assumed / unknown in plain prose — correlation is not causation. Don't fold to authority; if a stated approach is right, say so and move on.

## Commands

```bash
./install.sh --dry-run          # preview what would be installed, writes nothing
./install.sh --agent=claude     # install skills/config for Claude Code
./install.sh --agent=codex      # install skills/config for Codex
scripts/scan-secrets.sh         # grep-based leak check (paths, keys, emails, UUIDs)
scripts/verify-install.sh       # confirms a prior install landed correctly
```

## Project structure

```
AGENTS.md              canonical instructions (this file)
CLAUDE.md, GEMINI.md    real duplicate files mirroring AGENTS.md (not symlinks)
README.md               what this is, quickstart, support matrix
SETUP.md                full install walkthrough
templates/AGENTS.md     generic copy install.sh drops into a user's project
docs/                   PER-AGENT.md, AGENTS-MD-GUIDE.md, SKILLS.md, skills/*
skills/                 portable SKILL.md packages
scripts/                install.sh, scan-secrets.sh, verify-install.sh
```

## Verification

A change is done when `scripts/scan-secrets.sh` passes AND `scripts/verify-install.sh` passes. Evidence before done — read back the result (script exit code, diff, installed file listing), don't trust your own narration of what happened.

## Git / PR

- Branch prefix: `feat/`, `fix/`, or `docs/` + short slug. No work directly on `main`.
- Small, focused commits; message states the why, not just the what.
- Always run `scripts/scan-secrets.sh` before every push — this is a public repo, leaks don't get a second chance.

## Boundaries

**Always**
- Run `scripts/scan-secrets.sh` before push.
- Use `${ENV_VAR}` or `<YOUR_KEY>` placeholders for anything credential-shaped — never a literal key, token, or cookie.

**Ask-first**
- Writing into a user's existing agent config file (their `CLAUDE.md`, `AGENTS.md`, IDE rules) rather than a fresh one.
- Overwriting a same-named skill already installed on the target machine.

**Never**
- Commit secrets, `.env` files, keys, or any absolute home-directory path.
- Force-push to `main`.
- Vendor a third-party licensed skill's full text into this repo — point to it and attribute instead (see `docs/CREDITS-AND-UPSTREAM.md`).

## Model tiering

Route by work shape: Luna/low for deterministic extraction, Terra/low for exact search, Terra/medium for exploration and spec-closed implementation, and Sol/high for consequential advice, judgment-heavy slices, and final falsification. Keep recursion at depth one and use no more than three useful lanes per wave. Deep research may require Terra/medium collectors when source interpretation is non-trivial. Per-agent templates: `docs/CODEX-FAST-SETUP.md` and `configs/codex/agents/`.

## Project Learnings

<!-- append-only: one line per correction, newest last -->
- AGENTS.md != CLAUDE.md — Claude Code reads `CLAUDE.md`, not `AGENTS.md`, so this repo ships real duplicate files, not symlinks (symlinks break on Windows clones).
- Point, don't vendor, third-party skills — attribute and link instead of copying their full text in.
- Codex Skills use the identical open `SKILL.md` spec as Claude skills, so most skills here are format-portable without a rewrite.

## More

- `docs/PER-AGENT.md` — per-agent capability and file-format mapping
- `docs/AGENTS-MD-GUIDE.md` — how to write your own AGENTS.md
- `docs/SKILLS.md` — skill index and routing
- `docs/skills/DEEP-RESEARCH.md` — the deep-research method in full
