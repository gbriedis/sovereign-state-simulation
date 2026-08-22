# Geological Material Composition

- **Status:** Accepted material architecture; basis and algorithms unresolved
- **Scope:** Geological material during generated prehistory
- **Last reviewed:** 2026-08-22

## Core principle

> **Represent ordinary geological material with a compact bulk-composition
> basis, keep trace elements separate, and derive minerals and rocks from
> composition plus pressure, temperature, volatiles, formation process, and
> geological history.**

The simulation preserves meaningful geochemical causes without becoming a full
chemistry simulator.

> **Store causes and history; derive consequences and classifications wherever
> practical.**

For geological material, composition, physical conditions, volatiles, formation
process, and history are deeper truths than a primitive label such as
`rock_type = Granite`.

Under the
[canonical present-state model](CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md),
this principle does not make every consequence a stored field. The causes needed
to define present truth or future evolution may be canonical while reliable
consequences remain derived or cached. The exact boundary remains unresolved.

## Bulk composition

Ordinary rock-forming chemistry uses a compact geochemical basis similar in
spirit to real whole-rock analysis. A candidate major-component basis may
include:

```text
SiO₂  Al₂O₃  FeO / total iron  MgO  CaO  Na₂O  K₂O  TiO₂  P₂O₅
```

Relevant volatile components may include:

```text
H₂O  CO₂  S
```

These lists are illustrative, not final. The accepted point is to represent the
bulk chemistry available to geological processes. The final components, iron
representation, normalization, precision, and storage format remain unresolved.

## Trace elements

Economically or geologically important trace material remains conceptually
separate from the major rock-forming composition. Possible future examples
include Cu, Ni, Zn, Pb, Au, Ag, Li, U, and rare-earth elements, but no final trace
vocabulary is accepted.

> **Background trace concentration is not the same thing as an ore deposit.**

A future deposit would require geological processes to mobilize, transport, and
concentrate trace material. This note does not define deposits or resource-
generation algorithms.

## Derived minerals and rocks

The causal direction is:

```text
bulk composition
+ volatile state
+ pressure
+ temperature
+ geological environment / formation process
+ history
→ mineral assemblage
→ rock material
```

Named rocks such as granite, basalt, limestone, and schist should be derived
classifications or material outcomes where practical, not arbitrary primitive
labels.

The eventual mineral-assemblage model should retain real causal relationships
through a tractable approximation suitable for the game. Possible approaches
may use composition regimes, pressure-temperature regimes, volatile state,
formation-process rules, or validated lookup and interpolation data. The final
method is unresolved, and the game does not require a full thermodynamic
equilibrium solver.

## Geological bodies and space

Bulk composition does not belong directly to every terrain-sampling cell. A
geological body or formation may own or reference composition and formation
history while cells and other query products sample or reference that body.

```text
geological body
├── geometry
├── bulk composition
├── volatile state / history
├── trace inventory
├── formation time / history
└── later modification history
```

This is illustrative only. It does not settle ownership, storage layout, cell
references, continuous fields, interpolation, or spatial variation within a
body. The accepted spatial direction is documented in
[Sparse 3D Geological World](SPARSE_3D_GEOLOGICAL_WORLD.md): bodies and contact
surfaces contribute to three-dimensional geological truth beneath map queries,
without fixing their geometry representation.

The body retains its geological identity across computational domains; neither
those domains nor their sampling cells divide it into unrelated entities. See
[Adaptive Spatial Partitioning](ADAPTIVE_SPATIAL_PARTITIONING.md).

## Minimal Rust-facing vocabulary

The following types name the minimum concepts without fixing their
representation:

```rust
struct GeologicalMaterial {
    bulk_composition: BulkComposition,
    volatile_state: VolatileState,
    trace_inventory: TraceInventory,
    material_state: GeologicalMaterialStateRef,
    history: GeologicalHistoryRef,
}

struct GeologicalBody {
    geometry: GeologicalBodyGeometry,
    material: GeologicalMaterialRef,
    formation_age: GeologicalAge,
    history: GeologicalHistoryRef,
}
```

All referenced types are intentionally undefined. Mineral assemblages and named
rock classifications are omitted because their derivation is not yet designed.

Solid, melt, and fluid coexistence and coherent versus unconsolidated structure
are documented separately in
[Geological Material State](GEOLOGICAL_MATERIAL_STATE.md). That state extends the
composition model without turning rock, magma, sediment, and fluid into mutually
exclusive primitive types.

## Scope boundary

This note establishes material-chemistry architecture only. It does not define:

- final mineral or rock taxonomies;
- full thermodynamic chemistry;
- ore deposits, resource placement, or resource economics;
- erosion, sediment transport, hydrology, climate, soils, or ecosystems;
- continents, political territories, or human systems.
