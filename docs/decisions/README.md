---
id: DECISION-INDEX
type: decision-record-index
status: accepted
scope: Accepted architecture and world-generation change records
authority: Owns the durable decision-record process and index
last_reviewed: 2026-08-30
---

# Decision Records

Accepted cross-cutting architecture currently lives in
[ARCH-001](../architecture/ARCHITECTURE_OVERVIEW.md), and specialized accepted
world-generation decisions live in the documents routed by
[WG-INDEX](../world-generation/README.md).

Create a decision record when resolving an `ARCH-OPEN-*` or future `WG-OPEN-*`
packet, reversing accepted truth, or preserving rationale and consequences that
do not belong in a specification.

Use `ARCH-DEC-*` for software and cross-cutting architecture decisions. Use
`WG-DEC-*` for changes to accepted world-generation truth.
Existing imported records retain their stable IDs when integration would
otherwise erase durable decision identity. `ADR-0002` is one such imported
record: it retains its upstream `ADR-*` ID and its additional team-routing,
adoption, and reversal sections for traceability. This is an ID and section-shape
exception only; its canonical document type remains `decision-record`. New
records follow the ID conventions and required shape below.

## Required record shape

```markdown
---
id: AREA-DEC-001
type: decision-record
status: accepted
scope: Exact decision scope
authority: Owns the selected choice and its rationale
last_reviewed: YYYY-MM-DD
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

Add `implementation` only when the record selects work whose implementation
state must be tracked. Add `resolves` only when the record resolves a stable
open-decision packet. Add `supersedes` or `related` only when the relationship is
factual and useful. Omit inapplicable optional fields instead of inventing a
placeholder relationship.

## Index

| ID | Decision | Resolves |
| --- | --- | --- |
| [`ARCH-DEC-002`](ARCH-DEC-002-earth-like-reference-ellipsoid.md) | Adopt an Earth-like reference ellipsoid | Selects the stable oblate mathematical reference shape within `ARCH-OPEN-001`, `ARCH-OPEN-007`, `ARCH-OPEN-009`, and `ARCH-OPEN-019`; parameter and implementation questions remain open |
| [`ARCH-DEC-001`](ARCH-DEC-001-planet-fixed-physical-reference-frame.md) | Adopt a planet-fixed physical reference frame | Selects the conceptual frame within `ARCH-OPEN-001` and `ARCH-OPEN-007`; both packets remain open for implementation choices |
| [`ADR-0002`](ADR-0002-earth-like-planetary-contract.md) | Adopt an Earth-like planetary contract | Establishes `WG-025` and refines `WG-001` |
