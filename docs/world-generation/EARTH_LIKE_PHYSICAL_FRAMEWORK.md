---
id: WG-001
type: world-generation-specification
status: accepted
scope: Common Earth-like physical rules and the minimal planetary context consumed by geological prehistory
authority: Owns the common physical rules and reference framework consumed by geology; WG-025 owns bounded per-world planetary selection
implementation: unresolved
concept_state: accepted
coverage: partial
related: ADR-0002, WG-025
last_reviewed: 2026-08-23
---

# Earth-Like Physical Framework

## Core rule

The game generates Earth-like worlds under a common, versioned physical
framework. It is not a generic planet simulator, and compatible worlds do not
use different physical laws.

> **Fix the physics of the world where the game is not trying to create
> variation; procedurally generate the geology and history that are meant to
> differ between worlds.**

The framework provides common physical rules and reference behavior. The
selected [Earth-Like Planetary Contract](EARTH_LIKE_PLANETARY_CONTRACT.md) may
vary bounded planetary causes within that framework before geological history
begins; it does not randomize fundamental planetary physics.

> **Store causes and history; derive consequences and classifications wherever
> practical.**

Pressure, density, buoyancy, melting tendency, mechanical behavior, effective
lithosphere thickness, and classifications should follow from the common rules,
selected contract, generated state, and accumulated history wherever the
abstraction supports it. They should not be unrelated random values.

## Planetary context consumed by geology

The current geological-prehistory layer consumes only this minimal Earth-like
context:

- **Planet radius and curvature** — establish the world's scale and curved
  geometry for absolute position and contextual depth relationships. The exact
  datum and coordinate representation remain open.
- **Surface gravity** — provide the baseline acceleration needed by pressure,
  buoyancy, and mechanical reasoning. Whether later queries vary gravity with
  position or depth remains open.
- **Broad mantle reference conditions** — only the versioned asthenospheric
  reference thermal, density, basal heat, and related conditions required by
  the lithosphere and broad-buoyancy abstractions; not mantle convection or a
  full mantle model.
- **Surface pressure baseline** — a reference datum if a later absolute-pressure
  query requires it.
- **Basic water and volatile inputs** — the inventories and physical reference
  behavior needed by current geological reasoning, such as effects on density,
  melting, or material state; not their final surface distribution or a
  hydrological, atmospheric, or ocean model.

Some of these inputs may remain fixed or versioned ruleset baselines; others may
receive bounded values from `WG-025`. Exact values, supported ranges,
correlations, precision, and implementation types are unresolved. Standard Earth
reference values may be used when needed, but must be identified as baselines or
selected contract inputs rather than hidden assumptions.

## Generated physical state

World generation varies physical state and history within the common rules and
selected planetary contract.
Relevant generated state currently includes:

- lithosphere geometry;
- [geological material composition](GEOLOGICAL_MATERIAL_COMPOSITION.md);
- [multi-phase and structural material state](GEOLOGICAL_MATERIAL_STATE.md);
- [thermal state](DEPTH_PRESSURE_AND_THERMAL_STATE.md);
- volatile state where it matters to current geological reasoning;
- plate motion;
- solid-Earth geometry, loads, and any active vertical disequilibrium required
  to continue broad adjustment;
- accumulated geological history.

The exact representation of these causes remains unresolved.

## Derived state

Consequences should be calculated or classified from common rules, selected
contract inputs, generated state, and history wherever practical. Examples
include:

- lithostatic pressure from geometry, gravity, and material overburden;
- density behavior;
- buoyancy;
- preferred lithospheric vertical response and broad surface elevation;
- melting conditions or tendency;
- strength and rheological behavior;
- effective lithosphere thickness;
- continental-like or oceanic-like crust classification;
- contextual depth and local geothermal-gradient query products.

This does not require every consequence to be recalculated continuously.
Whether derived values are computed on demand, cached, summarized, or persisted
is an implementation decision.

Broad elevation follows the accepted
[Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md)
model. The elevation datum, asthenospheric buoyancy reference, and practical
deep evaluation horizon have different purposes and must remain distinct. The
deep horizon is not an additional physical planetary boundary.

## Scope boundary

This note defines the common Earth-like physical framework and the minimal
context consumed by current geological reasoning. `WG-025` owns the broader
Level 0 contract. This note does not define:

- arbitrary planet types or non-Earth-like physics;
- full atmospheric composition, solar irradiance, axial tilt, seasons, or
  climate constants;
- hydrology, ocean circulation, soils, ecosystems, or resources;
- continents, political territories, or human systems.
