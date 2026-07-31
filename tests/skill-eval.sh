#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ROOT="${REPO_ROOT}/optional-skills/skill-eval"
FIXTURE_ROOT="$(mktemp -d)"
LOCAL_PATH_PATTERN='/''Users/|/''home/|~/\.(claude|codex|agents)'
FIXED_MODEL_PATTERN='gpt-''[0-9]|model: "(op''us|son''net|hai''ku)"'

cleanup() {
  case "${FIXTURE_ROOT}" in
    /tmp/*|/var/folders/*) rm -rf -- "${FIXTURE_ROOT}" ;;
    *) printf 'refusing to remove unexpected fixture path: %s\n' "${FIXTURE_ROOT}" >&2 ;;
  esac
}
trap cleanup EXIT

required_files=(
  "${BUNDLE_ROOT}/SKILL.md"
  "${BUNDLE_ROOT}/scripts/firing_eval.py"
  "${BUNDLE_ROOT}/scripts/report.py"
  "${BUNDLE_ROOT}/scripts/usage_audit.py"
)
for required_file in "${required_files[@]}"; do
  [ -f "${required_file}" ] || {
    printf 'FAIL: missing portable skill-eval file: %s\n' "${required_file}" >&2
    exit 1
  }
done

expected_header="$(printf '%s\n' \
  '---' \
  'name: skill-eval' \
  'description: "Evaluate skill routing and usage from explicit case, result, skill, and transcript paths. Use only when explicitly invoked as $skill-eval."' \
  '---')"
[ "$(sed -n '1,4p' "${BUNDLE_ROOT}/SKILL.md")" = "${expected_header}" ] || {
  printf 'FAIL: skill-eval frontmatter is not the required four-line manual-only header\n' >&2
  exit 1
}

command -v python3 >/dev/null 2>&1 || {
  printf 'FAIL: portable skill-eval requires python3\n' >&2
  exit 1
}

PYTHONPYCACHEPREFIX="${FIXTURE_ROOT}/pycache" \
  python3 -m py_compile "${BUNDLE_ROOT}"/scripts/*.py

case_output="$(
  python3 "${BUNDLE_ROOT}/scripts/firing_eval.py" \
    --cases-dir "${BUNDLE_ROOT}/cases" \
    --list
)"
case "${case_output}" in
  *"skills | "*"should-fire | "*"must-not-fire"*) ;;
  *)
    printf 'FAIL: firing eval did not list the bundled cases\n' >&2
    exit 1
    ;;
esac

mkdir -p \
  "${FIXTURE_ROOT}/cases" \
  "${FIXTURE_ROOT}/skills/alpha" \
  "${FIXTURE_ROOT}/skills/beta" \
  "${FIXTURE_ROOT}/transcripts/session"
printf '%s\n' \
  'skill: alpha' \
  'should_fire:' \
  '  - run the alpha workflow' \
  'must_not_fire:' \
  '  - inspect the beta result' \
  >"${FIXTURE_ROOT}/cases/alpha.yaml"
printf '%s\n' '---' 'name: alpha' 'description: fixture' '---' \
  >"${FIXTURE_ROOT}/skills/alpha/SKILL.md"
printf '%s\n' '---' 'name: beta' 'description: fixture' '---' \
  >"${FIXTURE_ROOT}/skills/beta/SKILL.md"
printf '%s\n' \
  '{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Skill","input":{"skill":"alpha"}}]}}' \
  '{"message":{"role":"user","content":[{"type":"text","text":"<command-name>/beta</command-name>"}]}}' \
  >"${FIXTURE_ROOT}/transcripts/session/events.jsonl"
printf '%s\n' \
  '[{"skill":"alpha","expect":"should_fire","prompt":"run the alpha workflow","fired":"alpha"},{"skill":"alpha","expect":"must_not_fire","prompt":"inspect the beta result","fired":"none"}]' \
  >"${FIXTURE_ROOT}/results.json"

score_output="$(
  python3 "${BUNDLE_ROOT}/scripts/firing_eval.py" \
    --cases-dir "${FIXTURE_ROOT}/cases" \
    --score "${FIXTURE_ROOT}/results.json"
)"
case "${score_output}" in
  *"alpha"*"100%"*"GOOD"*) ;;
  *)
    printf 'FAIL: firing eval did not score the explicit fixture correctly\n' >&2
    exit 1
    ;;
esac

python3 "${BUNDLE_ROOT}/scripts/report.py" \
  "${FIXTURE_ROOT}/results.json" \
  --output "${FIXTURE_ROOT}/report.md"
grep -q '| `alpha` | 100% | 100% | GOOD |' "${FIXTURE_ROOT}/report.md" || {
  printf 'FAIL: report renderer did not write the expected GOOD row\n' >&2
  exit 1
}

python3 "${BUNDLE_ROOT}/scripts/usage_audit.py" \
  --skills-dir "${FIXTURE_ROOT}/skills" \
  --transcripts-dir "${FIXTURE_ROOT}/transcripts" \
  --json \
  >"${FIXTURE_ROOT}/audit.json"
python3 - "${FIXTURE_ROOT}/audit.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    audit = json.load(handle)

assert audit["installed"] == 2
assert audit["counts"] == {"alpha": 1, "beta": 1}
assert audit["never_fired"] == []
PY

if grep -R -n -E "${LOCAL_PATH_PATTERN}|${FIXED_MODEL_PATTERN}" \
  "${BUNDLE_ROOT}"; then
  printf 'FAIL: skill-eval contains a machine-local path or fixed model name\n' >&2
  exit 1
fi

printf 'portable skill-eval: PASS\n'
