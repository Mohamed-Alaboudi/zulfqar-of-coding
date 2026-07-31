---
name: compact-handoff
description: Produce a durable continuation handoff before context compaction or a new thread. Use only when explicitly invoked as $compact-handoff.
---

# Durable compact handoff

Apply this skill only when explicitly invoked as `$compact-handoff`.

Create a self-contained continuation handoff that preserves the objective, decisions and their reasons, current repository state, changed paths, verification evidence, failed or rejected approaches, open uncertainties, and unverified claims.

End with exactly one concrete next action that a fresh session can execute. Save the handoff where the active workflow supports durable handoff artifacts, or return it in a clearly copyable form when no such location is available.

Tell the user how to start the next context or thread. Do not claim to invoke client-side compaction controls on the user's behalf.
