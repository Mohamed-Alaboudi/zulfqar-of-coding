---
name: optimize-code
description: Improve a measurable software outcome through a bounded baseline-hypothesis-experiment loop. Use for latency, memory, build time, bundle size, throughput, or relevance bottlenecks; not for vague cleanup or optimization without representative measurement.
---

# Optimize code

Optimize a reproducible measurement while preserving correctness, not a story inferred from static
inspection.

## Set the contract

Before editing, establish:

- one primary metric and desired direction;
- a representative workload, corpus, or fixture;
- correctness, quality, security, and compatibility guardrails;
- the exact measurement command and environment;
- an iteration, time, or regression budget; and
- the paths authorized for change.

Use existing project and platform tooling first. Do not install a profiler, add telemetry, send code
or data to an external service, or widen the change scope without explicit approval. Preserve
unrelated working-tree changes.

## Run the loop

1. Run correctness checks and record a baseline. Repeat noisy measurements enough to estimate
   variance.
2. Profile or inspect evidence to find the dominant bottleneck.
3. Rank a small set of hypotheses by expected impact, confidence, cost, and risk.
4. Change one causal variable at a time unless interaction is the stated experiment.
5. Run the identical measurement and guardrails. Record the command, result, delta, variance, and
   whether the hypothesis held.
6. Keep only changes that exceed measurement noise and preserve every guardrail. Remove only the
   experiment's own regressing changes; never reset or overwrite unrelated work.
7. Stop when the budget is reached, gains flatten, the bottleneck moves, or added complexity costs
   more than the measured gain.

For semantic quality, define a small rubric and representative samples alongside cheap hard gates.
Do not present a proxy metric as the user outcome.

## Report

Report the baseline, final result, absolute and relative delta, measurement method, variance, kept
changes, rejected hypotheses, and remaining uncertainty. Never claim a speedup from inspection
alone, from unmatched before-and-after workloads, or from a single noisy run.
