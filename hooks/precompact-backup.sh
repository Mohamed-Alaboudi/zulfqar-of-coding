#!/usr/bin/env bash
# precompact-backup.sh
# PreCompact hook: back up the full transcript before any compaction (auto or
# manual) so nothing is lost if compaction eats context a handoff missed.
# Keeps the newest 30 backups. Fail-open everywhere.
#
# Portable pattern from the Zulfqar of Coding toolkit. The backup dir defaults
# to $HOME/.claude/transcript-backups; override CC_BACKUP_DIR to relocate it.
# See precompact-backup.README.md for reimplementation notes.
set -euo pipefail

input="$(cat)"
tp="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)"
sid="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || echo unknown)"
[[ -z "$tp" || ! -r "$tp" ]] && exit 0

dir="${CC_BACKUP_DIR:-$HOME/.claude/transcript-backups}"
mkdir -p "$dir" 2>/dev/null || exit 0
safe_sid="${sid//[^A-Za-z0-9._-]/_}"
cp "$tp" "$dir/$(date +%Y%m%d-%H%M%S)-${safe_sid}.jsonl" 2>/dev/null || exit 0

# Retention: keep newest 30.
ls -t "$dir"/*.jsonl 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null || true
exit 0
