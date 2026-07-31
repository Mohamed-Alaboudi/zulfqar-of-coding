---
name: systematic-debugging
description: "Use immediately for bugs, failing tests, crashes, tracebacks, regressions, or unexpected behavior; establish the causal chain before changing production code. Not for new features or known mechanical corrections."
---

# Systematic Debugging

The deliverable is not a plausible fix. It is an evidence-backed explanation
of how the observed symptom is produced, followed by the smallest correction
to that cause.

## 1. Stabilize the observation

- Capture the exact command, input, environment, output, and exit status.
- Reduce the problem to the smallest repeatable reproduction.
- If it is intermittent, gather timing, ordering, and state evidence before
  editing code.
- Read the complete error and the frames or logs that precede it.

If the reported behavior cannot be reproduced, state what was tested and add
diagnostics at the boundary where evidence disappears. Do not guess.

## 2. Trace the causal path

Start at the symptom and walk backward:

1. Which value or state is wrong here?
2. Which caller or boundary supplied it?
3. Where was it first created or mutated?
4. Which contract allowed that state?

For multi-process or multi-service paths, record the value entering and
leaving each boundary. Redact secrets. Stop when the first incorrect
transition is proven.

Compare the failing path with the nearest working path. List meaningful
differences in inputs, configuration, versions, state, and ordering.

## 3. Test one hypothesis

Write one statement in this form:

> Because evidence A and B show transition C, cause D produces symptom E.

Choose a minimal experiment that can falsify it. Change one variable, run the
reproduction, and record the result. A failed experiment replaces the
hypothesis; it does not justify stacking another speculative change on top.

## 4. Correct the cause

Before implementation, leave a runnable check that fails for the reproduced
case when practical. Then:

- change the earliest shared point that permits the invalid state;
- preserve public contracts unless the task explicitly changes them;
- avoid opportunistic refactors;
- run the focused check and the relevant regression suite;
- verify external state or side effects by reading them back.

## Escalation

After three distinct hypotheses fail, stop editing. Summarize the evidence,
failed explanations, and suspected architectural assumption, then use
`unstick` or ask for the missing decision. Repeating variants of the same
experiment is not progress.

## Report

Give the reproduction, causal chain, fix, regression evidence, and remaining
unknowns. Distinguish observation from inference.

## Provenance

This condensed Zulfiqar workflow is an independent reimplementation inspired
by the evidence-first debugging pattern in
[obra/superpowers](https://github.com/obra/superpowers). It does not reproduce
the upstream skill text. See `THIRD-PARTY-NOTICES.md`.
