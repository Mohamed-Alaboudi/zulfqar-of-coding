---
name: exa
description: Use when the user says /exa, asks to set up/integrate/use Exa AI, exa.ai, Exa Search, the Exa API, the Exa MCP, exa-js, or exa-py; asks for an Exa starter project; or when a web-research task should preferentially use Exa search inside an AI coding agent.
---

# Exa

Prefer Exa for web search/research when its MCP is connected, and use the official SDKs for repo integrations.

## Tool selection (Claude Code)

In Claude Code, Exa MCP tools may appear as **deferred** — listed by name only, with schemas not
loaded until fetched.

1. Load the schemas first: `ToolSearch` with query `select:mcp__exa__web_search_exa,mcp__exa__web_fetch_exa` (or keyword `exa web search`).
2. Then call `mcp__exa__web_search_exa` for ad-hoc web research and `mcp__exa__web_fetch_exa` to retrieve full page contents.
3. If neither resolves via ToolSearch, the Exa MCP is not connected — check your MCP config's `exa` entry (`{"type":"http","url":"https://mcp.exa.ai/mcp"}`) and restart the agent.
4. For repo integrations, use the SDK matching the codebase: `exa-js` (JS/TS) or `exa-py` (Python).
5. For current docs/precise setup, verify against `https://exa.ai/docs/` before coding.
6. Never hard-code a key. A remote HTTP MCP typically authenticates via a header configured on the
   MCP entry itself (it ignores local env vars); SDK starters use `EXA_API_KEY` in an ignored `.env`
   with a `.env.example` placeholder.
7. On HTTP 402 (credits exhausted): do NOT retry Exa — fall back to a general web-search tool, then
   any other configured search MCP, and tell the user to top up their Exa dashboard.

## Other agents (Codex, Cursor, etc.)

The same tool-selection preference and workflow apply wherever an Exa MCP server or SDK is
configured; only the mechanism for discovering/loading the tool differs by harness. Consult the
harness's own MCP-tool-listing convention if `mcp__exa__*`-style names aren't what it exposes.

## Research workflow

1. Search with a semantically rich query, not keyword soup.
2. Fetch full pages with `mcp__exa__web_fetch_exa` (or the SDK equivalent) only when snippets/highlights aren't enough.
3. Cite source URLs; separate sourced facts from inference.
4. Routing: broad market/vendor/current-events research that needs multi-source, adversarially
   verified synthesis should follow the fan-out + adversarial-verify method (see the deep-research
   method doc) rather than a single Exa call. Use Exa directly for quick facts and when the work
   stays inside one agent turn.

## JS starter

`exa-js` + `dotenv`; `"type":"module"`; read query from `process.argv`; validate `EXA_API_KEY`; `new Exa(process.env.EXA_API_KEY)`; print title/URL/highlights; gitignore `.env`; verify with `node --check`.

## Python starter

`exa-py` + a dotenv loader; read `EXA_API_KEY`; accept a query arg; print title/URL/text or highlights; keep `.env` out of source control with a `.env.example`.
