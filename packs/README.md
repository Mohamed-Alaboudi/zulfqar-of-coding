# Repo-scoped skill packs

These packs are opt-in collections, not bundled dependencies. Enable them only in the repository subtree that needs them. Keep third-party sources pinned, attributed, and outside this repository unless their license explicitly permits redistribution.

| Pack | Scope | Coordinator / preferred tools | Never publish |
|---|---|---|---|
| `design` | Web UI, screenshot critique, interaction, motion, polish | Project-native design system; exported assets; optional Figma CLI/API | Figma tokens, private files, deployed preview credentials |
| `apps` | Apple/iOS development and review | `xcodebuild`, `xcrun simctl`, Swift Package Manager, Maestro | Signing identities, provisioning profiles, App Store credentials |
| `growth` | Ads, SEO, analytics, attribution, feeds | Authenticated vendor CLIs/APIs with secret injection | Ad-account IDs, analytics credentials, customer data, conversion secrets |
| `voice` | Voice-agent QA and call-flow debugging | Provider CLIs/APIs; optional scoped MCPs | Phone numbers, call recordings, transcripts, provider credentials |

Audited registered names: [`design`](design/manifest.md), [`apps`](apps/manifest.md), [`growth`](growth/manifest.md), and [`voice`](voice/manifest.md).

## Portable activation contract

1. Maintain a local manifest that maps a pack name to reviewed skill sources and pinned revisions.
2. Link or install those skills into `<PROJECT>/.agents/skills`; do not copy an entire global catalog.
3. Record pack ownership in a marker so disabling a pack removes only links created by that pack.
4. Print the exact linked skill names after enablement.
5. Never add an account-bound MCP globally as a side effect of enabling a pack.

The author’s local pack snapshots and rollback copies are intentionally not included. They contain third-party material and machine-specific state; use the public contract above to recreate the layout from licensed upstream sources.
