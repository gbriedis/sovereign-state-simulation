---
id: HANDOFF-CURRENT
type: operational-handoff
status: accepted
scope: Current repository state, immediate milestone, blockers, and next actions
authority: Owns current operational facts only; it does not own product or technical decisions
last_reviewed: 2026-08-31
---

# Current State

- **Snapshot date:** 2026-08-31
- **Active phase:** Natural-world foundation (`0.0.1`–`0.1.0`)
- **Immediate milestone:** `PROTO-001` — map and spatial model prototype
- **Implementation state:** The main worktree contains a Cargo workspace and
  minimal Bevy application shell but no spatial model, world core, simulation core, or game systems;
  it also contains no integrated planetary spatial-reference implementation
- **Provisional prototype evidence:** Read-only inspection on 2026-08-31 found
  seven uncommitted planetary-reference source/test changes and 12 passing
  public-contract tests only in isolated worktree
  `C:/Users/legion/.codex/worktrees/cf36/state-of-consequence`, based at
  `8bfe4c63bfbe0f449d0f59e4ebcdf6dec1b1de83`; the code began before the
  `PROTO-001` design-readiness gate passed and is not integrated architecture
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

1. Freeze integration and expansion of the isolated planetary-reference
   implementation.
2. Complete the retrospective `PROTO-001` readiness and evidence packet without
   claiming that the original gate passed.
3. Compare the implementation's numeric, ellipsoid-parameter, conversion, tolerance,
   domain, and error choices with alternatives; separate observed tests from
   requirement-derived acceptance bounds and identify untested prototype goals.
4. Use governed architecture to decide which choices, if any, should be
   retained, replaced, or removed.
5. Resume integration or broader spatial implementation only after that
   decision authorizes a bounded next step.

## Active blockers

The retrospective `PROTO-001` readiness and evidence packet and its later
governed interpretation block integration or expansion of the isolated
implementation. Exact reference-ellipsoid parameters, geodetic conversions, numeric
representation, tolerances, error behavior, derived presentation, and
navigation choices remain unresolved and must be handled through the
open-decision process before they become durable architecture.
`VISION-001` also records the exact
Product Owner clarification required before Web3 could supersede its accepted
optional-later boundary; that clarification does not block the current natural-
world milestone.

## Handoff maintenance

Replace this snapshot after meaningful implementation or planning changes. Keep
it factual and short; link to accepted decisions instead of copying them here.
