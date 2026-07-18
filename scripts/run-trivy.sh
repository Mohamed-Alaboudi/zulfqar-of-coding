#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRIVY_IMAGE="aquasec/trivy:0.72.0@sha256:cffe3f5161a47a6823fbd23d985795b3ed72a4c806da4c4df16266c02accdd6f"

case "${1:-}" in
  --print-command)
    printf 'docker run --rm -v <repo>:/workspace:ro -v zulfqar-trivy-cache:/root/.cache/trivy -w /workspace %s fs --exit-code 1 --severity HIGH,CRITICAL --scanners vuln,misconfig,license .\n' "${TRIVY_IMAGE}"
    exit 0
    ;;
  -h|--help)
    printf 'usage: scripts/run-trivy.sh [--print-command]\n'
    printf 'Scans the current repository read-only with pinned Trivy; HIGH/CRITICAL findings fail.\n'
    exit 0
    ;;
  '') ;;
  *)
    printf 'unknown argument: %s\n' "$1" >&2
    exit 2
    ;;
esac

exec docker run --rm \
  -v "${REPO_ROOT}:/workspace:ro" \
  -v "zulfqar-trivy-cache:/root/.cache/trivy" \
  -w /workspace \
  "${TRIVY_IMAGE}" \
  fs \
  --exit-code 1 \
  --severity HIGH,CRITICAL \
  --scanners vuln,misconfig,license \
  .
