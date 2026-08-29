---
id: WG-007
type: world-generation-specification
status: accepted
scope: Canonical present geological truth, provenance, and deterministic refinement
authority: Owns the distinction between canonical state, provenance, constraints, refinement, and derived data
implementation: unresolved
concept_state: accepted
coverage: partial
last_reviewed: 2026-08-22
---

# Canonical Geological State and Refinement

## Core direction

> **History generates the world; current state becomes authoritative.**

Geological prehistory and its event/operator sequence produce the world, but
normal gameplay and simulation queries do not replay that prehistory from the
beginning.

The seed, retained history, and compatible generator remain important inputs,
but they are not the sole normal-runtime representation of a generated world.

```text
initial conditions
+ geological prehistory
+ events / operators
        ↓
canonical present geological state
        +
compact retained causal history
```

Canonical truth also does not require maximum-resolution meshes, voxels, or
other presentation data to be stored everywhere.

## Canonical present state

> **Canonical current state is the smallest persistent representation
> sufficient to define what physically exists now, independently of
> presentation and without replaying geological prehistory.**

For geology, it may eventually include enough information to represent:

- currently existing geological bodies and their present queryable 3D geometry;
- the present semantic boundary of the ground-material domain needed to query
  ground and seafloor;
- contacts, bounding surfaces, faults, and present displacement relationships;
- current material identity, composition, and state;
- essential topology and spatial relationships;
- active physical state required to determine future geological evolution.

Canonical relationships may include:

```text
body A overlies body B
intrusion C cuts body A
fault F displaces bodies A and C
erosion surface U truncates older bodies
```

The exact schema, geometry representation, and persisted/derived boundary remain
open.

## Present state and provenance

Canonical present physical state answers:

```text
What physically exists here now?
```

Persistent causal provenance answers:

```text
How did it get here?
When did it form?
Which events affected it?
What geological episode produced it?
```

For example:

```text
Body #381
formed: 462 Ma
origin: marine deposition
metamorphosed: 338 Ma
faulted: 291 Ma
exposed by erosion: 41 Ma
```

History remains compact, explanatory, and causally useful. It need not retain
every temporary numerical field or intermediate geometry used during generation
when present truth no longer depends on replaying those exact steps.

## Derived and disposable representations

> **Materializing canonical geology does not mean materializing renderer
> geometry.**

```text
CANONICAL GEOLOGY
        ↓ query / sample / materialize
DERIVED REPRESENTATION
        ↓
RENDERER / CLIENT
```

Bevy meshes, GPU buffers, LOD meshes, heightmaps, sampled elevation or
surface-geology rasters, 250/500 m map layers, cross-section render products,
client chunk caches, and other renderer-ready or query products are
non-canonical derived data. Deleting one must not alter world truth.

## Stored causes and active state

Canonical state does not imply storing every calculable property.

> **Store causes and history; derive consequences wherever practical.**

If density can be derived reliably from composition, phase or mineral state,
pressure or depth, and temperature, it may remain derived or cached. Caching a
quantity for performance does not make it more fundamental. The exact
persisted/derived split is unresolved.

Canonical state is not necessarily static geometry:

> **Present active physical state belongs to canonical truth when it is
> necessary to determine future evolution.**

Current thermal, magma-body, stress or strain, vertical disequilibrium or active
displacement, fluid-pressure, or other process state may later qualify. This
principle does not design those systems.

For current geology, absolute position belongs to canonical geometry, while
depth is contextual and lithostatic pressure is normally derived from gravity
and the actual overlying material column. Temperature belongs to canonical
present state when present geometry and retained provenance cannot reconstruct
the thermal truth promised to future queries. It is spatial query state across
bodies and adaptive computational domains; bodies supply material properties
rather than owning isolated temperatures. Conservative remapping may operate on
thermal content rather than literal temperature, and ordinary contacts must not
create artificial discontinuities unless modeled interface physics justifies
specialized behavior. The exact pressure cache, field representation, and
coarse/fine boundary contract remain open; see
[Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md).

Transient thermal detail may simplify only when all information promised to the
finest future canonical query class remains recoverable. A small but meaningful
signal may persist as constrained residual state or sufficient compact
provenance even when explicit transient detail is discarded.

Actual broad solid-Earth geometry is canonical, and the semantic upper boundary
of its ground-material domain supplies ground, seafloor, and elevation queries.
It is not necessarily the highest spatial point with a nonzero solid fraction or
a single-valued height function. Preferred vertical response, regional support
constraints, or vertical disequilibrium may also belong to active canonical
state when necessary to determine continuing geometry evolution. Their exact
persisted-versus-derived split remains open.

Broad vertical response transforms the affected canonical 3D state, not merely
a derived surface. Relevant bodies, contacts, faults, topology, material and
thermal state, mass or volume accounting, provenance relationships, and
cross-domain geometry must remain consistent unless modeled physics justifies a
change. Refinement must preserve those established relationships and regional
response constraints rather than regenerate elevation as independent local
detail. See
[Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md).

## Canonical unresolved detail

> **Unresolved detail means “not yet explicitly materialized,” not “the universe
> has not decided anything.”**

A coarse canonical region may combine established large-scale truth with bounded
unresolved degrees of freedom. For a sedimentary basin, established facts might
include its existence, broad age range, basement-depth range, regional dip,
major fault system, and broad lithological sequence. Exact local bed thickness,
minor faults, metre-scale heterogeneity, small channels or lenses, and fine
fractures may remain unresolved but constrained by those facts.

Canonical truth therefore has three useful states:

1. **Established canonical truth** — explicitly resolved facts that do not
   change merely because resolution increases, such as a basin, fault, or
   cross-cutting relationship.
2. **Constrained unresolved truth** — unmaterialized details bounded by current
   truth, such as a thickness range, permitted minor-fault regime, composition
   distribution, or small-scale folds compatible with regional structure.
3. **Truly unspecified** — information about which the model currently makes no
   meaningful claim. Use this state sparingly.

When simulation requires truly unspecified information, the authority may
resolve it and promote the result to established canonical state.

> **Canonical truth can consist of both resolved facts and constraints over
> unresolved facts.**

```text
before refinement:
canonical truth = allowed realizations satisfying constraints C

after refinement:
one deterministic realization satisfying C becomes established canonical detail
```

## Deterministic constrained refinement

```text
parent canonical constraints
+ retained geological history
+ stable world seed
+ region identity
+ target refinement level
+ compatible generator / ruleset
        ↓
deterministic finer realization
        ↓
validate against parent constraints
        ↓
promote to canonical resolved state
```

The same stable inputs must produce the same realization. Unloading, reloading,
or inspecting repeatedly must not provide rerolls.

> **Observation may trigger refinement, but observation is not the physical
> cause of the resulting geology.**

Player activity may require finer resolution, causing the authority to resolve
allowed detail deterministically and promote it to canonical state. Refinement
is a computational act, not a geological event.

The governing laws are:

> **Refinement reveals detail; it does not casually rewrite established truth.**

> **Unmaterialized does not mean unconstrained.**

> **Detail may increase while previously established truth remains stable.**

If coarse truth establishes a major granite body in a regional volume, ordinary
refinement cannot replace the entire region with limestone unless the earlier
uncertainty explicitly allowed that outcome. Refinement narrows the solution
space.

## Canonical refinement hierarchy

Canonical constraints may form a hierarchy:

```text
global history
↓
tectonic province
↓
geological region
↓
basin / mountain belt
↓
local geological bodies
↓
site-scale detail
↓
mine / borehole-scale detail
```

Each child must remain compatible with its parent. Required detail follows
physical complexity, simulation relevance, and observation or gameplay needs
without choosing exact levels, partitions, or resolutions.

This geological constraint hierarchy is distinct from the computational domains
that index and materialize it. Their accepted relationship is documented in
[Adaptive Spatial Partitioning](ADAPTIVE_SPATIAL_PARTITIONING.md). The final
refinement hierarchy remains open.

## Persistence and generator evolution

> **Once materially relevant detail becomes canonical, it should not reroll
> because the generator changes or because the area is revisited.**

A persistent authority may outlive many generator versions. Seed and event
history alone are not assumed to reproduce the identical world under future
algorithms. Already resolved or interacted-with regions should preserve their
canonical state rather than silently regenerate through newer algorithms.

Still-unmaterialized detail may potentially use compatible generator
improvements if it continues to satisfy all parent canonical constraints. Exact
versioning, migration, checkpointing, and old-generator retention policies are
unresolved.

## Preferred overall model

```text
CANONICAL WORLD

1. RESOLVED PRESENT STATE
   - explicit physical facts
   - geometry / topology / material state
   - active physical state where needed

2. CONSTRAINED UNRESOLVED STATE
   - bounded degrees of freedom
   - compatible with established truth

3. PERSISTENT PROVENANCE
   - compact geological history
   - causal origin and transformation relationships

4. NON-CANONICAL DERIVED DATA
   - meshes, rasters, LODs
   - renderer data, caches, query products
```

## Scope boundary

This note does not define database or serialization schemas, ECS layouts,
refinement algorithms, noise formulas, implicit fields, meshing, networking,
client streaming, mining, drilling, resource generation, groundwater, climate,
hydrology, soils, ecosystems, or human systems.
