# How to Write a Great AGENTS.md

`AGENTS.md` is an open, Linux-Foundation-stewarded convention for a single
Markdown file that tells any AI coding agent how to work in a repo — build
commands, test commands, style conventions, and boundaries. It is read
natively by roughly two dozen tools at this point, including Codex, Cursor,
GitHub Copilot's coding agent, Google Jules, Gemini CLI, Aider, Devin, goose,
Factory, Windsurf, Zed, Amp, opencode, and RooCode. Claude Code is the notable
exception — it reads `CLAUDE.md` instead — which is why this toolkit ships
`AGENTS.md` as the canonical source and `CLAUDE.md` / `GEMINI.md` as real
duplicate files (see [below](#one-canonical-file-real-duplicates-not-symlinks)).

Because so many tools converge on this one file, `AGENTS.md` is the highest-
leverage document in a repo for agent productivity — and also the easiest to
get wrong by writing it like a README.

## The evidence-backed conventions

**Commands-first.** Lead with exactly the commands an agent needs to build,
test, lint, and run the project — verbatim, copy-pasteable, no prose between
them. An agent that can run `npm test` in the first ten lines behaves
correctly for the rest of the session; an agent that has to infer the test
command from a paragraph about your CI philosophy often gets it wrong once
and then compounds the error.

**100–150 line ceiling.** Keep the file itself in that range. This isn't
arbitrary: Codex hard-caps merged instructions at **32 KiB** — if `AGENTS.md`
plus any nested/merged instructions blow past that, content gets silently
truncated or dropped, not gracefully summarized. A file under ~150 lines of
normal Markdown comes nowhere near that ceiling and gives you headroom for
nested per-directory `AGENTS.md` files if the repo needs them later.

**The first ~100 lines matter most.** Agents weight earlier content more
heavily in practice, and some tools truncate or deprioritize what comes
after a length threshold even under the hard cap. Put commands, the
boundaries block, and the highest-value style rules first; put anything
optional — deep architecture rationale, historical context — last or in a
linked file under `docs/`.

**Show, don't tell.** For any non-obvious style rule, include one real code
snippet demonstrating it rather than a sentence describing it. "Use early
returns instead of nested conditionals" is a claim an agent might or might
not apply consistently; a four-line before/after snippet is unambiguous and
gets pattern-matched directly.

```md
<!-- Bad: tell -->
- Prefer early returns over deep nesting.

<!-- Good: show -->
- Prefer early returns over deep nesting:
  ```ts
  // Do this
  function get(id: string) {
    if (!id) return null;
    return db.find(id);
  }
  // Not this
  function get(id: string) {
    if (id) {
      return db.find(id);
    } else {
      return null;
    }
  }
  ```
```

**Tiered Boundaries block.** Don't write a flat list of dos and don'ts —
tier it by consequence, so the agent can tell the difference between a style
preference and a hard stop:

```md
## Boundaries

**Always**
- Run the test suite before declaring a change done.
- Use the existing error-handling pattern in `lib/errors.ts`.

**Ask first**
- Adding a new external dependency.
- Any schema migration.

**Never**
- Commit secrets, `.env` files, or credentials.
- Force-push to the default branch.
- Delete data without an explicit, unambiguous instruction.
```

This gives an agent a decision procedure instead of a vibe: "Always" items
are just done, "Ask first" items pause for confirmation, "Never" items are
hard-blocked regardless of how the request is phrased.

**Append-only Project Learnings section.** A short section at the bottom the
agent is explicitly told to update whenever a human correction reveals a
convention the file didn't capture:

```md
## Project Learnings
<!-- Agent: append a line here when corrected on something not covered above. -->
- 2026-06: this repo's migrations must run in a transaction — see `db/migrate.ts`.
```

The point is append-only, not curated-on-the-fly — resist the urge to edit
this into prose during a task. Let it accumulate as raw corrections, and
fold it into the main body during a periodic cleanup pass instead. This is
what turns `AGENTS.md` from a static doc into something that actually gets
better every time the agent is wrong about something.

## Why AGENTS.md is canonical, and who reads it

`AGENTS.md` is a Linux Foundation-stewarded open standard, not a single
vendor's convention — which is the whole reason it has ~24-tool reach instead
of being one more proprietary config format. The practical upshot: writing
one good `AGENTS.md` is the single highest-leverage thing you can do to make
a repo behave consistently across whichever agent a contributor happens to be
running, without maintaining N separate instruction files by hand.

## One canonical file, real duplicates, not symlinks

Claude Code reads `CLAUDE.md`; Gemini CLI reads `GEMINI.md`; nothing else in
the ~24-tool list reads either. The fix isn't to write three different files
by hand — that guarantees drift the first time someone updates one and
forgets the others. The fix is:

- `AGENTS.md` is the single canonical source. All real content lives here.
- `CLAUDE.md` and `GEMINI.md` are **committed as real file copies** of
  `AGENTS.md`, each with a one-line header noting it mirrors `AGENTS.md` and
  should not be hand-edited independently.

**Why copies and not symlinks.** A symlink is the obvious first instinct —
one file, two names, zero duplication risk. It breaks in practice: Windows
clones of a git repo containing a symlink either fail outright or produce a
plain text file containing the literal link-target path, depending on git's
`core.symlinks` setting and whether the checkout was done with developer
mode / admin rights. That's a broken `CLAUDE.md` for every Windows
contributor, silently, with no error at clone time. Real duplicate files
always Just Work on every OS. The cost is a regeneration step — regenerate
`CLAUDE.md`/`GEMINI.md` from `AGENTS.md` whenever the canonical file changes,
either by hand or with a small script/pre-commit hook — which is a solved,
low-stakes problem compared to a platform-dependent clone failure.

## Minimal skeleton

```md
# AGENTS.md

## Commands
- Install: `npm install`
- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`

## Style
- TypeScript, strict mode. No `any` without a comment explaining why.
- Prefer early returns over deep nesting:
  ```ts
  function get(id: string) {
    if (!id) return null;
    return db.find(id);
  }
  ```

## Boundaries

**Always**
- Run `npm test` before declaring a change done.

**Ask first**
- Adding a new dependency.
- Any schema/migration change.

**Never**
- Commit `.env` or secrets.
- Force-push to the default branch.

## Project Learnings
<!-- Append corrections here; fold into the sections above periodically. -->
```

Keep it there — commands, a few show-don't-tell style rules, tiered
boundaries, an append-only learnings section — and resist growing it much
past 150 lines. Anything longer belongs in a linked `docs/` file the agent
can be pointed to when relevant, not inline in the file every agent loads on
every task.
