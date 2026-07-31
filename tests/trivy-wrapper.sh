#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

output="$(bash "${REPO_ROOT}/scripts/run-trivy.sh" --print-command)"

case "${output}" in
  *'zulfiqar-trivy-cache:/root/.cache/trivy'*'aquasec/trivy:0.72.0@sha256:cffe3f5161a47a6823fbd23d985795b3ed72a4c806da4c4df16266c02accdd6f'*'fs'*'--scanners vuln,misconfig,license'*'.'*) ;;
  *)
    printf 'FAIL: Trivy command is not pinned or lacks the expected repository scanners\n' >&2
    exit 1
    ;;
esac

if grep -Eq ':(latest|edge)([[:space:]]|$)' "${REPO_ROOT}/scripts/run-trivy.sh"; then
  printf 'FAIL: mutable Trivy image tag detected\n' >&2
  exit 1
fi

if grep -q -- '--scanners .*secret' "${REPO_ROOT}/scripts/run-trivy.sh"; then
  printf 'FAIL: Trivy duplicates the native secret gate and its synthetic fixtures\n' >&2
  exit 1
fi

printf 'Trivy wrapper: PASS\n'
