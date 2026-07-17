#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for manifest in .codex-plugin/plugin.json .claude-plugin/plugin.json; do
  if [ ! -f "${REPO_ROOT}/${manifest}" ]; then
    printf 'FAIL: missing %s\n' "${manifest}" >&2
    exit 1
  fi
done

[ -d "${REPO_ROOT}/skills" ] || {
  printf 'FAIL: canonical plugin-root-relative skills directory is missing\n' >&2
  exit 1
}

for manifest in .codex-plugin/plugin.json .claude-plugin/plugin.json; do
  grep -q '"name": "zulfqar-of-coding"' "${REPO_ROOT}/${manifest}" || {
    printf 'FAIL: wrong plugin name in %s\n' "${manifest}" >&2
    exit 1
  }
  grep -q '"skills": "./skills/"' "${REPO_ROOT}/${manifest}" || {
    printf 'FAIL: %s does not use the canonical skills tree\n' "${manifest}" >&2
    exit 1
  }
done

printf 'plugin manifests: PASS\n'
