# precompact-backup.sh

**Defends against** silent context loss at compaction. When an agent session's
context window fills and the transcript is compacted (automatically or on
demand), whatever the summariser drops is gone — including details a handoff
note didn't capture. This hook copies the full raw transcript to a timestamped
`.jsonl` file *before* any compaction runs, so the complete history is always
recoverable. It keeps the newest 30 backups (older ones are pruned) and fails
open everywhere — a backup error never blocks compaction. The backup directory
defaults to `$HOME/.claude/transcript-backups` and can be relocated with the
`CC_BACKUP_DIR` environment variable.

**Wired in Claude Code** as a `PreCompact` hook (fires before both auto and
manual compaction). It reads the event JSON on stdin, which includes
`transcript_path` and `session_id`, and copies the transcript. Register it in
`settings.json`:

```json
{ "hooks": { "PreCompact": [ { "hooks": [
  { "type": "command", "command": "$CLAUDE_PROJECT_DIR/hooks/precompact-backup.sh" } ] } ] } }
```

**Reimplement outside Claude Code**: this hook is specific to a host that (a)
exposes a compaction lifecycle event and (b) hands you a path to the running
transcript, so it has no direct git-hook analogue. **As a Codex hook**, wire it
to whatever Codex exposes as a pre-summarisation / pre-compaction event and copy
the session log it provides; the copy-plus-retention shell ports verbatim. If a
host offers no compaction event at all, approximate it with a periodic
out-of-band copy of the session log file (e.g. a cron/`fswatch` job that
snapshots the log every few minutes and keeps the newest N).
