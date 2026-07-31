---
name: skill-eval
description: "Evaluate skill routing and usage from explicit case, result, skill, and transcript paths. Use only when explicitly invoked as $skill-eval."
---

# Skill Eval

Measure whether skills are selected on requests they own, avoided on near misses, and observed in explicit transcript data.

This bundle never calls a model. It prepares evaluation packets, scores externally collected decisions, audits structured transcript files, and renders a report.

## Resolve paths

Set explicit paths for every input. Do not infer a home directory, agent installation, transcript store, or session history.

```bash
SKILL_ROOT="<installed-skill-eval-directory>"
CASES_DIR="${SKILL_ROOT}/cases"
RESULTS_PATH="<results.json>"
SKILLS_DIR="<installed-skills-directory>"
TRANSCRIPTS_DIR="<transcript-directory>"
```

## Tier 1: Routing evaluation

List and validate cases:

```bash
python3 "${SKILL_ROOT}/scripts/firing_eval.py" \
  --cases-dir "${CASES_DIR}" \
  --list
```

Build packets:

```bash
python3 "${SKILL_ROOT}/scripts/firing_eval.py" \
  --cases-dir "${CASES_DIR}" \
  --packets \
  --output "<packets.json>"
```

Each packet contains a target skill, expected class, and natural-language prompt. Give the prompts to fresh context-isolated evaluators. Ask each evaluator which one skill it would invoke, or `none`; do not invoke the skill or perform the task. Keep model or runtime selection outside this portable bundle.

Collect results as:

```json
[
  {
    "skill": "example-skill",
    "expect": "should_fire",
    "prompt": "natural user request",
    "fired": "example-skill"
  }
]
```

Score the results:

```bash
python3 "${SKILL_ROOT}/scripts/firing_eval.py" \
  --cases-dir "${CASES_DIR}" \
  --score "${RESULTS_PATH}" \
  --output "<scores.json>"

python3 "${SKILL_ROOT}/scripts/report.py" \
  "${RESULTS_PATH}" \
  --output "<report.md>"
```

Interpret recall as correct selection on `should_fire` cases. Interpret precision as the target skill staying out of its `must_not_fire` cases. A routing eval does not judge output quality.

## Tier 2: Usage audit

Audit structured JSONL transcripts only when the user explicitly supplies the transcript and installed-skill directories:

```bash
python3 "${SKILL_ROOT}/scripts/usage_audit.py" \
  --skills-dir "${SKILLS_DIR}" \
  --transcripts-dir "${TRANSCRIPTS_DIR}" \
  --json \
  --output "<usage.json>"
```

Count only structured tool calls and explicit command tags. Plain-text skill names do not count because injected catalogs and documentation can contain them without an invocation.

Transcript access can expose sensitive conversation history. Keep the input scope narrow, do not print transcript bodies, and store reports only at an authorized path.

## Case quality

- Write prompts in natural user language rather than copying descriptions.
- Include adjacent-skill near misses in every `must_not_fire` list.
- Keep third-party skill bodies out of this bundle; evaluation cases name behaviors only.
- Change one description at a time, rerun its cases, and compare the new result.
- Treat zero observed usage as reach evidence, not proof that a skill lacks value.

## Boundaries

- Use `skill-forge` to author or harden a skill.
- Use a fresh contract-based reviewer to judge output quality.
- Never infer transcript locations, read all history by default, or send transcript content to an external evaluator.
