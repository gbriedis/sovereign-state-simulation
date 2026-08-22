---
id: HANDOFF-CURRENT
type: operational-handoff
status: accepted
scope: Current repository state, immediate milestone, blockers, and next actions
authority: Owns current operational facts only; it does not own product or technical decisions
last_reviewed: 2026-08-22
---

# Current State

- **Snapshot date:** 2026-08-22
- **Active phase:** Natural-world foundation (`0.0.1`–`0.1.0`)
- **Immediate milestone:** `PROTO-001` — map and spatial model prototype
- **Implementation state:** No game/runtime source code or completed simulation
  implementation is present in this workspace
- **Documentation state:** Governance and source-of-truth structure established;
  world-generation implementation choices remain open
- **Exploration state:** Early and intentionally incomplete; accepted concepts
  cover only the physical topics explored so far

## Read before working

1. [Documentation Standard](../README.md)
2. [Knowledge Development Workflow](../governance/workflows/KNOWLEDGE_DEVELOPMENT_WORKFLOW.md)
3. [World-Generation Source of Truth](../world-generation/README.md)
4. [World-Generation Authoring Protocol](../world-generation/AUTHORING_PROTOCOL.md)
5. [Architecture Overview](../architecture/ARCHITECTURE_OVERVIEW.md)
6. [Open Architecture Decisions](../architecture/OPEN_DECISIONS.md)
7. [Map and Spatial Model Prototype](../architecture/MAP_SPATIAL_PROTOTYPE.md)

Use the [Document Index](../INDEX.md) to locate product, brand, roadmap, and
specialized world-generation authority. Do not treat this handoff as a substitute
for those documents.

## Immediate work

1. Create a Rust workspace with presentation-independent world/simulation code
   and a Bevy application boundary.
2. Define versioned prototype seed inputs and provisional coordinate,
   spatial-domain, and sampling-cell identifiers.
3. Implement and test coordinate-to-domain-to-cell mapping.
4. Build seeded landmass rendering and map camera controls.
5. Measure the provisional spatial choices without promoting them to final
   world-generation decisions.

## Active blockers

No external blocker is documented. Several implementation choices are unresolved
and must be handled through the open-decision process before they become durable
architecture.

## Handoff maintenance

Replace this snapshot after meaningful implementation or planning changes. Keep
it factual and short; link to accepted decisions instead of copying them here.
