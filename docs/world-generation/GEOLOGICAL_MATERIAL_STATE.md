# Geological Material State

- **Status:** Accepted material-state architecture; representation unresolved
- **Scope:** Multi-phase geological material during generated prehistory
- **Last reviewed:** 2026-08-22

## Core decision

> **Do not model rock, magma, sediment, and fluid as four mutually exclusive
> material types. Represent geological material through composition/history,
> phase fractions, and structural state.**

The minimum conceptual model is:

```text
GEOLOGICAL MATERIAL
+ bulk composition
+ trace inventory
+ geological history

PHASE FRACTIONS
- solid
- melt
- fluid

STRUCTURAL / CONSOLIDATION STATE
- coherent
- unconsolidated
```

Exact storage and numeric representation remain unresolved.

Material state required to determine ongoing evolution may belong to
[canonical present truth](CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md). This
does not settle which phase, structural, thermal, or other quantities must be
persisted rather than derived.

Lithostatic pressure and pore-fluid pressure remain distinct. Lithostatic
pressure normally follows gravity and material overburden; fluid within pores or
fractures may carry separate pressure state. Phase, structural, porosity, and
fluid state may also influence thermal behavior. These relationships are
documented without a poromechanics or heat solver in
[Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md).

Material state influences spatial thermal properties, but canonical temperature
belongs to a continuous field across bodies and contacts rather than to one
independent value stored by each body.

## Phase fractions

Solid, melt, and fluid may coexist in one geological material volume. This
allows partial melting and fluid-bearing material without forcing the entire
body into one exclusive state.

Illustrative examples include:

```text
100% solid + coherent
→ ordinary solid rock

80% solid + 15% melt + 5% fluid
→ partially molten rock

65% solid grains + 35% fluid + unconsolidated
→ wet sediment

mostly melt
→ magma-dominated material
```

These examples do not establish thresholds, classifications, precision, or
normalization rules.

## Structural state

Rock versus sediment is partly a structural and mechanical condition rather
than a difference in fundamental chemistry. At minimum, the model distinguishes:

- **coherent / lithified material**;
- **unconsolidated granular or particulate material**.

This supports causal transitions such as:

```text
weathering / fragmentation
coherent → unconsolidated

burial + compaction + cementation / lithification
unconsolidated → coherent
```

Whether consolidation is categorical, continuous, strength-based,
porosity-based, or represented through another mechanical abstraction remains
open.

Regolith is not a fundamental material phase. It may later be represented as a
near-surface form or subtype of unconsolidated material produced by weathering
and/or transport. This note does not define regolith or soils.

## Material-changing processes

The accepted state model provides causal vocabulary for later processes:

```text
melting                 → increases melt fraction
crystallization         → decreases melt fraction / increases solid fraction
metamorphism            → changes solid mineral assemblage while mostly solid
weathering/fragmentation→ weakens or destroys coherent structure
erosion/transport       → moves unconsolidated material
deposition              → places unconsolidated material elsewhere
burial/compaction/
cementation             → increases consolidation and may produce coherent rock
fluid infiltration      → changes fluid fraction and/or fluid chemistry
hydrothermal transport  → moves dissolved inventory through mobile fluid
precipitation           → transfers dissolved material into solid minerals
```

These are examples of how future processes map to state changes. They do not
define a final process enum, thresholds, rates, or simulation algorithms.

## Relationship to composition

This state model extends, rather than replaces,
[Geological Material Composition](GEOLOGICAL_MATERIAL_COMPOSITION.md):

```text
bulk composition
+ trace inventory
+ volatile / fluid chemistry
+ phase fractions
+ structural state
+ pressure
+ temperature
+ geological history
→ mineral assemblages
→ rock classifications
→ melt behavior
→ metamorphic transformations
→ sedimentary material
→ hydrothermal alteration
```

Named rock classes remain derived outcomes where practical.

## Minimal Rust-facing vocabulary

The following is domain vocabulary only, not an accepted storage schema:

```rust
struct MaterialPhaseFractions {
    solid: Fraction,
    melt: Fraction,
    fluid: Fraction,
}

struct GeologicalMaterialState {
    phases: MaterialPhaseFractions,
    structure: StructuralState,
}

enum StructuralState {
    Coherent,
    Unconsolidated,
}
```

Numeric types and storage are unresolved. Phase fractions may not be stored in
this exact form, structural state may become continuous, and conservation and
normalization rules remain open.

## Scope boundary

This note establishes the multi-phase material-state model only. It does not
define:

- final mineral or rock taxonomies or full thermodynamic equilibrium;
- detailed melting, metamorphic, sediment-transport, hydrothermal-flow, or
  erosion algorithms;
- poromechanics, hydrology, climate, soils, or ecosystems;
- ore deposits, resources, continents, political territories, or human systems.
