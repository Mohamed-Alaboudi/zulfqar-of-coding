# Routing and escalation

| Work shape | Route | Default effort | Escalate when |
|---|---|---|---|
| Deterministic extraction or inventory | `luna-reader` | Luna low | Diagnosis or semantic judgment appears |
| Exact locations or usages | `finder` | Terra low | Subsystem understanding is required |
| Architecture, execution paths, diagnosis | `explorer` | Terra medium | A consequential decision remains |
| Closed mechanical implementation | `worker-light` | Terra medium | Scope expands or design is unresolved |
| Consequential read-only decision | `sol-advisor` | Sol high | One exact evidence query is missing |
| Judgment-heavy bounded implementation | `worker-deep` | Sol high | The fix crosses the owned boundary |
| Final high-risk acceptance | `verifier` | Sol high | The claim is not proven by observed checks |

Prefer the lowest capable tier. Escalate Luna to Terra for diagnosis, planning, cross-file reasoning, contradictory evidence, or failed validation. Escalate Terra to Sol for architecture/security judgment, difficult reversibility, conflicting evidence, or two focused unclear failures. Do not retry an unchanged packet.

Run at most three lanes per wave. Keep depth at one. Use one writer per path. The root owns architecture, shared interfaces, integration, broad verification, and final acceptance.
