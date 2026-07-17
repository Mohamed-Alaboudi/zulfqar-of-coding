# Spinner Brief

A fill-in brief for spinning up a fresh, uncorrelated reviewer to stress-test a decision, an artifact, or a piece of output before you trust it. The reviewer gets *only* the artifact and its spec — nothing about how it was produced, no access to the reasoning that got there, no framing that nudges toward approval. The point is a genuinely independent second opinion, not a rubber stamp from an agent primed to agree.

Correlated review is the failure mode this prevents: the same agent (or family) that produced an output, asked to check its own output, tends to confirm its own priors and miss the exact blind spots that produced the error in the first place. A spinner is deliberately uncorrelated — different context at minimum, ideally a different model or model family, and never told "here's what I built, does it look good."

## When to use

- Before committing to an expensive or hard-to-reverse decision (architecture choice, irreversible migration, production deploy).
- Before reporting a long or autonomous run as complete (pairs with the audit gate in `long-horizon-launch-brief.md`).
- Whenever you notice you want the review to say yes — that's exactly the signal that you need someone who doesn't already want that.

## Principles

- **Author ≠ judge.** The agent/session that produced the artifact does not review it. Full stop.
- **Give it the artifact and the spec — nothing else.** No process narration, no "here's why I did it this way," no prior conversation. If the artifact can't be judged without that context, that's itself a finding.
- **Default-reject.** The burden of proof is on the artifact to demonstrate it meets the spec, not on the reviewer to find a reason to fail it. Absence of an obvious flaw is not the same as evidence of correctness.
- **Unfalsifiable claims auto-fail.** If the spec (or the artifact's own claims) can't be checked against something observable, that's a fail, not a pass-by-default.
- **Return a verdict, not a conversation.** The output is a decision plus a must-fix list — not a discussion, not hedged "looks mostly fine."

## Skeleton

```
You are an independent reviewer. You did not write this artifact and you
have no stake in it being approved. Default to REJECT unless the evidence
clearly demonstrates the spec is met — the burden of proof is on the
artifact, not on you to find a flaw.

## Spec
<the requirement/success criteria this artifact is supposed to satisfy —
paste it verbatim, do not paraphrase or soften it>

## Artifact
<the actual output to review — code diff, document, deployed URL, plan,
decision — nothing else, no backstory>

## Your task
1. Check the artifact against the spec, line by line / claim by claim.
2. Any claim in the artifact that cannot be verified against something
   observable (a file, a test, a live check) counts as unverified — treat
   unverified as failing, not as passing by default.
3. Actively look for what's wrong, missing, or edge-case-broken — do not
   look for reasons to approve.
4. Do not soften the verdict to be agreeable. A confident, wrong artifact
   deserves a confident FAIL.

## Required output format
VERDICT: PASS | FAIL

If FAIL, a must-fix list:
- <specific, actionable item> — <why it fails the spec>
- <specific, actionable item> — <why it fails the spec>

If PASS, state explicitly what evidence justified it (not "looks good" —
the specific checks that passed).
```

## Notes

- "Uncorrelated" means more than "a different chat window." If the reviewer is the same model family primed with similar training and similar defaults, correlation risk is still real — a different model/provider is stronger, a fresh context in the same model is the minimum bar.
- Don't let the artifact's own confidence leak into the brief. If you paste a PR description that says "this fully resolves the bug," strip the editorializing and paste just the diff — let the reviewer form its own read.
- Pairs naturally with `long-horizon-launch-brief.md`'s adversarial audit gate — that gate *is* a spinner call, scoped to a specific success predicate instead of a general spec.
