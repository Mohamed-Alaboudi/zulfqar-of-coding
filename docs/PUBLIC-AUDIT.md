# Public release audit

Audit date: 2026-07-17. This inventory separates portable source from local runtime state so “complete” never means “publish the home directory.”

## Included as source

- 19 portable skills under `skills/`, including their required references and scripts.
- Agent instruction mirrors (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`) and the generic template.
- Prompt, hook, MCP, install, verification, provenance, and CLI documentation.
- Secret and PII scanner with a self-test whose credential-shaped fixtures are assembled only at runtime.

## Included as manifests or pointers

- Repo-scoped design, Apple/iOS, growth, and voice pack routing: [`packs/README.md`](../packs/README.md).
- Enabled and observed plugin inventory, with status kept explicit: [`plugins/README.md`](../plugins/README.md).
- Public status-line contract and placeholder example: [`statusline/README.md`](../statusline/README.md).
- Four reviewed adopted skills—accessibility testing, security threat modeling, Supabase, and Supabase Postgres best practices—are recorded in `docs/PROVENANCE.yaml`. Their upstream projects remain the canonical source.
- CLI toolbelt, including `gws`: [`docs/clis/CLIS.md`](clis/CLIS.md).

## Deliberately excluded

- API keys, tokens, cookies, credentials, `.env` files, auth stores, account IDs, personal email addresses, and active MCP configuration.
- Plugin caches, marketplace clones, generated catalogs, binaries, package-manager caches, and vendor dependencies.
- Session history, project memory, transcripts, logs, reports, deep-research corpora, and machine-specific state.
- Raw backup payloads and dated skill snapshots. The public backup contract is documented in [`backups/README.md`](../backups/README.md).
- Third-party pack contents. This repository publishes provenance and routing guidance, not unlicensed copies.

## Audit result

The initial release was incomplete as an environment map: it omitted the named pack routers, plugin observations, status-line configuration shape, reviewed new-skill provenance, and several CLI entries. Those gaps are represented by the public-safe manifests above. Local installations can still diverge from these portable files; this repository is a curated release, not a byte-for-byte backup.
