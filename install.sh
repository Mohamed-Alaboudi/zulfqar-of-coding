#!/usr/bin/env bash
# install.sh — installer for Zulfqar of Coding.
#
# Copies (or, with --symlink, links) skills/* into your agent's skills dir,
# offers to drop templates/AGENTS.md + CLAUDE.md/GEMINI.md mirrors into a
# target project, and can append a starter MCP config. Dependency-light:
# only bash + coreutils (cp, mkdir, find) are required.
#
# Usage:
#   ./install.sh [--agent=claude|codex|cursor|all] [--dry-run] [--skills-only]
#                [--symlink] [--no-symlink] [--write-mcp] [--force]
#                [--project-dir=PATH] [-h|--help]
#
# See SETUP.md for the full walkthrough.

set -euo pipefail

# Preserve the caller's input stream for confirmations. Skill installation
# reads its manifest on stdin inside a loop, so prompts must not inherit that
# redirected descriptor.
exec 3<&0

# ---------------------------------------------------------------------------
# Paths — no hardcoded home directory anywhere below; everything derived
# from the HOME env var and the script's own location.
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME environment variable is not set}"

# ---------------------------------------------------------------------------
# Defaults / flags
# ---------------------------------------------------------------------------
AGENT=""
DRY_RUN=0
SKILLS_ONLY=0
DO_SYMLINK=0
WRITE_MCP=0
FORCE=0
PROJECT_DIR="$(pwd)"

usage() {
  cat <<'EOF'
install.sh — installer for Zulfqar of Coding

Usage:
  ./install.sh [options]

Options:
  --agent=claude|codex|cursor|all   Target agent. Default: auto-detect
                                     (~/.claude present -> claude,
                                      ~/.codex present  -> codex,
                                      both/neither       -> asks or installs
                                      the generic AGENTS.md-only path).
  --dry-run                         Print the full plan; write nothing.
  --skills-only                     Install skills only; skip AGENTS.md /
                                     CLAUDE.md / GEMINI.md / MCP steps.
  --symlink                         Symlink skills instead of copying them.
                                     OPT-IN. Default is copy (safe on Windows
                                     clones, where symlinks silently break).
  --no-symlink                      Explicit copy mode (this is already the
                                     default; use to override an earlier
                                     --symlink on the command line).
  --write-mcp                       Append the starter MCP server config to
                                     your agent's MCP config file. Without
                                     this flag, install.sh only prints the
                                     recommended config path and a BYO-key
                                     note — it never writes MCP config by
                                     default.
  --force                           Overwrite an existing same-named skill
                                     dir. If the existing target is a real
                                     directory (not a symlink), you will be
                                     asked for a SECOND explicit y/N
                                     confirmation before anything is deleted.
  --project-dir=PATH                Project dir to install AGENTS.md /
                                     CLAUDE.md / GEMINI.md into.
                                     Default: current directory.
  -h, --help                        Show this help and exit.

Examples:
  ./install.sh --dry-run
  ./install.sh --agent=claude
  ./install.sh --agent=all --write-mcp
  ./install.sh --skills-only --agent=codex --symlink
EOF
}

for arg in "$@"; do
  case "${arg}" in
    --agent=*)        AGENT="${arg#--agent=}" ;;
    --dry-run)         DRY_RUN=1 ;;
    --skills-only)      SKILLS_ONLY=1 ;;
    --symlink)          DO_SYMLINK=1 ;;
    --no-symlink)        DO_SYMLINK=0 ;;
    --write-mcp)          WRITE_MCP=1 ;;
    --force)               FORCE=1 ;;
    --project-dir=*)   PROJECT_DIR="${arg#--project-dir=}" ;;
    -h|--help)          usage; exit 0 ;;
    *)
      printf 'install.sh: unknown option: %s\n' "${arg}" >&2
      printf 'Run with -h for usage.\n' >&2
      exit 1
      ;;
  esac
done

case "${AGENT}" in
  ""|claude|codex|cursor|all) ;;
  *)
    printf 'install.sh: --agent must be one of claude|codex|cursor|all (got: %s)\n' "${AGENT}" >&2
    exit 1
    ;;
esac

log()  { printf '%s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }
plan() { printf '  [plan] %s\n' "$*"; }
wrote(){ printf '  [write] %s\n' "$*"; }
skip() { printf '  [skip] %s\n' "$*"; }

# ---------------------------------------------------------------------------
# Preflight: scan-secrets.sh MUST pass before anything else runs.
#
# scan-secrets.sh reads stdin when given no path argument (so it can double
# as a `git diff --cached | scan-secrets.sh -` pre-commit gate) — it is NOT
# "scan the whole repo" by default. install.sh therefore always passes
# REPO_ROOT explicitly as the path argument.
#
# Bounded with a portable watchdog (no GNU `timeout` on stock macOS): if the
# scan hasn't finished within SCAN_TIMEOUT_SECS, treat it as a failed
# preflight rather than hanging the installer forever. Override with
# ZULFQAR_SCAN_TIMEOUT_SECS if a very large repo needs more headroom.
# ---------------------------------------------------------------------------
step "Preflight: scanning this repo for secrets"
SCAN_SCRIPT="${REPO_ROOT}/scripts/scan-secrets.sh"
SCAN_TIMEOUT_SECS="${ZULFQAR_SCAN_TIMEOUT_SECS:-120}"

if [ ! -x "${SCAN_SCRIPT}" ] && [ ! -f "${SCAN_SCRIPT}" ]; then
  printf 'install.sh: ABORT — scripts/scan-secrets.sh not found at %s\n' "${SCAN_SCRIPT}" >&2
  printf 'Refusing to install from a repo whose secret scanner is missing.\n' >&2
  exit 1
fi

SCAN_LOG="$(mktemp)"
trap 'rm -f "${SCAN_LOG}"' EXIT

bash "${SCAN_SCRIPT}" "${REPO_ROOT}" > "${SCAN_LOG}" 2>&1 &
SCAN_PID=$!
SCAN_ELAPSED=0
SCAN_STATUS=""
while kill -0 "${SCAN_PID}" 2>/dev/null; do
  sleep 1
  SCAN_ELAPSED=$((SCAN_ELAPSED + 1))
  if [ "${SCAN_ELAPSED}" -ge "${SCAN_TIMEOUT_SECS}" ]; then
    kill -9 "${SCAN_PID}" 2>/dev/null || true
    wait "${SCAN_PID}" 2>/dev/null || true
    cat "${SCAN_LOG}"
    printf '\ninstall.sh: ABORT — scan-secrets.sh did not finish within %ss.\n' "${SCAN_TIMEOUT_SECS}" >&2
    printf 'Refusing to install without a completed secret scan. Re-run scripts/scan-secrets.sh\n' >&2
    printf 'directly to investigate, or set ZULFQAR_SCAN_TIMEOUT_SECS to allow more time.\n' >&2
    exit 1
  fi
done
wait "${SCAN_PID}"
SCAN_STATUS=$?
cat "${SCAN_LOG}"

if [ "${SCAN_STATUS}" -ne 0 ]; then
  printf '\ninstall.sh: ABORT — scan-secrets.sh reported findings (see above).\n' >&2
  printf 'This protects you: the toolkit will not install from a repo copy that may\n' >&2
  printf 'contain leaked secrets or private paths. Fix the findings and re-run.\n' >&2
  exit 1
fi
log "  preflight: PASS"

# ---------------------------------------------------------------------------
# Detect target agent(s) if --agent was not given.
# ---------------------------------------------------------------------------
CLAUDE_HOME="${HOME_DIR}/.claude"
CODEX_HOME="${HOME_DIR}/.codex"

detect_agent() {
  local have_claude=0 have_codex=0
  [ -d "${CLAUDE_HOME}" ] && have_claude=1
  [ -d "${CODEX_HOME}" ] && have_codex=1

  if [ "${have_claude}" -eq 1 ] && [ "${have_codex}" -eq 1 ]; then
    echo "all"
  elif [ "${have_claude}" -eq 1 ]; then
    echo "claude"
  elif [ "${have_codex}" -eq 1 ]; then
    echo "codex"
  else
    echo "cursor"
  fi
}

if [ -z "${AGENT}" ]; then
  AGENT="$(detect_agent)"
  log "  --agent not given, auto-detected: ${AGENT}"
fi

# ---------------------------------------------------------------------------
# Resolve skills target dir(s) per agent.
# ---------------------------------------------------------------------------
CLAUDE_SKILLS_DIR="${CLAUDE_HOME}/skills"
CODEX_SKILLS_DIR="${CODEX_HOME}/skills"

TARGET_SKILL_DIRS=()
case "${AGENT}" in
  claude) TARGET_SKILL_DIRS=("${CLAUDE_SKILLS_DIR}") ;;
  codex)  TARGET_SKILL_DIRS=("${CODEX_SKILLS_DIR}") ;;
  all)    TARGET_SKILL_DIRS=("${CLAUDE_SKILLS_DIR}" "${CODEX_SKILLS_DIR}") ;;
  cursor)
    log "  Cursor / AGENTS.md-native agents read AGENTS.md directly — no skills dir to install into."
    ;;
esac

step "Plan"
log "  repo root:      ${REPO_ROOT}"
log "  agent:          ${AGENT}"
log "  mode:           $([ "${DRY_RUN}" -eq 1 ] && echo 'DRY RUN (nothing will be written)' || echo 'live')"
log "  skill link mode: $([ "${DO_SYMLINK}" -eq 1 ] && echo 'symlink' || echo 'copy (default)')"
log "  skills-only:    $([ "${SKILLS_ONLY}" -eq 1 ] && echo 'yes' || echo 'no')"
log "  write-mcp:      $([ "${WRITE_MCP}" -eq 1 ] && echo 'yes' || echo 'no (printing instructions only)')"
log "  force:          $([ "${FORCE}" -eq 1 ] && echo 'yes' || echo 'no')"
if [ "${SKILLS_ONLY}" -eq 0 ]; then
  log "  project dir:    ${PROJECT_DIR}"
fi
if [ "${#TARGET_SKILL_DIRS[@]}" -gt 0 ]; then
  for d in "${TARGET_SKILL_DIRS[@]}"; do
    log "  skills target:  ${d}"
  done
fi

# ---------------------------------------------------------------------------
# Skill install
# ---------------------------------------------------------------------------
SRC_SKILLS_DIR="${REPO_ROOT}/skills"
SKILL_MANIFEST="${SRC_SKILLS_DIR}/manifest.txt"
INSTALLED_SKILL_COUNT=0
SKIPPED_SKILL_COUNT=0

install_one_skill() {
  # $1 = skill source dir, $2 = skills target parent dir
  local src="$1" target_parent="$2"
  local name
  name="$(basename "${src}")"
  local dest="${target_parent}/${name}"

  if [ -e "${dest}" ] || [ -L "${dest}" ]; then
    if [ "${FORCE}" -ne 1 ]; then
      skip "skill '${name}' already exists at ${dest} (use --force to overwrite)"
      SKIPPED_SKILL_COUNT=$((SKIPPED_SKILL_COUNT + 1))
      return 0
    fi

    # --force given. If the existing target is a REAL directory (not a
    # symlink), require a second explicit y/N confirmation before deleting.
    if [ -d "${dest}" ] && [ ! -L "${dest}" ]; then
      if [ "${DRY_RUN}" -eq 1 ]; then
        plan "would ask to confirm overwrite of REAL directory ${dest} (skipped in dry-run)"
        return 0
      fi
      printf '  [confirm] %s is a real directory, not a symlink.\n' "${dest}"
      printf '  [confirm] --force will DELETE it and replace it with this repo'"'"'s copy.\n'
      printf '  [confirm] Overwrite %s ? [y/N] ' "${dest}"
      local reply=""
      read -r reply <&3 || reply=""
      case "${reply}" in
        y|Y|yes|YES) ;;
        *)
          skip "user declined overwrite of ${dest}"
          SKIPPED_SKILL_COUNT=$((SKIPPED_SKILL_COUNT + 1))
          return 0
          ;;
      esac
    fi

    if [ "${DRY_RUN}" -eq 1 ]; then
      plan "would remove existing ${dest} and reinstall (--force)"
    else
      rm -rf "${dest}"
    fi
  fi

  if [ "${DRY_RUN}" -eq 1 ]; then
    if [ "${DO_SYMLINK}" -eq 1 ]; then
      plan "would symlink ${dest} -> ${src}"
    else
      plan "would copy ${src} -> ${dest}"
    fi
    INSTALLED_SKILL_COUNT=$((INSTALLED_SKILL_COUNT + 1))
    return 0
  fi

  mkdir -p "${target_parent}"
  if [ "${DO_SYMLINK}" -eq 1 ]; then
    ln -s "${src}" "${dest}"
    wrote "symlinked ${dest} -> ${src}"
  else
    cp -R "${src}" "${dest}"
    wrote "copied ${src} -> ${dest}"
  fi
  INSTALLED_SKILL_COUNT=$((INSTALLED_SKILL_COUNT + 1))
}

if [ "${#TARGET_SKILL_DIRS[@]}" -gt 0 ]; then
  step "Installing skills"
  if [ ! -d "${SRC_SKILLS_DIR}" ]; then
    printf 'install.sh: ABORT — skills source dir not found: %s\n' "${SRC_SKILLS_DIR}" >&2
    exit 1
  fi
  if [ ! -f "${SKILL_MANIFEST}" ]; then
    printf 'install.sh: ABORT — skills/manifest.txt not found: %s\n' "${SKILL_MANIFEST}" >&2
    exit 1
  fi

  for target_parent in "${TARGET_SKILL_DIRS[@]}"; do
    log "  target: ${target_parent}"
    if [ "${DRY_RUN}" -eq 1 ] && [ ! -d "${target_parent}" ]; then
      plan "would create ${target_parent}"
    fi
    while IFS= read -r skill_name || [ -n "${skill_name}" ]; do
      case "${skill_name}" in ""|\#*) continue ;; esac
      case "${skill_name}" in
        *[!a-z0-9-]*)
          printf 'install.sh: ABORT — invalid skill name in manifest: %s\n' "${skill_name}" >&2
          exit 1
          ;;
      esac
      skill_src="${SRC_SKILLS_DIR}/${skill_name}"
      if [ ! -d "${skill_src}" ]; then
        printf 'install.sh: ABORT — manifest skill source not found: %s\n' "${skill_src}" >&2
        exit 1
      fi
      install_one_skill "${skill_src}" "${target_parent}"
    done < "${SKILL_MANIFEST}"
  done
  log "  skills installed: ${INSTALLED_SKILL_COUNT}, skipped: ${SKIPPED_SKILL_COUNT}"
fi

# ---------------------------------------------------------------------------
# AGENTS.md / CLAUDE.md / GEMINI.md into the target project
# ---------------------------------------------------------------------------
if [ "${SKILLS_ONLY}" -eq 0 ]; then
  step "Project instruction files (${PROJECT_DIR})"

  install_agents_md() {
    local dest="${PROJECT_DIR}/AGENTS.md"
    if [ -f "${dest}" ]; then
      skip "AGENTS.md exists, skipping (${dest})"
      return 0
    fi
    if [ "${DRY_RUN}" -eq 1 ]; then
      plan "would copy templates/AGENTS.md -> ${dest}"
      return 0
    fi
    printf '  [confirm] Copy templates/AGENTS.md into %s ? [y/N] ' "${dest}"
    local reply=""
    read -r reply || reply=""
    case "${reply}" in
      y|Y|yes|YES)
        mkdir -p "${PROJECT_DIR}"
        cp "${REPO_ROOT}/templates/AGENTS.md" "${dest}"
        wrote "AGENTS.md -> ${dest}"
        ;;
      *)
        skip "user declined AGENTS.md install"
        ;;
    esac
  }

  # CLAUDE.md / GEMINI.md are mirrors of AGENTS.md: prefix header + body.
  # Written as real copies (never symlinks — symlinks break on Windows
  # clones), and only ever alongside a freshly-installed AGENTS.md, never
  # over an existing project AGENTS.md that install_agents_md declined to
  # touch (that project's CLAUDE.md/GEMINI.md may be intentionally
  # different and unrelated to this repo's template).
  install_mirror_md() {
    local mirror_name="$1" agent_label="$2" reads_not="$3"
    local dest="${PROJECT_DIR}/${mirror_name}"
    local agents_md="${PROJECT_DIR}/AGENTS.md"

    if [ -f "${dest}" ]; then
      skip "${mirror_name} exists, skipping (${dest})"
      return 0
    fi
    if [ ! -f "${agents_md}" ]; then
      skip "${mirror_name} skipped — no AGENTS.md present at ${agents_md} to mirror"
      return 0
    fi
    if [ "${DRY_RUN}" -eq 1 ]; then
      plan "would write ${dest} as a real-copy mirror of ${agents_md}"
      return 0
    fi
    printf '  [confirm] Write %s as a mirror of AGENTS.md (for %s) ? [y/N] ' "${dest}" "${agent_label}"
    local reply=""
    read -r reply || reply=""
    case "${reply}" in
      y|Y|yes|YES)
        {
          printf '> This repository uses AGENTS.md as its canonical instruction file. This file mirrors it for %s (which reads %s, not AGENTS.md).\n\n' "${agent_label}" "${reads_not}"
          cat "${agents_md}"
        } > "${dest}"
        wrote "${mirror_name} -> ${dest} (real copy, not a symlink)"
        ;;
      *)
        skip "user declined ${mirror_name} install"
        ;;
    esac
  }

  case "${AGENT}" in
    claude)
      install_agents_md
      install_mirror_md "CLAUDE.md" "Claude Code" "CLAUDE.md"
      ;;
    codex|cursor)
      install_agents_md
      ;;
    all)
      install_agents_md
      install_mirror_md "CLAUDE.md" "Claude Code" "CLAUDE.md"
      install_mirror_md "GEMINI.md" "Gemini CLI" "GEMINI.md"
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# MCP config
# ---------------------------------------------------------------------------
if [ "${SKILLS_ONLY}" -eq 0 ]; then
  step "MCP server config"

  CLAUDE_MCP_SRC="${REPO_ROOT}/mcp/claude-code.mcp.json"
  CODEX_MCP_SRC="${REPO_ROOT}/mcp/codex.config.toml"
  CLAUDE_MCP_DEST="${CLAUDE_HOME}/mcp.json"
  CODEX_MCP_DEST="${CODEX_HOME}/config.toml"

  print_mcp_instructions() {
    local label="$1" src="$2" dest="$3"
    log "  ${label}:"
    log "    recommended config: ${src}"
    log "    target path:        ${dest}"
    log "    Every credential-shaped field in that file is a \${ENV_VAR} placeholder —"
    log "    bring your own key and export the matching env var yourself."
    log "    Re-run with --write-mcp to append these servers automatically (existing"
    log "    entries in your config are never touched or clobbered)."
  }

  append_json_mcp() {
    # Best-effort, dependency-light append for the Claude Code mcp.json shape.
    # Only ever ADDS: if the dest file already exists, do not risk corrupting
    # a hand-maintained JSON file with a naive merge — print instructions
    # instead and let the user merge by hand.
    local src="$1" dest="$2"
    if [ "${DRY_RUN}" -eq 1 ]; then
      if [ -f "${dest}" ]; then
        plan "would print merge instructions for ${dest} (file exists, not auto-merging JSON)"
      else
        plan "would create ${dest} from ${src}"
      fi
      return 0
    fi
    if [ -f "${dest}" ]; then
      log "  ${dest} already exists — not auto-merging JSON (risk of corrupting your config)."
      log "  Merge by hand: open ${src} and add any missing entries from its \"mcpServers\" block"
      log "  into the \"mcpServers\" block of ${dest}."
      return 0
    fi
    mkdir -p "$(dirname "${dest}")"
    cp "${src}" "${dest}"
    wrote "${dest} (from ${src})"
  }

  append_toml_mcp() {
    # TOML is line-appendable: Codex config.toml is a flat file of
    # [mcp_servers.<name>] tables, so appending new tables is safe as long
    # as none of the table names already exist in the dest file.
    local src="$1" dest="$2"
    if [ "${DRY_RUN}" -eq 1 ]; then
      if [ -f "${dest}" ]; then
        plan "would check ${dest} for existing [mcp_servers.*] tables, then append any new ones from ${src}"
      else
        plan "would create ${dest} from ${src}"
      fi
      return 0
    fi
    if [ ! -f "${dest}" ]; then
      mkdir -p "$(dirname "${dest}")"
      cp "${src}" "${dest}"
      wrote "${dest} (from ${src})"
      return 0
    fi

    local any_conflict=0
    while IFS= read -r table_name; do
      [ -n "${table_name}" ] || continue
      if grep -qF "[mcp_servers.${table_name}]" "${dest}" 2>/dev/null; then
        log "  [mcp_servers.${table_name}] already present in ${dest} — leaving it untouched."
        any_conflict=1
      fi
    done < <(grep -oE '^\[mcp_servers\.[A-Za-z0-9_-]+\]' "${src}" | sed -E 's/^\[mcp_servers\.([A-Za-z0-9_-]+)\]$/\1/')

    if [ "${any_conflict}" -eq 1 ]; then
      log "  Some servers already exist in ${dest}; not appending anything automatically to avoid duplicates."
      log "  Add missing servers by hand from ${src}."
      return 0
    fi

    {
      printf '\n# --- appended by zulfqar-of-coding install.sh (--write-mcp) ---\n'
      cat "${src}"
    } >> "${dest}"
    wrote "appended MCP servers from ${src} -> ${dest}"
  }

  case "${AGENT}" in
    claude)
      if [ "${WRITE_MCP}" -eq 1 ]; then append_json_mcp "${CLAUDE_MCP_SRC}" "${CLAUDE_MCP_DEST}"
      else print_mcp_instructions "Claude Code" "${CLAUDE_MCP_SRC}" "${CLAUDE_MCP_DEST}"; fi
      ;;
    codex)
      if [ "${WRITE_MCP}" -eq 1 ]; then append_toml_mcp "${CODEX_MCP_SRC}" "${CODEX_MCP_DEST}"
      else print_mcp_instructions "Codex" "${CODEX_MCP_SRC}" "${CODEX_MCP_DEST}"; fi
      ;;
    all)
      if [ "${WRITE_MCP}" -eq 1 ]; then
        append_json_mcp "${CLAUDE_MCP_SRC}" "${CLAUDE_MCP_DEST}"
        append_toml_mcp "${CODEX_MCP_SRC}" "${CODEX_MCP_DEST}"
      else
        print_mcp_instructions "Claude Code" "${CLAUDE_MCP_SRC}" "${CLAUDE_MCP_DEST}"
        print_mcp_instructions "Codex" "${CODEX_MCP_SRC}" "${CODEX_MCP_DEST}"
      fi
      ;;
    cursor)
      log "  Cursor MCP config is per-IDE (Settings > MCP) — see ${CLAUDE_MCP_SRC} for the server list to add by hand."
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# Done. Hand off to verify-install.sh (unless this was only a dry run — a
# dry run wrote nothing, so there's nothing to verify).
# ---------------------------------------------------------------------------
step "Summary"
if [ "${#TARGET_SKILL_DIRS[@]}" -gt 0 ]; then
  log "  skills: ${INSTALLED_SKILL_COUNT} installed, ${SKIPPED_SKILL_COUNT} skipped"
fi

if [ "${DRY_RUN}" -eq 1 ]; then
  log "  dry run complete — nothing was written."
  log "  re-run without --dry-run to apply this plan."
  exit 0
fi

VERIFY_SCRIPT="${REPO_ROOT}/scripts/verify-install.sh"
if [ -f "${VERIFY_SCRIPT}" ]; then
  step "Running verify-install.sh"
  bash "${VERIFY_SCRIPT}" --agent="${AGENT}" --project-dir="${PROJECT_DIR}"
else
  log "  verify-install.sh not found at ${VERIFY_SCRIPT} — skipping verification."
fi
