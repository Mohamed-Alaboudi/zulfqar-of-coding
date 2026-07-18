# Fast Codex setup

This package includes a public-safe version of the Luna/Terra/Sol routing setup used to keep Codex fast without assigning expensive reasoning to mechanical work.

## Routing ladder

| Work | Agent | Model / effort | Access |
|---|---|---|---|
| Deterministic extraction and inventories | `luna-reader` | Luna / low | Read-only |
| Exact locations and usages | `finder` | Terra / low | Read-only |
| Architecture and code-path understanding | `explorer` | Terra / medium | Read-only |
| Spec-closed implementation | `worker-light` | Terra / medium | Inherits parent |
| Consequential advice | `sol-advisor` | Sol / high | Read-only |
| Judgment-heavy bounded implementation | `worker-deep` | Sol / high | Inherits parent |
| Final falsification | `verifier` | Sol / high | Read-only |

Model names depend on the catalog available to your account and Codex release. Keep the work-shape routing even when you substitute models: cheapest capable reader first, balanced implementation second, expensive judgment last.

## Install

1. Copy [`configs/codex/config.example.toml`](../configs/codex/config.example.toml) into the relevant parts of `~/.codex/config.toml`; merge it rather than replacing an existing file.
2. Copy the TOML files under [`configs/codex/agents/`](../configs/codex/agents/) into `~/.codex/agents/`.
3. Install the bundled `delegating-work` skill with `./install.sh --agent=codex --skills-only`.
4. Restart Codex and ask it to delegate two independent read-only checks. Use `/agent` to inspect the child threads.
5. Run `skills/delegating-work/scripts/validate-routing` against the installed paths.

`multi_agent` is stable and current Codex releases normally enable subagents. The example leaves `multi_agent_v2` commented out because it was **under development in locally verified Codex CLI 0.144.5**. Enable it only for explicit experimentation, and remove it if `codex --strict-config` rejects it or live dispatch is unreliable.

## Fast mode versus light models

These are different controls:

- A light worker model such as Terra lowers cost and latency for delegated work.
- Codex Fast mode increases supported-model speed by about 1.5× while consuming credits faster. Toggle it with `/fast on`, `/fast off`, or `/fast status`.
- The example [`fast.config.toml`](../configs/codex/profiles/fast.config.toml) is a profile layer. Install it as `~/.codex/fast.config.toml`, then run `codex --profile fast`.

Use light workers for routine fan-out. Use Fast mode only when wall-clock speed is worth the higher credit multiplier.

## Full access / YOLO mode

The [`full-access.config.toml`](../configs/codex/profiles/full-access.config.toml) profile is intentionally separate and is never installed automatically. It removes both approval prompts and the sandbox. It can read or modify unrelated files, use the network, execute destructive commands, and expose credentials reachable by the process. The cross-agent warning and Claude Code equivalent are in [`DANGEROUS-PERMISSIONS.md`](DANGEROUS-PERMISSIONS.md).

Use it only for a trusted repository inside an external disposable sandbox or container with no production credentials. Prefer the safe default:

```shell
codex --sandbox workspace-write --ask-for-approval on-request
```

The one-off bypass flag is `--dangerously-bypass-approvals-and-sandbox`. Do not place it in a shell alias, default config, installer, CI job, or shared project file.

## Known runtime boundary

Configuration validation proves that roles are discoverable and internally consistent; it does not prove that a particular CLI/app-server build can spawn them. If a live smoke trace reports an empty receiver list or no child thread, treat delegation as unavailable for that build and update Codex rather than claiming the routing worked.
