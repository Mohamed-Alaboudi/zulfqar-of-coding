---
name: stop-slop
description: "Use while drafting, editing, or reviewing prose to remove generic AI-writing habits without imitating a person's voice. Not for fact-checking, substantive review, or voice matching."
---

# Stop Slop

Make prose sound deliberate and specific while preserving its facts, intent,
and useful caveats.

## Pass 1: structure

- Cut introductions that announce the point before stating it.
- Remove repeated conclusions and summaries that add no new information.
- Replace canned setup-and-reveal contrasts with the direct claim.
- Break mechanical sequences of equal-length paragraphs or three-part lists.
- Keep headings only when they help a reader navigate.

## Pass 2: sentences

- Prefer concrete nouns and verbs over vague importance or intensity.
- Name the actor when passive voice hides responsibility.
- Replace business jargon with the shortest accurate term.
- Remove filler, empty reassurance, and transitions the paragraph already
  makes clear.
- Limit punctuation used as a dramatic beat, including repeated em dashes and
  fragments.
- Vary sentence length when the rhythm feels generated, but do not manufacture
  variety at the cost of clarity.

## Guardrails

- Do not change technical terms, quoted material, legal language, or required
  safety caveats without a substantive reason.
- Do not invent examples or certainty to make a sentence sound stronger.
- Do not apply a mechanical word ban. Keep a phrase when it is the clearest
  wording in context.
- Preserve the writer's humor, bluntness, and domain vocabulary.

## Output

Return the revised prose. Explain edits only when the user asks, or when a
meaningful ambiguity requires a decision.

## Provenance

This compact Zulfiqar workflow is an independent reimplementation inspired by
Hardik Pandya's
[Stop Slop](https://github.com/aiskillstore/marketplace/tree/main/skills/hardikpandya/stop-slop).
It does not reproduce the upstream skill or reference text. See
`THIRD-PARTY-NOTICES.md`.
