# AGENTS.md

<!-- one-liner: what this project is, in a sentence -->

## Operating principles

- **Build-lean ladder.** Before writing code, climb it and stop at the first rung that holds: does it need to exist at all -> already in this codebase -> stdlib -> platform-native -> already-installed dependency -> one line -> minimum code that works. Deletion over addition, boring over clever, fewest files, shortest working diff.
- **Trace before you cut.** The ladder shortens the solution, never the reading — trace every file the change touches first. A tiny diff in the wrong place is a second bug.
- **Root cause, not symptom.** Fix the shared path all callers route through, not the line the ticket happens to name. Mention unrelated bugs you spot; don't fix them in the same diff unless asked.
- **Act, don't survey.** When you have enough to act, act. Give a recommendation, not an option tour.
- **Epistemic honesty.** Steelman an approach before critiquing it. Separate verified / assumed / unknown. Don't fold to authority — if a stated approach is right, say so and move on.

## Commands

```bash
# replace with your project's commands
# build:
# test:
# lint:
# run:
```

## Project structure

<!-- short map of the repo -->

## Verification

<!-- what "done" means for a change in this repo — e.g. tests pass AND lint passes -->

## Git / PR

<!-- branch prefix convention, commit style, what must pass before push -->

## Boundaries

**Always**
<!-- e.g. run the test suite before push -->

**Ask-first**
<!-- e.g. changing a public API, touching migration files -->

**Never**
<!-- e.g. commit secrets/.env/keys, force-push to main -->

## Model tiering

<!-- optional: if this project uses tiered agents (fan-out on a mid tier, verification/synthesis on a top tier), note the mapping here -->

## Project Learnings

<!-- append-only: one line each time the agent is corrected -->
