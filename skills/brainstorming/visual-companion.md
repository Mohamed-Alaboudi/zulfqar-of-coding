# Visual Companion Guide

A pattern for showing mockups, diagrams, and visual options during brainstorming instead of describing them in text, plus the interaction loop for iterating on them with the user.

## When to Use

Decide per-question, not per-session. The test: **would the user understand this better by seeing it than reading it?**

**Show a visual** when the content itself is visual:

- **UI mockups** — wireframes, layouts, navigation structures, component designs
- **Architecture diagrams** — system components, data flow, relationship maps
- **Side-by-side visual comparisons** — comparing two layouts, two color schemes, two design directions
- **Design polish** — when the question is about look and feel, spacing, visual hierarchy
- **Spatial relationships** — state machines, flowcharts, entity relationships rendered as diagrams

**Use text** when the content is text or tabular:

- **Requirements and scope questions** — "what does X mean?", "which features are in scope?"
- **Conceptual A/B/C choices** — picking between approaches described in words
- **Tradeoff lists** — pros/cons, comparison tables
- **Technical decisions** — API design, data modeling, architectural approach selection
- **Clarifying questions** — anything where the answer is words, not a visual preference

A question *about* a UI topic is not automatically a visual question. "What kind of wizard do you want?" is conceptual — use text. "Which of these wizard layouts feels right?" is visual — show a mockup.

## The Shape of the Loop

Regardless of what rendering surface the target agent has (a live browser tab, a static HTML/image artifact, an attached screenshot, or nothing at all), the pattern is the same four-step loop:

1. **Render the visual.** Produce the mockup/diagram/comparison in whatever form the agent can actually show the user — an HTML page, an inline image, a rendered diagram block. Explain in one line what the visual is showing and what decision it's meant to inform.
2. **Ask a specific question about it**, not just "thoughts?" — "Which layout feels more scannable, A or B?" gets a decision faster than "here's a mockup."
3. **Read back whatever feedback the surface provides.** On a fully interactive surface this might be structured click/selection data; on a static one it's just the user's reply in words. Either way, the user's plain-text response is the primary signal — never treat structured interaction data as more authoritative than what they actually said.
4. **Iterate or advance.** If feedback changes the current visual, produce a new version (don't silently overwrite the one just shown — versioning makes "go back to the first one" possible). Only move to the next question once the current one is resolved.

## Practical Notes

- **2-4 options max per screen.** More than that and the user is doing the narrowing-down work that should be yours.
- **Explain the question alongside the visual** — "Which layout feels more professional?" not just an unlabeled image.
- **Use real content when it matters.** For a photography portfolio mockup, use actual (or realistic placeholder) images — generic gray boxes obscure the design issues you're actually trying to surface.
- **Scale fidelity to the question.** Rough wireframes for a layout question; more polish for a genuine visual-style question. Don't over-invest in pixel-perfect mockups when the decision is about structure, not finish.
- **Never reuse a filename/version for an iteration** — each revision should be independently referenceable so "go back to version 2" is possible.

## Per-Target-Agent Notes

This pattern needs *some* way to show the user a rendered visual and get feedback back. How well-supported that is varies a lot by agent:

- **An agent with a rich artifact/canvas surface** (a hosted HTML/image preview the user can view and react to) is the best fit — render there directly.
- **An agent that can only output text in a terminal** can still approximate this: write the mockup to an HTML file and tell the user to open it locally, or fall back to an ASCII/text sketch of the layout when a real render isn't available. The loop (render, ask a specific question, read back feedback, iterate) still holds — only the rendering surface changes.
- **An agent with no visual output at all** should skip this pattern entirely for genuinely visual questions and fall back to describing options carefully in words, being explicit that a text description is a weaker substitute for something the user should really be looking at, and flagging low confidence in the resulting decision accordingly.

Whatever the surface, the discipline that matters is asking one specific, decision-forcing question per visual and treating the user's plain-language reply as ground truth over any structured interaction data the surface happens to capture.
