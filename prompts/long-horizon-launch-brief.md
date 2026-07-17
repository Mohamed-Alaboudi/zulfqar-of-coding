# Long-Horizon Launch Brief

A launch prompt for an autonomous agent (or a parallel multi-agent run) that will operate for a long time, with many steps, with no human in the loop until it returns. The brief has to do the job a manager does for a long-running employee: define terms precisely, state an exact and checkable success condition, rule out ways the agent could convince itself it's done when it isn't, set explicit rules for when to keep going versus stop and come back, and force a hostile check before the result is trusted.

Most autonomous runs fail not because the model is incapable, but because the brief left "done" fuzzy enough that the agent declared victory early, or left "keep going" open-ended enough that it burned the whole budget circling.

## When to use

- Kicking off a long unattended run (background agent, overnight job, multi-hour autonomous loop).
- Launching several parallel agents at a hard problem where you want a genuine portfolio of approaches, not four agents converging on the same first idea.
- Any task where "how would I know if this actually worked" is not obvious from the task description alone.

## What this brief must contain

1. **Defined terms.** Any word in the task that could mean two things gets pinned down in this document. Don't rely on the agent's judgment for what "complete," "working," "all," or "correct" means — say it.
2. **An exact success predicate, stated linguistically.** Not a vibe ("make sure it works well") — a sentence the agent (or a different agent) can evaluate as true or false against observable evidence.
3. **Non-counting outcomes.** Explicitly list what does *not* count as success, especially outcomes the agent might be tempted to report as success under budget pressure (e.g., "tests pass" when the tests were weakened; "deployed" when it's deployed but unreachable).
4. **Persistence rules.** When does the agent retry vs. try a different approach vs. stop and return control? Loops without an explicit stop condition run forever or give up too early — both are failures of the brief, not the agent.
5. **Effort floor.** The minimum depth of verification/reasoning expected before any claim of completion — stops a fast, shallow pass from masquerading as done.
6. **Adversarial audit gate before return.** The agent does not get to mark itself done. A fresh, uncorrelated check (different agent, different context, default-skeptical) evaluates the output against the success predicate before the run is allowed to report success.

## Skeleton

```
# Launch Brief: <task name>

## Defined terms
- "<term used ambiguously in casual phrasing>" means: <precise definition>
- "<another term>" means: <precise definition>

## Success predicate
This task is successful if and only if:
<one falsifiable sentence, or a short conjunction of falsifiable sentences,
each checkable against observable evidence — a file, a command output, a
live URL, a test result>

## Explicitly does NOT count as success
- <outcome that looks like success but isn't — and why>
- <outcome that looks like success but isn't — and why>

## Persistence rules
- Retry the same approach if: <condition — e.g., transient failure, clear fix identified>
- Switch to a different approach if: <condition — e.g., N failed attempts, structural blocker found>
- Stop and return control if: <condition — e.g., budget exhausted, genuine ambiguity requiring a human decision, destructive/irreversible action required>
- Maximum <turns / time / attempts> before forced return, regardless of progress.

## Effort floor
Before any completion claim, the agent must have:
- <minimum verification step — e.g., run the affected flow end-to-end, not just typecheck>
- <minimum evidence gathered — e.g., read back external state, not self-narration>

## Approach portfolio (for parallel/multi-agent runs only)
- Track attempted approaches in a shared registry: <path/mechanism>.
- Do not converge on the first idea — if running N parallel agents, each
  should commit to a genuinely distinct approach before any results come back.
- Mark blocked/failed routes in the registry so parallel agents don't repeat them.

## Adversarial audit gate
Before returning as complete, a fresh agent with no prior context in this
run must:
1. Be given only the output/artifact and this brief's success predicate —
   not the working history or the executing agent's narration.
2. Default to REJECT — the burden is on the evidence to prove success, not
   on the auditor to find a flaw.
3. Return a verdict (PASS/FAIL) plus, on FAIL, the specific must-fix list.
Only a PASS verdict from this gate allows the run to report success.

---

Objective: <restate the one-line objective>

Task: Begin work now. Do not report completion until the success predicate
is met AND the adversarial audit gate has returned PASS.
```

## Notes

- The success predicate is the single highest-leverage sentence in the brief. If you can't write it as a falsifiable statement, the task isn't ready to hand off unattended yet — go back and narrow it.
- "Non-counting outcomes" is not paranoia — it's where most silent failures in autonomous runs actually happen: the agent optimizes for the letter of the predicate and finds a technically-true-but-useless way to satisfy it.
- The audit gate must be a genuinely different evaluative context (fresh agent, or at minimum fresh conversation state) — an agent grading its own homework in the same context it did the work in will not catch its own blind spots.
