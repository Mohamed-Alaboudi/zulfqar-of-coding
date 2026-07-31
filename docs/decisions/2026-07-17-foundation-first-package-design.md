# Foundation-first package design

Status: approved direction, awaiting implementation-plan approval.

## Objective

Make Zulfiqar a trustworthy, natively distributable Codex/Claude coding package. “Best” remains an evidence target, not a marketing claim: the package must first prove its documented behavior, installation result, dependency reproducibility, and cross-agent packaging.

## Evidence

The local audit found three correctness gaps:

1. `SETUP.md` advertises installer modes and Codex target behavior that `install.sh` does not implement.
2. `verify-install.sh` can pass when unrelated pre-existing skills exist because it does not verify this package’s expected skill set.
3. MCP templates execute mutable unversioned or `@latest` npm packages.

Current official guidance supports the chosen direction:

- [OpenAI Codex customization](https://developers.openai.com/codex/concepts/customization) treats `AGENTS.md`, skills, MCP, plugins, and subagents as complementary layers and recommends enforcement through hooks and automated checks.
- [OpenAI skill authoring](https://developers.openai.com/codex/skills) identifies plugins as the distribution unit for reusable skills and connectors.
- [Claude Code plugin guidance](https://code.claude.com/docs/en/plugins) identifies plugins as the versioned, shareable unit for skills, agents, hooks, and MCP servers.
- [Claude Code marketplace guidance](https://code.claude.com/docs/en/plugin-marketplaces) provides later marketplace distribution, but marketplace publication is outside this first implementation.

## Design

### 1. One truthful support contract

Create one machine-readable expected-skill manifest and make the installer, verifier, tests, and documentation derive their claims from it. Remove unsupported agent values and path-detection claims unless implementation is deliberately added. Correct the gitleaks wording: the built-in scanner is the mandatory gate; Gitleaks is an optional second engine.

### 2. Artifact-specific verification

Update `verify-install.sh` to prove that every expected Zulfiqar skill landed in the selected target. A directory containing unrelated skills must fail. Preserve current collision safety: existing same-named skills are skipped unless the user explicitly forces replacement.

Run installer integration cases under an isolated temporary home directory so tests cannot touch real agent configuration. Cover dry run, copy mode, symlink mode, collision preservation, forced replacement, and MCP non-clobbering.

### 3. Reproducible MCP templates

Replace mutable npm MCP commands with explicit versions. Record package name, version, source, and update policy in provenance. MCP installation stays opt-in, and credentials remain environment placeholders.

### 4. Native plugin packaging without duplication

Add root-level Codex and Claude plugin manifests that point to the existing `skills/` directory. The repository remains the single source of truth; no nested copies or generated vendor cache are committed. Marketplace publication and UI assets are deferred until this installable root package validates on both harnesses.

### 5. Continuous verification

Add CI that runs shell syntax checks, manifest validation, scanner self-tests, the full public-payload scan, installer integration tests, and artifact-specific install verification. CI must use an isolated environment and contain no authenticated steps.

## Boundaries

- Do not vendor third-party skills, plugin caches, or marketplace payloads.
- Do not publish credentials, active MCP configuration, account identifiers, or local backups.
- Do not add more skills merely to increase the count.
- Do not claim universal superiority or marketplace availability without comparative evidence and a published marketplace entry.
- Do not weaken overwrite confirmations, secret scanning, or existing public contracts.

## Acceptance

- Every documented installer mode executes successfully, and no undocumented mode is presented as supported.
- Verification fails when any expected package skill is absent, even if unrelated skills exist.
- No package-resolved MCP dependency is unversioned or uses `@latest`; external CLI prerequisites are identified separately.
- Codex and Claude manifests validate and reference the canonical root skills.
- CI passes all isolated install, syntax, manifest, and secret-scan checks.
- A fresh adversarial review finds no unsupported “best” claim, credential exposure, or duplicated skill source.
