# Adaptive Spatial Partitioning

- **Status:** Accepted architectural direction; hierarchy and indexing unresolved
- **Scope:** Geological continuity, computational locality, and sampling
- **Last reviewed:** 2026-08-22

## Core direction

> **Resolution is a property of a representation, not of physical reality.**

No universal cell size defines geological truth. A `500 × 500 m`, `250 × 250 m`,
or other grid may be useful for a prototype, query, simulation, or map layer,
but it is not the ontology of the world.

> **Canonical geology may exist at different resolved levels of detail in
> different places.**

A simple region may remain coarse while a complex or currently relevant region
requires a finer canonical representation. A clean nested hierarchy is
preferred over arbitrary unrelated resolutions where practical. An illustrative
sequence is:

```text
4000 × 4000 m
↓
2000 × 2000 m
↓
1000 × 1000 m
↓
500 × 500 m
↓
250 × 250 m
↓
125 × 125 m
```

These values are not accepted levels.

> **Use the coarsest representation that preserves the canonical truth required
> at that location and time.**

## Why detail is required

Detail follows more than attention:

```text
required detail
= physical / geological complexity
+ simulation relevance
+ observation / gameplay needs
```

Observation may trigger refinement, but it is not the only cause of
computational detail. A structurally complex faulted region may need finer
representation than a simple stable region before direct inspection.

## Three distinct spatial concepts

> **Geological structure determines physical continuity; spatial partitions
> determine computational locality. Never confuse the two.**

- A **geological feature** is a continuous canonical entity such as a body,
  fault, intrusion, basin, fold, or contact surface.
- A **spatial domain or chunk** is infrastructure for indexing, local queries,
  refinement, persistence locality, streaming, caching, workload scheduling,
  and visibility or materialization.
- A **cell or sampling unit** is a system-specific analysis or presentation
  unit.

```text
CELL
= system-specific sample / analysis unit

CHUNK / SPATIAL DOMAIN
= computational locality

GEOLOGICAL FEATURE
= physical canonical entity
```

These concepts need not share a resolution.

## Geological identity crosses domains

Spatial boundaries must not split one geological feature into unrelated
identities.

```text
GEOLOGICAL WORLD
├── Body #172
├── Fault #31
├── Intrusion #94
└── Contact #551

SPATIAL DOMAINS
├── Domain A references #172 and #31
├── Domain B references #172, #31, and #94
└── Domain C references #31 and #94
```

A domain may hold only a partial representation of a large feature without
creating a new geological entity.

> **A geological entity may have a global identity while only parts of its
> representation are loaded, refined, persisted, or materialized locally.**

```text
Geological Body #172
├── identity
├── provenance
├── broad canonical constraints
└── spatial representations / refinement nodes
    ├── Region A
    ├── Region B
    └── Region C
```

Querying one area of a very large body does not require loading its entire
highest-detail representation.

## Cells query geology

> **Cells sample geological truth; they do not contain or define it.**

Different sampling grids may query the same canonical 3D state. Changing map or
simulation sampling resolution does not regenerate geological truth.

```text
500 m map ─┐
           ├─→ canonical 3D geology
250 m map ─┘
```

## Independent hierarchies

The geological and computational hierarchies overlap spatially but remain
distinct.

```text
GEOLOGICAL HIERARCHY           COMPUTATIONAL SPATIAL HIERARCHY

planetary lithosphere          world
↓                              ↓
geological province            spatial region
↓                              ↓
basin / orogen / region        subregion
↓                              ↓
geological bodies              chunk / refinement domain
↓                              ↓
local structures               local query domain
```

A fault may cross many computational domains, and one domain may intersect many
geological bodies. Geological entities do not need to align with computational
boundaries.

## Variable neighboring resolution

Neighboring canonical regions may legitimately use different refinement levels:

```text
Region A: 250 m resolved representation
Region B: 1000 m resolved representation
```

Both must remain compatible with shared parent truth and shared geological
features. Uniform refinement is not required merely to avoid a representational
mismatch.

> **Shared canonical features constrain every representation that intersects
> them, regardless of local refinement level.**

If `Fault #31` crosses fine and coarse regions, both refer to the same canonical
fault. Fine representation may add compatible bends, segmentation, displacement
variation, or subsidiary structures, but it may not contradict the established
parent feature.

A future boundary contract may need canonical feature identity, boundary
crossings, broad orientation, body ordering or topology, parent material
identity, fault displacement relationships, and compatible parent-field values.
Its exact form remains open.

## Context-aware refinement

Local refinement is constrained by more than its target domain:

```text
parent canonical constraints
+ cross-boundary feature constraints
+ neighbor context
+ retained geological history
        ↓
local refinement
        ↓
finer representation compatible with parent truth
```

Fine detail must reconnect consistently with canonical parent features at
domain boundaries. Refinement may therefore require a surrounding context,
halo, or overlap region:

```text
┌─────────────────────────────┐
│        context / halo       │
│    ┌───────────────────┐    │
│    │ refinement target │    │
│    └───────────────────┘    │
│        context / halo       │
└─────────────────────────────┘
```

This supports continuity of faults, folds, contacts, intrusions, and
stratigraphic trends. Halo size and generation rules remain unresolved.

## Topology and persistence ownership

Relationships such as `Intrusion C cuts Body A`, `Fault F offsets A and C`, or
`Unconformity U truncates all three` belong to canonical geological entities.
They are not unrelated facts independently owned by every intersected chunk. A
future topology or relationship structure may exist above spatial partitions;
its schema is unresolved.

Persistence may be spatial while identity and history remain geological:

```text
ENTITY IDENTITY
    Body #12
    Fault #9

SPATIAL REPRESENTATION
    Body #12 / Region R42
    Body #12 / Region R43
    Fault #9 / Region R42

TOPOLOGY / HISTORY
    Body #12 created by Event E7
    Fault #9 cuts Body #12
```

This is a conceptual ownership boundary, not a database or serialization design.

## Compatibility with canonical refinement

Adaptive resolution follows the established canonical-state laws:

```text
coarse canonical constraints
↓
finer deterministic realization
↓
promoted established truth
```

Once materially relevant fine detail becomes canonical, it remains stable.
Derived caches and presentation products may still be unloaded without deleting
established truth.

Thermal representation follows the same adaptive rule. Stable ancient regions
may use a coarse background field, while young intrusive or active regions may
need finer spatial or temporal state. Coarse and fine representations must
describe one compatible canonical thermal state. Their shared boundary contract
may eventually constrain temperature, heat flux, transport-relevant material
properties, and parent thermal state without making computational edges physical
thermal boundaries. Remapping and refinement must conserve total energy except
for explicitly modeled sources, sinks, or transport across the chosen
control-volume boundary; internal phase transformations may change energy form
but not total energy. Ordinary contacts must not create artificial
discontinuities, while future modeled interface physics may justify specialized
behavior. Interpolation and conservation methods remain open. See
[Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md).

Broad vertical response is regional rather than a set of independent columns.
A load, lithospheric buoyancy anomaly, or flexural response may cross multiple
geological and computational domains. Coarse and fine representations must
preserve established broad solid-Earth geometry, compatible total loads, and
shared regional-response constraints. Local refinement must not create an
elevation seam, silently change regional mass balance, or replace canonical 3D
geometry with a local heightmap. The exact adaptive response representation and
support kernel remain open; see
[Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md).

## Preferred overall model

```text
NO UNIVERSAL GEOLOGICAL CELL SIZE

continuous geological entities
+ hierarchical / adaptive spatial domains
+ variable canonical refinement
+ shared boundary constraints
+ system-specific sampling grids
```

The governing laws are:

> **Resolution is a property of a representation, not of physical reality.**

> **Geological structure determines physical continuity; spatial partitions
> determine computational locality.**

> **Spatial partition boundaries must not become geological boundaries unless
> geology itself created a boundary there.**

> **Different parts of the same canonical world may exist at different resolved
> levels of detail provided their shared parent constraints and cross-boundary
> geological relationships remain consistent.**

## Scope boundary

This note does not choose a quadtree, octree, BVH, R-tree, domain dimensions,
refinement levels, halo size, database, serialization, networking, meshing,
Bevy chunk system, refinement algorithm, cell-size tuning, terrain generation,
hydrology, climate, soils, resources, mining, roads, settlements, political
borders, or human simulation.
