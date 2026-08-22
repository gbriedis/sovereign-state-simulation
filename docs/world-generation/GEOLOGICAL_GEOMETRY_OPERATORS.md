# Geological Geometry Operators

- **Status:** Accepted conceptual model; mathematics and implementation unresolved
- **Scope:** Event-driven modification of inherited 3D geological state
- **Last reviewed:** 2026-08-22

## Core principle

> **Geological events should modify inherited 3D geological state through a
> small set of reusable geometric operations rather than painting final terrain
> or requiring full volumetric physics.**

A **geological event** describes what happened in geological history. A
**geometric operator** describes how that event changes the canonical 3D
geological state.

```text
GEOLOGICAL EVENT
→ applies one or more
GEOMETRIC OPERATORS
→ modifies
SURFACES / BODIES / CONTACTS
→ produces
UPDATED 3D GEOLOGICAL STATE
```

For example:

```text
continental rifting episode
→ extension
→ faulting / displacement
→ subsidence
→ possible intrusion

continental collision
→ shortening / compression
→ folding / warping
→ faulting / thrusting
→ uplift
```

These examples do not establish a final geological-event taxonomy or exact
composition rules.

## Candidate operator families

This is an accepted conceptual vocabulary, not a final enum, implementation
API, or claim that every item is a primitive.

### Create material

- **Deposit / accumulate** creates a geological body or layer, may fill
  available or accommodation space, and acts on inherited surfaces and
  geometry.
- **Intrude** inserts a younger material body into older geology and may
  cross-cut existing bodies and contacts.

### Remove material

- **Erode / truncate** removes existing material according to a younger
  erosional or truncation surface and may expose deeper or older bodies.

### Deform material

- **Fold / warp** continuously deforms existing surfaces and bodies without
  necessarily creating a discontinuity.
- **Extend / rift** stretches or thins a region and may compose with faulting
  and subsidence.
- **Compress / shorten** shortens, thickens, and deforms a region and may
  compose with folding, faulting, and uplift.
- **Uplift / subside** changes regional vertical position or shape and may
  create or remove accommodation space.

### Break and offset material

- **Fault / displace** creates a discontinuity and offsets older geological
  bodies and surfaces across it.

## Chronology and inheritance

> **Chronology determines cross-cutting and inheritance relationships.**

A later operator acts on the 3D state produced by earlier events. An
illustrative sequence is:

```text
1. sediment A deposited
2. sediment B deposited
3. folding
4. intrusion
5. faulting
6. erosion / truncation
7. younger sediment deposited
```

The resulting world must preserve relationships such as:

- the intrusion is younger than the bodies it cuts;
- the fault is younger than the bodies it offsets;
- an erosion surface may truncate older faults, folds, and bodies;
- younger sediment may overlie that truncation surface without inheriting the
  older displacement.

This establishes causal chronology, not a full geological inference system or
its storage representation.

After geological prehistory, the resulting present state becomes authoritative.
Compact provenance retains the meaningful event and transformation history, but
normal queries do not replay the full operator sequence. See
[Canonical Geological State and Refinement](CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md).

## Composition

Higher-level geological episodes should generally compose reusable operators
rather than introduce unrelated one-off geometry rules.

```text
rifting
= extension
+ faulting
+ subsidence
+ optional intrusion / magmatism

collision
= compression
+ folding
+ faulting
+ uplift
+ later material or process consequences
```

The operator sequence, parameterization, overlap, concurrency, and interaction
with material-changing processes remain unresolved.

Operators also change physical causes inherited by later queries. Deposition
and erosion alter material overburden and therefore pressure; intrusion may
introduce a transient thermal anomaly. These consequences follow from updated
geometry, material, and history rather than becoming unrelated operator labels.
Their accepted causal role is documented in
[Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md).

## Representation independence

The operator model does not select uniform voxels, triangle meshes, implicit
scalar fields, boundary representations, displacement grids, finite-element
mechanics, or a particular geometry library.

Candidate implementation strategies may include implicit geological modelling,
explicit surfaces or boundary representations, displacement or deformation
fields, and hybrid approaches. These are open decisions, not accepted
architecture.

## Governing abstraction

> **Do not simulate every force continuously when a causally justified
> geological event can be represented by a geometric transformation that
> preserves chronology and inherited state.**

This does not prohibit later physically informed deformation models. It defines
the intended abstraction boundary for geological world generation.

## Scope boundary

This note does not define:

- final mathematical deformation algorithms or a geometry engine;
- implicit-modelling, mesh, voxel, or finite-element implementation;
- a final geological-event taxonomy or final operator API;
- erosion rates, sediment transport, or magma flow;
- hydrology, climate, soils, resources, continents, political systems, or human
  simulation.
