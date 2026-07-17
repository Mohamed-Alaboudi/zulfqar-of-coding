# pii-scan.sh

**Defends against** committing or pasting PII and credential-shaped strings. It
scans a file, a staged diff, or stdin for 14 categories — email, US SSN,
credit-card-like numbers, generic `sk-`/`pk-` API keys, Stripe / OpenAI /
GitHub / AWS keys, private-key headers, password assignments, JWTs, IPv4
addresses, and US phone numbers — and reports each hit as
`[SEVERITY] category line N preview: <redacted>`. It **never echoes a full
match** (previews keep a couple of chars at each end and asterisk out the
middle), so the scanner's own output can't become the leak. It's a heuristic
shape-scanner, not a validator: treat findings as "go look here," and expect
both false positives and false negatives. Exit `1` on any HIGH-severity finding
(live-looking key or private-key header), `0` otherwise.

Reimplemented from the **ruvnet/ruflo aidefence** pattern; see
`THIRD-PARTY-NOTICES.md`.

> For a **public repo**, prefer `scripts/scan-secrets.sh` — it ports this whole
> battery and adds the categories that matter for an open repo (bare project
> UUIDs / `projectId=`, Slack/Google/Anthropic/GitLab/npm/SendGrid keys,
> private-key filenames, and literal personal/company identifiers) and exits `1`
> on **any** hit, not just HIGH. This `pii-scan.sh` is the lighter, general-purpose
> version.

**Wired in Claude Code**: it is *not* wired as an automatic hook by default (it
runs nowhere on its own) — invoke it manually or wire it yourself:

```bash
pii-scan.sh path/to/file.txt        # scan one file
git diff --cached | pii-scan.sh -    # scan the staged diff
pii-scan.sh --selftest               # built-in detection self-test
```

To make it automatic, register it as a `PreToolUse` command hook (e.g. matcher
`Bash`, gating `git commit`) that pipes the staged diff through it and denies on
exit 1.

**Reimplement as a git `pre-commit` hook** (per-repo, opt-in): put
`git diff --cached | /path/to/pii-scan.sh - || exit 1` in `.git/hooks/pre-commit`.
**As a Codex hook**, wire the same `stdin → exit 1 on HIGH` contract into Codex's
commit or command gate. The per-line category passes and the redaction scheme are
plain bash and port verbatim; only how you feed it the content (staged diff vs.
file vs. tool payload) and how you signal a block differ per host.
