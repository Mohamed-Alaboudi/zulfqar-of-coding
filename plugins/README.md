# Plugin inventory

Plugin caches are installed artifacts, not source code for this repository. This file records the adopted surfaces without vendoring marketplace payloads.

## Enabled at the recorded audit

| Plugin | Version at audit | Purpose | Source channel |
|---|---:|---|---|
| `documents` | 26.630.12135 | Word and Docs-targeted artifacts | OpenAI primary runtime |
| `pdf` | 26.630.12135 | PDF creation, reading, rendering, verification | OpenAI primary runtime |
| `spreadsheets` | 26.630.12135 | Spreadsheet creation and analysis | OpenAI primary runtime |
| `presentations` | 26.630.12135 | PowerPoint and Slides-targeted decks | OpenAI primary runtime |
| `browser` | 26.707.91948 | In-app browser control and local web testing | OpenAI bundled |
| `sites` | 0.1.27 | Website building and hosting | OpenAI bundled |
| `visualize` | 1.0.11 | Interactive visualizations and tools | OpenAI bundled |
| `template-creator` | 26.630.12135 | Artifact-template creation | OpenAI primary runtime |
| `last30days` | 3.16.0 | Recent public-discourse research | [`mvanhorn/last30days-skill`](https://github.com/mvanhorn/last30days-skill) |
| `claude-mem` | 13.11.0 | Cross-session memory retrieval | [`thedotmack/claude-mem`](https://github.com/thedotmack/claude-mem) |
| `deep-research` | cortex build | Cited fan-out research and verification | [`Mohamed-Alaboudi/deep-research`](https://github.com/Mohamed-Alaboudi/deep-research) |
| `security-guidance` | 2.0.6 | Security-oriented lifecycle guidance | Anthropic official plugins |

Versions are audit evidence, not evergreen requirements. Install through the provider marketplace and accept the provider’s current compatible version.

## Observed but not asserted enabled

| Artifact | Version observed | Source | Audit status |
|---|---:|---|---|
| Notion Claude plugin | 0.1.0 | [`makenotion/claude-code-notion-plugin`](https://github.com/makenotion/claude-code-notion-plugin) | Local checkout observed; enabled state not established |
| `openai-templates` | 0.1.0 | OpenAI curated remote | Cached; not asserted enabled |

Cache presence is not enabled state. These artifacts are not copied here; license, provenance, and account coupling must be reviewed before adoption.

Never commit plugin caches, marketplace clones, installed-state registries, app connector catalogs, auth data, or provider-managed runtime files.

## Optional security plugin

Current Codex releases offer the official Codex Security plugin through the provider marketplace. Treat it as an optional upstream install rather than vendoring it here. Review its requested tools and data access, install the provider's current compatible release, and run security work inside `workspace-write` or a tighter sandbox unless an externally isolated test explicitly requires more.
