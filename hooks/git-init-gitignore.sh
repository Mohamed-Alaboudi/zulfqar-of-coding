#!/usr/bin/env bash
# git-init-gitignore.sh
# PostToolUse hook (matcher: Bash): after any command containing `git init`,
# seed the new repo's .gitignore with .env rules so secret files can never be
# staged in the first place (companion to git-guardrail's deny). Fail-open.
#
# Portable pattern from the Zulfiqar toolkit (see the README beside
# this file for how to reimplement as a git template or Codex hook).
set -euo pipefail
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
case "$cmd" in *"git init"*) ;; *) exit 0 ;; esac
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"

seed() {
  local root="$1" gi
  [[ -n "$root" && -d "$root/.git" ]] || return 0
  gi="$root/.gitignore"
  grep -qxF '.env' "$gi" 2>/dev/null && return 0
  printf '.env\n.env.*\n!.env.example\n' >> "$gi" 2>/dev/null || true
}

# Each `git init [flags] [dir]` segment: first non-flag arg is the target dir;
# none -> the call's cwd.
found_any=0
while IFS= read -r seg; do
  [[ -n "$seg" ]] || continue
  found_any=1
  dir="$(printf '%s' "$seg" | sed -E 's/^git[[:space:]]+init[[:space:]]*//' \
        | awk '{for(i=1;i<=NF;i++) if($i !~ /^-/){print $i; exit}}')"
  if [[ -n "$dir" ]]; then
    dir="${dir%\"}"; dir="${dir#\"}"; dir="${dir%\'}"; dir="${dir#\'}"
    [[ "$dir" = /* ]] || dir="$cwd/$dir"
    seed "$dir"
  else
    seed "$cwd"
  fi
done < <(printf '%s' "$cmd" | grep -oE 'git[[:space:]]+init[^;&|]*' || true)
[[ "$found_any" -eq 0 ]] && seed "$cwd"
exit 0
