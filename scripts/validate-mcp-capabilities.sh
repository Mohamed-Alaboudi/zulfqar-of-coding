#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MANIFEST="${REPO_ROOT}/mcp/capabilities.tsv"
CLAUDE_CONFIG="${REPO_ROOT}/mcp/claude-code.mcp.json"
CODEX_CONFIG="${REPO_ROOT}/mcp/codex.config.toml"
EXPECTED_HEADER=$'name\ttransport\tcredentials\tdata_classes\tread\twrite\tlocal_exec\tbrowser\thuman_confirmation\ttrust_authorization\treview_signal'

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

for required_file in "${MANIFEST}" "${CLAUDE_CONFIG}" "${CODEX_CONFIG}"; do
  [[ -f "${required_file}" ]] || fail "missing ${required_file}"
done

header="$(grep -v '^#' "${MANIFEST}" | sed -n '1p')"
[[ "${header}" == "${EXPECTED_HEADER}" ]] || fail 'manifest header does not match the capability schema'

manifest_names="$(mktemp)"
claude_names="$(mktemp)"
codex_names="$(mktemp)"
trap 'rm -f "${manifest_names}" "${claude_names}" "${codex_names}"' EXIT

awk -F '\t' '
  $0 !~ /^#/ {
    if ($1 == "name") next
    if (NF != 11) {
      printf "manifest row %d has %d columns; expected 11\n", NR, NF > "/dev/stderr"
      exit 1
    }
    for (column = 1; column <= NF; column++) {
      if ($column == "") {
        printf "manifest row %d has an empty required field\n", NR > "/dev/stderr"
        exit 1
      }
    }
    if ($2 !~ /^(http|stdio)$/) {
      printf "manifest row %d has invalid transport\n", NR > "/dev/stderr"
      exit 1
    }
    if ($3 != "-" && $3 !~ /^[A-Z][A-Z0-9_]*(,[A-Z][A-Z0-9_]*)*$/) {
      printf "manifest row %d credentials must be environment-variable names only\n", NR > "/dev/stderr"
      exit 1
    }
    for (column = 5; column <= 8; column++) {
      if ($column !~ /^(yes|no)$/) {
        printf "manifest row %d has invalid capability boolean\n", NR > "/dev/stderr"
        exit 1
      }
    }
    if ($11 !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2};.+$/) {
      printf "manifest row %d needs a review date and version signal\n", NR > "/dev/stderr"
      exit 1
    }
    print $1
  }
' "${MANIFEST}" > "${manifest_names}" || fail 'manifest contains an invalid row'

[[ -s "${manifest_names}" ]] || fail 'manifest has no servers'
if duplicate="$(sort "${manifest_names}" | uniq -d)"; [[ -n "${duplicate}" ]]; then
  fail "manifest has duplicate server name(s): ${duplicate}"
fi

sed -nE 's/^    "([^"]+)": \{$/\1/p' "${CLAUDE_CONFIG}" > "${claude_names}"
sed -nE 's/^\[mcp_servers\.([[:alnum:]_-]+)\]$/\1/p' "${CODEX_CONFIG}" > "${codex_names}"
sort -u "${manifest_names}" -o "${manifest_names}"

[[ -s "${claude_names}" ]] || fail 'could not read Claude MCP server names'
[[ -s "${codex_names}" ]] || fail 'could not read Codex MCP server names'
if duplicate="$(sort "${claude_names}" | uniq -d)"; [[ -n "${duplicate}" ]]; then
  fail "Claude MCP config has duplicate server name(s): ${duplicate}"
fi
if duplicate="$(sort "${codex_names}" | uniq -d)"; [[ -n "${duplicate}" ]]; then
  fail "Codex MCP config has duplicate server name(s): ${duplicate}"
fi
sort -u "${claude_names}" -o "${claude_names}"
sort -u "${codex_names}" -o "${codex_names}"
cmp -s "${manifest_names}" "${claude_names}" || fail 'manifest names drift from Claude MCP config'
cmp -s "${manifest_names}" "${codex_names}" || fail 'manifest names drift from Codex MCP config'

claude_block() {
  local name="$1"
  awk -v marker="    \"${name}\": {" '
    $0 == marker { active = 1 }
    active { print }
    active && /^    }[,]?$/ { exit }
  ' "${CLAUDE_CONFIG}"
}

codex_block() {
  local name="$1"
  awk -v main="[mcp_servers.${name}]" -v prefix="[mcp_servers.${name}." '
    $0 == main { active = 1 }
    active && /^\[mcp_servers\./ && $0 != main && index($0, prefix) != 1 { exit }
    active { print }
  ' "${CODEX_CONFIG}"
}

normalize_credentials() {
  if [[ "$1" == "-" || -z "$1" ]]; then
    printf '%s' '-'
  else
    printf '%s\n' "$1" | tr ',' '\n' | LC_ALL=C sort -u | paste -sd, -
  fi
}

while IFS=$'\t' read -r name transport credentials _rest; do
  claude_server="$(claude_block "${name}")"
  codex_server="$(codex_block "${name}")"

  claude_transport="stdio"
  codex_transport="stdio"
  grep -q '"url"[[:space:]]*:' <<<"${claude_server}" && claude_transport="http"
  grep -q '^url[[:space:]]*=' <<<"${codex_server}" && codex_transport="http"
  [[ "${transport}" == "${claude_transport}" ]] || fail "${name} transport drifts from Claude MCP config"
  [[ "${transport}" == "${codex_transport}" ]] || fail "${name} transport drifts from Codex MCP config"

  claude_credentials="$(grep -oE '\$\{[A-Z][A-Z0-9_]*\}' <<<"${claude_server}" | tr -d '${}' | LC_ALL=C sort -u | paste -sd, - || true)"
  codex_credentials="$(grep -oE '"[A-Z][A-Z0-9_]*"' <<<"${codex_server}" | tr -d '"' | LC_ALL=C sort -u | paste -sd, - || true)"
  expected_credentials="$(normalize_credentials "${credentials}")"
  [[ "$(normalize_credentials "${claude_credentials}")" == "${expected_credentials}" ]] || fail "${name} credentials drift from Claude MCP config"
  [[ "$(normalize_credentials "${codex_credentials}")" == "${expected_credentials}" ]] || fail "${name} credentials drift from Codex MCP config"
done < <(grep -v '^#' "${MANIFEST}" | sed '1d')

printf 'MCP capabilities: PASS\n'
