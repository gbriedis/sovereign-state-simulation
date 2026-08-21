# Sparse 3D Geological World

- **Status:** Accepted architectural direction; representation unresolved
- **Scope:** Geological space beneath the map-first interface
- **Last reviewed:** 2026-08-22

## Core decision

> **Sparse 3D geological truth beneath a map-first interface.**

The physical world is genuinely three-dimensional. Surface maps are views and
queries over that world, not the complete source of geological truth. The game
does not need a uniform planet-sized voxel grid to preserve this distinction.

The intended abstraction is sparse geological structure composed from surfaces
and bounded bodies or volumes where geological history requires them.

## Geological surfaces and bodies

Surfaces may represent ground, contacts between units, the top or bottom of a
body, faults, unconformities, or intrusive contacts. Bounded geological bodies
may represent sedimentary units, intrusive bodies, metamorphic bodies, fault
blocks, unconsolidated deposits, and other volumes created by later accepted
geological processes.

These examples establish the kinds of spatial truth the model must eventually
express; they are not a final taxonomy or geometry model.

Later geological events must be able to act on inherited three-dimensional
structure. The accepted
[Geological Geometry Operators](GEOLOGICAL_GEOMETRY_OPERATORS.md) model separates
the historical event from the reusable operations that cut, displace, truncate,
bury, intrude, erode, or otherwise modify earlier surfaces and bodies. The exact
topology, contact rules, overlap semantics, mathematics, and event algorithms
remain unresolved.

## Map-first presentation

The primary player experience remains a map. A surface cell, map layer,
cross-section, or local inspection is a query or projection of relevant
three-dimensional truth.

The renderer, camera, and interface do not define physical reality. The
simulation/world core owns that reality independently of presentation so it can
support headless authority and more than one future view without changing the
underlying geological meaning.

## Detail follows attention

Three-dimensional truth does not imply maximum resolution everywhere. Distant
or inactive regions may remain coarse summaries; important regions may retain
richer structure; the player's nation may receive higher detail; and a small
local area may later be refined further when a relevant query requires it.

Refinement must preserve compatibility with canonical history and coarser
state. Whether detail is generated eagerly, lazily, hierarchically, cached,
persisted, or deterministically rematerialized is unresolved.

## Authority boundary

The authoritative world generator creates the canonical geological world and
its history. In multiplayer, the server owns that truth and provides clients
only the subsets and derived presentation data they need. Clients do not
independently generate authoritative geology or reconstruct the whole planet.

Singleplayer uses the same conceptual boundary with a local authority; it does
not require networking.

> **Authoritative world generation is separated from client play cost.**

Expensive generation may occur during world creation, while canonical state can
still remain hierarchical, summarized, lazy, refined, or cached rather than
fully materialized at maximum resolution.

## Scope boundary

This note does not define:

- final surface, volume, topology, coordinate, precision, or indexing models;
- a voxel simulation, final meshes, renderer, network protocol, or database;
- geological-event, erosion, sedimentation, or other process algorithms;
- mining, drilling, tunnels, geothermal systems, or groundwater;
- hydrology, climate, soils, ecosystems, resources, continents, political
  territories, or human systems.
