---
name: verification-before-completion
description: "Use before claiming work is complete, fixed, passing, deployed, or pushed. Run fresh checks that directly prove the claim and read back changed state."
---

# Verification Before Completion

Match every outward claim to current evidence.

## Claim-to-proof gate

Before committing, pushing, handing off, or saying a result is complete:

1. List the claims you are about to make.
2. Name the command or read-back that would disprove each claim.
3. Run those checks against the final state, not an earlier revision.
4. Read the exit code and relevant output; do not infer success from silence.
5. Confirm changed external state independently:
   - Git: compare local and remote object IDs;
   - deployment: inspect the deployed version and status;
   - data mutation: query the affected record;
   - generated artifact: open or render it.
6. Report exactly what the evidence supports, including warnings and checks
   that were not available.

## Evidence quality

Use the narrowest proof that covers the claim:

| Claim | Required evidence |
|---|---|
| bug fixed | original reproduction now passes plus relevant regressions |
| tests pass | fresh complete test command with zero failures |
| build works | build command exit status, not lint output |
| install works | isolated install followed by file and behavior checks |
| push landed | remote reference equals the intended commit |
| review addressed | every comment mapped to a verified disposition |

Agent reports, code inspection, and confidence are inputs to verification, not
verification themselves.

If a final edit occurs after a check, rerun every gate that the edit could
affect. If a check cannot run, state that limitation instead of upgrading an
assumption into a result.

## Provenance

This condensed Zulfiqar workflow is an independent reimplementation inspired
by the fresh-evidence completion gate in
[obra/superpowers](https://github.com/obra/superpowers). It does not reproduce
the upstream skill text. See `THIRD-PARTY-NOTICES.md`.
