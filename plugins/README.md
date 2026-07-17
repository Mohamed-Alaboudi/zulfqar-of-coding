# Plugin inventory

Plugin caches are installed artifacts, not source code for this repository. This file records the adopted surfaces without vendoring marketplace payloads.

## Enabled official plugins

| Plugin | Version at audit | Purpose | Source channel |
|---|---:|---|---|
| `documents` | 26.630.12135 | Word and Docs-targeted artifacts | OpenAI primary runtime |
| `pdf` | 26.630.12135 | PDF creation, reading, rendering, verification | OpenAI primary runtime |
| `spreadsheets` | 26.630.12135 | Spreadsheet creation and analysis | OpenAI primary runtime |
| `presentations` | 26.630.12135 | PowerPoint and Slides-targeted decks | OpenAI primary runtime |
| `browser` | 26.707.91948 | In-app browser control and local web testing | OpenAI bundled |
| `sites` | 0.1.27 | Website building and hosting | OpenAI bundled |
| `visualize` | 1.0.11 | Interactive visualizations and tools | OpenAI bundled |

Versions are audit evidence, not evergreen requirements. Install through the provider marketplace and accept the provider’s current compatible version.

## Observed but not asserted enabled

| Artifact | Version observed | Source | Audit status |
|---|---:|---|---|
| Notion Claude plugin | 0.1.0 | [`makenotion/claude-code-notion-plugin`](https://github.com/makenotion/claude-code-notion-plugin) | Local checkout observed; enabled state not established |
| `claude-mem` | 13.11.0 | [`thedotmack/claude-mem`](https://github.com/thedotmack/claude-mem) | Cached; not enabled as a plugin |
| `last30days` | 3.16.0 | [`mvanhorn/last30days-skill`](https://github.com/mvanhorn/last30days-skill) | Cached; standalone route exists separately |
| `deep-research` | 3.6.3-cortex | Local marketplace build | Cached; provenance requires review before adoption elsewhere |
| `security-guidance` | 2.0.6 | [`anthropics/claude-plugins-official`](https://github.com/anthropics/claude-plugins-official) | Cached; not asserted enabled |
| `openai-templates` | 0.1.0 | OpenAI curated remote | Cached; not asserted enabled |
| `template-creator` | 26.630.12135 | OpenAI primary runtime | Cached; not asserted enabled |

Cache presence is not enabled state. These artifacts are not copied here; license, provenance, and account coupling must be reviewed before adoption.

Never commit plugin caches, marketplace clones, installed-state registries, app connector catalogs, auth data, or provider-managed runtime files.
