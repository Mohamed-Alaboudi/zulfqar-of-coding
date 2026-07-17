---
name: skill-forge
description: "Use when authoring or hardening an agent skill (Claude Code SKILL.md or a Codex skill using the same spec) — scaffolds frontmatter, writes a pushy plus anti-trigger description, and runs a fresh-subagent firing test before you trust it. Triggers: build or author a skill, scaffold or skill-ify a workflow, a skill isn't auto-firing, Skills-spec lookup. NOT for one-off solutions, single-repo conventions (put those in that repo's CLAUDE.md/AGENTS.md), or anything a hook or validator already enforces."
---

# Skill Forge

Author skills that fire when they should and stay cheap when they don't. A skill is a Markdown
playbook (`SKILL.md`) an agent loads on demand when its `description` matches the task. This skill
scaffolds one correctly **and proves it triggers** using a fresh subagent before you trust it.

**Core principle:** A skill you didn't watch a fresh agent invoke is a skill you're hoping fires, not one you know fires. Evidence before "done."

**This file practices what it preaches:** single-line quoted description, pushy trigger list + a "NOT for" clause, under 500 lines, imperative voice. Read it as a worked example.

## The Iron Law

```
NO SKILL IS DONE UNTIL A FRESH SUBAGENT TRIGGERS IT FROM THE DESCRIPTION ALONE
```

You wrote it and it reads well = unverified. Restart-and-eyeball = unverified. Only a fresh agent,
given the candidate description in its skill list and the bare task (skill name HIDDEN), choosing to
invoke it, counts as proof. Evidence before claims — treat this the same way you'd treat any other
unverified assertion about your own work.

## Step 0: Should this be a skill at all? (gate)

Stop here if any apply. Building the wrong thing is the most expensive failure.

| Situation | Do this instead |
|-----------|-----------------|
| One-off solution you won't reuse | Just do the task. No skill. |
| Conventions for ONE repo | Put them in that repo's `CLAUDE.md` / `AGENTS.md`. |
| Mechanically enforceable (regex, lint, schema, a hook) | Automate it. Save skills for judgment calls. |
| A workflow you run < ~2-3×/week | Wait for the pattern to prove itself, then forge. |

**Forge a skill when:** a multi-step technique recurs across projects, the method wasn't obvious,
mis-firing it costs you, and it needs *judgment* (not just validation). Single responsibility, one
skill, one job. If you're describing two jobs, that's two skills.

## Step 1: Name + placement

- **Name:** lowercase, hyphens only, verb-first or core-insight (`condition-based-waiting`, not
  `async-helpers`). Title Case also accepted by the spec; hyphenated-lowercase is the safer default.
  Max 64 chars.
- **Directory (people get this wrong):** the folder MUST sit *directly* under one of
  `~/.claude/skills/<name>/SKILL.md` (global, all projects) or
  `<repo>/.claude/skills/<name>/SKILL.md` (project-local, committed). Codex skills follow the same
  one-folder-per-skill layout under its own skills directory. **No nested subfolders** for
  the skill folder itself.

## Step 2: The description (the line that decides everything)

The `description` is the only part always in context; it is what the agent matches against. A vague→sharp
rewrite roughly 4×s activation. Description-only triggering realistically tops out well short of
certainty (see the reliability ladder in Step 5), so make it as sharp as the format allows.

**Formula (single line, third person, ≤1024 chars):**

```
[what it does, briefly]. Use when [literal trigger phrases the user would actually type]. NOT for [the
1-2 strongest false-positive cases → where to go instead].
```

**Domain-drift skills get a fourth move: force a fetch, forbid memory.** If the skill's subject is
facts that go stale (an API surface, pricing tiers, model ids, version numbers, anything a provider
can silently change), a good pushy+anti-trigger description still lets the agent answer fluently and
wrong from training data. Add an explicit anti-memory clause that names the live reference and bans
recall:

```
ALWAYS read <reference file/path> before answering. Never answer <the-drifting-topic> from memory:
model ids, prices, and limits go stale between training cutoffs.
```

Put the reference file itself at Level 3 (`references/*.md`) and keep it the single place those facts
live, dated. This is a sharper version of the anti-trigger move: instead of only steering *whether*
the skill fires, it steers *what the skill is allowed to do* once it fires: retrieve, don't recall.
Reserve it for reference-type skills (Step 2.5) over volatile subject matter; a stable technique skill
doesn't need it.

Three moves, all mandatory:

1. **Pushy + literal.** List concrete things the user might say, in their words. Skill-authoring
   guidance from the major agent vendors converges on making this "a little bit pushy." Cover
   synonyms, error strings, tool/lib names, the words you'd grep for.
2. **The anti-trigger line ("NOT for ...").** The highest-leverage part most authors skip. It cuts
   false positives *and* sharpens the true-positive boundary. Always include one.
3. **What-it-does, kept short.** One clause. Do **not** narrate the workflow, see the trap below.

```
# ❌ vague, won't fire (~20%)
description: "A comprehensive guide to API documentation."

# ❌ workflow-summary trap: the agent follows the description and SKIPS the body
description: "Use when documenting APIs: first parse routes, then emit OpenAPI, then validate, then write the file."

# ✅ pushy + literal + anti-trigger, no workflow
description: "Generate OpenAPI 3.0 docs from Express routes. Use when creating API docs, documenting endpoints, writing an API spec, or adding Swagger. NOT for GraphQL schemas (use the gql-docs skill) or one-off endpoint comments."
```

**The workflow-summary trap (tested, real):** if the description summarizes the steps, the agent often
*acts on the description and never opens the body*: a 2-review skill got done as 1 review because the
description said "review between tasks." Triggers in the description, **process in the body.** Never both.

**Voice:** third person. Not "I help you..." / not "you should...". Just the triggering conditions.

## Step 2.5: Know your skill TYPE (it decides how you verify in Step 4)

Tag the skill now; the type changes the success test (Step 4) and the wrong test gives false confidence.

| Type | What it is | Step-4 success test |
|------|-----------|---------------------|
| **technique** | a concrete method/steps | *apply it*: fresh agent runs the steps gap-free, right artifact (4d) |
| **reference** | API/spec/fact lookup | *retrieve from it*: fresh agent finds the right fact fast (4d, retrieval not artifact) |
| **pattern** | a mental model / way to frame | *recognize when*: fires on the right situation, NOT the wrong one (4b is the whole test) |

All three pass 4b (triggering); technique/reference add 4d (but the 4d bar differs, artifact vs retrieval).

## Step 3: Write the body (progressive disclosure)

Three levels keep a large always-on skill library cheap:

| Level | What | Loaded |
|-------|------|--------|
| 1 | `name` + `description` | **always** (~100 tok), every conversation pays this |
| 2 | `SKILL.md` body | only when the skill triggers, keep **< 500 lines / ~1500-2000 words** |
| 3 | `references/*.md`, `scripts/`, `assets/` | only when the agent navigates to them |

Body rules:
- **Imperative / verb-first** ("Run the test", "List the routes"), never second person.
- Lead with a one-line **core principle**, then the gate/steps. Put a quick-reference **table** for
  anything scannable; a **small inline flowchart only** if a decision is genuinely non-obvious.
- **One excellent example** beats five mediocre ones. No 5-language dilution, no fill-in-the-blank
  templates, no "in session X we found..." narrative.
- **No time-sensitive content.** No "as of the latest version", no dates that rot inside the steps.
- **No voodoo constants**, any number/threshold in a script gets a one-line why.
- Push heavy reference (100+ lines, full API tables) to a Level-3 file, **one level deep**, linked by
  name, never `@path` (that force-loads and burns context). Add a TOC to any file > 100 lines.

**Rule/discipline skills** (verification gates, TDD) benefit from a **Red Flags** list and a
**Rationalization → Reality** table in the body to pre-empt the excuses the agent makes, write those
inline from the failures you actually expect.

## Step 4: VERIFY IT TRIGGERS (mandatory, the step everyone skips)

Soft routing means the description is a bet. Test the bet with a fresh agent **before** claiming done.
30 minutes here roughly doubles real-world reliability. Use whatever cheap, judgment-light subagent
tier your harness offers for this — don't build an external test harness for it.

**Why a subagent and not just "restart and re-prompt yourself":** you wrote the description, so you're
contaminated, you'll invoke it on intent. A fresh agent that never saw this conversation is the only
honest test of whether the *words* pull the skill in.

**4a. Build the eval set:** 8-15 should-fire prompts (vary phrasing, synonyms, indirect asks) + 5-8
must-NOT-fire prompts (the adjacent-but-wrong cases your anti-trigger line targets).

**4b. Run the triggering test (RED→GREEN for *firing*).** Spawn a fresh, cheap, judgment-light
subagent that has NOT loaded this skill. The decisive trick: give it the candidate `name +
description` in a list of plausible skills and the bare user prompt, **hide which skill is "right."**
If you name the skill as a directive, it fires 100% and you've measured nothing — named skills fire
close to 100% in subagents, unnamed considerably less, so naming it proves nothing.

Handoff packet (self-contained, the agent hasn't seen this chat):

```
You are evaluating skill auto-selection. You have NOT been told which skill is correct.

Candidate skills (name + one-line description only):
  1. <candidate skill>: <its description>
  2. <2-3 real decoy skills with overlapping keywords>
  3. ...

For EACH user message below, answer ONLY: which numbered skill (or "none") would you
invoke, and the trigger phrase that decided it. No other action.

SHOULD-FIRE: <8-15 prompts>
MUST-NOT-FIRE: <5-8 adjacent prompts>

Return a table: prompt | chosen | trigger phrase. No preamble.
```

**4c. Read the result as evidence, not a verdict.** Score:
- should-fire hit rate: aim **as high as the format allows** (a clean ~50%+ here is a realistic
  description-only ceiling, not 90%; the rest is bought with registration + hooks, Step 5);
- false-positive rate on must-NOT-fire: drive toward 0.
- **Misses → add the missed phrasing to the description's trigger list.**
- **False positives → tighten or extend the "NOT for ..." clause.** Iterate the description and
  re-run 4b until both move. This is RED→GREEN→REFACTOR for triggering.

**4c.5: One passing run proves nothing; run the eval set repeatedly and read the variance.** A
description that fires 3 times out of 5 identical spawns is not a reliable description, it's a coin
flip that happened to land once. Before trusting a 4b result, re-run the *same* eval set (same
prompts, fresh subagent each time, no caching between runs) 3-5 times and report the spread, not a
single score:

```
Run 1: 7/10 should-fire, 0/6 false-positive
Run 2: 5/10 should-fire, 1/6 false-positive
Run 3: 8/10 should-fire, 0/6 false-positive
→ should-fire hit rate: 5-8/10 (variance too wide, description underspecified)
```

High variance on should-fire prompts means the description is sitting right on the model's decision
boundary — small, meaningless differences in the fresh agent's reasoning tip it either way. That's a
signal to sharpen wording (more literal trigger phrases, less abstraction), not a signal to re-roll
until you get a good run and call it done.

**Description-optimizer loop:** treat 4b/4c as a loop, not a one-shot. Each iteration: run the full
eval set 3+ times → take the *low* end of the variance band as the honest score (not the best run) →
edit the description to close the specific gap the misses point at → re-run the whole band again.
Stop when the low end stabilizes near the ceiling for this layer (~50%), not when any single run looks good.

**Grade the eval itself before trusting its verdict.** A high hit rate on a weak assertion is worse
than useless, it's false confidence. Before relying on a 4b/4c result, check the eval set the way you'd
check a test suite: do the SHOULD-FIRE prompts actually resemble what a real user would type, or are
they secretly paraphrases of the description (trivially easy)? Do the MUST-NOT-FIRE prompts genuinely
tempt a false positive, or are they obviously unrelated (trivially easy the other way)? An eval that
only contains easy cases will report a clean score that means nothing — critique the assertions with
the same skepticism you'd apply to the skill, then re-run.

**4d. Functional smoke test (technique/reference skills).** Have the agent actually *apply* the skill
to one real task; confirm the steps are gap-free and produce the right artifact (for reference skills,
that it can *retrieve* the right fact).

## Step 5 — Register + the reliability ladder

Triggering is engineered in layers, not left to a single description — measured, not hoped:

| Layer | ~Reliability | Status |
|-------|--------------|--------|
| Vague description | ~20% | avoid |
| Sharp pushy description + anti-trigger (Steps 2+4) | ~50% | **you just did this** |
| + entry in a project-level skills routing index | ~60-70% | **do this now** |
| + a startup hook listing available skills | ~65% | optional |
| + a prompt-time hook injecting an explicit `Use Skill(x)` directive on keyword match | ~84% | opt-in, see below |

These numbers are order-of-magnitude from one harness's internal testing, not a universal constant —
re-measure on your own eval set (Step 4) rather than trusting the table blindly.

**Required registration (do all of it, or the skill is orphaned in routing):**
1. Add an entry to whatever routing index your project keeps (a `SKILLS.md`, a README table, etc.) —
   what it does + "fires when you…" examples, plus a disambiguation line if it overlaps an existing
   skill.
2. Add the name to your project's own instructions file (`CLAUDE.md` / `AGENTS.md`) skills
   enumeration, if one exists.
3. Keep the reliability ladder above in mind as the standard every time you register a new skill.

The index is both a routing aid and the keyword source for an optional hook — skipping it leaves
~10-20pp of reliability on the table for free.

**Maintenance (edit ≠ done either):** if you later sharpen a description (Step 4c tells you to iterate),
the routing index's "what it does" text drifts — re-run its regenerate step AND re-run the 4b triggering
test. One source of truth; date-stamped facts go stale. Birth and edit both require the eval.

**Crossing ~70% (optional, only for a must-fire skill):** the sole lever past the soft ceiling is a
prompt-time hook that injects an explicit directive — `Use Skill(<name>)` — on a keyword match
(a vague "consider a skill" reminder does **not** fire; the directive does). Scope it to 3-5 must-fire
skills only — broad keyword lists create noise, and the agent can still ignore hook output in some
setups, so ~84% is real but not free or guaranteed. Provide the keyword→skill line for your routing
index and offer to wire the hook; whether to enable it by default is a per-project call.

**Do not set `disable-model-invocation: true`.** It kills auto-trigger, which defeats the whole point
of an always-on skill. *Only* exception: a skill whose mere act of running has side effects (writes,
deploys, sends) and must be manual-only — then it's defensible. Default = leave auto-trigger ON.

## Step 6 — Discover + final claim

```bash
mkdir -p ~/.claude/skills/<name>      # folder == skill name, directly under skills/
# write SKILL.md, then restart the agent (or reload) so Level-1 metadata registers
```

Then claim done **only with evidence**: state the should-fire hit rate and false-positive count you
observed in Step 4, and that the routing-index entry is added. No "it should trigger" — quote the
eval table.

## Red Flags — STOP, you're shipping an unverified skill

- "It reads well, it'll fire." → Run Step 4. Reading ≠ firing.
- "I'll just restart and try it myself." → You're contaminated. Use a fresh agent that can't see this chat.
- "I named the skill in the test prompt." → That guarantees a fire. Hide the name; test the words.
- "Description is fine, skipping the anti-trigger line." → Add "NOT for ...". It's the highest-leverage line.
- "I'll summarize the workflow in the description so it's clear." → That makes the agent skip the body. Triggers only.
- "Done — it should work." → No evidence = not done. Quote the eval.
- "It's a one-off / one repo / regex-enforceable." → Step 0 says don't build it. Go back.

## Gotchas (cheap hardening)

- **Single-line quoted `description:`.** Avoid `description: |` block scalars — multi-line scalars are
  a documented discovery fragility on some parsers, and it's a free risk to skip. Likewise avoid a
  `paths:` field unless you've tested it on your target harness's version.
- **Combined description+context truncates** in some listing UIs around ~1500 chars — front-load the
  primary use case so it survives the cut.
- **One level deep** for references; link by name, never `@file` (force-loads, burns context).

## Quick reference

| Do | Don't |
|----|-------|
| Single-line pushy description + literal triggers | Vague summary; block-scalar `description:` |
| `NOT for ...` anti-trigger line | Omit it (false positives) |
| Triggers in description, process in body | Summarize the workflow in the description |
| Body < 500 lines, imperative voice | Second person; > 2000 words inline |
| Fresh subagent, skill name HIDDEN | "Restart and try it myself"; name the skill |
| Iterate description on misses/false-positives | "It reads fine, ship it" |
| Register in your project's routing index | Leave ~10-20pp reliability unclaimed |
| Auto-trigger ON | `disable-model-invocation` by default |
| Claim done with the eval numbers | "It should trigger" |
