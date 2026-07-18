#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "${REPO_ROOT}/skills/delegating-work/scripts/validate-routing" \
  --config "${REPO_ROOT}/configs/codex/config.example.toml" \
  --agents-dir "${REPO_ROOT}/configs/codex/agents" \
  --skill-dir "${REPO_ROOT}/skills/delegating-work"

grep -q '^approval_policy = "on-request"$' "${REPO_ROOT}/configs/codex/config.example.toml"
grep -q '^sandbox_mode = "workspace-write"$' "${REPO_ROOT}/configs/codex/config.example.toml"

if grep -Eq 'approval_policy = "never"|sandbox_mode = "danger-full-access"' \
  "${REPO_ROOT}/configs/codex/config.example.toml"; then
  printf 'FAIL: dangerous permissions leaked into the safe default\n' >&2
  exit 1
fi

grep -q '^approval_policy = "never"$' "${REPO_ROOT}/configs/codex/profiles/full-access.config.toml"
grep -q '^sandbox_mode = "danger-full-access"$' "${REPO_ROOT}/configs/codex/profiles/full-access.config.toml"
grep -q 'never install or select this profile by default' "${REPO_ROOT}/configs/codex/profiles/full-access.config.toml"

grep -q '^# multi_agent_v2 = true$' "${REPO_ROOT}/configs/codex/config.example.toml"
if grep -q '^multi_agent_v2 = true$' "${REPO_ROOT}/configs/codex/config.example.toml"; then
  printf 'FAIL: experimental multi_agent_v2 enabled in the portable default\n' >&2
  exit 1
fi

grep -q '^\[mcp_servers.exa.env_http_headers\]$' "${REPO_ROOT}/mcp/codex.config.toml"
grep -q '^x-api-key = "EXA_API_KEY"$' "${REPO_ROOT}/mcp/codex.config.toml"
grep -q '^env_vars = \["FIRECRAWL_API_KEY"\]$' "${REPO_ROOT}/mcp/codex.config.toml"

if command -v codex >/dev/null 2>&1; then
  TEMP_CODEX_HOME="$(mktemp -d)"
  trap 'rm -rf "${TEMP_CODEX_HOME}"' EXIT
  for config in \
    "${REPO_ROOT}/configs/codex/config.example.toml" \
    "${REPO_ROOT}/mcp/codex.config.toml"; do
    cp "${config}" "${TEMP_CODEX_HOME}/config.toml"
    CODEX_HOME="${TEMP_CODEX_HOME}" codex mcp-server --strict-config </dev/null >/dev/null
  done
fi

printf 'Codex routing and permission profiles: PASS\n'
