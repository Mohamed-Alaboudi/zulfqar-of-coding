#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

FIXTURE="${TEST_ROOT}/fixture"
mkdir -p "${FIXTURE}/scripts" "${FIXTURE}/skills/sample" "${FIXTURE}/templates" "${FIXTURE}/mcp"
cp "${REPO_ROOT}/install.sh" "${FIXTURE}/install.sh"
cp "${REPO_ROOT}/scripts/verify-install.sh" "${FIXTURE}/scripts/verify-install.sh"
cp "${REPO_ROOT}/templates/AGENTS.md" "${FIXTURE}/templates/AGENTS.md"
cp "${REPO_ROOT}/mcp/claude-code.mcp.json" "${FIXTURE}/mcp/claude-code.mcp.json"
cp "${REPO_ROOT}/mcp/codex.config.toml" "${FIXTURE}/mcp/codex.config.toml"
printf 'sample\n' > "${FIXTURE}/skills/manifest.txt"
printf '%s\n' '---' 'name: sample' 'description: Test fixture.' '---' > "${FIXTURE}/skills/sample/SKILL.md"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "${FIXTURE}/scripts/scan-secrets.sh"
chmod +x "${FIXTURE}/install.sh" "${FIXTURE}/scripts/scan-secrets.sh"

DRY_HOME="${TEST_ROOT}/dry-home"
mkdir -p "${DRY_HOME}"
HOME="${DRY_HOME}" bash "${FIXTURE}/install.sh" --agent=codex --skills-only --dry-run >/dev/null
[ ! -e "${DRY_HOME}/.codex" ] || { printf 'FAIL: dry run wrote files\n' >&2; exit 1; }

COPY_HOME="${TEST_ROOT}/copy-home"
mkdir -p "${COPY_HOME}"
HOME="${COPY_HOME}" bash "${FIXTURE}/install.sh" --agent=codex --skills-only >/dev/null
[ -f "${COPY_HOME}/.codex/skills/sample/SKILL.md" ] && [ ! -L "${COPY_HOME}/.codex/skills/sample" ] || {
  printf 'FAIL: copy mode did not install a real skill directory\n' >&2; exit 1;
}

LINK_HOME="${TEST_ROOT}/link-home"
mkdir -p "${LINK_HOME}"
HOME="${LINK_HOME}" bash "${FIXTURE}/install.sh" --agent=codex --skills-only --symlink >/dev/null
[ -L "${LINK_HOME}/.codex/skills/sample" ] || { printf 'FAIL: symlink mode did not create a link\n' >&2; exit 1; }

printf 'local customization\n' > "${COPY_HOME}/.codex/skills/sample/SKILL.md"
HOME="${COPY_HOME}" bash "${FIXTURE}/install.sh" --agent=codex --skills-only >/dev/null || true
grep -q 'local customization' "${COPY_HOME}/.codex/skills/sample/SKILL.md" || {
  printf 'FAIL: collision handling overwrote local content\n' >&2; exit 1;
}
printf 'y\n' | HOME="${COPY_HOME}" bash "${FIXTURE}/install.sh" --agent=codex --skills-only --force >/dev/null
cmp -s "${FIXTURE}/skills/sample/SKILL.md" "${COPY_HOME}/.codex/skills/sample/SKILL.md" || {
  printf 'FAIL: confirmed --force did not replace the skill\n' >&2; exit 1;
}

PROJECT="${TEST_ROOT}/project"
MCP_HOME="${TEST_ROOT}/mcp-home"
mkdir -p "${PROJECT}" "${MCP_HOME}/.codex"
printf '# user marker\n' > "${MCP_HOME}/.codex/config.toml"
OUTPUT="${TEST_ROOT}/install-output"
printf 'y\n' | HOME="${MCP_HOME}" bash "${FIXTURE}/install.sh" --agent=codex --write-mcp --project-dir="${PROJECT}" > "${OUTPUT}"
grep -q "\[PASS\] AGENTS.md present: ${PROJECT}/AGENTS.md" "${OUTPUT}" || {
  printf 'FAIL: installer did not verify the selected project directory\n' >&2; exit 1;
}
grep -q '# user marker' "${MCP_HOME}/.codex/config.toml" || { printf 'FAIL: MCP write clobbered existing config\n' >&2; exit 1; }
[ "$(grep -c 'appended by zulfqar' "${MCP_HOME}/.codex/config.toml")" -eq 1 ] || {
  printf 'FAIL: MCP template was not appended exactly once\n' >&2; exit 1;
}
HOME="${MCP_HOME}" bash "${FIXTURE}/install.sh" --agent=codex --write-mcp --project-dir="${PROJECT}" >/dev/null
[ "$(grep -c 'appended by zulfqar' "${MCP_HOME}/.codex/config.toml")" -eq 1 ] || {
  printf 'FAIL: repeated MCP install duplicated entries\n' >&2; exit 1;
}

printf 'installer integration: PASS\n'
