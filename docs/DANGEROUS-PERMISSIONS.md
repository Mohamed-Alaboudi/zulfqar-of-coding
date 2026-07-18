# Dangerous permission bypasses

Both Codex and Claude Code expose an explicit way to remove their normal approval and sandbox boundaries:

```bash
# Codex
codex --dangerously-bypass-approvals-and-sandbox

# Claude Code
claude --dangerously-skip-permissions
```

These switches are intentionally **not** enabled by this repository's installer, default configuration, shell aliases, hooks, or CI. They let agent-generated commands read, modify, and execute with the authority of the surrounding environment.

Use them only inside a disposable external sandbox or an equivalently isolated environment that contains no credentials, personal files, production access, or untrusted mounts. Prefer the ordinary approval flow for day-to-day work.

For Codex, [`configs/codex/profiles/full-access.config.toml`](../configs/codex/profiles/full-access.config.toml) is the same capability as a separate, visibly dangerous profile. It must be selected deliberately; copying the safe example does not activate it.

Before bypassing permissions:

- Confirm the exact working directory, repository provenance, branch, and dirty state.
- Remove credentials and personal data from the environment and mounted paths.
- Inspect repository instructions and executable setup before running anything.
- Keep production services, signing keys, browser sessions, and cloud credentials unreachable.
- Treat all resulting changes as untrusted until the diff and relevant checks have been reviewed.
