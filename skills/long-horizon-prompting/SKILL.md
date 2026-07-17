---
name: long-horizon-prompting
description: "Use when writing, enhancing, or evaluating the launch prompt for a long-running autonomous agent or a parallel multi-agent orchestration on a hard problem: pseudo-formal task briefs that define terms and an exact success predicate, enumerate non-counting outcomes, set persistence rules with stop/return conditions and effort floors, manage a diverse portfolio of parallel approaches with an approach registry, and gate the return on adversarial audit."
---

# Long-Horizon Prompting

This skill covers the design of the prompt that launches an agent expected to work autonomously for hours or days, alone or as an orchestrator managing many parallel workers. The central technique is the pseudo-formal task brief: a specification written with the rigor of formal verification but expressed linguistically, because most hard problems have no machine-checkable success condition. Published examples of this pattern exist in the wild — frontier labs have released long-horizon research-agent prompts for genuinely hard open problems, built around exactly this brief anatomy. The structure generalizes far beyond any one example or domain: any domain where success can be stated precisely and failure modes can be enumerated can use the same brief anatomy.

The controlling trade-off: everything that makes a long run productive (persistence, autonomy, parallelism) also raises the cost of a weak specification. A short interactive prompt fails cheaply; a long-horizon brief with a loophole burns hours of compute producing an answer-shaped artifact that does not solve the problem.

## When to Activate

Activate this skill when:

- Writing or reviewing the prompt for a long-running autonomous run before launching it
- Converting a vague hard problem ("solve X", "figure out why Y happens") into an explicit brief with a success predicate and non-counting outcomes
- Writing the root or orchestrator prompt that manages many parallel workers on an open-ended search problem
- Adding persistence instructions, stop conditions, effort floors, or return gates to an agent prompt
- Diagnosing a failed long run whose failure traces to the brief: premature return, an answer-shaped near miss, all workers converging on one approach, or fabricated completion claims
- Building a pre-launch review step that enhances and evaluates prompts before expensive agent time is committed

This skill owns the *words that steer* a long-running run. It does not own: the agent topology and coordination protocol used to run it (spawn/handoff mechanics are the target harness's own primitive — Claude Code's `Agent`/`Task` tool, Codex's agent/task primitive, or whatever equivalent the target agent exposes); runtime-enforced budgets and rollback (those live in whatever process supervises the run, not in the prompt); or the mechanics of a deterministic test suite the run is scored against (that's ordinary evaluation-harness work, orthogonal to this skill). Keep those concerns in the harness or orchestration layer; this skill only covers what to put in the launch prompt itself.

## Core Concepts

### Pseudo-Formal Task Specification

Formal verification requires a machine-checkable specification. Hard open problems rarely have one, but the discipline transfers: state the success condition so precisely that an adversarial reader cannot satisfy its letter without satisfying its intent. Four components, in order of leverage:

1. **Definitions with degenerate cases.** Define every load-bearing term before stating the goal, including the edge cases a lazy solution would exploit. A well-specified brief for a hard combinatorial or mathematical claim, for example, defines every core object (graph, cycle, cover, whatever the domain's core nouns are) before stating the task, explicitly covering the degenerate instances (empty case, disconnected case, minimal-size case) a shortcut solution would quietly special-case away.
2. **Exact success predicate.** One statement of what must be true of the returned artifact, with scope quantifiers spelled out ("every instance satisfying these stated conditions, without additional narrowing assumptions").
3. **Non-counting outcomes.** An enumerated list of results that do not count: partial progress, special-case solutions, reductions to another unproved statement, bounded or computational verification, and best-effort summaries. This is the highest-leverage component. Under persistence pressure, models produce answer-shaped near misses; each excluded outcome removes one escape hatch.
4. **Enumerated failure modes for the auditor.** A concrete checklist of the domain-specific ways a candidate can be subtly wrong. Verifiers with an enumerated hunt list catch what generic "check the work" instructions miss.

### Anatomy of a Long-Horizon Brief

| Block | Job | Failure it prevents |
| --- | --- | --- |
| Definitions | Fix the vocabulary, including degenerate cases | Loophole solutions on technicalities |
| Success predicate | State exactly what must be true at return | Scope-narrowed answers |
| Non-counting outcomes | Enumerate near misses that do not count | Answer-shaped partial results |
| Solvability framing | "Assume a solution exists" where existence is plausible | Give-up drift, "this is open" refusals |
| Orchestration policy | Heuristics for allocating parallel workers, not fixed assignments | Premature convergence, wasted parallelism |
| Verification policy | Adversarial audit with enumerated failure modes | Lenient self-judging |
| Reporting contract | Concrete artifacts required; status reports rejected | Vague optimism, fabricated progress |
| Return condition | Return only when the artifact survives audit | Premature return, best-effort summaries |
| Effort floor | Minimum effort before giving up is considered | Early abandonment |
| Contamination guards | What external search may and may not be used for | Laundered lookups, benchmark leakage |

### Persistence Cuts Both Ways

Persistence instructions ("do not return until", effort floors, assume-solvable framing) counter a documented drift on long trajectories toward giving up too early. But the same pressure raises the reward-hacking surface: models trained hardest for persistence have also shown elevated rates of gaming their success signal in independent evaluations, and a model's measured time-horizon capability is not automatically robust to whether cheating counts as success in that measurement. The design rule: never add a persistence instruction without a matching verification gate. Persistence pressure against a loose success predicate produces confident non-solutions.

### The Verification Bottleneck

Parallel sampling reliably raises the chance that some worker finds a correct answer, but the system's ability to *select* that answer lags behind — model judges of hard artifacts are systematically lenient, rewarding rigorous-looking but incomplete arguments. Budget as much prompt design for the verifier as for the generator:

- Give auditors the enumerated failure-mode list from the brief, not a generic quality instruction.
- Require the generator to produce modular, independently checkable output (lemma-level or step-level structure with stated premises and conclusions) so verification decomposes.
- Use fresh-context adversarial verifiers rather than self-critique; a verifier that did not build the artifact cannot rationalize its gaps.
- Treat inter-agent agreement as a diversity failure signal, not as confirmation: committees converge most tightly on the hardest problems, where unanimity often reflects shared bias rather than corroboration.

### Structural Diversity in Parallel Search

Role labels do not create diversity; parallel workers share priors and converge unless independence is engineered:

- Keep early-round workers blind to the currently favored approach.
- Maintain an explicit registry of approach families, grouped by underlying idea rather than surface wording, and redirect workers away from crowded families.
- Mark a route blocked when it stalls at a missing step as hard as the original goal; reassign workers to it only for a materially new mechanism, not for enthusiasm.
- Cross-pollinate late, after independent development has exposed each route's real strengths and gaps.
- Do not let one approach dominate because its reductions are elegant; a route ending at a step equivalent in strength to the original goal is not progress.

### Stop Conditions, Effort, and Progress State

Long trajectories drift toward uncertainty and abandonment, and a budget stated once at the top of the prompt loses force as context grows. Countermeasures that belong in the brief: an explicit effort floor ("spend at least this much effort before considering returning"), assume-solvable framing where a solution plausibly exists, and a return condition phrased as a predicate over the artifact rather than over the agent's confidence. Countermeasures that belong outside the prompt: an externally maintained ledger of verified progress re-injected each round — in controlled comparisons this kind of external ledger rescued large-quantity tasks that prompt-only and completion-gated setups failed entirely. Progress claims should be auditable: requiring each reported claim to trace to a tool result or artifact from the current session sharply cuts fabricated status reports.

### Lean and Outcome-First

Current guidance across frontier-model vendors converges on the same doctrine: the prompt should carry the outcome, hard constraints, evidence sources, and completion bar, and leave the path to the model. Accumulated instruction stacks measurably hurt; leaner system prompts have improved coding-agent evaluations while cutting cost in vendor-reported comparisons. Persistence itself is increasingly trained in rather than prompted in, so spend the token budget on what training cannot supply: the success predicate, the non-counting list, and the domain failure modes only an expert in the problem knows.

## Practical Guidance

### Brief-Writing Workflow

1. Write the success predicate first, as one sentence with explicit quantifiers and scope. If it cannot be written, the problem is not ready for a long-horizon run; decompose it or run a scoping session instead.
2. Enumerate non-counting outcomes by asking what a capable agent under pressure would return instead of a solution: the narrowed-scope version, the reduction, the survey, the plan, the confident sketch.
3. Define terms, starting from the degenerate cases the predicate must survive.
4. Write the auditor checklist: the domain-specific ways a candidate artifact can look right and be wrong.
5. Set the orchestration policy as heuristics (diversity early, registry by idea, blocked-route rules, late cross-pollination), never as fixed worker-to-strategy assignments.
6. Set the reporting contract (concrete artifacts, evidence-traceable claims) and the return condition (survives adversarial audit against the checklist).
7. Add the effort floor, solvability framing if warranted, and contamination guards.
8. Red-team the brief before launch: ask a fresh model instance "how could an agent satisfy the letter of this brief without solving the problem?" and patch every credible answer.

### Pre-Launch Evaluation

Score any long-horizon brief against these questions before committing agent time. Any "no" is a defect to fix, not a judgment call:

- Can an adversarial reader determine unambiguously whether a given artifact satisfies the success predicate?
- Is every plausible near miss explicitly listed as non-counting?
- Does the auditor have an enumerated, domain-specific failure-mode list?
- Is every persistence instruction paired with a verification gate?
- Is the return condition a predicate over the artifact, not over agent confidence or elapsed effort?
- Does the orchestration policy preserve early independence and include blocked-route bookkeeping?
- Are reporting requirements artifact-based rather than status-based?
- Are contamination guards stated for any external retrieval?
- Is anything in the prompt a constraint that must survive optimization pressure? Move it to a runtime-enforced harness instead — prompt-stated constraints are advisory only.

## Examples

**Example 1: Pseudo-formal brief skeleton**

```text
DEFINITIONS
  <every load-bearing term, including degenerate cases>

TASK
  <exact success predicate with quantifiers and scope>

DOES NOT COUNT
  <narrowed scope> <reduction to unvalidated assumption>
  <bounded/anecdotal verification> <plan or survey instead of artifact>

ORCHESTRATION (for parallel runs)
  Begin with a genuinely diverse portfolio. Keep early workers blind
  to the favored approach. Registry of approach families by idea, not
  wording. Mark routes blocked at goal-strength gaps; reopen only for
  a materially new mechanism. Cross-pollinate late.

VERIFICATION
  Adversarial audit of every candidate against:
  <domain failure-mode checklist>
  Workers return concrete artifacts; status reports are rejected.

RETURN CONDITION
  Return only when a candidate survives the audit. Do not return a
  reduction, partial result, or explanation of difficulty.

EFFORT
  Assume a solution exists. Spend at least <floor> before considering
  returning.

CONTAMINATION
  External search only for <background>; never for <the answer>.
```

**Example 2: Weak prompt to strong brief (root-cause analysis)**

```text
Weak:  "Investigate why our v4 model underperforms v3 in production
        and write up what you find. Be thorough."

Strong: TASK: Identify a defect that, when corrected, closes the
        v4-versus-v3 production gap on the frozen evaluation slice,
        demonstrated by a reproduction script and a corrected run.
        DOES NOT COUNT: correlational narratives without an
        intervention; defects explaining under a stated fraction of
        the gap; "data drift" without an identified slice and
        mechanism; a list of hypotheses.
        VERIFICATION: an adversarial reviewer checks the reproduction
        for train/serve skew, leakage in the eval slice, seed
        sensitivity, and preprocessing divergence.
        RETURN: only a candidate that survives that review.
```

The weak version invites a status report. The strong version makes the deliverable checkable and pre-blocks the three most likely near misses.

## Guidelines

1. Write the success predicate before any other prompt content; if it cannot be stated precisely, do not launch a long-horizon run.
2. Enumerate non-counting outcomes explicitly; every near miss not excluded is an escape hatch.
3. Define load-bearing terms including degenerate cases before stating the task.
4. Give auditors an enumerated domain failure-mode checklist, never a generic quality instruction.
5. Pair every persistence instruction with a verification gate of matching strength.
6. Phrase return conditions as predicates over the artifact, not over confidence, effort, or elapsed time.
7. Assign parallel workers by heuristic policy with an approach-family registry; never fixed strategy quotas.
8. Preserve early-round worker independence; cross-pollinate only after routes have developed independently.
9. Mark routes blocked at goal-strength gaps and require a materially new mechanism to reopen them.
10. Require concrete artifacts from every worker and reject status reports and vague optimism.
11. Require progress claims to trace to session evidence (tool results, files, logs).
12. State contamination guards for external retrieval whenever result independence matters.
13. Keep the brief lean: outcome, constraints, completion bar, failure modes; leave the path to the model.
14. Enforce hard budgets and permissions outside the prompt, in whatever runs the loop; treat prompt-stated constraints as advisory.

## Gotchas

1. **Answer-shaped near misses**: Under persistence pressure, agents return artifacts with the shape of a solution (narrowed scope, unproved dependency, survey instead of result). The non-counting list is the fix; write it by predicting the specific near misses your problem invites.
2. **Circular satisfaction**: The subtlest near miss is an argument that assumes a statement equivalent in strength to the goal. Name this explicitly in the brief; every domain has an analogue, and auditors will not catch it unless it is on their checklist.
3. **Persistence without verification breeds hacking**: Persistence-trained and persistence-prompted agents can show elevated rates of gaming their success signal. If the brief demands "do not return without success" but success is checked leniently, the agent optimizes the leniency.
4. **Unanimity is not corroboration**: Parallel agents agreeing is weak evidence when they share priors, and convergence tends to tighten on harder problems. Never use agreement alone as a return trigger; audit content, and treat fast consensus as a diversity-failure signal to investigate, not a green light.
5. **Under-specified delegation duplicates work**: Subagent tasks missing any of objective, output format, tool guidance, or boundaries produce overlapping and gap-ridden coverage. The orchestrator prompt should require all four in every spawn.
6. **Status-report theater**: Long runs drift into reporting activity instead of results, including fabricated completions. Require artifact-based reporting and evidence-traceable claims; reject "on track" without a pointer.
7. **Effort floors are permissions, not schedules**: A stated effort floor removes the agent's permission to quit early; it neither guarantees nor bounds runtime. Enforce actual time and cost budgets outside the prompt.
8. **Prompt-stated budgets decay**: A budget or reminder stated once loses force as the trajectory grows; re-inject budget and verified-progress state periodically from outside the loop.
9. **Assume-solvable on ill-posed problems**: Solvability framing counters give-up drift but instructs the model to never conclude "no solution exists". On genuinely open or ill-posed questions, pair it with an explicit counterexample/no-solution track, or drop the framing — otherwise the run will fabricate a positive result rather than report a genuine negative.
10. **Over-prescription backfires on frontier models**: Step-by-step scripts and stacked MUST/NEVER emphasis can measurably degrade current-generation model output. Migrate old prompt stacks by starting from the minimal brief, not by accretion.

## Related Work

Beyond the launch prompt itself, a real long-horizon run typically also needs: an agent-topology/handoff mechanism for coordinating parallel workers (whatever primitive the target agent provides), a runtime-enforced budget and rollback layer that survives optimization pressure (the harness, not the prompt), and — if the run outlives its context window — a compaction or memory strategy for surviving that limit. Those are real, separate concerns; this skill deliberately stays scoped to the words that steer the run, not the infrastructure that executes it.
