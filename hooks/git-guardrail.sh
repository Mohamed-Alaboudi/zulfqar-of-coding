#!/usr/bin/env bash
# git-guardrail.sh
# PreToolUse hook (matcher: Bash): deterministic guardrail for three
# provably-destructive command patterns that agent instructions otherwise only
# "trust" the model to avoid:
#   1. git add/commit of .env-style secret files (allows .env.example/.sample/.template)
#   2. force-push to main/master
#   3. rm -rf on filesystem root or home root
# Deny = permissionDecision "deny" with a reason fed back to the model.
# Deliberately NARROW - false negatives are acceptable, false positives are not.
# Fail-open: any parse error -> allow.
#
# Portable pattern from the Zulfiqar toolkit. Reimplement anywhere an
# agent runs shell commands (see git-guardrail.README.md).
set -euo pipefail

input="$(cat)"
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)"
[[ "$tool_name" != "Bash" ]] && exit 0
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[[ -z "$cmd" ]] && exit 0

deny() {
  jq -cn --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}' 2>/dev/null
  exit 0
}

# 1. Committing/staging .env files (but not .env.example/.sample/.template).
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+(add|commit)[^|;&]*\.env\b' \
   && ! printf '%s' "$cmd" | grep -qE '\.env\.(example|sample|template)'; then
  # Auto-fix: make sure the repo's .gitignore covers .env before denying.
  gi_note=""
  cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
  if [[ -n "$cwd" ]]; then
    root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$root" ]] && ! grep -qxF '.env' "$root/.gitignore" 2>/dev/null; then
      printf '.env\n.env.*\n!.env.example\n' >> "$root/.gitignore" 2>/dev/null \
        && gi_note=" .env rules were just auto-added to the repo .gitignore -"
    fi
  fi
  deny "git-guardrail: staging/committing a .env file is blocked (never commit secrets).${gi_note} retry without the .env file; use .env.example for placeholders."
fi

# 2. Force-push targeting main/master.
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push[^|;&]*([[:space:]]-f\b|--force)' \
   && ! printf '%s' "$cmd" | grep -qE '\-\-force-with-lease' \
   && printf '%s' "$cmd" | grep -qE '(^|[[:space:]:/])(main|master)([[:space:]]|$)'; then
  deny "git-guardrail: force-push to main/master is blocked. Use a feature branch, or ask the user for explicit OK (this is a high-stakes pause)."
fi

# 3. rm -rf on / or ~ (root-level catastrophes only).
if printf '%s' "$cmd" | grep -qE '(^|[;&|][[:space:]]*)(sudo[[:space:]]+)?rm[[:space:]]+-[a-zA-Z]*[rf][a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+["'"'"']?(/|~|\$HOME)/?\*?["'"'"']?([[:space:]]|$)'; then
  deny "git-guardrail: rm -rf on filesystem root or home root is blocked. Target a specific subdirectory."
fi

exit 0
