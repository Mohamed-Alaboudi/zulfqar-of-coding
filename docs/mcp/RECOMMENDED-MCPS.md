# Recommended MCP servers

Six MCP servers worth wiring up on day one, ranked by how often they earn their
keep. Config for both formats lives next to this doc:

- Claude Code: [`mcp/claude-code.mcp.json`](../../mcp/claude-code.mcp.json)
- Codex: [`mcp/codex.config.toml`](../../mcp/codex.config.toml)

| MCP | Tier | Key needed? | Install | Note |
|---|---|---|---|---|
| **context7** | Core | No | `http` — `https://mcp.context7.com/mcp` | Live, version-pinned library docs. Pull this before trusting your own training data on any API surface — SDKs move faster than model knowledge cutoffs. |
| **duckduckgo** | Core | No | `stdio` — `uvx duckduckgo-mcp-server` | Zero-config web search fallback. No account, no rate-limit surprises. Good default when you don't want to manage a search API key at all. |
| **serena** | Core | No | `stdio` — `serena start-mcp-server` | Symbol-level code navigation (find/rename/insert by symbol, not by line) across large repos. Cuts token spend versus grep-and-read loops on codebases in the tens of thousands of lines. |
| **exa** | Power | **Yes** — `EXA_API_KEY` | `http` — `https://mcp.exa.ai/mcp`, header `x-api-key: ${EXA_API_KEY}` | Neural/semantic web search, meaningfully better than keyword search for "find me the thing that matches this concept" queries. Paid tier past a free quota. |
| **firecrawl** | Power | **Yes** — `FIRECRAWL_API_KEY` | `stdio` — `npx -y firecrawl-mcp`, env `FIRECRAWL_API_KEY` | Full-page scraping/crawling/extraction with JS rendering — handles sites that block plain HTTP fetches. Paid tier past a free quota. |
| **playwright** | Power | No (interactive auth) | `stdio` — `npx @playwright/mcp@latest` | Real browser automation: click, type, screenshot, drive auth flows. First run pops an interactive browser window for trust/login prompts — do that once locally before expecting it to work headless. |

## Tiers, explained

- **Core** — install these regardless of what you're building. No key, no
  billing surface, immediate value.
- **Power** — meaningfully better than the Core equivalent for their niche
  (semantic search, JS-rendered scraping) but gated behind your own API key
  and a paid tier once you're past the free quota. Add them when the Core
  tools start missing.

## Bring your own key

Two servers need a key you provide — nothing here ships with one baked in.

| Env var | Where to get it | Free tier |
|---|---|---|
| `EXA_API_KEY` | [dashboard.exa.ai](https://dashboard.exa.ai) — sign up, create a key | Yes, capped; billed past that |
| `FIRECRAWL_API_KEY` | [firecrawl.dev](https://firecrawl.dev) — sign up, create a key | Yes, capped; billed past that |

Set both as real environment variables (shell profile, `.env` loaded by your
secrets tool, or your agent's own env-injection mechanism) — never hardcode a
key into `claude-code.mcp.json`, `codex.config.toml`, or any file that gets
committed. Both shipped configs reference them only as `${EXA_API_KEY}` /
`${FIRECRAWL_API_KEY}` placeholders; your MCP client resolves those from the
environment at launch.

## Deliberately excluded

A few MCP categories are left out of this list on purpose:

- **Personal/keyed infra MCPs** (e.g. a Supabase project MCP wired to one
  person's database, or a secrets-manager-wrapped MCP like an Infisical
  integration). These are inherently single-tenant — they point at *your*
  database, *your* project ID, *your* org. Shipping one as a "recommended"
  default would either be useless to everyone else or, worse, invite people
  to paste in credentials that don't belong in a public config. If you need
  this class of tool, wire your own project's MCP directly rather than
  adapting a stranger's.
- **Local custom binaries** (bespoke CLIs wrapped as MCP servers that only
  exist on one machine). Not installable by anyone else, so listing them here
  would be a dead end rather than a recommendation. If a workflow like this
  earns its keep repeatedly, the right move is to publish the underlying CLI
  as its own open-source tool — then it belongs in this list.

The six above are the ones that install cleanly for anyone, on any machine,
with nothing but a `git clone` and (for two of them) a free-tier signup.
