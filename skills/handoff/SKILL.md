---
name: handoff
description: Write a cold-resume HANDOFF PROMPT for the next agent session — a prompt that drops a fresh session into your exact spot and drives it to act, not a status summary. Captures decisions + WHY, dead-ends, checkable state, one bookended next action. Use at ~85-90% context, before compaction, or at a task boundary.
---

# handoff

You are writing a **handoff prompt** for the next session, which sees NONE of this
conversation; only what you write plus the repo, git state, and any auto-loaded memory. It is the
prompt that RUNS the next session: a fresh agent must read it and, within ~30s, know the goal,
what to trust, what NOT to retry, and its first move.

**The one idea: preserve decision-density, not information-density.** A summary already captures
what happened. Capture what to do next, WHY the current shape was chosen, and what was ruled out.
The highest-value, most-skipped part is **dead-ends**: leaving them out makes the successor
re-run failures. Cut any corner but that one.

## Size it (auto-detect; user can force short or full)

- **MICRO, the default.** ≤ ~2 files touched, 0–1 nontrivial decisions, no dead-ends worth
  recording, obvious next step → 4–6 lines, no headers, no empty scaffolding.
- **FULL**, only for real decision-density: multiple decisions with live tradeoffs, ≥1 dead-end,
  a non-obvious mental model, or many files in flight. Target **≤ ~35 lines**; longer only if
  every line earns it.

When torn, write MICRO plus the 1–2 extra lines that genuinely matter. One real dead-end or
load-bearing constraint is what justifies FULL; never promote "to be safe."

## Gather (parallel reads; MICRO needs only step 1)

1. `git branch --show-current` + `git status --short` + `git log --oneline -10`.
2. Any task list in use; the newest plan/PROGRESS/decisions doc, name it, don't re-summarize it.
3. Reconstruct the process: decisions + WHY (chose X over Y because Z); dead-ends AND
   out-of-scope landmines by path:line ("known, don't fix"); the non-obvious mental model;
   constraints stated once; what you did NOT verify.
4. Memory or notes files written this session, by name.

## Output

Fenced code block, second person, directive prose. Only write a file when asked or when the
convention in this repo calls for it (e.g. `tmp/handoff-YYYY-MM-DD-HHMM.md`, or an equivalent
scratch location when not in a repo).

### Micro format

````
# Handoff — <branch> — <YYYY-MM-DD HH:MM local>
**Mission:** <one sentence — the goal>.
You are continuing <X>; as of now <state in 1 sentence>.
State: branch `<branch>`, <key dirty file(s), or "clean">. <Last command → result, if any.>
<Only if real: Don't retry <X> — failed because <Y>. / Don't fix <path:line> — out of scope.>
**Start here:** <the single concrete next action — exact file path or command>.
````

Wanting more than ~3 extra lines for decisions/dead-ends = switch to FULL; don't grow micro.

### Full format

````
# Handoff — <branch> — <YYYY-MM-DD HH:MM local>

## Mission
<One sentence. Opens AND closes the handoff (bookend).>

## You are here
<2-3 sentences, second person: what's in flight, where it just shipped or broke.>

## How this works (mental model)
<The non-obvious understanding you built — the gotcha invisible from grep/git. Omit if none.>

## Decisions & WHY
- <Chose X over Y because Z — never a bare conclusion. Include constraints stated once.>

## Ruled out / dead-ends — DO NOT RETRY / DO NOT FIX
<MANDATORY; write "None this session." if truly empty. (a) Tried X → failed because Y.
(b) Known out-of-scope bugs by path:line the successor must not "helpfully" fix.>

## State you can act on (evidence, not ground truth — verify against the repo)
- **Branch / dirty:** <branch; key uncommitted files>
- **Key files:** <path:line — why it matters; one-line contract for anything half-built;
  mark just-written-not-yet-proven code as such>
- **Commands run + result:** <exact command → pass/fail>
- **NOT verified:** <the honesty line — what you did not check>
- **Open questions:** <only genuine unknowns + what unblocks each; small calls: just make them>

## Background work
<Only if something is still running (a loop, scheduled job, or background agent): name + trigger + effect. Else omit.>

## Authoritative docs / memory
- <plan/tracker path> · <memory or notes files written this session>

## Start here
Reminder — Mission: <restate verbatim>. Re-read <the 1-2 grounding files>; trust the repo over
this handoff if they conflict.
<THE single concrete next action — exact path or command. LAST line, nothing follows.>
````

## Rules

- **A prompt, not a report.** "You are continuing X; start by…" beats "X was in progress."
- **Names, not labels.** `lib/spike.js:204 drops caller audio` beats "the echo bug."
- **Every decision carries its WHY**: bare conclusions get reversed or re-hallucinated.
- **Dead-ends are non-negotiable when they exist.** FULL writes "None this session." if empty;
  MICRO omits the line only when there truly is none. Never silently drop a real one.
- **State is evidence, not truth**: the successor verifies against the repo before acting.
- **Reference, don't duplicate**: paths instead of pasted plans/PRDs; disk survives.
- **"NOT verified" is load-bearing honesty**: a false "passed" is worse than "unchecked."
- **Bookend.** Mission opens; Start-here restates it and ENDS on the single next action. (See the
  `bookend` skill in this toolkit for the general version of this transform, applicable to any
  prompt, not just handoffs.)

Test: a fresh session reads it, re-reads the 1–2 named files, and acts correctly on the first
move, with no re-derived decisions, no re-run dead-ends, no questions this should have answered.
If a section won't change what the next agent *does*, cut it.
