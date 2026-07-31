# Credits & upstream bundles

This toolkit **points to** the third-party plugin/skill bundles below rather
than vendoring copies of them. That's a deliberate choice, not an oversight:
copying someone else's plugin into this repo would mean re-shipping their
code under our own tree, tracking their updates by hand, and (for
non-permissive-but-still-open licenses) taking on obligations — like
Apache-2.0's NOTICE-file requirement — that are easy to silently drop the
first time someone edits a vendored copy without reading the license header
again.

Pointing instead means: install the upstream project yourself, from its own
repo, under its own license, updated on its own cadence. This toolkit's
config just tells you it exists and why it's worth having.

For artifacts this toolkit *does* ship as files (small derived hooks/scripts,
not full plugins) rather than merely pointing to, see
[`THIRD-PARTY-NOTICES.md`](../THIRD-PARTY-NOTICES.md) — those carry their own
provenance notes because they're reimplementations/adaptations of a specific
upstream pattern, not straight installs.

## Bundles

| Bundle | Repo | License | Why it's worth having |
|---|---|---|---|
| **compound-engineering** | [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) | MIT © Every | A structured code-review board pattern (multiple review passes with distinct lenses) that catches more than a single pass — good for anything you'd call a "real" PR. |
| **apple-skills** | [vabole/apple-skills](https://github.com/vabole/apple-skills) | MIT | Skill pack for Apple-platform development (Swift/SwiftUI/Xcode conventions) — install if you're shipping iOS/macOS. |
| **ponytail** | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | MIT | "Build lean" discipline: climb-the-ladder-before-writing-code habits, encoded as an installable skill rather than something you have to remember to self-apply. |
| **impeccable** | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Apache-2.0 | Visual/design review pass for web UI — catches spacing, contrast, and layout issues a functional-only review misses. **Apache-2.0 carries a NOTICE-file obligation** — if you redistribute this bundle (not just use it locally), you must preserve its NOTICE file per the license terms. |
| **swiftui-pro** | [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill) | — (see repo) | Deeper SwiftUI-specific agent skill from a well-known Swift educator — pairs with apple-skills for iOS/macOS work. Check the repo directly for its current license before redistributing. |
| **claude-mem** | [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) | Apache-2.0 | Persistent cross-session memory for Claude Code — lets an agent recall "did we solve this before" across sessions instead of starting cold every time. |
| **last30days** | [mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill) | — (see repo) | Pulls recent (last-30-day) chatter on a topic across Reddit/X/YouTube/HN/GitHub/web in one pass — good for "what are people actually saying right now" questions that a static search misses. |
| **security-guidance** | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | — (see repo) | Anthropic's own official security-review plugin — baseline security-review pass, maintained by the same org that ships the agent. |
| **accessibility-testing** | [Community-Access/accessibility-agents](https://github.com/Community-Access/accessibility-agents) | — (see repo) | Source for the locally reviewed accessibility-testing workflow. This toolkit records an install pointer rather than redistributing the skill. |
| **security-threat-model** | [openai/skills](https://github.com/openai/skills) | — (see repo) | Source for the locally reviewed repository-grounded threat-modeling skill. Install from the pinned upstream revision recorded in `PROVENANCE.yaml`. |
| **Supabase agent skills** | [supabase/agent-skills](https://github.com/supabase/agent-skills) | — (see repo) | Source for the reviewed Supabase and Postgres-best-practices skills. Install upstream; do not copy active project credentials or configuration. |
| **Google Workspace CLI** | [googleworkspace/cli](https://github.com/googleworkspace/cli) | Apache-2.0 | Optional `gws` CLI for Workspace automation. It states that it is not an officially supported Google product; OAuth state remains local. |
| **Agent Reach** | [Panniantong/Agent-Reach](https://github.com/Panniantong/Agent-Reach) | — (see repo) | Multi-platform search and retrieval tooling. This repo records the local skill fingerprints but does not publish its bodies, browser state, or authenticated clients. |
| **Firecrawl agent skills** | [firecrawl/skills](https://github.com/firecrawl/skills) | — (see repo) | Upstream home for the locally observed Firecrawl integration and workflow skills. Install upstream rather than copying the local bundle. |
| **Superpowers skills** | [obra/superpowers](https://github.com/obra/superpowers) | MIT | Upstream family for locally installed planning, debugging, TDD, and verification workflows. Full upstream bodies remain pointers. Zulfiqar ships six short, independently written workflows inspired by the same general methods; their relationship is recorded in `THIRD-PARTY-NOTICES.md`. |
| **Stop Slop** | [Hardik Pandya's Stop Slop](https://github.com/aiskillstore/marketplace/tree/main/skills/hardikpandya/stop-slop) | MIT | Source of the locally installed prose-editing bundle. Its body and references remain upstream; Zulfiqar ships a compact, independently written editing workflow with explicit attribution. |
| **BMAD Method family** | [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) | — (see repo) | Branding-level pointer for an unattributed local edge-case review skill. Its exact derivative could not be verified, so the body is not published. |
| **Anthropic service document skills** | [Anthropic consumer terms](https://www.anthropic.com/legal/consumer-terms) | Proprietary | The locally installed document, PDF, and spreadsheet bundles prohibit copying and redistribution. Their names and fingerprints are cataloged; their bodies and helper payloads are excluded. |

## License notes

- **MIT** bundles (compound-engineering, apple-skills, ponytail, Superpowers,
  Stop Slop): permissive, with the copyright and license notice preserved when
  redistributing upstream expression.
- **Apache-2.0** bundles (impeccable, claude-mem, Google Workspace CLI): permissive but carries a
  **NOTICE file** requirement — if you redistribute the licensed work (with
  or without modification), any NOTICE file the upstream ships must be
  preserved and passed along. Since this toolkit only *points to* these
  repos rather than redistributing their code, that obligation sits with
  whoever installs and *then redistributes* the bundle — not with this repo.
- Bundles marked "— (see repo)" don't have a license this document can state
  confidently as of the last update here; check the repo's own `LICENSE`
  file before redistributing.
- The BMAD pointer identifies a project family, not the verified exact
  source of the local derivative. The catalog records that uncertainty
  instead of inventing authorship.
- Zulfiqar's Superpowers-inspired and Stop Slop-inspired bodies use original,
  condensed prose. The upstream skill files and helper payloads are not
  included.
- Anthropic's local document bundles are proprietary and are not
  redistributable from this repository.

This is a point-with-attribution list, not a legal opinion. Read the
upstream's actual license file before you redistribute anything.
