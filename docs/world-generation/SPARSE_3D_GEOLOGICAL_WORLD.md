---
id: WG-005
type: world-generation-specification
status: accepted
scope: Geological space beneath the map-first interface
authority: Owns the sparse three-dimensional geological truth model and its separation from presentation
implementation: unresolved
concept_state: accepted
coverage: partial
last_reviewed: 2026-08-30
---

# Sparse 3D Geological World

## Core decision

> **Sparse 3D geological truth beneath a map-first interface.**

The physical world is genuinely three-dimensional. Surface maps are views and
queries over that world, not the complete source of geological truth. The game
does not need a uniform planet-sized voxel grid to preserve this distinction.

The intended abstraction is sparse geological structure composed from surfaces
and bounded bodies or volumes where geological history requires them.

Canonical geometry uses physical position in the
[accepted planet-fixed frame](../decisions/ARCH-DEC-001-planet-fixed-physical-reference-frame.md).
Geodetic latitude, longitude, and reference height derive against the stable
[Earth-like reference ellipsoid](../decisions/ARCH-DEC-002-earth-like-reference-ellipsoid.md).
The ellipsoid is not physical ground or seafloor. Elevation and depth below
local ground, sea level, or another explicit reference surface are contextual
queries derived from canonical geometry, not the stored meaning of one
coordinate. Numeric encoding, precision, and exact query transformations remain
open; see
[Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md).

The physical ground or seafloor is queried from the upper boundary of the
canonical solid-Earth or ground-material domain. This is a semantic domain
boundary, not simply the highest point containing solid matter. It may later
include coherent rock, unconsolidated sediment, regolith, or soil while keeping
water, ice, atmosphere, vegetation, artificial structures, and suspended
sediment conceptually separate. Final domain ownership remains open.

Canonical 3D truth need not be a single-valued height function. Caves,
overhangs, cliffs, voids, and multiple ground/void intersections may exist. A
map elevation layer may derive one selected surface according to a future query
policy. Heightmaps, sampled elevation fields, and terrain meshes do not replace
canonical geometry. See
[Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md).

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

> **Cells sample geological truth; they do not contain or define it.**

Geological features retain continuous canonical identity across computational
domains. Chunks provide locality, and sampling grids provide system-specific
views; neither creates geological boundaries. See
[Adaptive Spatial Partitioning](ADAPTIVE_SPATIAL_PARTITIONING.md).

The renderer, camera, and interface do not define physical reality. The
world core owns that reality independently of presentation so it can
support headless authority and more than one future view without changing the
underlying geological meaning.

## Detail follows need

Three-dimensional truth does not imply maximum resolution everywhere. Simple
regions may remain coarse; geological complexity or simulation relevance may
require richer structure; and observation may trigger additional local
refinement.

Coarse state may contain both established facts and constrained unresolved
detail. Refinement must preserve established truth and remain compatible with
canonical history and parent constraints. Observation may trigger deterministic
refinement, but it does not physically create geology or permit a reroll.

[Canonical Geological State and Refinement](CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md)
defines this accepted distinction. Exact levels, persistence, constraint
representation, and refinement algorithms remain unresolved.

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

Normal authority queries use canonical present state; they do not replay the
entire geological prehistory. Compact history remains as provenance and as an
input or constraint for controlled refinement.

## Scope boundary

This note does not define:

- final surface, volume, topology, numeric encoding, precision, or indexing
  models;
- a voxel simulation, final meshes, renderer, network protocol, or database;
- geological-event, erosion, sedimentation, or other process algorithms;
- mining, drilling, tunnels, geothermal systems, or groundwater;
- hydrology, climate, soils, ecosystems, resources, continents, political
  territories, or human systems.
