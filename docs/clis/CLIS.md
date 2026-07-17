# CLI toolbelt — when to reach for each

Command-line tools worth having on `PATH` before you start a coding session,
and the moment each one actually pays off.

| Tool | Reach for it when… | Install |
|---|---|---|
| **gh** | Anything touching GitHub — PRs, issues, releases, Actions runs, repo settings — without leaving the terminal or hand-building API calls. | [cli.github.com](https://cli.github.com) |
| **ripgrep (`rg`)** | Searching code. Faster than `grep`, respects `.gitignore` by default, sane defaults for recursive multi-file search. Prefer it over `grep -r` and over reading whole files to find one symbol. | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep#installation) |
| **gitleaks** | Before every commit that might touch config, env-loading code, or anything copy-pasted from a dashboard. Scans for hardcoded secrets/keys/tokens in the working tree or history. **Recommended install** — cheap insurance, catches what a hurried human misses. | [github.com/gitleaks/gitleaks](https://github.com/gitleaks/gitleaks#installing) |
| **Google Workspace CLI (`gws`)** | Scriptable Gmail, Calendar, Drive, Sheets, Docs, Tasks, Contacts, and other Workspace operations. Keep OAuth credentials and account data outside the repo. This community CLI explicitly states it is not an officially supported Google product. | [`googleworkspace/cli`](https://github.com/googleworkspace/cli), or `brew install googleworkspace-cli` |
| **pandoc + typst** | Turning Markdown into a properly typeset PDF (or DOCX/HTML/EPUB). `pandoc` converts, `typst` is the modern typesetting backend — noticeably faster and easier to theme than a LaTeX toolchain for this use case. | [pandoc.org/installing](https://pandoc.org/installing.html), [typst.app](https://github.com/typst/typst#installation) |
| **playwright** | Driving a real browser: clicking through an auth flow, screenshotting a rendered page, verifying a deployed UI actually works end to end (not just that the build succeeded). | `npx playwright install` (see [playwright.dev](https://playwright.dev)) — also available as an MCP server, see [`RECOMMENDED-MCPS.md`](../mcp/RECOMMENDED-MCPS.md) |
| **Node.js** | Running `npx`-based browser and MCP tooling. Prefer a project-pinned version rather than relying on a global install. | [nodejs.org](https://nodejs.org) |
| **Dev Container CLI** | Executing unfamiliar repositories inside a reproducible container after host-side read-only inspection. | [`@devcontainers/cli`](https://github.com/devcontainers/cli) |

## Local wrappers → generic equivalents

The author's own setup layers a few thin personal CLI wrappers on top of the
tools above — additional Workspace automation around `gws`, a
Markdown-to-PDF wrapper (a `pandoc` + `typst` invocation baked into one
command), and a platform-reach CLI (fetches from a handful of social/content
platforms for research fan-out). None of those are shipped here — they're
personal scripts tied to one machine's paths and accounts, not generalizable
tools.

The generic equivalents anyone can install:

- **Workspace automation** → `gws` for broad CLI coverage, or Google's own [Google Workspace APIs](https://developers.google.com/workspace) client libraries for an application-specific integration.
- **Markdown → PDF** → `pandoc` + `typst` directly (see the table above). A one-line shell function or Makefile target gets you 90% of what a bespoke wrapper does: `pandoc input.md -o output.pdf --pdf-engine=typst`.
- **Platform-reach research fetches** → each platform's own public API or a maintained scraping library (e.g. `praw` for Reddit, `yt-dlp` for YouTube) — or route through an MCP-based research flow (see [`RECOMMENDED-MCPS.md`](../mcp/RECOMMENDED-MCPS.md) for `firecrawl`/`exa`, which cover most of this without platform-specific glue code).

The point isn't "install these exact wrappers" — it's "notice the repeated
shape of your own workflow and give it a one-command entry point," using
whatever's already on your machine.
