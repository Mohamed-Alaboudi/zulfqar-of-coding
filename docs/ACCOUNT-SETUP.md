# Optional accounts and subscriptions

You do not need every service below. Create or connect an account only when a workflow you actually use requires it. Prices, plans, and authentication steps change; verify current details with the provider before subscribing.

| Service | Needed for | Account or subscription | Local credential/configuration |
|---|---|---|---|
| GitHub | Cloning, pushing, issues, pull requests, releases | Free account is sufficient for public repositories; paid plans are optional | Authenticate `gh` locally; never commit its token |
| OpenAI / Codex | Codex and OpenAI API workflows | ChatGPT/Codex access or API billing, depending on the chosen product | Keep API keys in a secret manager or `OPENAI_API_KEY` locally |
| Anthropic / Claude Code | Claude Code workflows | Claude subscription access or Anthropic API billing | Keep API keys in a secret manager or `ANTHROPIC_API_KEY` locally |
| Google Workspace | `gws` access to Gmail, Calendar, Drive, Sheets, Docs, and related services | Google account; Workspace organization only when organizational features are needed | Complete OAuth locally; never publish client secrets, refresh tokens, email addresses, or tenant data |
| Exa | Exa search MCP and API workflows | Exa account and API access | Provide `EXA_API_KEY` locally |
| Firecrawl | Web search, scraping, crawling, and extraction | Firecrawl account; free or paid usage depends on workload | Provide `FIRECRAWL_API_KEY` locally |
| Supabase | Database, Auth, Storage, Edge Functions, and related workflows | Supabase account; paid plan only when project requirements exceed the free tier | Authenticate the CLI locally; never publish access tokens, database URLs, service-role keys, or project credentials |
| Figma | Optional design inspection and asset workflows | Figma account; paid features are optional | Keep personal access tokens and private file identifiers local |
| Vercel | Optional design previews and Sites-compatible web deployments | Vercel account; paid plan depends on deployment needs | Authenticate locally; never publish deployment tokens or protected environment variables |
| Apple Developer | Device signing, TestFlight, and App Store distribution | Free Apple ID for basic development; paid Apple Developer Program membership for distribution | Keep certificates, signing keys, provisioning profiles, issuer IDs, and App Store credentials local |
| Twilio / Telnyx | Optional voice and telephony testing | Provider account with funded usage where required | Keep auth tokens, phone numbers, recordings, and webhook secrets local |
| ElevenLabs | Optional text-to-speech and voice-agent workflows | Account; paid plan depends on usage and model access | Keep API keys, voice IDs tied to private assets, and generated private audio local |
| Infisical | Recommended secret injection for authenticated CLI/API workflows | Account or self-hosted instance; paid features are optional | Store secrets there rather than in this repository |

## Setup rule

Use placeholders such as `${EXA_API_KEY}` in committed configuration. Put real values in a secret manager or an ignored local environment file, confirm that `.env*`, auth files, tokens, cookies, signing material, account identifiers, and backup payloads are excluded, then run `scripts/scan-secrets.sh` before every push.

The MCP examples are in [`mcp/`](../mcp/), CLI guidance is in [`docs/clis/CLIS.md`](clis/CLIS.md), and pack-specific privacy boundaries are in [`packs/README.md`](../packs/README.md).
