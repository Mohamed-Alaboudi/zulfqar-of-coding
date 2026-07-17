# Status-line template

The local agent setup uses a status-line command, but its executable path and runtime configuration are machine-specific. This folder publishes only the portable configuration shape.

Use [`claude-settings.example.json`](claude-settings.example.json) as a merge fragment. Replace `<STATUSLINE_COMMAND>` locally with a trusted executable. Do not commit the resulting settings file if it contains home-directory paths, account data, tokens, session identifiers, or provider configuration.

A status-line program should consume the agent’s documented JSON input from standard input, emit one concise line, avoid network access, avoid reading secrets, and degrade to empty output on malformed input.
