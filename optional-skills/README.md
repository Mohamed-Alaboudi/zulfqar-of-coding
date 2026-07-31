# Optional skills

These reviewed, first-party skill bodies are public source but are not loaded
by the plugin manifests or the default installer. Keeping them opt-in prevents
specialized or manually invoked workflows from consuming the default
skill-discovery budget.

Inspect a skill before installing it. Then copy only the named directory into
the target agent's skill root, after confirming that a same-named skill is not
already present. For example:

```bash
skill_name=concise
test ! -e "${HOME}/.codex/skills/${skill_name}"
cp -R "optional-skills/${skill_name}" "${HOME}/.codex/skills/${skill_name}"
```

For Claude Code, use `${HOME}/.claude/skills/` as the target. Never bulk-copy
this tree over an existing installation. The full provenance and collision
decisions live in [`../catalog/skills.tsv`](../catalog/skills.tsv).
