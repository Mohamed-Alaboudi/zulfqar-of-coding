# Public release audit

Audit date: 2026-07-31. This inventory separates portable source from local runtime state so “complete” never means “publish the home directory.”

## Included as source

- 20 reviewed default skills under `skills/`, including required references and scripts.
- 22 reviewed first-party opt-ins under `optional-skills/`, including the portable standard-library skill-evaluation bundle.
- A catalog with 136 observed local Codex, Claude Code, shared, system, and backup entries plus 42 repository body-owner records: [`catalog/skills.tsv`](../catalog/skills.tsv).
- Agent instruction mirrors (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`) and the generic template.
- Prompt, hook, MCP, install, verification, provenance, and CLI documentation.
- A minimal Dev Container that supplies Bash, Git, and Python for isolated verification.
- Secret and PII scanner with a self-test whose credential-shaped fixtures are assembled only at runtime.

## Included as manifests or pointers

- Repo-scoped design, Apple/iOS, growth, and voice pack routing: [`packs/README.md`](../packs/README.md).
- Enabled and observed plugin inventory, with status kept explicit: [`plugins/README.md`](../plugins/README.md).
- Public status-line contract and placeholder example: [`statusline/README.md`](../statusline/README.md).
- Reviewed adopted and observed third-party skills are recorded in `docs/PROVENANCE.yaml`. Their upstream projects remain the canonical source; proprietary document bundles are named and fingerprinted but not redistributed.
- Seven attributed default workflows use independently written, condensed
  bodies. The related third-party skill text and helper files remain upstream.
- CLI toolbelt, including `gws`: [`docs/clis/CLIS.md`](clis/CLIS.md).

## Deliberately excluded

- API keys, tokens, cookies, credentials, `.env` files, auth stores, account IDs, personal email addresses, and active MCP configuration.
- Plugin caches, marketplace clones, generated catalogs, binaries, package-manager caches, and vendor dependencies.
- Session history, project memory, transcripts, logs, reports, deep-research corpora, and machine-specific state.
- Raw backup payloads and dated skill snapshots. Their catalog rows prove they were reviewed without making the payloads public. The public backup contract is documented in [`backups/README.md`](../backups/README.md).
- Third-party pack contents. This repository publishes provenance and routing guidance, not unlicensed copies.
- The private WhatsApp integration, the disabled watcher, host-specific usage tooling, and runtime-managed Codex system skills.

## Audit result

Every local skill entry observed on 2026-07-31 now has an explicit public disposition: default body, optional body, attributed pointer, superseded variant, or exclusion. The catalog validator checks unique body ownership, public-body hashes, provenance links, and drift between both public trees and the default manifest. Local-source fingerprints were verified against all 134 live observed `SKILL.md` files during the audit; a public clone cannot recompute those home-directory hashes. Local installations can still diverge after this audit. Zulfiqar remains a curated public release, not a byte-for-byte home-directory backup.
