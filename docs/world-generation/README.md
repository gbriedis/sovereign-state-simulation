---
id: WG-INDEX
type: source-of-truth-index
status: accepted
scope: Natural-world generation concepts and their authoritative owners
authority: Owns world-generation concept IDs, concise truth statements, dependencies, and document routing
coverage: partial
last_reviewed: 2026-08-23
---

# World-Generation Source of Truth

This is the required entry point for natural-world generation. It records ideas
discovered so far, gives each idea one stable identifier, and points to the
document that owns its detailed meaning. The linked owner—not a paraphrase in a
roadmap or handoff—governs implementation.

Coverage is intentionally partial. An absent topic has not yet been explored; it
is not implicitly rejected or outside world generation. Future agents must use
the [World-Generation Authoring Protocol](AUTHORING_PROTOCOL.md) to recognize,
explore, propose, accept, revise, or retire ideas.

## Interpretation rules

- Every row in **Accepted concepts** is accepted only at its stated conceptual
  scope. Acceptance does not imply a complete subsystem design.
- `Implementation unresolved` means the idea is accepted but its algorithm,
  data structure, numerical method, or storage representation is not selected.
- Examples and Rust-facing types in linked documents are illustrative unless
  explicitly labelled normative.
- Open choices are listed in
  [Open Architecture Decisions](../architecture/OPEN_DECISIONS.md). Options in
  that register are not accepted implementation decisions.

## Accepted concepts

| ID | Accepted truth | Detailed owner | Implementation |
| --- | --- | --- | --- |
| `WG-001` | Compatible worlds share one versioned Earth-like physical ruleset and geological reference framework rather than randomized physical laws. | [Earth-Like Physical Framework](EARTH_LIKE_PHYSICAL_FRAMEWORK.md) | Unresolved |
| `WG-002` | World generation creates a geological prehistory; the playable physical world is the accumulated result of that history. | [Geological Prehistory](GEOLOGICAL_PREHISTORY.md) | Unresolved |
| `WG-003` | Geological material preserves compact bulk composition and separate trace inventory; minerals and named rocks are derived where practical. | [Geological Material Composition](GEOLOGICAL_MATERIAL_COMPOSITION.md) | Unresolved |
| `WG-004` | Geological material is described through composition and history, coexisting solid/melt/fluid fractions, and structural state—not mutually exclusive rock, magma, sediment, and fluid types. | [Geological Material State](GEOLOGICAL_MATERIAL_STATE.md) | Unresolved |
| `WG-005` | Geological truth is sparse, three-dimensional, history-bearing, and independent of the map representation. | [Sparse 3D Geological World](SPARSE_3D_GEOLOGICAL_WORLD.md) | Unresolved |
| `WG-006` | Geological events modify inherited 3D state through composable geometry operators while preserving chronology and cross-cutting relationships. | [Geological Geometry Operators](GEOLOGICAL_GEOMETRY_OPERATORS.md) | Unresolved |
| `WG-007` | Ordinary queries use canonical present state; compact provenance and constrained unresolved detail support explanation and deterministic refinement. | [Canonical Geological State and Refinement](CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md) | Unresolved |
| `WG-008` | Geological identity, computational spatial domains, and system-specific sampling cells are separate concepts; partition boundaries must not create geological boundaries. | [Adaptive Spatial Partitioning](ADAPTIVE_SPATIAL_PARTITIONING.md) | Unresolved |
| `WG-009` | Canonical geometry uses absolute position; depth is contextual, lithostatic pressure follows actual overburden, and pore-fluid pressure remains separate. | [Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md) | Unresolved |
| `WG-010` | Temperature is canonical history-bearing spatial state when present geometry and compact provenance cannot recover the promised future query truth; geothermal gradient is derived. | [Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md) | Unresolved |
| `WG-011` | Tectonic plates are the earliest useful evolving lithospheric abstraction; their properties and relative motion supply causes for later geology. | [Tectonic Plates](TECTONIC_PLATES.md) | Unresolved |
| `WG-012` | Boundary-relative motion produces tectonic interactions, persistent structures, and geological provinces—not final terrain. | [Tectonic Structures and Geological Provinces](TECTONIC_STRUCTURES_AND_PROVINCES.md) | Unresolved |
| `WG-013` | Broad solid-Earth geometry responds to whole-lithosphere buoyancy, loads, regional strength, tectonic forcing, disequilibrium, and relaxation. | [Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md) | Unresolved |
| `WG-014` | Ground, seafloor, and elevation are semantic queries over the transformed 3D ground-material domain; heightmaps and meshes are derived products. | [Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md) | Unresolved |
| `WG-015` | Seeds, selected Level 0 planetary contracts, and compatible generator/ruleset versions identify reproducible generation, while persisted canonical truth survives later algorithm changes. | [Architecture Overview](../architecture/ARCHITECTURE_OVERVIEW.md) | Unresolved |
| `WG-016` | The authority owns canonical generation and refinement; clients receive only relevant subsets or derived views. | [Architecture Overview](../architecture/ARCHITECTURE_OVERVIEW.md) | Not started |
| `WG-025` | Each world begins with a selected Level 0 planetary contract whose bounded causal parameters remain inside the supported Earth-like envelope and are inherited by later histories. | [Earth-Like Planetary Contract](EARTH_LIKE_PLANETARY_CONTRACT.md) | Unresolved |

## Recognized exploration topics

These topics are known to matter, but no conceptual model is accepted yet. Their
questions are starting points, not requirements or preferred solutions.

| ID | Concept state | Exploration question | Detailed owner |
| --- | --- | --- | --- |
| `WG-017` | `recognized` | How do weathering, erosion, transport, deposition, glaciation, and other surface processes transform inherited solid-Earth geometry into present terrain? | Not created |
| `WG-018` | `recognized` | How should surface water, groundwater, drainage, rivers, lakes, wetlands, and coastlines arise from terrain, material, and climate causes? | Not created |
| `WG-019` | `recognized` | What climate abstraction produces useful temperature, precipitation, wind, and seasonality from physical geography without becoming a full atmospheric simulator? | Not created |
| `WG-020` | `recognized` | How should regolith, parent material, and soils develop from geology, climate, organisms, topography, and time? | Not created |
| `WG-021` | `recognized` | How should vegetation and ecosystems emerge from climate, water, soil, disturbance, and biological history? | Not created |
| `WG-022` | `recognized` | How should minerals, extractable resources, and natural energy potential derive from geological history and present physical conditions? | Not created |
| `WG-023` | `recognized` | How should floods, erosion, landslides, and other natural hazards derive from the same physical state used by ordinary world queries? | Not created |
| `WG-024` | `recognized` | Which physical properties must support later engineering, drainage, bearing-capacity, harbor, and infrastructure-suitability queries? | Not created |

## Dependency order

The accepted dependency model begins with initial physical causes before plates
evolve. It is a causal map, not a required one-pass algorithm:

```text
common Earth-like physical rules + selected bounded planetary contract
→ initial lithosphere geometry, composition, material state, and thermal state
→ tectonic plates and plate motion
→ boundary-relative motion and tectonic interaction
→ tectonic structures and geological provinces
→ geological events operating on inherited sparse 3D state
→ density, thermal, load, and strength consequences
→ regional buoyancy, flexural target, disequilibrium, and relaxation
→ transformed canonical solid-Earth geometry
→ semantic ground and seafloor queries
→ later surface processes
→ present-day natural world
```

Feedback is allowed where physical dependencies require it. Numerical staging,
iteration, and approximation remain implementation decisions.

## Document map

| Document | Primary concept IDs |
| --- | --- |
| [Earth-Like Physical Framework](EARTH_LIKE_PHYSICAL_FRAMEWORK.md) | `WG-001` |
| [Geological Prehistory](GEOLOGICAL_PREHISTORY.md) | `WG-002` |
| [Geological Material Composition](GEOLOGICAL_MATERIAL_COMPOSITION.md) | `WG-003` |
| [Geological Material State](GEOLOGICAL_MATERIAL_STATE.md) | `WG-004` |
| [Sparse 3D Geological World](SPARSE_3D_GEOLOGICAL_WORLD.md) | `WG-005` |
| [Geological Geometry Operators](GEOLOGICAL_GEOMETRY_OPERATORS.md) | `WG-006` |
| [Canonical Geological State and Refinement](CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md) | `WG-007` |
| [Adaptive Spatial Partitioning](ADAPTIVE_SPATIAL_PARTITIONING.md) | `WG-008` |
| [Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md) | `WG-009`, `WG-010` |
| [Tectonic Plates](TECTONIC_PLATES.md) | `WG-011` |
| [Tectonic Structures and Geological Provinces](TECTONIC_STRUCTURES_AND_PROVINCES.md) | `WG-012` |
| [Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md) | `WG-013`, `WG-014` |
| [Architecture Overview](../architecture/ARCHITECTURE_OVERVIEW.md) | `WG-015`, `WG-016` |
| [Earth-Like Planetary Contract](EARTH_LIKE_PLANETARY_CONTRACT.md) | `WG-025` |

## Phase boundary

The [Natural-World Foundation Roadmap](../planning/NATURAL_WORLD_FOUNDATION_ROADMAP.md) owns the
active phase scope. Human civilization, political simulation, economics,
multiplayer implementation, and Web3 mechanics remain outside this phase.
