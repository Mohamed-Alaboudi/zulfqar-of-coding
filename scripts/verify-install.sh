#!/usr/bin/env bash
# verify-install.sh — smoke check that an install.sh run landed correctly.
#
# Confirms the target skills dir exists and reports how many installed
# skills it contains, confirms CLAUDE.md/GEMINI.md are present when an
# AGENTS.md was installed, and prints a summary + next steps.
#
# Usage:
#   scripts/verify-install.sh [--agent=claude|codex|cursor|all]
#                              [--project-dir=PATH]
#                              [--skills-dir=PATH]
#
# Exit 0 on success (checks that legitimately don't apply — e.g. no MCP
# config because --write-mcp was never used — are reported as "n/a", not
# failures). Exit 1 only if something that SHOULD be there is missing.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:?HOME environment variable is not set}"

AGENT=""
PROJECT_DIR="$(pwd)"
SKILLS_DIR_OVERRIDE=""

for arg in "$@"; do
  case "${arg}" in
    --agent=*)       AGENT="${arg#--agent=}" ;;
    --project-dir=*) PROJECT_DIR="${arg#--project-dir=}" ;;
    --skills-dir=*)  SKILLS_DIR_OVERRIDE="${arg#--skills-dir=}" ;;
    -h|--help)
      printf 'Usage: %s [--agent=claude|codex|cursor|all] [--project-dir=PATH] [--skills-dir=PATH]\n' "$0"
      exit 0
      ;;
  esac
done

CLAUDE_HOME="${HOME_DIR}/.claude"
CODEX_HOME="${HOME_DIR}/.codex"
CLAUDE_SKILLS_DIR="${CLAUDE_HOME}/skills"
CODEX_SKILLS_DIR="${CODEX_HOME}/skills"
if [ -n "${SKILLS_DIR_OVERRIDE}" ]; then
  CLAUDE_SKILLS_DIR="${SKILLS_DIR_OVERRIDE}"
  CODEX_SKILLS_DIR="${SKILLS_DIR_OVERRIDE}"
fi

if [ -z "${AGENT}" ]; then
  have_claude=0; have_codex=0
  [ -d "${CLAUDE_HOME}" ] && have_claude=1
  [ -d "${CODEX_HOME}" ] && have_codex=1
  if [ "${have_claude}" -eq 1 ] && [ "${have_codex}" -eq 1 ]; then
    AGENT="all"
  elif [ "${have_claude}" -eq 1 ]; then
    AGENT="claude"
  elif [ "${have_codex}" -eq 1 ]; then
    AGENT="codex"
  else
    AGENT="cursor"
  fi
fi

case "${AGENT}" in
  claude|codex|cursor|all) ;;
  *)
    printf 'verify-install.sh: --agent must be one of claude|codex|cursor|all (got: %s)\n' "${AGENT}" >&2
    exit 2
    ;;
esac

OK=1
PASS_COUNT=0
FAIL_COUNT=0
NA_COUNT=0

pass() { printf '  [PASS] %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf '  [FAIL] %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); OK=0; }
na()   { printf '  [n/a]  %s\n' "$1"; NA_COUNT=$((NA_COUNT + 1)); }

printf 'Verifying install (agent: %s)\n\n' "${AGENT}"

# ---------------------------------------------------------------------------
# Skills dir check
# ---------------------------------------------------------------------------
check_skills_dir() {
  local label="$1" dir="$2"
  if [ ! -d "${dir}" ]; then
    fail "${label} skills dir not found: ${dir}"
    return 0
  fi
  local manifest="${REPO_ROOT}/skills/manifest.txt"
  local skill_name expected=0 missing=0
  if [ ! -f "${manifest}" ]; then
    fail "expected-skill manifest not found: ${manifest}"
    return 0
  fi
  while IFS= read -r skill_name || [ -n "${skill_name}" ]; do
    case "${skill_name}" in ""|\#*) continue ;; esac
    expected=$((expected + 1))
    if [ ! -f "${dir}/${skill_name}/SKILL.md" ]; then
      fail "${label} skill missing: ${dir}/${skill_name}/SKILL.md"
      missing=$((missing + 1))
    elif ! cmp -s "${REPO_ROOT}/skills/${skill_name}/SKILL.md" "${dir}/${skill_name}/SKILL.md"; then
      fail "${label} skill differs from this Zulfiqar release: ${dir}/${skill_name}/SKILL.md"
      missing=$((missing + 1))
    fi
  done < "${manifest}"
  if [ "${missing}" -eq 0 ]; then
    pass "${label} has all ${expected} expected Zulfiqar skills: ${dir}"
  fi
}

case "${AGENT}" in
  claude) check_skills_dir "Claude Code" "${CLAUDE_SKILLS_DIR}" ;;
  codex)  check_skills_dir "Codex" "${CODEX_SKILLS_DIR}" ;;
  all)
    check_skills_dir "Claude Code" "${CLAUDE_SKILLS_DIR}"
    check_skills_dir "Codex" "${CODEX_SKILLS_DIR}"
    ;;
  cursor)
    na "Cursor / AGENTS.md-native agents have no skills dir to check"
    ;;
esac

# ---------------------------------------------------------------------------
# AGENTS.md / CLAUDE.md / GEMINI.md check
# ---------------------------------------------------------------------------
printf '\n'
AGENTS_MD="${PROJECT_DIR}/AGENTS.md"
CLAUDE_MD="${PROJECT_DIR}/CLAUDE.md"
GEMINI_MD="${PROJECT_DIR}/GEMINI.md"

if [ -f "${AGENTS_MD}" ]; then
  pass "AGENTS.md present: ${AGENTS_MD}"

  case "${AGENT}" in
    claude|all)
      if [ -f "${CLAUDE_MD}" ]; then
        pass "CLAUDE.md present (mirrors AGENTS.md): ${CLAUDE_MD}"
      else
        fail "AGENTS.md exists but CLAUDE.md is missing: ${CLAUDE_MD}"
      fi
      ;;
  esac

  case "${AGENT}" in
    all)
      if [ -f "${GEMINI_MD}" ]; then
        pass "GEMINI.md present (mirrors AGENTS.md): ${GEMINI_MD}"
      else
        fail "AGENTS.md exists but GEMINI.md is missing: ${GEMINI_MD}"
      fi
      ;;
  esac

  if [ "${AGENT}" = "codex" ] || [ "${AGENT}" = "cursor" ]; then
    na "CLAUDE.md/GEMINI.md not expected for --agent=${AGENT} (reads AGENTS.md directly)"
  fi
else
  na "no AGENTS.md at ${AGENTS_MD} — either not installed yet, or this project intentionally skipped it"
fi

# ---------------------------------------------------------------------------
# MCP config check (best-effort — --write-mcp is opt-in, so absence is n/a)
# ---------------------------------------------------------------------------
printf '\n'
CLAUDE_MCP_DEST="${CLAUDE_HOME}/mcp.json"
CODEX_MCP_DEST="${CODEX_HOME}/config.toml"

case "${AGENT}" in
  claude|all)
    if [ -f "${CLAUDE_MCP_DEST}" ]; then
      pass "Claude Code MCP config present: ${CLAUDE_MCP_DEST}"
    else
      na "no Claude Code MCP config at ${CLAUDE_MCP_DEST} (only written with --write-mcp)"
    fi
    ;;
esac
case "${AGENT}" in
  codex|all)
    if [ -f "${CODEX_MCP_DEST}" ]; then
      pass "Codex MCP config present: ${CODEX_MCP_DEST}"
    else
      na "no Codex MCP config at ${CODEX_MCP_DEST} (only written with --write-mcp)"
    fi
    ;;
esac

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\n==> Summary: %d pass, %d fail, %d n/a\n' "${PASS_COUNT}" "${FAIL_COUNT}" "${NA_COUNT}"

if [ "${OK}" -eq 1 ]; then
  printf '\nverify-install: PASS\n'
  printf '\nNext steps:\n'
  case "${AGENT}" in
    claude|all) printf '  - Restart Claude Code (or run /doctor) to pick up newly installed skills.\n' ;;
  esac
  printf '  - Fill in the Commands / Project structure / Boundaries sections of your AGENTS.md.\n'
  printf '  - Run scripts/scan-secrets.sh in YOUR project before your first push, same as this repo does.\n'
  exit 0
else
  printf '\nverify-install: FAIL — see [FAIL] lines above.\n'
  exit 1
fi
