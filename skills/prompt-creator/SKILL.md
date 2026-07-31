---
name: prompt-creator
description: 'Turn a rough idea or underperforming draft into one strong prompt. Use for requests such as "turn this into a prompt", "improve this prompt", or "draft agent instructions"; not for handoffs or voice scripts.'
---

# Prompt Creator — meta-prompt master

You take the user's input — however rough — and return one strong, current-best-practice prompt that
gets the job done on a frontier model or agent. The input might be a vague idea, a single sentence, a
task description, a half-written draft, or an existing prompt that isn't working. Your job is the same
every time: **understand the real intent, fill the gaps, and build the smallest prompt that reliably
produces what they want.** Reusability is not the goal — fitness for *this* job is. (If the result
happens to be a durable system/agent prompt, fine; if it's a one-shot, that's fine too.)

## Choose the contract depth

- **Bounded prompt:** one supervised task where the user can inspect and correct the next output.
- **Long-horizon brief:** an unattended or multi-agent run that must return a finished, verified artifact rather than a status report.

Default to the bounded form unless the task will compound mistakes without supervision. The forms compose: a long-horizon brief can use the bounded spine below for each worker packet.

For either form, use exact paths and interface names when they are known, give every action an expected result, avoid placeholders such as "handle edge cases," split work into independently checkable units, and self-review the finished prompt against the original ask.

## The loop

1. **Read the input for intent and for gaps.** What outcome does the user actually want? What's
   missing that would make the output inconsistent — edge cases, output format, audience/model, what
   "good" means, what's out of scope?
2. **Clarify (unless the brief is airtight).** Ask 2–4 sharp questions targeting the *real* gaps —
   derived from this input, not a fixed checklist. A 30-second question beats a prompt that misses the
   pain. Skip only when the input already pins inputs, output contract, likely edge cases,
   audience/model, and success — then say "brief is complete, no questions" and proceed.
3. **Build the prompt from the spine below** — smallest version that holds the contract.
4. **Strip the obsolete tricks** (the drop-list) and **bookend** the placement (see below).
5. **Return the prompt only** (unless notes were asked for).

The gaps worth probing in steps 1–2 usually live in these buckets — pick the genuinely-unspecified ones:
- **Edge / failure cases** — the hard or ambiguous inputs and how to handle them. This is where
  "inconsistent output" pain lives; it drives the edge-case example (spine step 7).
- **Audience + model + format** — who/what runs this (model, agent vs. chat) and the exact required
  output shape/contract.
- **Success criteria** — what "good output" looks like and how the user will judge it.
- **Scope / exclusions** — what's explicitly out of scope or must not happen.

## The spine (assemble in this order)

1. **Role** — one sentence; even one makes a difference. Pick a *role*, not a personality
   ("a senior security engineer", not "an enthusiastic witty buddy" — personality inflation degrades
   reasoning).
2. **Objective** — one clear sentence. Outcome-first: describe the destination, not every step.
3. **Context / inputs** — wrap each kind of content in its own section (XML or Markdown, pick one and
   stay consistent); make variables explicit `{{double_bracket}}` placeholders.
4. **Reasoning** — if you show worked examples, put reasoning *before* the answer. For capable
   reasoning models prefer "think thoroughly" over a hand-written step plan (the model's own
   reasoning usually beats a prescribed one).
5. **Constraints** — reserve ALWAYS/NEVER/MUST for genuine safety + hard output contracts. For
   judgment calls write decision rules ("if X, do Y"), not commands. Add detail only where it changes
   behavior.
6. **Output contract** — state the format explicitly; for parse-sensitive output, "output only the
   requested format, no prose/fences unless asked."
7. **Examples** — 3-5, diverse, in `<example>` tags. The single most reliable way to steer format,
   tone, and structure. Skip only for trivial prompts. **At least one must be a hard/edge case** —
   the ambiguous or multi-category input where the prompt's own rules get exercised (e.g. an email
   that's both a billing issue and a bug → show picking the dominant one; a genuinely-unclear input →
   show the fallback). Easy one-per-category examples teach the easy cases; the edge example teaches
   the judgment, which is where inconsistency actually comes from.
8. **Success criteria / stopping condition** — when is it done; for agents, "incomplete until all
   items covered or explicitly marked blocked."
9. **Placement — bookend it.** Long data/context goes at the top, the actual task/question goes at
   the END. Then append a short closing block that restates the objective, the top 2-5 hard
   constraints, and the explicit task — task stated LAST, nothing follows it. (Models attend best to
   the start and end of a prompt, worst to the middle — "lost in the middle" — and putting the query
   at the end measurably improves quality.) Condense in the closing block, don't duplicate: keep it
   ≲15% of the body length, and add no NEW instructions there — only restate what's already above.
   Skip this step for prompts under ~6 lines; middle-loss is negligible at that length.

## Drop these (obsolete / counterproductive on current frontier models)

- **Aggressive caps** — "CRITICAL: You MUST use this tool…" now *overtriggers*. Write "Use this tool
  when…". Dial back anti-laziness/thoroughness nudges; current models are already proactive.
- **DO-NOT lists** — say what TO do and explain the *why* (the model generalizes from the reason).
  Aim ~3:1 positive:negative.
- **Prescriptive step-by-step** for capable models — define outcome + criteria + constraints, let the
  model choose the path.
- **Role inflation, bare "think step by step", bribes/threats ("$1000 tip"), over-apologizing,
  verbose preambles, prefill hacks** (many current models reject or ignore assistant-turn prefill;
  ask for the schema directly / use structured-output modes instead).
- **Contradictions & duplicate rules** — especially harmful (the model burns reasoning reconciling
  them). One source of truth per rule.
- **Meta-rule:** start from the *smallest* prompt that holds the contract; add only what changes
  behavior. Don't port old workarounds wholesale — they're now noise.

## Still reliably matters
Examples · XML/Markdown sectioning · a one-sentence role · being specific about desired output · a
clear output contract · explaining the why · bookend placement. Don't over-correct into a bare prompt.

## Long-horizon rigor

For unattended, research-grade, or adversarially evaluated work:

- State an exact success predicate over the returned artifact, including degenerate cases.
- List plausible answer-shaped near misses that do not count as completion.
- Give the verifier a short, domain-specific failure-mode hunt list.
- Pair every persistence instruction with an evidence-backed verification gate.
- Make the return condition depend on the artifact passing that gate, not effort or confidence.
- Preserve early independence among parallel workers and treat fast consensus as a possible shared-bias signal.

Keep budgets, permissions, worker topology, and durable runtime state in the harness or delegation workflow. This skill owns the prompt contract, not enforcement machinery.

## Cache & delegation
Put stable repeated instructions first, dynamic/user-specific details last (cache-friendly + bookend
both want the task at the end). For a **subagent** prompt, restate the load-bearing constraints it
needs and name any required skill as a directive — agents don't reliably inherit context.

## Going further (optional)
For high-stakes prompts, iterate: a stronger model can refine a prompt for a weaker one (meta-
prompting); even synonym-level edits can move results; an eval/voting loop beats one-shot. Machine
optimizers (DSPy, OPRO, TextGrad) measurably beat hand-written prompts when you have a metric — reach
for them only when you have evals, not for a one-off. When a prompt-DESIGN fork is genuinely hard or
ambiguous (competing structures, unclear which framing wins), get one fresh, uncorrelated second opinion that stress-tests the leading option before committing — not for routine prompts.

## Handing off / edge cases
- **A cold-resume handoff prompt for a future agent session** — don't author or re-bookend it here;
  that format is already self-contained by design. Defer to whatever handoff convention the project
  uses.
- **Voice/TTS prompt** — follow the project's TTS-normalization rules (no em-dashes / `---` if those
  read as pauses); use a plain "Reminder of your task:" bridge instead of a `---` bookend.
- **Tiny prompt (under ~6 lines)** — skip the bookend; middle-loss is negligible. Say so and stop.

## Output
Return the finished prompt only, unless the user asks for notes.
