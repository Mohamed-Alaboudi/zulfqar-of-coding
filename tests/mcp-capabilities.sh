#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="${REPO_ROOT}/scripts/validate-mcp-capabilities.sh"

assert_fails() {
  local label="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    printf 'FAIL: %s unexpectedly passed\n' "${label}" >&2
    exit 1
  fi
}

make_fixture() {
  local fixture_root
  fixture_root="$(mktemp -d)"
  mkdir -p "${fixture_root}/scripts"
  cp -R "${REPO_ROOT}/mcp" "${fixture_root}/mcp"
  cp "${VALIDATOR}" "${fixture_root}/scripts/validate-mcp-capabilities.sh"
  printf '%s\n' "${fixture_root}"
}

cleanup_fixture() {
  rm -rf "$1"
}

"${VALIDATOR}" "${REPO_ROOT}"

fixture="$(make_fixture)"
awk 'NR != 3' "${fixture}/mcp/capabilities.tsv" > "${fixture}/mcp/capabilities.tsv.next"
mv "${fixture}/mcp/capabilities.tsv.next" "${fixture}/mcp/capabilities.tsv"
assert_fails 'missing manifest server' "${VALIDATOR}" "${fixture}"
cleanup_fixture "${fixture}"

fixture="$(make_fixture)"
sed -n '3p' "${fixture}/mcp/capabilities.tsv" >> "${fixture}/mcp/capabilities.tsv"
assert_fails 'duplicate manifest server' "${VALIDATOR}" "${fixture}"
cleanup_fixture "${fixture}"

fixture="$(make_fixture)"
awk 'BEGIN { FS = OFS = "\t" } NR == 3 { $3 = "not-a-variable" } { print }' \
  "${fixture}/mcp/capabilities.tsv" > "${fixture}/mcp/capabilities.tsv.next"
mv "${fixture}/mcp/capabilities.tsv.next" "${fixture}/mcp/capabilities.tsv"
assert_fails 'credential literal' "${VALIDATOR}" "${fixture}"
cleanup_fixture "${fixture}"

fixture="$(make_fixture)"
sed -i.bak 's/EXA_API_KEY/EXA_WRONG_KEY/' "${fixture}/mcp/codex.config.toml"
rm "${fixture}/mcp/codex.config.toml.bak"
assert_fails 'Codex credential drift' "${VALIDATOR}" "${fixture}"
cleanup_fixture "${fixture}"

fixture="$(make_fixture)"
sed -i.bak '/\[mcp_servers.context7\]/,/^$/s/^url = /command = /' \
  "${fixture}/mcp/codex.config.toml"
rm "${fixture}/mcp/codex.config.toml.bak"
assert_fails 'Codex transport drift' "${VALIDATOR}" "${fixture}"
cleanup_fixture "${fixture}"

fixture="$(make_fixture)"
sed -i.bak 's/\[mcp_servers.context7\]/[mcp_servers.context-eight]/' \
  "${fixture}/mcp/codex.config.toml"
rm "${fixture}/mcp/codex.config.toml.bak"
assert_fails 'Codex config name drift' "${VALIDATOR}" "${fixture}"
cleanup_fixture "${fixture}"

printf 'MCP capabilities: PASS\n'
