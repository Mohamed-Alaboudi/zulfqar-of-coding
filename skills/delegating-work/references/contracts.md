# Briefing and result contracts

Use compact contracts only when they save context or preserve a consequential decision.

## Evidence packet

```markdown
## STATE
<HEAD, branch, dirty-state fingerprint>

## FINDINGS
- E1 [observed]: <claim> — <path:line or command>
- E2 [inferred]: <claim> — based on E1; confidence <high|medium|low>

## CONTRADICTIONS
- <conflict>

## UNKNOWNS
- <missing evidence and exact next query>

## NEXT ACTION
<smallest useful move>
```

Limit findings to eight and omit raw inventories.

## Slice report

```markdown
## SLICE
<name and complete|blocked|needs-review>
## OWNED PATHS
- <path>
## CHANGES
- <path> — <what and why>
## VERIFICATION
- <command> -> <observed result>
## DEVIATIONS
<none or explicit deviation>
## RISKS AND UNKNOWNS
- <remaining item>
```

## Verification verdict

```markdown
## CLAIM
<load-bearing claim>
## VERDICT
<confirmed|refuted|not-proven>
## EVIDENCE
- <command and decisive output>
## SUSPICIOUS OR UNCHECKED
- <edge or uncertainty>
```
