# Earth-Like Physical Framework

- **Status:** Accepted foundational rule; numerical details unresolved
- **Scope:** Minimal planetary context for geological prehistory
- **Last reviewed:** 2026-08-22

## Core rule

The game generates Earth-like worlds under a common Earth-like physical
framework. It is not a generic planet simulator. The broader Level 0 boundary
is defined by the
[Earth-Like Planetary Contract](EARTH_LIKE_PLANETARY_CONTRACT.md).

> **Fix the physics of the world where the game is not trying to create
> variation; procedurally generate the geology and history that are meant to
> differ between worlds.**

The framework fixes physical rules where variation is not part of the game. A
world-creation profile may also select bounded Earth-like planetary causes
before geological history begins. Generated geology varies within that selected
context rather than randomizing fundamental physics.

> **Store causes and history; derive consequences and classifications wherever
> practical.**

Pressure, density, buoyancy, melting tendency, mechanical behavior, effective
lithosphere thickness, and classifications should follow from the fixed context,
generated state, and accumulated history wherever the abstraction supports it.
They should not be unrelated random values.

## Planetary context consumed by geology

The current geological-prehistory layer needs only a minimal Earth-like
context. Values come from the compatible ruleset and selected planetary
contract:

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
- **Basic water and volatile assumptions** — the inventories and physical
  reference behavior needed by current geological reasoning, such as effects on
  density, melting, or material state; not their final surface distribution or
  a hydrological, atmospheric, or ocean model.

Some values may be fixed versioned baselines; others may vary within the bounded
Earth-like contract. Which values vary, their exact ranges, correlations,
precision, and implementation types remain unresolved. Standard Earth reference
values may be used when needed, but must be identified as baseline or
configurable constants rather than hidden assumptions.

## Generated physical state

World generation varies physical state and history within the fixed framework.
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

Consequences should be calculated or classified from fixed context, generated
state, and history wherever practical. Examples include:

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

This note defines the minimal Earth-like context used by current geological
reasoning, not a planetary-science specification. It does not define:

- configurable planet types or non-Earth-like physics;
- final atmospheric composition, climate, seasons, or surface water
  distribution;
- hydrology, ocean circulation, soils, ecosystems, or resources;
- continents, political territories, or human systems.
