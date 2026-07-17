# Spinner — the decision-stress-test method

A discipline for getting a genuinely independent second opinion on a decision, instead of a second
opinion that quietly agrees with the first because it inherited the same framing.

## What it is

When the same context that produced a set of options also evaluates them, it's anchored — it
tends to defend the framing it already committed to and inherits its own blind spots. Asking that
same context "are you sure?" rarely surfaces a real problem, because the context that would notice
the problem is the one that already didn't. Spinner breaks that by handing the decision to a
**fresh, uncorrelated evaluator** — one that starts with none of the reasoning that led to the
options on the table, reads the underlying evidence itself, and commits to an independent pick.

The value is entirely in the decorrelation. A second pass that reuses the same context, the same
chat history, or even just the same train of thought in a new message is not a stress test — it's
a rubber stamp with extra latency.

## The discipline

Four rules make this a real check rather than theater:

1. **Fresh, uncorrelated context.** The evaluator gets the decision and the options, stated
   neutrally, plus pointers to where to verify claims (files, docs, data) — not a summary written
   by the side that's anchored, and not the reasoning trail that produced the options. A summary
   re-imports the anchoring it's supposed to escape. If the evaluator can look things up itself
   (read the code, check a doc), it should — trust the primary source over any restatement of it.

2. **Author ≠ judge.** Whoever produced the options, or has a leaning toward one of them, does not
   also grade them. This is the same principle as "don't grade your own homework" — not because
   the author is dishonest, but because anchoring is not a character flaw, it's a structural fact
   about having already reasoned your way to a position. The fix is organizational, not
   attitudinal: a different evaluator, every time, for anything that matters.

3. **Default-reject.** The evaluator's job is to find reasons the leading option is wrong, not to
   confirm it's fine. It should actively hunt for the edge case, the second-order consequence, the
   option nobody listed, the constraint that quietly rules one choice out — and only affirm the
   original pick if it survives that hunt. A stress test that defaults to "looks good" isn't one.

4. **Unfalsifiable → auto-fail.** If a decision or its justification can't be checked against
   anything concrete — no code to read, no data to verify, no way the evaluator could come back
   with "actually, X is false" — that's not a pass, it's a sign the decision wasn't ready for this
   step. An evaluation that can't possibly return a negative verdict isn't providing information.

## When to use it

Not every choice needs this. The overhead — a second full pass, on a fresh context, ideally the
strongest model available — is only worth paying when the cost of being wrong exceeds the cost of
checking:

- **Expensive forks.** A decision that's costly to unwind once acted on: an architecture choice,
  a schema design, a public-facing commitment, anything where "we'll just change it later" is more
  work than getting it right now.
- **Load-bearing decisions.** Choices other decisions will be built on top of — if this is wrong,
  everything downstream inherits the mistake, often silently, until it surfaces somewhere far from
  the original choice and much harder to trace back.
- **Irreversible actions.** Anything that can't be cleanly undone: a production deploy, a
  destructive migration, a message sent, a public commit. The cost of a wrong call here isn't
  "redo the work," it's "live with the consequence."
- **Genuine forks with real options on the table.** If there's only one sane choice, or the
  decision is trivially reversible, the overhead isn't worth it — save the stress test for when it
  can actually change the outcome.

Skip it for: pure factual lookups with one right answer, trivial and cheaply-reversible choices,
and cases where the decision is already made and the ask is "build it," not "should we build it
this way." A stress test dispatched on a decision that isn't genuinely open just burns a pass
without adding information.

## Degraded fallback (no subagent primitive)

"Spawn a fresh sub-agent" is the Claude-Code-native form of this method — it is not the method
itself. The discipline transfers to any agent, environment, or even a human reviewer, as long as
the four rules above survive the substitution:

- **A new chat window, given only the artifact + its spec.** Open a fresh conversation containing
  nothing but the decision, the options, and the constraints — deliberately not the conversation
  that produced them. This is the most direct substitute: same decorrelation mechanism (a context
  window with no memory of the anchored reasoning), just triggered manually instead of via a
  sub-agent spawn.
- **A second model.** If more than one model or provider is available, routing the stress test to
  a *different* model than the one that made the original call is a stronger decorrelation than a
  fresh session on the same model — different models don't share the same systematic blind spots
  the way same-model instances tend to.
- **Git worktree + separate session.** For a decision embedded in code, check the relevant branch
  out into a separate worktree and evaluate it from a clean session rooted there — this gives the
  evaluator a genuinely fresh read of the actual state (not a description of it) without
  disturbing the working session that's mid-task.
- **A human reviewer.** Not every agent-shaped problem needs an agent-shaped answer. For a
  decision a colleague can evaluate faster than an agent can be dispatched and read back, handing
  it to a person who wasn't part of the original discussion satisfies every rule above just as
  well — the point was never "must be a subagent," it was "must not share the anchoring."

Whatever the substitution, the four rules from "The discipline" still have to hold: the evaluator
must be genuinely uncorrelated (not just a differently-worded prompt to the same context), the
author must not be the judge, the default posture must be skeptical rather than confirmatory, and
an unfalsifiable justification must fail rather than pass by default.

## Running the check

A useful brief for the evaluator — whatever form it takes — covers, without leaking a preference:

1. **The decision**, stated in one or two neutral sentences.
2. **The options**, described without indicating which one the author favors. If the author
   authored the options, this is the single easiest rule to break by accident — resist the urge to
   hint even implicitly (option order, which one gets more detail, adjective choice).
3. **Where to look** — files, docs, data the decision touches — not a summary of what's there.
4. **Hard constraints** that are genuinely fixed, separated clearly from soft preferences that
   aren't.

Ask it to: read the material itself, decide how much scrutiny the decision actually warrants (a
clear-cut call doesn't need maximum effort; a genuinely tangled one does — and when in doubt, lean
toward more scrutiny, since a missed edge case is expensive), hunt for what the original framing
likely missed, and commit to a single best answer — proposing an option that wasn't on the
original list at all if that's what the evidence supports. The output should lead with the
decision, surface the edge cases prominently (that's usually the actual value delivered), and
state a confidence level plus what would change it.

**The result informs, it doesn't execute.** A stress test that returns a verdict is not itself
permission to act on it — acting is still a separate, explicit step taken by whoever owns the
decision, after seeing the independent read. If the evaluator's pick disagrees with the leaning
going in, that disagreement is the signal the whole exercise exists to surface — report it
plainly, don't quietly reconcile it away.
