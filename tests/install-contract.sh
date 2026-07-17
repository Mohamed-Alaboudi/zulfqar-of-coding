#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_ROOT="$(mktemp -d)"
cleanup() {
  case "${FIXTURE_ROOT}" in
    /tmp/*|/var/folders/*) rm -rf -- "${FIXTURE_ROOT}" ;;
    *) printf 'refusing to remove unexpected fixture path: %s\n' "${FIXTURE_ROOT}" >&2 ;;
  esac
}
trap cleanup EXIT

mkdir -p "${FIXTURE_ROOT}/sandbox/.codex/skills/unrelated"
printf '%s\n' '# unrelated' > "${FIXTURE_ROOT}/sandbox/.codex/skills/unrelated/SKILL.md"

if HOME="${FIXTURE_ROOT}/sandbox" bash "${REPO_ROOT}/scripts/verify-install.sh" \
  --agent=codex --project-dir="${REPO_ROOT}" >/dev/null 2>&1; then
  printf 'FAIL: unrelated skill produced a false verification pass\n' >&2
  exit 1
fi

mkdir -p "${FIXTURE_ROOT}/same-names"
while IFS= read -r skill_name || [ -n "${skill_name}" ]; do
  case "${skill_name}" in ""|\#*) continue ;; esac
  mkdir -p "${FIXTURE_ROOT}/same-names/${skill_name}"
  printf '%s\n' '# unrelated same-name skill' > "${FIXTURE_ROOT}/same-names/${skill_name}/SKILL.md"
done < "${REPO_ROOT}/skills/manifest.txt"

if HOME="${FIXTURE_ROOT}/sandbox" bash "${REPO_ROOT}/scripts/verify-install.sh" \
  --agent=codex \
  --skills-dir="${FIXTURE_ROOT}/same-names" \
  --project-dir="${REPO_ROOT}" >/dev/null 2>&1; then
  printf 'FAIL: unrelated same-named skills produced a false verification pass\n' >&2
  exit 1
fi

grep -q 'skills/manifest.txt' "${REPO_ROOT}/install.sh" || {
  printf 'FAIL: installer does not consume the canonical skill manifest\n' >&2
  exit 1
}

if HOME="${FIXTURE_ROOT}/sandbox" bash "${REPO_ROOT}/scripts/verify-install.sh" \
  --agent=gemini --project-dir="${REPO_ROOT}" >/dev/null 2>&1; then
  printf 'FAIL: verifier accepted an unsupported agent\n' >&2
  exit 1
fi

printf 'install contract: PASS\n'
