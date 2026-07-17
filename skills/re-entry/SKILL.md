---
name: re-entry
description: "Keeps a project legible for a future cold agent session. Invoke when the user asks to: set up/scaffold this repo, audit project hygiene, log progress, record a decision, get project state, or reconcile a folder after a work session (update docs + surface dead code for deletion). Also fires on first-touch of a repo with no AGENTS.md / docs/PROGRESS.md. NOT a per-edit autosave."
user-invocable: true
---

# re-entry

You make repos legible to a future agent session that has zero context. A bare agent tends to:
- Create generic filenames (`NOTES.md`, `TODO.md`, `scratch.md`) that vanish into greps.
- Spawn parallel docs that drift (`PROGRESS.md`, `PROGRESS-v2.md`, `STATUS.md`).
- Forget to append to a work log, so the next session re-derives state.
- Re-attempt dead ends because failed approaches were never recorded.
- Bloat `AGENTS.md`/`CLAUDE.md` past the point where a long instructions file gets silently truncated or deprioritized.

This skill fixes those gaps with a small, opinionated convention and these modes: **init**, **log**, **decide**, **sweep**, **reconcile**, **handoff**.

## Modes

| Mode | When | What it does |
|---|---|---|
| `init` | First touch of a new or unstructured repo | Scaffold AGENTS.md + docs/PROGRESS.md + docs/decisions/ + tmp/ + .gitignore additions |
| `log` | After a substantial work block, before a handoff, or whenever the user says "log this" | Append a dated entry to `docs/PROGRESS.md` |
| `decide` | When making a meaningful architectural / dependency / convention choice | Write the next `docs/decisions/NNNN-<slug>.md` (AgDR Y-statement) |
| `sweep` | Periodic (weekly-ish) or when the user says "tidy up", "audit", "things feel messy" | Run the audit checklist on *organization/docs*; propose pruning (read-only) |
| `reconcile` | On an **established** folder after a work session — user says "reconcile this", "we changed a lot, clean it up", "update the docs and kill the dead code" | Reconstruct what changed *this session*, propose deleting old/superseded **source** code that conflicts with the new work, and update docs to match. Code-touching → strictly confirm-first |
| `handoff` | End of a session | Compose handoff (delegates to a `handoff` skill/command if present in this environment), optionally append to PROGRESS.md |

Default to the mode the user named explicitly. If they invoke this skill with no mode, ask which one — don't guess.

## Pre-flight (every invocation)

1. **Confirm you're at a project root.** Look for `.git/`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, or similar. If none, ask the user whether this is the right directory.
2. **Detect existing structure.** Note presence of: `AGENTS.md`, `CLAUDE.md`, `docs/PROGRESS.md`, `docs/decisions/`, `tmp/`, `.claudeignore`. Don't clobber any of them.
3. **If `CLAUDE.md` and `AGENTS.md` both exist as real files** (not a symlink or a duplicate mirroring the other), flag this — they're likely to drift. Offer to either symlink one to the other, or keep them as duplicates with a one-line header noting which is canonical (symlinks break on a Windows clone, so a real-duplicate-with-header is the safer default for a repo that must clone cleanly cross-platform).

## Mode: `init`

Scaffold the canonical layout. Skip any file that already exists; never overwrite.

### Target tree

```
project-root/
├── AGENTS.md                    # primary agent context (≤300 lines)
├── CLAUDE.md -> AGENTS.md       # symlink, or a duplicate with a header note, so multiple agent ecosystems read one source of truth
├── docs/
│   ├── PROGRESS.md              # append-only dated work log
│   └── decisions/
│       └── 0001-record-agent-decisions.md
├── tmp/                         # gitignored scratch
│   └── .gitkeep
└── .gitignore                   # ensure tmp/, *.local.*, .visual-baselines/ are listed
```

### Step-by-step

1. **Create `AGENTS.md`** at root using the template below. Fill in what you can detect (project name from `package.json`/etc., test command from scripts, build command). Leave clearly-marked TODOs for what you can't.
2. **Link `CLAUDE.md` to `AGENTS.md`** — symlink (`ln -s AGENTS.md CLAUDE.md`) if the environment/repo tolerates symlinks, otherwise a real duplicate file with a one-line header ("mirrors AGENTS.md — edit that file, not this one"). If `CLAUDE.md` already exists as a real file with independent content, ask the user before replacing.
3. **Create `docs/PROGRESS.md`** with the template below. Seed with one entry: today's date + "Initialized project structure via re-entry init."
4. **Create `docs/decisions/0001-record-agent-decisions.md`** as the first AgDR, formally adopting the convention.
5. **Create `tmp/.gitkeep`** so the directory exists in git but stays empty.
6. **Update `.gitignore`** — add `tmp/`, `*.local.md`, `*.local.json`, `.visual-baselines/`, `CLAUDE.local.md` if not already present. Use `Edit` not `Write` to preserve existing entries.
7. **Report what you created vs skipped** in plain text: which files are new, which already existed, what links were made, what TODOs in AGENTS.md need user input.

Do not start a dev server, run tests, or make any non-filesystem changes during `init`.

### `AGENTS.md` template

Keep under 300 lines total. Four sections, in this order:

```markdown
# <Project name>

> Agent context. Human-facing docs are in README.md.

## Project overview
<2-3 sentences: what it is, who it's for, current phase. Strip marketing.>

## Build / test / push
- Install: `<command>`
- Run dev: `<command>`
- Test: `<command>`
- Lint / typecheck: `<command>`
- Deploy / preview URL: `<url or command>`

## Development workflow
- Source lives in: `<path>`
- Tests mirror source structure at: `<path>`
- Branch convention: `<convention>`
- Where plans/progress/decisions go: see `docs/PROGRESS.md`, `docs/decisions/`
- Scratch / ephemeral notes: `tmp/` (gitignored)

## Common pitfalls / prohibited patterns
- DON'T <thing the model should never do>
- ALWAYS <thing the model should always do>
- Known dead-ends: <approaches that were tried and failed; link to PROGRESS entries>
```

If the project has a non-trivial domain or stack, progressive-disclose into `docs/`:
- `docs/STACK.md` — versions, key libraries, why-chosen
- `docs/TESTING.md` — how the test suite is structured
- `docs/CONVENTIONS.md` — code style not enforced by linter

Reference these from AGENTS.md with one-line pointers; don't inline.

### `docs/PROGRESS.md` template

```markdown
# Progress log

Append-only. Most recent first. Date stamps as `## YYYY-MM-DD`.
Never edit past entries — supersede with a new one if facts change.
This is portable long-term memory: track failed approaches so future sessions don't re-attempt them.

---

## YYYY-MM-DD
- <what changed, in past tense>
- Decisions: <link to docs/decisions/NNNN-*.md if any>
- Dead-ends: <approaches tried that didn't work — important>
- Open questions: <only if blocking future work>
```

### `docs/decisions/0001-record-agent-decisions.md` template (AgDR)

```markdown
---
id: 0001
timestamp: YYYY-MM-DDTHH:MM:SSZ
agent: <agent name, e.g. claude-code, codex>
model: <model-id>
trigger: re-entry init
status: executed
---

# AgDR-0001: Record agent decisions

In the context of a multi-session agent-driven project, facing the risk of repeated dead-ends and undocumented reasoning, I decided to adopt the Agent Decision Record (AgDR) format to achieve durable, queryable decision history, accepting the overhead of writing one document per significant decision.

## Context
This project will be worked on by one or more agents across many sessions. Without durable decision records, each session re-derives the same trade-offs.

## Options considered
| Option | Pros | Cons |
|---|---|---|
| Inline decisions in commit messages | Cheap, always present | Hard to query; no structured metadata |
| ADRs in `docs/adr/` | Established format | Designed for humans; lacks agent metadata |
| AgDRs in `docs/decisions/` | Required metadata, Y-statement body | Slightly more overhead |

## Decision
Use AgDR format with YAML frontmatter (`id`, `timestamp`, `agent`, `model`, `trigger`, `status`) and a Y-statement opening.

## Consequences
- Easier: replaying why a decision was made, even months later
- Easier: detecting when a decision has been superseded
- Harder: writing one AgDR per significant choice — slight ceremony cost
- Revisit: if AgDRs aren't being written, downgrade to plain inline notes in PROGRESS.md
```

## Mode: `log`

Append a dated entry to `docs/PROGRESS.md`. Don't create the file if missing — instead suggest `re-entry init` first.

### Rules
- Append only. Never edit a past dated entry.
- Use `## YYYY-MM-DD` as the date header. If today's header already exists, append bullets under it instead of duplicating the header.
- Required content: what changed, in past tense, with file paths or PR/commit refs.
- Strongly encouraged: dead-ends section if anything was tried and didn't work.
- Optional: open questions (only if they block future work).
- Don't narrate every tool call. One entry per substantial work block, not one per file edit.
- Keep each entry under ~15 bullets. If longer, you probably want a separate `docs/plans/` doc instead.

### When to invoke `log` proactively (without being asked)
- After completing a multi-step task that touched the codebase substantively.
- Before composing a handoff.
- After hitting a dead-end (capture the failure before context is lost).
- NOT after trivial single-file edits or read-only investigations.

## Mode: `decide`

Write the next `docs/decisions/NNNN-<slug>.md` AgDR. Use the same template as the `0001` example above. Increment `NNNN` by reading the highest existing number in `docs/decisions/`.

### When to write an AgDR (not just a PROGRESS bullet)
- Choosing between two or more genuine options for an architectural / dependency / convention decision.
- Reversing a previous decision (mark the old one `status: superseded` and link to the new one).
- Adopting a non-obvious pattern that future-you will wonder about.

Do NOT write an AgDR for: bug fixes, small refactors, file moves, formatting choices, anything you'd be embarrassed to bring up at a code review.

## Mode: `sweep`

Audit the project's organization state and propose changes. This is read-only by default; only apply changes when the user confirms.

### Audit checklist
Report each finding with file path, severity (info / warn / fix), and a proposed action.

1. **Any long-lived memory/notes file over a reasonable size cap** — many agent memory systems silently drop or deprioritize content past a size threshold. Propose consolidation into topic files.
2. **`AGENTS.md` / `CLAUDE.md` drift** — both exist as real files with diverging content, not a symlink or an intentionally-labeled duplicate. Diff them; propose merging into one canonical file.
3. **Generic filename detected** — `NOTES.md`, `TODO.md`, `scratch.md`, `temp.md` anywhere outside `tmp/`. Propose rename or move.
4. **Stale `tmp/` files** — anything in `tmp/` not modified in 14+ days. List them; propose deletion or promotion to `docs/`.
5. **Orphan plans** — `docs/plans/*.md` not referenced anywhere in PROGRESS.md or AGENTS.md. Flag as possibly abandoned.
6. **PROGRESS.md silence** — no entries in the last 14 days despite recent commits. Flag as a logging gap.
7. **PROGRESS.md bloat** — file over 2000 lines. Propose moving entries older than 6 months to `docs/PROGRESS-archive-YYYY.md`.
8. **Superseded AgDRs not marked** — search decision bodies for "deprecated", "replaced by", "no longer"; flag any AgDR matching that's still `status: executed`.
9. **`.gitignore` gaps** — `tmp/` not in gitignore; `.visual-baselines/` not in gitignore; `*.local.*` not in gitignore.
10. **AGENTS.md over 300 lines** — propose progressive disclosure into `docs/`.
11. **Doc-vs-reality drift** — commands in AGENTS.md that don't exist in package.json scripts (or equivalent). Spot-check a few.

### Output format
```
## re-entry sweep — 2026-MM-DD

Findings:
1. [WARN] docs/PROGRESS.md — no entries in 21 days, but 12 commits since last entry.
2. [FIX]  NOTES.md at root — should move to tmp/<task>-notes.md.
3. [INFO] tmp/ contains 4 files > 14 days old: <list>.

Apply? (y / pick numbers / n)
```

Only apply changes after user confirmation. Never auto-delete user files.

## Mode: `reconcile`

For an **established** folder you've been actively working in this session. Unlike `sweep` (which only audits docs/organization and never touches code), `reconcile` looks at what the work *actually changed* and brings the repo back into a coherent state: it proposes removing **old/dead/superseded source code that now conflicts with or is replaced by the new work**, and updates the docs to match reality. This is the only mode that may touch source files — and it does so **only after explicit confirmation, one batch at a time.**

### What it does
1. **Reconstruct the session's changes.** Build the picture of what changed from concrete evidence, not memory:
   - `git status` and `git diff --stat` (and `git diff` for specifics) to see uncommitted work.
   - `git log --oneline -20` for commits made this session.
   - The conversation's own edit history for files touched.
   Summarize: "This session you added X, refactored Y, replaced Z's approach."
2. **Find the conflicts / leftovers** the new work created. Look for:
   - **Superseded files** — an old implementation left behind after a rewrite (e.g. `auth.js` still present after `auth.ts` replaced it; `Component.old.tsx`; a v1 alongside a v2).
   - **Dead code** — functions/exports/components no longer imported anywhere (grep each suspect symbol for remaining references before flagging).
   - **Orphaned config/assets** — env keys, routes, fixtures for a feature that was removed.
   - **Duplicate sources of truth** the change introduced (two files now doing the same job).
   - **Doc drift** — README/AGENTS.md/PROGRESS.md describing the *old* behavior.
3. **Present a reconciliation plan** and STOP for confirmation. Two clearly separated groups:

```
## re-entry reconcile — 2026-MM-DD

Changed this session: <1-3 line summary>

Proposed code deletions (CONFLICTS with / SUPERSEDED by new work):
  1. [DELETE] src/lib/auth-legacy.ts — replaced by src/lib/auth.ts this session; 0 remaining imports (verified).
  2. [DELETE] src/components/OldCard.tsx — superseded by Card.tsx; only referenced by the deleted page.
  3. [REVIEW] utils/format.js — `formatV1()` now unused, but `formatDate()` still imported in 3 files → delete only the one export?

Proposed doc updates:
  4. README.md — "uses JWT cookies" → now bearer tokens (matches this session's change).
  5. docs/PROGRESS.md — append today's entry (what changed + dead-ends).

Apply? (all / pick numbers / just docs / n)
```

4. **Apply only what's confirmed.** Honor the global hard rules: look at each deletion target before removing it — **if a file's contents contradict how it was described (or it wasn't created this session), surface that instead of deleting.** Never delete something you can't show is genuinely superseded/unreferenced.

### Hard rules specific to `reconcile`
- **Never auto-delete.** Code deletions are *always* proposed and confirmed first, in a labeled batch, never silently.
- **Prove "dead" before proposing deletion.** Grep the symbol/file for remaining references; if anything still uses it, downgrade to `[REVIEW]` with the specifics, don't assert `[DELETE]`.
- **Separate code changes from doc changes** in the plan so the user can approve docs-only if they want (`just docs`).
- **Prefer git-tracked deletions.** If the repo is a git repo, deleted code is recoverable; if it is NOT under git, say so explicitly in the plan (deletion is irreversible) and lean toward `[REVIEW]`.
- **One reconciliation, not a rolling autosave.** This runs when asked at a session boundary, not after every edit.
- Update `docs/PROGRESS.md` (via `log` mode's rules) as part of the doc batch, capturing what was removed and why.

## Mode: `handoff`

Compose a handoff for the next session.

1. If a `handoff` skill/command exists in the user's environment, invoke it — don't reimplement.
2. Whether or not it exists, offer to append a condensed version of the handoff (Status, Pending, Suggested next) to `docs/PROGRESS.md` as today's entry. Default to yes unless the user just logged.

## Hard rules (apply across all modes)

- **AGENTS.md ≤ 300 lines**; **any persistent memory/notes file kept reasonably small** — many memory systems silently drop content past a size cap; **CLAUDE.md mirrors AGENTS.md** (symlink where tolerated, else a labeled duplicate).
- **Append-only PROGRESS.md** — never edit past dated entries. Supersede with a new entry.
- **Date-stamp anything that can go stale** — use `[YYYY-MM-DD]` inline prefix.
- **One source of truth per concept** — don't create `PROGRESS-v2.md`, `STATUS.md`, `WHATS-NEXT.md`. Update the canonical file.
- **Generic filenames are banned outside `tmp/`** — `notes.md`, `todo.md`, `scratch.md`, `temp.md`. Use task-descriptive names: `oauth-migration-plan.md`, `redis-vs-postgres-investigation.md`.
- **Treat memory as a hint, not a fact** — verify against current code before asserting.
- **Don't auto-create files in `init` mode that the user didn't ask for** — if you'd add an opinionated structure (e.g. `.github/workflows/`), ask first.

## Interaction with other tools in this environment

- **A `handoff` skill/command** (if present) — kept as the source of truth for handoff blocks. `re-entry handoff` delegates to it rather than reimplementing.
- **Design-scaffolding or brand-setup tooling** (if present) — orthogonal. Use it for design-doc scaffolding; use `re-entry init` for project-org scaffolding. Both can run on the same project without conflict.
- **Any long-term memory system** (project-scoped memory files, an index, etc.) — independent. `re-entry sweep` will flag an oversized memory/notes file as a finding, but doesn't write memory entries directly; defer to whatever memory convention this environment already has.

## What this skill explicitly does NOT do

- Doesn't run dev servers, tests, or builds.
- Doesn't modify source code outside `docs/`, `tmp/`, `.gitignore`, `AGENTS.md`, `CLAUDE.md` — **except** in `reconcile` mode, which may delete superseded/dead source, and only after the user confirms the labeled deletion batch (never silently, never unproven).
- Doesn't auto-write to any external memory system — that's that system's own job, if one exists.
- Doesn't push or commit. The user controls git state.
- Doesn't fetch external resources or call APIs.
