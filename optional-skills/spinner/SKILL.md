---
name: spinner
description: "Run one fresh independent review for a decision, pre-execution plan audit, or post-build refutation. Use only when explicitly invoked as $spinner."
---

# Spinner

Produce a genuinely independent review without importing the current agent's preference or reasoning.

## Choose one mode

| Mode | Artifact state | Deliverable |
|---|---|---|
| Decide | Concrete options exist | One choice, runner-up, edge cases, confidence |
| Audit a plan | A plan or spec exists but is not executed | Clarification questions, missing scope, contradictions, readiness |
| Refute | Work or a claim already exists | Issues only, classified against the contract |

Use one fresh, context-isolated reviewer. If no fresh-agent mechanism or collaboration slot is available, report that independence cannot be preserved and stop. Do not simulate a spin in the anchored context.

## Build a neutral packet

Include:

1. the artifact or exact path to it;
2. exact files or systems to inspect;
3. hard constraints and must-not-break behavior;
4. verified facts and explicitly labeled unknowns;
5. the mode-specific task and return shape.

Exclude the current agent's recommendation, ranking, confidence, and prior reasoning. Tell the reviewer to inspect primary evidence and repository contents directly, not trust the packet's summaries. Do not delegate recursively.

## Mode: Decide

Require a neutral decision statement, every option under consideration, relevant locations, and fixed constraints. Ask a concise clarification question before dispatch when the decision or options are ambiguous.

Request:

```text
Choose one option after inspecting the referenced evidence.
Try to falsify each option against the hard constraints.
Hunt for unstated assumptions, missing options, boundary failures,
hidden coupling, and second-order effects.

Return:
Decision: <single pick>
Why: <evidence-grounded reason>
Edge cases and missed considerations: <numbered>
Runner-up: <option and when it wins>
Confidence: <high, medium, or low; what could change it>
```

Do not implement the selected option.

## Mode: Audit a plan

Use before execution. Give the reviewer the plan in full, the files it claims to affect, settled decisions, and how execution will be performed.

Request:

```text
Audit this unexecuted plan. Read the referenced code before claiming
a conflict. Hunt in this order:
1. Ambiguity a competent implementer could read two ways.
2. Internal contradictions or conflicts with verified project state.
3. Missing scope, callers, migrations, security boundaries, rollback, or tests.
4. Tangent bait that permits unrelated work.
5. Steps without falsifiable completion checks.

Return:
Clarification questions: <quote the line, explain the ambiguity, ask one question>
Missing scope: <numbered>
Contradictions: <numbered with both sides>
Verdict: READY, READY WITH ANSWERS, or NOT READY
```

Answer valid questions and revise the plan before execution. Do not use post-build bug framing on work that does not exist yet.

## Mode: Refute

Use after implementation or for a concrete claim. Pass the smallest reviewable artifact plus its contract and locations. Do not pass the author's conclusion.

Request:

```text
Adversarial review. Find what is wrong with this artifact.
Do not validate, summarize, or list strengths.
Look for unstated assumptions, unhandled edge cases, hidden shared state,
contract violations, broken conventions, and unexpected-input failures.
Return issues only, or state that none were found after examination.
```

Re-read the artifact before accepting each finding. Classify it as valid and actionable, valid trade-off, contract misread, or noise. A clean refutation pass lowers risk but does not replace runnable verification.

## Stop conditions

- Run only one spin on an unchanged artifact.
- Stop after three revised cycles and surface remaining disagreement.
- Never auto-execute a decision or fix after the spin; implementation requires separate authority.
