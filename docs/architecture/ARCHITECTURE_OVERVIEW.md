---
id: ARCH-001
type: architecture-overview
status: accepted
scope: Software boundaries, world authority, persistence, and presentation-independent architecture
authority: Owns accepted cross-cutting software and runtime architecture
implementation: not-started
last_reviewed: 2026-08-22
---

# Architecture Overview

## Decision

The project separates authoritative world and simulation logic from presentation.
The same authority model supports local singleplayer and eventual multiplayer;
only the location of the authority changes.

The [World-Generation Source of Truth](../world-generation/README.md) owns the
accepted physical-world concepts. This document owns how software authority,
persistence, and presentation interact with those concepts.

## Player experience boundary

The world map is the primary player surface. Players pan, zoom, select geography,
and govern through contextual map interactions. Lines, polygons, sampling cells,
symbols, and procedural geometry form the main visual language.

The map presents and queries the physical world. It does not define physical
truth. Geological reality remains genuinely three-dimensional even when the
player views it through maps, sections, rasters, or meshes.

## Runtime boundaries

- **Bevy application:** windowing, cameras, input, meshes, picking, shaders, and
  presentation.
- **World core:** presentation-independent Rust code that owns physical-world
  generation, canonical world truth, and world queries.
- **Simulation core:** presentation-independent Rust code that evolves gameplay
  simulation state.
- **Development interface:** egui inspectors, generation controls, profiling,
  and diagnostics. egui is not the primary player interface.

Neither the world core nor the simulation core may depend on Bevy or egui types
or lifecycle. They must remain testable without a renderer.

## Deterministic generation and persistence

A seed is the root identity of a generated world. The same seed, inputs, and
compatible generator/ruleset version must reproduce the same foundational world.

Once materially relevant detail becomes canonical, persisted truth takes
precedence over regeneration. A later algorithm version must not silently alter
resolved or interacted-with geology. Still-unresolved detail may use a compatible
new generator only when it preserves all established constraints.

```text
seed + generator/ruleset version + declared inputs
→ authoritative geological prehistory
→ canonical present world + constraints + compact provenance
→ persisted authority-owned state
→ relevant queries and derived views
```

## Canonical and derived data

Canonical present state is the smallest presentation-independent authority
sufficient to describe what physically exists now and continue relevant
evolution without replaying all geological prehistory.

Canonical truth may include resolved facts, constraints over unresolved detail,
compact provenance, and active physical state. Renderer meshes, GPU buffers,
rasters, sampled layers, level-of-detail products, and client caches are derived
and disposable.

The detailed ownership and refinement rules are defined by `WG-005` through
`WG-010` in the [world-generation index](../world-generation/README.md).

## Spatial model

Geological features, computational spatial domains, and sampling cells are
different concepts:

- A geological feature has continuous canonical identity.
- A spatial domain supplies computational locality, indexing, loading, or
  refinement.
- A sampling cell queries canonical truth for one system or presentation.

Political territories also reference physical space; they do not own natural
features, spatial domains, or sampling cells. Borders may change without
regenerating geography. Rivers, watersheds, geological formations, ecosystems,
and hazards may cross any number of political territories.

The `500 m × 500 m` sampling cells in `PROTO-001` are provisional measurements,
not a fundamental unit of world truth.

## Detail and refinement

Representation cost follows geological complexity, simulation relevance, and
declared query needs. The architecture must not require every possible sampling
cell or maximum-resolution geological representation to exist at once.

Refinement must preserve established canonical truth and shared constraints.
Observation may trigger refinement, but it does not physically create geology
or permit a reroll. Different regions may hold compatible levels of resolved
detail without creating artificial physical discontinuities.

## Authority model

The authority owns canonical world and simulation state, validates commands, and
performs authoritative generation and refinement.

- In singleplayer, the authority runs locally.
- In multiplayer, the authority runs on the server.
- Clients own presentation, input, local caches, and any later prediction around
  received state.
- Clients do not independently generate authoritative geology or reconstruct the
  complete world.

Expensive world creation is separate from client play cost. This decision does
not select eager or lazy generation, persistence granularity, database design,
or a network protocol.

## Geography before politics

Natural geography is generated before political allocation. Coastlines,
elevation, drainage, rivers, climate, biomes, and other physical conditions
establish the world that later political territories must respect.

Continents may later provide bounded allocation areas containing country slots.
A player may occupy a slot and receive a political territory shaped by physical
geography. Capacity, allocation rules, and the final continent model remain open.

## Consequences

- Seed inputs and generator/ruleset versions must be explicit.
- Coordinate, spatial-domain, and sampling-cell mappings must be testable.
- Presentation code must query world/simulation APIs rather than own simulation
  truth.
- Persistence must distinguish canonical state from derived caches.
- Cross-domain features and refinement boundaries must preserve continuity.
- Implementation choices listed in
  [Open Architecture Decisions](OPEN_DECISIONS.md) remain unresolved until an
  accepted decision record resolves them.

## Out of scope

This overview does not select:

- coordinate systems, projections, spatial indexes, or domain dimensions;
- geological geometry, topology, numerical solvers, or refinement algorithms;
- terrain-generation, hydrology, climate, soil, ecosystem, or resource models;
- renderer internals, databases, serialization formats, or network protocols;
- country-slot capacity or political-allocation rules.
