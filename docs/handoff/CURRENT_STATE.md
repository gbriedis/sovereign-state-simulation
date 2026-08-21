# Current State and Handoff

- **Snapshot date:** 2026-08-21
- **Project phase:** Natural-world foundation (`0.0.1`–`0.1.0`)
- **Immediate milestone:** Prototype v0.1
- **Implementation status:** No source code or completed implementation is
  documented in this workspace

## Settled direction

- The game simulates an autonomous sovereign nation; the player influences rather
  than directly controls all actors.
- Systems should preserve meaningful real-world causes and constraints.
- The map is the primary player experience.
- Bevy handles runtime and rendering; a pure-Rust core owns simulation/world logic.
- World generation is seed-based and versioned for reproducibility.
- Geography is generated before political territories.
- Spatial detail is lazy, chunked, and proportional to attention.
- Singleplayer and eventual multiplayer share one authority model.
- The eventual multiplayer server is authoritative.

## Current target

Implement the scoped map prototype in
`../architecture/PROTOTYPE_V0.1.md`. The 500 m cell size is a measurement target,
not a final commitment.

## Important boundaries

- Do not start human civilization or economic simulation in the current phase.
- Do not couple simulation data to Bevy or egui types.
- Do not treat open questions as accepted decisions.
- Do not let optional Web3 ideas shape foundational simulation design.

## Recommended next actions

1. Create the Rust workspace with separate simulation/world and Bevy application
   crates or modules.
2. Define versioned seed inputs and coordinate/chunk/cell identifiers.
3. Implement and test coordinate-to-chunk-to-cell mapping.
4. Build the seeded landmass render and map camera controls.
5. Measure the provisional cell and chunk choices before resolving them.

## Before continuing work

Read the prototype specification and the relevant open decisions. If a task would
resolve an open decision, record both the rationale and consequences instead of
only changing code.
