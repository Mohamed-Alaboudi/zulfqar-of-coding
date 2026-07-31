# Skills — routing index

Every skill shipped in `skills/`, plus the two method docs in `docs/skills/`, grouped by what
they're for. Each entry: one-line purpose, a **PORTABLE** / **NEEDS-ADAPTATION** tag, and a note on
how it plays per agent.

- **PORTABLE** — the method and the `SKILL.md` file work as-is for any agent that reads the shared
  `SKILL.md` spec (Claude Code, Codex). No harness-specific feature required.
- **NEEDS-ADAPTATION** — the core method is portable, but the file references a harness primitive
  (sub-agent spawning, a specific tool name) that doesn't exist everywhere; the doc says what to
  substitute.

Invocation differs by agent: Claude Code auto-invokes by matching the `description` field, or you
type `/name`; Codex invokes by name (`$name`) or via `/skills`. Both read the same `SKILL.md`
frontmatter (`name` ≤100 chars, `description` ≤500 chars) and body — that's what makes the shipped
files portable in the first place.

Run `scripts/check-skill-budget.sh` after adding or expanding skills. It measures the deterministic
initial catalog payload (`name` + `description`), warns at 6,400 characters, and gates at 8,000 so
trigger descriptions remain discoverable instead of silently consuming the whole startup budget.

This index has two public body tiers: 20 defaults under `skills/`, loaded by
the installer and plugin manifests, and 22 manual opt-ins under
`optional-skills/`. The complete 2026-07-31 local inventory—including
duplicate Claude/Codex variants, pointers, and exclusions—is recorded in
[`catalog/skills.tsv`](../catalog/skills.tsv).

---

## Anti-slop / reasoning

| Skill | Purpose | Tag | Per-agent note |
|---|---|---|---|
| `stop-slop` | Strips generic AI writing tells (the "not just X, it's Y" cadence, "delve," em-dash spam, hedging) from prose while drafting or editing. No voice-matching, no corpus needed — the lightweight universal pass. | PORTABLE | Pure text-transform method; no tool dependency at all. |
| `honest-feedback` | Steelman-then-critique discipline: fully understand an approach before evaluating it, then give facts-and-logic-grounded feedback that separates verified / assumed / unknown and doesn't fold to authority just because it was asserted confidently. (Originally an `authentic` skill tied to one user's personal framing; shipped here genericized — same method, no personal references.) | PORTABLE | A reasoning discipline, not a tool-using skill — works identically everywhere it's read. |

## Planning / requirements

| Skill | Purpose | Tag | Per-agent note |
|---|---|---|---|
| `prompt-creator` | Turns a rough idea, one-liner, or underperforming prompt into one strong, current-best-practice prompt for a model or agent. | PORTABLE | Pure prompt-engineering method; no environment dependency. |
| `brainstorming` | Structured design exploration before implementation — surfaces user intent and requirements before any code gets written. | PORTABLE | Conversational method; works in any chat-shaped agent. |
| `writing-plans` | Turns a spec/requirements set into a concrete multi-step plan before touching code. | PORTABLE | Output is a plan document — agent-agnostic by construction. |
| `grill-with-docs` | A relentless requirements interview that also produces docs (decision records, a glossary) as it goes, so the plan is grounded rather than assumed. | PORTABLE | Doc-producing interview method; no harness feature required. |
| `long-horizon-prompting` | How to write the launch brief for an autonomous agent or multi-agent run expected to work for hours or days: defining terms precisely, an exact success predicate, persistence and stop conditions, and an approach registry for parallel attempts. | PORTABLE | The brief-writing discipline transfers directly; the *execution* of a multi-agent run still depends on the target agent's own orchestration primitive. |

## Debugging / review / quality

| Skill | Purpose | Tag | Per-agent note |
|---|---|---|---|
| `systematic-debugging` | Root-cause-first debugging: understand why a bug happens before proposing a fix, instead of pattern-matching straight to a patch. | PORTABLE | Pure investigative method; no tool dependency. |
| `verification-before-completion` | The evidence-before-assertion gate: before claiming work is done, fixed, or passing, actually run the verification commands and read their output — don't narrate success. | PORTABLE | Depends only on being able to run a command and read its result — universal. |
| `receiving-code-review` | How to handle incoming review feedback: verify each point technically before applying it, and push back with reasoning when a suggestion is wrong, instead of performatively agreeing. | PORTABLE | A response discipline, not a tool integration; works regardless of where the review came from. |
| `doubt-driven-development` | Subjects every non-trivial decision to a fresh-context adversarial review before it stands — the general form of the spinner discipline, applied continuously rather than at explicit decision points. | NEEDS-ADAPTATION | Assumes a sub-agent/fresh-context primitive to dispatch the adversarial pass; where that's unavailable, substitute the same degraded fallback documented in `docs/skills/SPINNER.md` (new chat window, second model, or a human reviewer). |
| `security-validators` | Three small, dependency-free validators for three recurring agent-adjacent security gaps: path-traversal-safe file path validation, SSRF-safe agent-influenced URL fetching, and prompt-injection-resistant LLM-graded output. | PORTABLE | Runnable validator code + the reasoning behind each; language/runtime-agnostic method, concrete reference implementation included. |

## Meta / repo hygiene

| Skill | Purpose | Tag | Per-agent note |
|---|---|---|---|
| `delegating-work` | Routes independent work into bounded Luna/Terra/Sol lanes with depth-one fan-out, single-writer ownership, compact packets, and central integration. | NEEDS-ADAPTATION | Native on Codex with custom agent TOMLs; other harnesses should map the same work shapes to their own subagent/model controls. |
| `skill-forge` | Authors and hardens a new skill: scaffolds correct frontmatter, writes a description that fires when it should and stays quiet when it shouldn't, and runs a fresh-context firing test before trusting it. | PORTABLE | Teaches the shared `SKILL.md` spec directly — arguably the most format-native skill in the set, since the spec it teaches *is* what makes everything else here portable. |
| `re-entry` | Keeps a project legible for whoever (human or agent) picks it up cold: scaffolding a new repo's docs, auditing hygiene, logging progress, recording a decision, or reconciling a folder after a work session. | PORTABLE | Reads/writes plain docs in the repo (`docs/PROGRESS.md`-style files); no harness-specific feature. |
| `handoff` *(originates as a command, ships as a portable prompt/method file)* | Writes a cold-resume prompt for the next session — decisions and *why* they were made, dead ends already ruled out, checkable state, one clearly bookended next action. Distinct from a status summary: it's written to be *acted on* by a fresh context with zero memory of this one. | PORTABLE | The output is a self-contained prompt; drop it into a fresh session on any agent and it should be immediately actionable. |
| `common-ground` *(originates as a command, ships as a portable prompt/method file)* | Surfaces hidden project assumptions ("the API is idempotent," "this table stays small") before they quietly calcify into unverified load-bearing facts, and persists them to a per-project ledger with an OPEN / WORKING / ESTABLISHED confidence tier. | PORTABLE | Writes a plain markdown ledger file to the repo; no tool dependency beyond file read/write. |
| `bookend` *(originates as a command, ships as a portable prompt/method file)* | A prompt-engineering transform: restate the objective, the hard constraints, and the explicit task at the very *end* of a prompt, after the body — because models attend best to the start and end of a long context and worst to the middle. | PORTABLE | Pure prompt-transform method — applies to any prompt headed to any model. |
| `unstick` | Breaks a stuck retry loop: stop, list what's been tried and why each attempt failed, propose three fundamentally different approaches, and don't execute yet. | PORTABLE | A metacognitive circuit-breaker; no environment dependency. |

## Research

| Skill | Purpose | Tag | Per-agent note |
|---|---|---|---|
| `exa` | Use or scaffold Exa AI search (the Exa API / MCP / SDKs) for web research inside an agent session, preferred over generic search when connected. | PORTABLE (bring-your-own-key) | Exa exposes both an MCP server (works in any MCP-capable agent) and official `exa-js`/`exa-py` SDKs for direct repo integration — pick whichever surface the target agent supports. Requires the user's own API key; the shipped skill never embeds one. |

## Optional skills

These reviewed first-party bodies are public source but are not loaded by
default. Install one named directory only after inspecting it and resolving
any same-name collision. Full instructions:
[`optional-skills/README.md`](../optional-skills/README.md).

| Skill | Purpose | Portability |
|---|---|---|
| `authentic` | User-invoked steelman-first, evidence-based feedback mode. | Text-only; explicit invocation. |
| `codex-delegation` | Runs one bounded worker through an installed Codex CLI. | Claude-side opt-in; CLI discovered from `PATH`. |
| `collaborator-handoff` | Writes a setup and access handoff for a human teammate. | Repository evidence only; no access grants. |
| `compact-handoff` | Produces a durable continuation handoff before a new context. | Text and repository artifacts only. |
| `concise` | Applies one answer-first, lossless terse-response pass. | Text-only; explicit invocation. |
| `email-to-md` | Saves new email drafts as Markdown instead of chat-only text. | Uses the current workflow's safe scratch path. |
| `explain-code` | Teaches a code path or diff with grounded evidence and a mental model. | Repository read-only unless the user asks for edits. |
| `extract` | Converts a recurring memory-backed procedure into a trigger-tested skill. | Requires project records and the available skill-authoring workflow. |
| `find-skills` | Discovers and evaluates existing skills before proposing a new one. | Uses the approved discovery surface; installation remains explicit. |
| `gws` | Uses a caller-configured Google Workspace CLI for reads and approved writes. | `gws` discovered from `PATH`; auth remains caller-managed. |
| `markdown-to-pdf` | Converts Markdown with a caller-installed typesetting toolchain and visual QA. | Requires `md2pdf`, `pandoc`, and `typst` on `PATH`. |
| `mem-search` | Retrieves prior-session evidence from a configured memory connector. | Read-only and connector-generic. |
| `optimize-code` | Runs a bounded baseline/hypothesis/measurement loop. | Uses existing project measurement tools. |
| `promote` | Proposes one proven memory fact as a governing rule. | Exact-text approval required before any edit. |
| `ship-it` | Publishes an already-verified change to an explicitly authorized destination. | Provider-neutral; external actions require current authority. |
| `simplify-code` | Reduces a recent diff while preserving behavior and safeguards. | Uses existing tests and project conventions. |
| `skill-eval` | Builds and scores routing cases and audits explicit transcript paths. | Python standard library only; never calls a model itself. |
| `spinner` | Runs one fresh decision, plan-audit, or post-build refutation pass. | Requires a fresh-context reviewer primitive. |
| `ui-demo` | Discovers, rehearses, records, and inspects a browser walkthrough. | Requires an authorized URL and browser automation surface. |
| `ultracode` | Executes hard implementation with maximum-depth root judgment and bounded lanes. | Codex-oriented; cannot raise an active session's native effort. |
| `ultrathink` | Performs maximum-depth, no-edit, no-delegation analysis. | Codex-oriented; cannot raise an active session's native effort. |
| `vidi` | Synchronizes transcript evidence with sampled video frames. | Uses caller-authorized media and tools discovered from `PATH`. |

## Method docs (not skills — no `SKILL.md`, just documented procedure)

These two are shipped as prose method documents rather than invocable skills, because their real
content is a *discipline* (how to structure a multi-agent research pass, how to get an
uncorrelated second opinion) that outlives any one harness's spawn mechanism. Read them, then
implement the shape with whatever primitive the target agent actually has.

| Doc | Purpose | Tag | Per-agent note |
|---|---|---|---|
| [`docs/skills/DEEP-RESEARCH.md`](skills/DEEP-RESEARCH.md) | The fan-out → adversarial-verify → cited-report method: neutral parallel research legs, every fact sourced, central claims checked by an independent pass, model-tiering table (competent-mid for fan-out, top-tier for verify/synthesis). | NEEDS-ADAPTATION | Native form needs a sub-agent primitive to fan out (Claude Code `Agent`/`Task`, Codex agent spawn). Fully documented degraded fallback for agents without one: sequential legs in one context, verify via a fresh session or second model. |
| [`docs/skills/SPINNER.md`](skills/SPINNER.md) | The decision-stress-test discipline: fresh/uncorrelated evaluator, author ≠ judge, default-reject, unfalsifiable justifications auto-fail. Use at expensive forks and load-bearing or irreversible decisions. | NEEDS-ADAPTATION | "Spawn a sub-agent" is the Claude-Code-native form, explicitly not the only valid one — the doc lists a new chat window with only the artifact + spec, a second model, a git worktree + separate session, or a human reviewer as equally valid substitutes, as long as the four discipline rules hold. |

---

## Not shipped here (pointers only)

A few skills the source toolkit includes are intentionally excluded from this repo — either they
wrap a third party's licensed plugin (point to it, don't vendor it — see
`docs/CREDITS-AND-UPSTREAM.md`), or they hardcode a personal environment (local CLIs, absolute
paths, account-specific tooling) that wouldn't function for a stranger cloning this repo. Their
*methods*, where genuinely novel, are folded into the docs above rather than shipped as
dead-on-arrival skill files.

### Reviewed adopted skills

These skills are installed in the audited local environment but remain upstream pointers because this repository does not vendor third-party packages:

| Skill | Purpose | Canonical source |
|---|---|---|
| `accessibility-testing` | WCAG, keyboard, focus, semantics, reflow, and reduced-motion auditing | [Community-Access/accessibility-agents](https://github.com/Community-Access/accessibility-agents) |
| `security-threat-model` | Repository-grounded AppSec threat modeling | [OpenAI skills](https://github.com/openai/skills) |
| `supabase` | CLI-first Supabase development and security workflows | [Supabase agent skills](https://github.com/supabase/agent-skills) |
| `supabase-postgres-best-practices` | Postgres schema, query, and performance guidance | [Supabase agent skills](https://github.com/supabase/agent-skills) |

The catalog also points to the locally observed Agent Reach, Firecrawl,
Compound Engineering, Last30Days, Superpowers-family, BMAD-family, and
proprietary Anthropic document bundles. See
[`docs/CREDITS-AND-UPSTREAM.md`](CREDITS-AND-UPSTREAM.md) for attribution and
license boundaries.

The default brainstorming, review-intake, debugging, strategy-reset,
verification, planning, and Stop Slop skills are short Zulfiqar
reimplementations of attributed workflow ideas. They do not include the
upstream bodies or helper files; see
[`THIRD-PARTY-NOTICES.md`](../THIRD-PARTY-NOTICES.md).

Repo-scoped `design`, `apps`, `growth`, and `voice` collections are documented in [`packs/README.md`](../packs/README.md). Their third-party payloads are intentionally not copied here.
