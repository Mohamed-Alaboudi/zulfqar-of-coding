# Deep Research — the fan-out / adversarial-verify / cited-report method

An agent-agnostic procedure for turning a research question into a report you can act on: every
factual claim traces to a source URL or file, and the load-bearing claims survive an adversarial
check before they ship. It generalizes the pattern behind Claude Code's `/dr`-style tooling to any
agent that can run sub-tasks — with a degraded fallback for the ones that can't.

## What it is

Single-pass research from one context window has three failure modes: it searches shallowly
because one thread can only chase so many angles before losing the plot, it accepts what the
first plausible-sounding source says because nothing is pushing back, and it can quietly blend
training-data recall with real fetches without flagging which is which. This method is the fix —
not "search harder," but a different **shape**: split the question into independent legs so each
gets full attention, force every fact to carry its source, then hand the finished draft to a
second, skeptical pass whose only job is to try to break it.

The result reads like conventional research output — an answer with caveats and citations — but
it was produced adversarially: nothing survives to the final report on the strength of one
pass's confidence alone.

## The pipeline

```
Question
   │
   ▼
1. PLAN — break into sub-questions, assign each a research depth
   │        (skip if the question is narrow enough for one pass)
   ▼
2. FAN OUT — parallel scraper/extractor tasks, one per angle
   │          each returns: facts + source URL/path + verbatim quote
   ▼
3. SELF-CHECK — did every angle come back with real, sourced facts?
   │             thin/missing/fabrication-smelling results get one retry
   ▼
4. EXTRACT CLAIMS — pull out the concrete, checkable statements
   │                 tag each: central (answers the question) / supporting / tangential
   ▼
5. ADVERSARIAL VERIFY — a second, skeptical pass checks CENTRAL claims only:
   │                     does the quote actually support the claim? does a
   │                     contradicting source exist? is the source strong enough
   │                     for how strong the claim is?
   ▼
6. LINK CHECK — confirm cited URLs/paths are still live and say what they're cited for
   │
   ▼
7. SYNTHESIZE — write the answer, keep genuine disagreement visible rather than
   │            smoothing it into false confidence, cite everything
   ▼
Cited report
```

Two properties make this different from "search, then write":

- **Neutral fan-out.** Each parallel leg is told the *question*, never the *expected answer*. A
  leg told what conclusion to support will preferentially find evidence for it — this is the
  single highest-leverage guard against fabrication-by-agreement. Phrase every dispatched angle as
  open information-gathering ("what do the docs say about X"), never as confirmation-seeking
  ("confirm that X is true").
- **Default-balanced verification, not default-refute.** The verify pass doesn't try to kill every
  claim; a thinly-sourced but uncontradicted claim survives at low confidence, not zero. It only
  throws a claim out when it finds a concrete, credible contradiction. This matters — a verifier
  tuned to reject anything not airtight produces a report that's technically safe and practically
  useless.

## Sub-agent roles

| Role | Job | What it must NOT do |
|---|---|---|
| **Orchestrator** | Plans sub-questions, dispatches fan-out legs, reads results, extracts claims, batches the verify pass, synthesizes the final report. | Never searches or fetches directly — its entire job is coordination, so a "the scraper failed, let me just look it up myself" moment defeats the whole design. If a leg can't be dispatched, the run aborts cleanly rather than silently degrading to unverified single-pass research. |
| **Scraper / extractor** (fan-out leg) | Collects facts for ONE narrow angle from one source domain — web, codebase, or a specific document set. Every fact carries a source URL/path and, ideally, a verbatim quote. Reports disconfirming evidence with equal weight to confirming evidence. | Doesn't evaluate, synthesize, or guess at what the orchestrator wants to hear. Doesn't report a fact with no real fetch/read behind it — an empty results section is the correct output when nothing was actually found, not an invented one. |
| **Verifier** | Given a batch of claims (with their quote + source), runs an independent check per claim: does the quote support the claim, does a contradiction exist, is the source strong enough. Returns one verdict per claim — confirmed / uncertain / contradicted — never synthesizes new findings of its own. | Doesn't default to refuting everything it can't fully confirm (that produces an over-cautious, useless report). Doesn't skip a claim because the batch is long — an unfinished claim gets an explicit "uncertain, not reached" verdict, never a silent drop. |

A **batch** verifier (one call checking ~10 claims, not one call per claim) keeps the pipeline
affordable — the cost driver is fan-out width, not verify-thoroughness, so batching the cheap part
of verification while keeping the check itself independent per claim is the right trade.

## Model-tiering table

The asymmetric-tiering principle: don't pay ceiling price for mechanical fan-out, don't cheap out
below competent extraction. Fan-out legs need to *read carefully and extract accurately* — that's
a floor, not a stretch goal — but they don't need frontier judgment, because nothing they do is
final. Verification and synthesis are where a wrong call ships to the user, so that's where the
top tier earns its cost.

| Role | Why this tier | Claude tier | Codex tier |
|---|---|---|---|
| Orchestrator (plan/dispatch/synthesize) | Coordination + final judgment call on what the evidence means — this is where mistakes compound into a wrong answer. | Whatever tier the session is already running (opus for judgment-heavy runs) | Session default, or explicit high `model_reasoning_effort` if run as its own agent |
| Scraper / extractor (fan-out leg) | **Competent mid tier, not the floor.** Needs solid instruction-following and long-context extraction accuracy — a leg that misreads a page or fabricates a quote poisons everything downstream, including the verifier that's supposed to catch it. Mechanical and parallel, so it doesn't need frontier reasoning either. | `sonnet` | `model_reasoning_effort = low` to `medium` |
| Verifier (adversarial check) | Judgment step — this is the one place a wrong call directly ships a false claim to the user. Never the same tier as the scrapers; the whole point is a *different, harder-to-fool* pass, not a rubber stamp. | `opus` | `model_reasoning_effort = high` to `xhigh` |
| Final synthesis | Same reasoning as verification: this is what the user actually reads, and framing genuine disagreement honestly (vs. smoothing it into false confidence) is a judgment call, not a mechanical one. | `opus` (or the orchestrator's tier if synthesis is folded into it) | `high` to `xhigh` |

**The explicit caveat:** "competent mid tier" for scrapers is a floor, not a target to undercut.
Bottom-tier extraction doesn't just produce worse research — it actively poisons the pipeline,
because the verifier is checking the scraper's *claims and quotes*, not re-doing the scraper's
work from scratch. A verifier can catch a scraper that got the wrong source; it's much weaker
against a scraper that mangled a *correct* source into an inaccurate quote, because the mangled
quote is what the verifier is handed to check against. If you're going to cut cost somewhere, cut
fan-out *width* (fewer parallel legs) before you cut fan-out *quality* (a weaker model per leg).

This is the config a real pipeline runs — not a hypothetical recommendation.

## Degraded fallback (no subagent primitive)

Not every agent can spawn independent parallel sub-tasks. The pipeline still works with the shape
preserved, just sequential instead of parallel and self-verified instead of independently
verified:

- **Sequential fan-out in one context.** Run each research leg one after another instead of in
  parallel, each as a distinct, bounded step: state the angle, search/read, record facts +
  sources, move to the next angle without carrying forward a running hypothesis about the answer.
  Slower, but the neutral-framing discipline (search for what's *true*, not what confirms a
  leaning) still applies and still matters — arguably more, since there's no independent leg to
  catch a biased framing that crept into an earlier one.
- **A second chat session as the verifier.** Open a fresh conversation (or a fresh context window
  within the same tool) with *only* the draft findings and their sources — not the reasoning that
  produced them. Ask it to check each central claim against its source and flag anything
  unsupported or contradicted. The value of adversarial verification comes from the checker not
  sharing the drafter's blind spots — a fresh session with a narrow brief approximates that even
  without a true sub-agent.
- **A second model as the verifier.** If you have access to more than one model/provider, running
  the verify pass on a different model than the one that drafted the findings is a stronger
  decorrelation than a fresh session on the *same* model, because the two won't share systematic
  blind spots the way same-model instances can.
- **What NOT to skip even in the degraded form:** every fact still needs a source. The verify pass
  is still a distinct step with its own default-balanced (not default-refute) standard. Neutral
  framing during fan-out still holds. The shape survives losing parallelism; it does not survive
  losing the separation between "gather" and "check."

## Per-agent invocation

- **Claude Code:** the native form is a `/dr`-style orchestrator skill that spawns scraper
  sub-agents (`model: sonnet`, tools scoped to search/fetch/grep/read) and a verifier sub-agent
  (`model: opus`) via the `Agent`/`Task` tool, with an explicit rule that the orchestrator itself
  never calls `WebSearch`/`WebFetch`/`Grep` directly — only the sub-agents do, and a failed spawn
  aborts the run rather than silently falling back to direct fetching. That "no fallback to
  self-research" rule is what keeps the verification layer honest; without it, a permissions hiccup
  quietly turns adversarially-verified research into unverified single-pass research with the same
  polished output format.
- **Codex:** either a dedicated skill (Codex Skills use the same `SKILL.md` spec, so the
  orchestrator logic ports directly) that spawns sub-agents via Codex's agent/task primitive at
  `model_reasoning_effort=low|medium` for scrapers and `high|xhigh` for the verifier profile, or —
  where sub-agent spawning isn't wired up — manually running the sequential degraded-fallback
  shape above within one session, explicitly narrating each phase (now fanning out on angle N, now
  switching to verify mode) so the separation of concerns survives even without separate contexts.
- **Generic / any agent with no subagent primitive:** run the degraded fallback verbatim —
  sequential legs in one context, then a fresh session or a second model as the verifier. The
  method's value is almost entirely in the *shape* (neutral fan-out → source-every-fact →
  independent adversarial check → cited synthesis), which survives running single-threaded far
  better than it survives skipping the verify step to save time.

## The non-negotiable core, restated

Whatever the execution shape, three things make this "deep research" rather than "research with
extra steps": (1) every dispatched fan-out angle is neutral — it doesn't know or hint at the
answer it's supposed to find, (2) every fact carries a real source, and an empty result is honest
output when nothing was found — never a filled-in guess, (3) central claims get checked by a pass
that is actually capable of disagreeing with the drafter, evaluated to a default-balanced (not
default-refute) standard. Everything else — tier choice, parallelism, batch size — is an
implementation detail that trades cost against speed against thoroughness.
