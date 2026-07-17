# check-unicode-safety.js

**Defends against** "ASCII smuggling" / "Tag smuggling" prompt injection and
stray non-text glyphs. An attacker can hide instructions inside
innocent-looking text using invisible Unicode — the deprecated Tag block
(U+E0000–U+E007F), zero-width spaces/joiners, bidi overrides, invisible math
operators, Hangul/Mongolian fillers — so a PR body, `SKILL.md`, or frontmatter
reads as plain ASCII to a human reviewer while the LLM consumes hidden bytes and
acts on them. This scanner walks every text file under the scan root, flags each
dangerous invisible code point (and stray emoji) with a `file:line:column
U+XXXX` report, and exits `1` if any remain — so hidden instructions can't ride
into a repo unseen. With `--write` it also auto-strips those characters from
writable Markdown/text files (and normalises some whitespace), skipping itself
and any test fixture that intentionally embeds samples. A short allowlist keeps
legitimate symbols like ©, ®, ™.

**Wired in Claude Code / CI** as a gate. The scan root is the current working
directory by default, or `CC_UNICODE_SCAN_ROOT` if set. Run it as a check:

```bash
node hooks/check-unicode-safety.js            # report + exit 1 on any violation
node hooks/check-unicode-safety.js --write    # also sanitize writable text files
```

You can also wire it as a `PreToolUse`/`PostToolUse` command hook in
`settings.json` to scan on write, or invoke it from a project verify step.

**Reimplement as a git `pre-commit` hook**: run
`node hooks/check-unicode-safety.js` over the tree (or scope it to staged files)
and `exit 1` on any finding so a smuggled instruction can never be committed —
this is the highest-value placement since it's the last line before code leaves
a developer's machine. **In CI**, run the same command as a required check on
every PR. **As a Codex hook**, wire it to Codex's file-write or pre-commit gate
with the same exit-code contract. The code-point tables and detection logic are
pure Node with no dependencies and port verbatim to any host that can run
`node`.
