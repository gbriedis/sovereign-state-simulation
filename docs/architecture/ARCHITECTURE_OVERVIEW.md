# Architecture Overview

- **Status:** Living / accepted direction
- **Scope:** Initial architecture
- **Last reviewed:** 2026-08-22

## Experience boundary

The world map dominates the game window. Players pan, zoom, select geography,
and inspect or govern through contextual overlays. Lines, polygons, cells,
symbols, and procedural geometry form the core visual language.

The map is a presentation and query surface over a genuinely three-dimensional
physical world. Sparse geological surfaces and bounded bodies preserve
subsurface truth without requiring a uniform planet-sized voxel grid. The
renderer and interface do not define that truth; the simulation/world core does.

## Runtime and simulation core

- **Bevy** provides windowing, cameras, input, meshes, picking, shaders, and
  presentation.
- The **simulation and world core** is pure Rust, deterministic where practical,
  and independent of Bevy types and lifecycle.
- **egui** is limited to development tools: inspectors, generation controls,
  profiling, and diagnostics. It is not the main player interface.

This boundary keeps the simulation testable, portable, and suitable for a future
authoritative server without requiring a renderer.

## Deterministic world generation

A seed is the root identity of a generated world. Compatible generator and
ruleset versions must reproduce the same foundational world from the same seed
and inputs. Once materially relevant detail becomes canonical, persisted world
truth takes precedence over silently regenerating it with changed algorithms.

```text
world seed
└── canonical geological world
    ├── continuous feature identities and topology
    ├── resolved present state and constraints
    └── compact provenance

computational spatial hierarchy
└── domains reference local representations of canonical features

system-specific sampling grids
└── cells query canonical physical truth

political allocation
└── country territories / settlement slots
    └── references to areas of the physical world
```

Natural geography is generated before political borders. Coastlines, elevation,
drainage, rivers, climate, and biomes establish physical regions. Territories and
country slots are fitted to that geography rather than forcing geography into
arbitrary borders.

Spatial domains and sampling cells belong to world infrastructure, not to
countries. Political territories reference physical space and may change
without regenerating it. A river, watershed, geological formation, ecosystem,
or hazard can cross any number of political boundaries and must not terminate
at a territory edge.

## Canonical state and provenance

Geological history generates the world; canonical present state then becomes
the authority for ordinary queries. It is the smallest persistent,
presentation-independent representation sufficient to say what physically
exists now without replaying geological prehistory.

Canonical truth may contain resolved facts, constraints over unmaterialized
detail, compact causal provenance, and active physical state needed for future
evolution. Renderer meshes, rasters, LOD products, and client caches are derived
and disposable. The complete accepted distinction is documented in
[Canonical Geological State and Refinement](../world-generation/CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md).

## Spatial scale and levels of detail

> **Resolution is a property of a representation, not of physical reality.**

The prototype uses **500 m × 500 m sampling cells** to validate mapping and
interaction. This is a provisional prototype scale, not a fundamental unit of
world or geological truth.

Geological features provide continuous physical identity. Spatial domains or
chunks provide computational locality. Cells are system-specific samples or
analysis units that query canonical truth. These three concepts need not align
or share a resolution.

Representations and derived detail are partitioned, lazy, and multi-resolution:

- Physical and geological complexity can require finer canonical detail.
- Simulation relevance can require finer detail even without direct inspection.
- Observation and gameplay needs may trigger deterministic refinement.
- Distant states remain coarse summaries sufficient for cross-border systems
  such as diplomacy, trade, demographics, and military strength.
- Constrained unresolved detail may be materialized deterministically according
  to focus and relevance, then promoted to stable canonical truth when required.
- Derived presentation data may be cached, unloaded, or regenerated without
  changing canonical truth.

The architecture must not require every possible sampling cell across the world
to exist at once.
Nor does canonical world state require maximum-resolution geology to exist
everywhere at once. Coarse summaries and deterministic refinement may represent
the same world at different levels according to need. Child detail must remain
compatible with parent constraints, subject to unresolved representation and
persistence rules.

Geological entities may cross many domains, and domains may contain partial
representations of many entities. Shared canonical features constrain every
intersecting coarse or fine representation. The accepted ownership and boundary
laws are documented in
[Adaptive Spatial Partitioning](../world-generation/ADAPTIVE_SPATIAL_PARTITIONING.md).

## Continents and country allocation

Continents provide a bounded allocation layer inspired by Ikariam. Each continent
contains a designed or generated set of country territories or slots. A player
occupies a slot and receives a sovereign territory shaped by physical geography.
Exact capacity and allocation rules remain open.

## Authority and multiplayer

The eventual multiplayer model is server-authoritative. The authority generates
and owns the canonical physical world and simulation state, validates commands,
and distributes an appropriate subset or derived view to each client. Clients
handle presentation, camera, input, caching, and any later prediction around
received state; they do not independently generate authoritative geology or
reconstruct the whole planet.

```text
seed and compatible ruleset
→ authoritative geological-prehistory generation
→ canonical present world, constraints, and compact provenance
→ persistent authority-owned state
→ relevant subsets and views delivered to clients
```

**Authoritative world generation is separated from client play cost.** Expensive
generation may occur during world creation. This does not decide whether
canonical detail is eagerly generated, lazily materialized, hierarchically
summarized, cached, or persisted.

Singleplayer follows the same model locally: a local authority runs the world and
simulation. Networking is not required for the first prototype, but commands and
state boundaries must not assume direct UI ownership.

## Architectural consequences

This direction requires early discipline in deterministic generation, spatial
indexing, and simulation/render separation. It enables a detailed personal
nation, large worlds, focused resource use, headless simulation, and a credible
path from local singleplayer to authoritative multiplayer.
