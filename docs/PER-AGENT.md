# Per-Agent Guide

This is the map from the toolkit's generic concepts (skills, hooks, MCP, model
tiering) to what each concrete coding agent actually supports today, where its
config lives, and what you have to change vs. what just works.

Every agent in this repo reads the same spine — `AGENTS.md` at the repo root
(see `docs/AGENTS-MD-GUIDE.md`) — plus whatever agent-specific file it
additionally understands (`CLAUDE.md`, `GEMINI.md`, etc., shipped as real
duplicate files, not symlinks).

Jump to: [Claude Code](#claude-code) · [Codex](#codex) ·
[Cursor / Windsurf / Zed / Aider / Copilot coding agent / Jules](#cursor--windsurf--zed--aider--copilot-coding-agent--jules) ·
[Generic / any agent](#generic--any-agent) · [Deep-research tiering summary](#deep-research-tiering-summary)

---

## Claude Code

**Install path.** Skills live in `~/.claude/skills/<name>/SKILL.md` (user-level,
all projects) or `<repo>/.claude/skills/<name>/SKILL.md` (project-scoped, wins
on name collision). Each skill is a directory with a `SKILL.md` front-matter
file (`name`, `description`, optional `allowed-tools`) plus any reference
files loaded on demand — the classic "progressive disclosure" shape: the
front-matter is always in context, the body loads only when the skill fires.

**How skills are invoked.** Two paths, both live simultaneously:

- **Explicit** — the user (or Claude) types `/skill-name` as a slash command.
- **Automatic** — Claude reads every installed skill's `description` field at
  session start and self-selects a skill when a user message matches it
  closely enough. This is why the `description` field is the single highest-
  leverage line in a skill: it's a firing trigger, not a doc comment. Good
  descriptions state the trigger phrases AND the anti-triggers ("NOT for X —
  use Y instead") so Claude doesn't false-positive on adjacent tasks.

**Model / effort tiering.** Three independent levers, from coarse to fine:

- **Per-subagent model pin** — when spawning a subagent (via the `Agent` /
  `Task` tool or a `Workflow` script's `agent()` calls), pass
  `model: "opus" | "sonnet" | "haiku"` explicitly. Unpinned spawns fall back to
  a default that is *not* guaranteed to be cheap — always pin explicitly in
  any orchestration script.
- **`/effort`** — an in-session slash command that sets adaptive-thinking depth
  (`low` / `medium` / `high` / `xhigh`) for the *current* session. This only
  affects the top-level session; subagents spawned inside it do **not**
  inherit a boosted effort or extended thinking — that's a known limitation.
- **Headless per-task effort** — to give one delegated unit of work its own
  thinking depth independent of the parent session, shell out:
  `claude -p --model <model> --effort <level> "<fully self-contained brief>"`.
  Because it's a fresh process, the brief must carry all context — no shared
  memory with the caller. This is the only reliable way to get a subagent a
  different effort ceiling than its parent right now.

**Hooks.** Configured in `settings.json` (global `~/.claude/settings.json` or
project `.claude/settings.json`), keyed by lifecycle event —
`SessionStart`, `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, etc. — each
mapped to a shell command or script. Hooks are the only way to guarantee an
automated behavior actually runs (skills and CLAUDE.md rules are read by the
model and can be skipped under pressure; a hook is enforced by the harness
regardless of what the model decides).

**Project instructions file.** Reads `CLAUDE.md` (repo root, and nested
`CLAUDE.md` files closer to the edited path take precedence for local
conventions). Does **not** read `AGENTS.md` natively — this toolkit ships
`CLAUDE.md` as a real duplicate of the canonical `AGENTS.md`, not a symlink,
specifically so Claude Code picks it up with zero extra config.

**What transfers vs. needs adaptation.**

| Transfers as-is | Needs adaptation |
|---|---|
| `SKILL.md` format (Codex uses the identical open spec) | Slash-command *invocation* syntax (`/name` here vs. `$name` in Codex) |
| MCP server configs (standard protocol) | Hook syntax (`settings.json` shape is Claude-specific) |
| The AGENTS.md spine itself | Model-tiering vocabulary (`model:`/`/effort` has no Codex equivalent; translate to `reasoning_effort`) |

---

## Codex

**Install path.** Skills live in `~/.codex/skills/<name>/SKILL.md` (user-level)
or `<repo>/.agents/skills/<name>/SKILL.md` (repo-level). Current Codex releases
discover skills without the old experimental `skills` flag.

**How skills are invoked.** `$skill-name` inline, or the `/skills` command to
list and pick interactively. **Custom prompts are deprecated** — OpenAI's
guidance is to migrate any custom-prompt workflow to a skill; don't build new
automation on custom prompts.

**Model / effort tiering.** Configured in `config.toml`, named profile files,
or custom agent TOMLs:

- `model_reasoning_effort = "minimal" | "low" | "medium" | "high" | "xhigh" | "ultra"` —
  the default reasoning depth for the session.
- **Per-agent TOML `model_reasoning_effort`** — standalone custom agents under
  `~/.codex/agents/` or project `.codex/agents/` can pin their own model,
  effort, and sandbox. See [`CODEX-FAST-SETUP.md`](CODEX-FAST-SETUP.md).
- **Named profiles** — `codex --profile fast` overlays
  `~/.codex/fast.config.toml` on the base config. Codex 0.134.0 and later use
  separate profile files, not legacy `[profiles.name]` tables.
- **Fast mode** — `/fast on` increases supported-model speed but consumes
  credits faster; it is not a cheaper-model substitute.

**MCP support.** Full, and bidirectional:

- Codex **consumes** MCP servers via `[mcp_servers.*]` blocks in
  `config.toml`, or manage them with `codex mcp add` / `codex mcp list` /
  `codex mcp login`. Codex reads each server's `instructions` field the same
  way Claude Code surfaces MCP server instructions — put steering guidance
  there, not just in the tool descriptions.
  ```toml
  [mcp_servers.example]
  command = "npx"
  args = ["-y", "@example/mcp-server"]
  ```
- Codex can itself **act as** an MCP server for another tool to call, via
  `codex mcp-server` — useful if you want Claude Code, Cursor, or a script to
  drive Codex as a subordinate agent through the standard protocol instead of
  shelling out.

**Project instructions file.** Reads `AGENTS.md` **natively** — no adaptation
needed, no duplicate file required. This is Codex's half of the reason
`AGENTS.md` is this repo's canonical spine.

**What transfers vs. needs adaptation.**

| Transfers as-is | Needs adaptation |
|---|---|
| `AGENTS.md` (native, no copy needed) | Skill invocation syntax (`$name`/`/skills` vs. `/name`) |
| `SKILL.md` bodies and reference files (identical spec) | Tiering vocabulary — translate Claude's `model:`/`/effort` to Codex profile and per-agent `model_reasoning_effort` |
| MCP server packages | Hook syntax differs from Claude Code's `settings.json` shape — same lifecycle idea, different config surface |

---

## Cursor / Windsurf / Zed / Aider / Copilot coding agent / Jules

These five are grouped because they share the same practical ceiling: all read
`AGENTS.md` **natively**, none has first-class, reliably-triggering skill
auto-invocation the way Claude Code and Codex do, and none exposes a
standardized per-subagent effort/reasoning-tier knob you can script against.

- **What's reliable across all five:** `AGENTS.md` at the repo root, and MCP
  server configuration (each has its own settings location — Cursor's
  `.cursor/mcp.json`, Zed's `settings.json` MCP block, etc. — but the
  *protocol* is identical, so the same server package works everywhere).
  Treat these two as the shared, dependable layer.
- **Skills:** best-effort only. Some of these tools have skill-like or
  prompt-template features (Cursor rules, Aider conventions files, Zed's
  prompt library), but none guarantees the same automatic-firing-on-
  description behavior Claude Code has, and the file format isn't uniformly
  `SKILL.md`. If you need a skill's *content* to be available in one of these
  tools, the reliable move is to fold its key instructions into `AGENTS.md`
  rather than assume the skill file itself gets picked up.
  - **Copilot coding agent** and **Jules** in particular are cloud-driven,
    task-dispatch agents rather than interactive REPLs — they read
    `AGENTS.md` for task context but don't have a local skills directory to
    install into at all.
- **Model tiering:** none of the five has a documented, stable, per-task
  reasoning-effort parameter equivalent to Codex's `reasoning_effort` or
  Claude's `model:` pin. Where the underlying tool exposes a model picker
  (Cursor, Windsurf, Zed all let you pick a model per chat/session), treat
  that as your only tiering lever and set it manually per task rather than
  scripting it.

**Practical guidance:** for this group, ship `AGENTS.md` + working MCP configs
and consider that "full support." Anything skill-shaped should be written so
its content is still useful if a human just reads it out of the skill file
and pastes the relevant part into `AGENTS.md` or a chat.

---

## Generic / any agent

For a coding agent not listed above, or one you're evaluating for the first
time, three things in this repo are portable regardless of what the tool
natively understands:

1. **`AGENTS.md`** — copy `templates/AGENTS.md` into the target repo's root.
   Any agent that doesn't read it natively can still be told "read
   `AGENTS.md` first" as a one-line system-prompt addition, which recovers
   most of the benefit even without native support.
2. **The MCP servers** — standard packages speaking the standard protocol.
   If the agent supports MCP at all (most current tools do, or are adding it),
   the same server config works with only the wrapper syntax changed.
3. **The prompt templates and method docs** (`docs/AGENTS-MD-GUIDE.md`,
   `docs/PHILOSOPHY.md`, and anything under `templates/`) — plain Markdown,
   agent-agnostic by construction. These are meant to be read by a human
   setting up a new agent, or pasted into whatever instructions surface that
   agent supports.

If you're unsure whether a given agent supports skills, hooks, or tiered
reasoning, default to: ship `AGENTS.md` + MCP, treat everything else as a
bonus if it happens to work.

---

## Deep-research tiering summary

The toolkit uses **work-shaped asymmetric tiering**. Deterministic inventories
and exact search use the lightest capable readers; source interpretation and
multi-file understanding use a competent middle tier; consequential judgment
and final falsification use the strongest tier. Per agent, that maps to:

- **Claude Code:** scrapers/fan-out on `sonnet`; the verifier step escalates
  to `opus`. Pin both explicitly with `model:` on each `agent()` call in the
  orchestration script — don't rely on defaults.
- **Codex:** Luna/low for deterministic extraction, Terra/low for exact search,
  Terra/medium for source interpretation and code paths, and Sol/high for
  consequential advice or verification. Set `model_reasoning_effort` in each
  custom agent TOML rather than making the global session high.
- **Everything else in the Cursor/Windsurf/Zed/Aider/Copilot/Jules group:**
  no scriptable per-task tier exists, so approximate this by hand — run the
  fan-out/scraping pass on whatever model the tool defaults to (usually
  already mid-tier), then manually switch to the tool's highest available
  model for the verification/synthesis pass before accepting the result.

This is the actual configuration a production research pipeline runs, not an
aspirational one — state it plainly rather than defaulting to "use the
cheapest model everywhere," which collapses extraction quality and produces
verification that's checking garbage.
