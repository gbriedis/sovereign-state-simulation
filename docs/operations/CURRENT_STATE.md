---
id: HANDOFF-CURRENT
type: operational-handoff
status: accepted
scope: Current repository state, immediate milestone, blockers, and next actions
authority: Owns current operational facts only; it does not own product or technical decisions
last_reviewed: 2026-08-30
---

# Current State

- **Snapshot date:** 2026-08-30
- **Active phase:** Natural-world foundation (`0.0.1`–`0.1.0`)
- **Immediate milestone:** `PROTO-001` — map and spatial model prototype
- **Implementation state:** A Cargo workspace and minimal Bevy application shell
  are present; no spatial model, world core, simulation core, or game systems
  are implemented
- **Documentation state:** Governance, source-of-truth routing, and a generated
  Project Journal and System Map are established; a top-level derivative browser
  view is available; the conceptual planet-fixed physical reference frame and
  its stable Earth-like oblate reference ellipsoid are accepted while exact
  parameters, conversions, and numeric and spatial implementation remain open
- **Exploration state:** Early and intentionally incomplete; accepted concepts
  cover only the physical topics explored so far

## Read before working

1. [Documentation Standard](../README.md)
2. [Project Journal and System Map](../project-journal/README.md)
3. [Browser Project Journal](../../project-journal-site/)
4. [Knowledge Workflow](../governance/workflows/KNOWLEDGE_WORKFLOW.md)
5. [World-Generation Source of Truth](../world-generation/README.md)
6. [World-Generation Authoring Protocol](../world-generation/AUTHORING_PROTOCOL.md)
7. [Architecture Overview](../architecture/ARCHITECTURE_OVERVIEW.md)
8. [Open Architecture Decisions](../architecture/OPEN_DECISIONS.md)
9. [Map and Spatial Model Prototype](../architecture/MAP_AND_SPATIAL_MODEL_PROTOTYPE.md)

Use the [Document Index](../INDEX.md) to locate product, brand, roadmap, and
specialized world-generation authority. Do not treat this handoff as a substitute
for those documents.

## Immediate work

1. Complete the `PROTO-001` design-readiness packet before spatial code.
2. Compare numeric encodings within the accepted planet-fixed frame and
   alternatives for reference-ellipsoid parameter handling, geodetic
   conversions, projection, pole, seam, globe/map, multiscale, spatial-domain,
   index, and sampling without selecting implementation architecture.
3. Define deterministic fixtures, observable success and failure conditions,
   and the requirement-derived acceptance evidence for the prototype.
4. Only after the readiness gate passes, extend the Bevy shell with the smallest
   presentation harness and presentation-independent fixture needed by the
   experiment.
5. Use the prototype evidence in a later governed architecture decision; do not
   treat an experiment as acceptance.

## Active blockers

No external blocker is documented. Exact reference-ellipsoid parameters,
geodetic conversions, numeric representation, derived presentation, and
navigation choices remain unresolved and must be handled through the
open-decision process before they become durable architecture.
`VISION-001` also records the exact
Product Owner clarification required before Web3 could supersede its accepted
optional-later boundary; that clarification does not block the current natural-
world milestone.

## Handoff maintenance

Replace this snapshot after meaningful implementation or planning changes. Keep
it factual and short; link to accepted decisions instead of copying them here.
