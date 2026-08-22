---
id: DECISION-INDEX
type: decision-record-index
status: accepted
scope: Accepted architecture and world-generation change records
authority: Owns the durable decision-record process and index
last_reviewed: 2026-08-22
---

# Decision Records

No dedicated decision record has been created yet. Accepted
cross-cutting architecture currently lives in
[ARCH-001](../architecture/ARCHITECTURE_OVERVIEW.md), and specialized accepted
world-generation decisions live in the documents routed by
[WG-INDEX](../world-generation/README.md).

Create a decision record when resolving an `ARCH-OPEN-*` or future `WG-OPEN-*`
packet, reversing accepted truth, or preserving rationale and consequences that
do not belong in a specification.

Use `ARCH-DEC-*` for software and cross-cutting implementation decisions. Use
`WG-DEC-*` for changes to accepted world-generation truth.

## Required record shape

```markdown
---
id: AREA-DEC-001
type: architecture-decision-record
status: accepted
scope: Exact decision scope
authority: Owns the selected choice and its rationale
implementation: not-started
last_reviewed: YYYY-MM-DD
resolves: AREA-OPEN-000
---

# Decision title

## Decision

Direct statement of the selected design.

## Context

Facts and constraints that required a decision.

## Rationale

Why this option was selected.

## Consequences

Required follow-up, benefits, costs, and compatibility effects.

## Rejected options

Alternatives considered and why they were rejected.
```

## Index

| ID | Decision | Resolves |
| --- | --- | --- |
| — | No records yet | — |
