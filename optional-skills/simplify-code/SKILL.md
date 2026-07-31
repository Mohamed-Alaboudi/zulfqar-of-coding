---
name: simplify-code
description: Simplify recently changed code while preserving behavior, tests, security, accessibility, and public contracts. Use for refactoring, over-engineering review, or reducing a branch diff; not for diagnosing bugs or changing product behavior.
---

# Simplify code

Reduce ownership cost without changing observable behavior.

## Resolve scope

Use the paths or change set named by the user. Otherwise inspect the current branch diff against its
base; if no base is available, use the staged and unstaged changes. Read the changed flow, callers,
tests, repository instructions, and working-tree state before editing. Preserve unrelated user
changes and do not widen scope silently.

Skip generated files, vendored code, lockfiles, formatting-only churn, and documentation-only churn
unless the user explicitly includes them.

## Climb the simplification ladder

Stop at the first sufficient rung:

1. Delete code that need not exist.
2. Reuse an existing project helper, type, or convention.
3. Use the standard library.
4. Use a native platform or database feature.
5. Use an already-installed dependency.
6. Keep the smallest explicit implementation that satisfies the contract.

Remove single-use abstraction layers, pass-through wrappers, speculative configuration, duplicated
branches, and comments that only narrate code. Prefer boring explicit control flow over compressed
cleverness. Do not add a dependency during a simplification pass.

## Preserve invariants

- Preserve behavior, error semantics, compatibility, accessibility, and public interfaces.
- Never remove trust-boundary validation, authorization, security controls, data-loss prevention, or
  a test that protects real behavior.
- Fix a shared root cause when every affected caller already routes through it.
- Do not reset, overwrite, or reformat unrelated changes.
- Stop and request authority if the best simplification changes product behavior or a public
  contract.

Run the focused existing tests and one proportional static or build check after editing. Report what
was deleted or reused, how behavior was verified, and which deliberate complexity remains.
