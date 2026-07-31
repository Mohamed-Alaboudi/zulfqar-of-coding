# Third-party notices

This file covers artifacts this toolkit **does ship as files** — small,
specific reimplementations or adaptations of a pattern that originated
upstream — as distinct from the full plugin/skill bundles this toolkit only
*points to* (see [`docs/CREDITS-AND-UPSTREAM.md`](docs/CREDITS-AND-UPSTREAM.md)
for those).

For each artifact below: what it is, the upstream it derives from, that
upstream's license, and an explicit statement of relationship
(reimplemented vs. derived). Original copyright in every case remains with
the upstream author — nothing here claims authorship of the underlying idea
or original code.

## Shipped artifacts

### `config-protection.js`

- **What**: A hook that blocks writes to sensitive config paths (guards
  against an agent accidentally overwriting its own permission/settings
  files).
- **Upstream**: [affaan-m/ECC](https://github.com/affaan-m) — Affaan Mustafa.
- **License**: MIT.
- **Relationship**: Derived. Adapted from the upstream project's approach to
  config-write protection; not a byte-for-byte copy, but the guard logic and
  path-matching strategy trace directly to that source.

### Anti-sycophancy hook pattern

- **What**: A `UserPromptSubmit` hook pattern that structurally discourages
  reflexive agreement — nudges the model toward stating what's verified vs.
  assumed vs. unknown rather than defaulting to affirmation.
- **Upstream**: [0xcjl/anti-sycophancy](https://github.com/0xcjl) — 0xcjl.
- **License**: (see upstream repo for current terms).
- **Relationship**: Reimplemented. This toolkit's version is a fresh
  implementation of the same *pattern* (structural anti-sycophancy
  enforcement via a prompt-submit hook), not a code copy — the idea and
  general approach originate with 0xcjl's project.

### `security-validators` SSRF guard

- **What**: Validation logic that blocks server-side request forgery when
  code fetches an agent-influenced or user-supplied URL (denylists internal/
  loopback/link-local address ranges, blocks redirect-based bypasses).
- **Upstream patterns from**: [qazbnm456/awesome-web-security](https://github.com/qazbnm456/awesome-web-security).
- **License**: (curated list repo — see upstream for terms; this is a
  patterns/knowledge source, not a code dependency).
- **Relationship**: Reimplemented from documented patterns. The SSRF-guard
  *techniques* (IP-range denylists, redirect-chain re-validation) are
  well-documented security patterns catalogued in that awesome-list; this
  toolkit's implementation is original code applying those patterns, not a
  copy of any single upstream implementation.

### `security-validators` path guard

- **What**: `path_within_allowed.py` — validation that a resolved filesystem
  path stays inside an allow-listed set of directories, blocking path-traversal
  (`../`, symlink, and absolute-path escapes) when code opens an
  agent-influenced or user-supplied path.
- **Upstream pattern from**: [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers)
  — `src/filesystem/path-validation.ts` (`isPathWithinAllowedDirectories`).
- **License**: MIT.
- **Relationship**: Reimplemented. The containment-check *technique* traces to
  that upstream validator; this toolkit's file is original Python applying the
  same approach, not a port or copy of the TypeScript source. The MIT license
  text (below) covers this upstream as well.

### `pii-scan` pattern

- **What**: A scanner that flags PII and secret-shaped strings (emails,
  API-key patterns, tokens, etc.) in a diff or file before it's committed or
  sent to a model.
- **Upstream**: Modeled after [ruvnet/ruflo](https://github.com/ruvnet/ruflo) aidefence.
- **License**: (see upstream repo for current terms).
- **Relationship**: Reimplemented. This toolkit's scanner follows the same
  *category structure* (multiple PII/secret pattern classes checked in one
  pass) modeled after ruflo's aidefence component, implemented independently.

### Superpowers workflow patterns

- **What**: The `brainstorming`, `receiving-code-review`,
  `systematic-debugging`, `unstick`, `verification-before-completion`, and
  `writing-plans` skill bodies.
- **Upstream pattern from**:
  [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent.
- **License**: MIT, Copyright (c) 2025 Jesse Vincent.
- **Relationship**: Reimplemented. Zulfiqar keeps the broad design-first,
  evidence-first debugging, review intake, strategy reset, verification gate,
  and executable-planning ideas while using new, condensed prose and
  structure. It does not ship the upstream skill bodies or helper files.

### Stop Slop editing pattern

- **What**: The compact `stop-slop` skill body.
- **Upstream pattern from**:
  [Hardik Pandya's Stop Slop](https://github.com/aiskillstore/marketplace/tree/main/skills/hardikpandya/stop-slop).
- **License**: MIT, Copyright (c) 2025 Hardik Pandya.
- **Relationship**: Reimplemented. Zulfiqar applies the general practice of
  removing generic AI-writing habits with new prose and a smaller two-pass
  workflow. It does not ship the upstream body, reference files, or bundled
  license file.

## License summary

| Artifact | Upstream license | Relationship |
|---|---|---|
| `config-protection.js` | MIT | Derived |
| Anti-sycophancy hook pattern | See upstream | Reimplemented |
| `security-validators` SSRF guard | See upstream (patterns catalog) | Reimplemented |
| `security-validators` path guard | MIT (modelcontextprotocol/servers) | Reimplemented |
| `pii-scan` pattern | See upstream | Reimplemented |
| Six Superpowers-inspired skill bodies | MIT | Reimplemented |
| `stop-slop` skill body | MIT | Reimplemented |

## MIT license text

The newly attributed upstream works retain these notices:

```text
Copyright (c) 2025 Jesse Vincent
Copyright (c) 2025 Hardik Pandya
```

The MIT items above (`config-protection.js`, from affaan-m/ECC; and the
`security-validators` path guard, from modelcontextprotocol/servers), plus the
Superpowers and Stop Slop patterns, use the standard MIT license text
reproduced once here:

```
MIT License

Copyright (c) <year> <copyright holders>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
```

The actual copyright holder and year for each original upstream work
(affaan-m/ECC; modelcontextprotocol/servers) should be read from that
project's own `LICENSE` file — the placeholder above is the license
*template* text, not a claim of authorship by this repo.
