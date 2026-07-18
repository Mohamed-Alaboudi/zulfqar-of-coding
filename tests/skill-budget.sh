#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKER="${REPO_ROOT}/scripts/check-skill-budget.sh"

current_output="$(bash "${CHECKER}")"
case "${current_output}" in
  *"skill budget: PASS"*"count="*"used="*"limit=8000"*) ;;
  *)
    printf 'FAIL: current catalog did not report a passing budget summary\n' >&2
    exit 1
    ;;
esac

temp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${temp_dir}"
}
trap cleanup EXIT

mkdir -p "${temp_dir}/over-budget"
cat > "${temp_dir}/over-budget/SKILL.md" <<'SKILL'
---
name: over-budget
description: this catalog intentionally exceeds the test budget
---
SKILL

if SKILL_BUDGET_SKILLS_DIR="${temp_dir}" SKILL_BUDGET_LIMIT=20 bash "${CHECKER}" >"${temp_dir}/output" 2>&1; then
  printf 'FAIL: over-budget catalog unexpectedly passed\n' >&2
  exit 1
fi

over_budget_output="$(<"${temp_dir}/output")"
case "${over_budget_output}" in
  *"skill budget: FAIL"*"count=1"*"used="*"limit=20"*) ;;
  *)
    printf 'FAIL: over-budget catalog did not report count, used, and limit\n' >&2
    exit 1
    ;;
esac

mkdir -p "${temp_dir}/reordered"
cat > "${temp_dir}/reordered/SKILL.md" <<'SKILL'
---
description: reordered metadata still counts
name: reordered
---
SKILL
reordered_output="$(SKILL_BUDGET_SKILLS_DIR="${temp_dir}/reordered" bash "${CHECKER}")"
case "${reordered_output}" in
  *"count=1"*"used=40"*) ;;
  *)
    printf 'FAIL: reordered frontmatter was not counted correctly\n' >&2
    exit 1
    ;;
esac

mkdir -p "${temp_dir}/missing-description"
cat > "${temp_dir}/missing-description/SKILL.md" <<'SKILL'
---
name: incomplete
---
SKILL
if SKILL_BUDGET_SKILLS_DIR="${temp_dir}/missing-description" bash "${CHECKER}" >/dev/null 2>&1; then
  printf 'FAIL: missing description unexpectedly passed the budget checker\n' >&2
  exit 1
fi

printf 'skill budget: PASS\n'
