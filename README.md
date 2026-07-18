# Zulfqar of Coding

A public, installable, cross-agent toolkit: operating rules, skills, and hook patterns that work whether you're driving Codex, Claude Code, Cursor, Gemini CLI, Aider, or basically any coding agent that reads project instructions.

## The insight

[AGENTS.md](https://agents.md) is an open, Linux-Foundation-adjacent standard now read **natively** by roughly two dozen agents — Codex, Cursor, GitHub Copilot's coding agent, Jules, Gemini CLI (partially), Aider, goose, Factory, Devin, Windsurf, Zed, Amp, opencode, RooCode, and more. Write instructions once, in one file, at the root of a repo, and most of the agent ecosystem picks them up with zero extra configuration.

Two well-known exceptions read a differently-named file instead: **Claude Code reads `CLAUDE.md`, not `AGENTS.md`**, and **Gemini CLI reads `GEMINI.md`**. So this repo's spine is one canonical `AGENTS.md`, and `CLAUDE.md` / `GEMINI.md` are committed as **real duplicate files** (not symlinks — symlinks silently break on Windows clones) with a one-line header pointing back at the source of truth. Edit `AGENTS.md`, regenerate the mirrors, done.

That one decision is most of what "superpowers ~24 agents at once" means in practice: no per-tool instruction dialect to maintain, no drift between what Codex sees and what Claude Code sees.

## Crown jewels

- **Deep-research method with model tiering** — fan-out scrapers on a competent mid tier, adversarial verification and synthesis on the top tier. See [`docs/skills/DEEP-RESEARCH.md`](docs/skills/DEEP-RESEARCH.md).
- **Spinner discipline** — before committing to an expensive or hard-to-reverse call, spin up one fresh, uncorrelated top-tier reviewer with no stake in the original answer to stress-test it. Default-reject, author never judges their own work.
- **prompt-creator** — turns a rough idea or an underperforming prompt into one that actually holds up under a real model.
- **skill-forge** — scaffolds a new skill's frontmatter, writes a description that fires reliably (and doesn't false-trigger), and runs a fresh-subagent firing test before you trust it.
- **stop-slop** — a lightweight pass that strips generic AI writing tells (the "not just X, it's Y" cadence, reflexive hedging, em-dash spam) without needing a voice corpus.
- **The build-lean ladder** — the rung-by-rung discipline for not writing code that didn't need to exist: see `AGENTS.md` Operating principles.
- **Guardrail + anti-sycophancy hook patterns** — pre-commit-style hooks that block secret commits and force-pushes to protected branches, plus a prompt-submit hook pattern that keeps agent feedback honest instead of reflexively agreeable.
- **Public-safe environment map** — audited manifests for repo-scoped packs, adopted plugins, MCP templates, CLI tooling, status-line configuration, and backup boundaries without publishing private runtime state.
- **Fast Codex routing** — public-safe Luna/Terra/Sol agent roles, depth-one delegation, profile examples, and an explicit full-access warning. See [`docs/CODEX-FAST-SETUP.md`](docs/CODEX-FAST-SETUP.md).
- **Lean capability governance** — a Codex skill-discovery budget gate, a seven-server MCP authorization manifest, and an optional pinned Trivy repository scan.

## 60-second quickstart

```bash
git clone <this-repo-url>
cd zulfqar-of-coding
./install.sh --dry-run          # see what would happen, changes nothing
./install.sh --agent=claude     # install for Claude Code
# or
./install.sh --agent=codex      # install for Codex
```

Full flags and per-agent detail: [`SETUP.md`](SETUP.md).

Optional service accounts, subscriptions, and credential setup: [`docs/ACCOUNT-SETUP.md`](docs/ACCOUNT-SETUP.md).

Codex model routing, Fast mode, named agents, and safe/full-access profiles: [`docs/CODEX-FAST-SETUP.md`](docs/CODEX-FAST-SETUP.md).

Permission-bypass flags and their isolation requirements: [`docs/DANGEROUS-PERMISSIONS.md`](docs/DANGEROUS-PERMISSIONS.md).

## Native plugin packaging

The repository root is an installable plugin source for both Codex and Claude Code. It ships `.codex-plugin/plugin.json` and `.claude-plugin/plugin.json`, and both manifests reference the same canonical `skills/` tree—there is no duplicated generated bundle to drift.

For local Claude Code evaluation, clone the repository and launch `claude --plugin-dir /path/to/zulfqar-of-coding`. For Codex, add or install the repository through the current Codex plugin interface. Marketplace publication is intentionally not claimed; use the source checkout until a versioned marketplace entry is released.

## Per-agent support matrix

| Agent | Reads which instruction file | Skills? | MCP? | Subagent tiering? |
|---|---|---|---|---|
| Claude Code | `CLAUDE.md` | Yes (`~/.claude/skills`) | Yes | Yes — `model:` param, `/effort`, headless `claude -p --effort` |
| Codex | `AGENTS.md` | Yes (`SKILL.md`) | Yes | Yes — named `.codex/agents/*.toml` roles and per-agent `model_reasoning_effort` |
| Cursor | `AGENTS.md` (+ `.cursor/rules`) | Partial | Yes | No reliable subagent tiering |
| Gemini CLI | `GEMINI.md` (+ `AGENTS.md` partial) | Emerging | Yes | Limited |
| Aider | `AGENTS.md` (`CONVENTIONS.md` legacy) | No | No | No |
| goose / Factory / Devin / Windsurf / Zed / Amp / opencode / RooCode | `AGENTS.md` | Varies | Varies | Varies |

See [`docs/PER-AGENT.md`](docs/PER-AGENT.md) for the full breakdown and sourcing.

## What's inside

```
AGENTS.md               canonical instructions
CLAUDE.md, GEMINI.md     real duplicate mirrors (see "The insight" above)
README.md                you are here
SETUP.md                 full install walkthrough
LICENSE                  MIT + third-party notice pointer
templates/AGENTS.md      generic copy install.sh drops into your project
docs/
  PER-AGENT.md            per-agent capability matrix, sourced
  CODEX-FAST-SETUP.md      Luna/Terra/Sol routing, profiles, permission safety
  DANGEROUS-PERMISSIONS.md opt-in Codex/Claude bypass flags and isolation rules
  AGENTS-MD-GUIDE.md       how to write your own AGENTS.md
  SKILLS.md                skill index and routing
  CREDITS-AND-UPSTREAM.md  where ideas and code came from
  PUBLIC-AUDIT.md           included, referenced, and private-only assets
  clis/CLIS.md              CLI inventory, including Google Workspace CLI
  skills/DEEP-RESEARCH.md  the deep-research method in full
skills/                  portable SKILL.md packages
packs/                   design/apps/growth/voice pack contract
plugins/                 adopted plugin inventory (no caches vendored)
statusline/              placeholder-only status-line configuration
configs/codex/           safe config, agent-role, and opt-in profile examples
mcp/capabilities.tsv     credential-name-only MCP access and confirmation ledger
backups/                 policy only; backup payloads stay private
scripts/
  install.sh              installer (--agent, --dry-run, --skills-only, ...)
  check-skill-budget.sh   guards Codex's initial skill-discovery context budget
  run-trivy.sh            optional pinned read-only repository assurance scan
  scan-secrets.sh          leak check, run before every push
  verify-install.sh        confirms an install landed correctly
```

## Credits

This toolkit distills patterns developed across real projects and borrows structural ideas from the wider agent-tooling ecosystem. Full attribution and upstream links: [`docs/CREDITS-AND-UPSTREAM.md`](docs/CREDITS-AND-UPSTREAM.md) and [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).

The release boundary and privacy exclusions are recorded in [`docs/PUBLIC-AUDIT.md`](docs/PUBLIC-AUDIT.md).
