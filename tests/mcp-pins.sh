#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if grep -R -E 'firecrawl-mcp(["`[:space:]]|$)|@playwright/mcp@latest|duckduckgo-mcp-server(["`[:space:]]|$)' \
  "${REPO_ROOT}/mcp/claude-code.mcp.json" \
  "${REPO_ROOT}/mcp/codex.config.toml" \
  "${REPO_ROOT}/docs/mcp/RECOMMENDED-MCPS.md"; then
  printf 'FAIL: executable MCP dependency is mutable or unversioned\n' >&2
  exit 1
fi

grep -q 'firecrawl-mcp@3.22.3' "${REPO_ROOT}/docs/mcp/RECOMMENDED-MCPS.md" || {
  printf 'FAIL: documented Firecrawl command is not pinned\n' >&2
  exit 1
}

printf 'MCP pins: PASS\n'
