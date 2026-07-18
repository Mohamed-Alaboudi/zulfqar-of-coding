#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while IFS= read -r shell_file; do
  bash -n "${shell_file}"
done < <(find "${REPO_ROOT}" -path "${REPO_ROOT}/.git" -prune -o -type f -name '*.sh' -print)

bash "${REPO_ROOT}/tests/install-contract.sh"
bash "${REPO_ROOT}/tests/installer-integration.sh"
bash "${REPO_ROOT}/tests/codex-routing.sh"
bash "${REPO_ROOT}/tests/mcp-pins.sh"
bash "${REPO_ROOT}/tests/plugin-manifests.sh"
bash "${REPO_ROOT}/tests/skill-frontmatter.sh"
bash "${REPO_ROOT}/hooks/pii-scan.sh" --selftest
bash "${REPO_ROOT}/scripts/scan-secrets.sh" --selftest
bash "${REPO_ROOT}/scripts/scan-secrets.sh" "${REPO_ROOT}"
bash "${REPO_ROOT}/scripts/verify-install.sh" \
  --agent=codex \
  --skills-dir="${REPO_ROOT}/skills" \
  --project-dir="${REPO_ROOT}"

printf 'all tests: PASS\n'
