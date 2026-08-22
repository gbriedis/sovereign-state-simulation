# World-Foundation Roadmap

- **Version range:** `0.0.1`–`0.1.0`
- **Status:** Current phase
- **Theme:** The world before human civilization

## Purpose

Create the coherent physical foundation that every later political, economic,
social, and infrastructure system must respect.

World generation is a simulation of
[Geological Prehistory](world-generation/GEOLOGICAL_PREHISTORY.md). Its
accumulated output becomes the initial physical state of the eventual playable
civilization era. Geological time is coarse and meaningful rather than one tick
per year, and its exact representation remains open.

This prehistory runs within a fixed
[Earth-Like Physical Framework](world-generation/EARTH_LIKE_PHYSICAL_FRAMEWORK.md).
Fundamental planetary context is held constant while geology, physical state,
and history vary between generated worlds.

## Causal generation model

Natural layers must not be generated as independent decorative noise. Each layer
should derive as much as practical from prior physical conditions, and later
layers should remain explainable through those dependencies.

The current working causal direction begins with:

```text
planet
→ lithospheric plates
→ plate motion
→ boundary-relative motion
→ tectonic interaction
→ tectonic structures / geological provinces
→ rock history + broad elevation tendencies
→ later surface processes
→ present-day terrain
```

This is a design dependency model, not yet a final scientific algorithm or
strict one-way pipeline. Feedback between systems may be necessary. Its purpose
is to prevent arbitrary soils, disconnected rivers, random forests, and other
layers that do not follow from the world around them.

The first focused abstraction within geological history is documented in
[Tectonic Plates](world-generation/TECTONIC_PLATES.md). It establishes causal
plate properties and interactions without committing to a full geophysics model.

The next accepted conceptual layer is documented in
[Tectonic Structures and Geological Provinces](world-generation/TECTONIC_STRUCTURES_AND_PROVINCES.md).
It preserves tectonic history and broad tendencies without treating them as
final terrain.

The material causes inherited and modified through that history are documented
in [Geological Material Composition](world-generation/GEOLOGICAL_MATERIAL_COMPOSITION.md).
Bulk composition and trace inventories are preserved so minerals and named rocks
can later be derived rather than assigned as arbitrary primitive labels.

[Geological Material State](world-generation/GEOLOGICAL_MATERIAL_STATE.md) adds
coexisting solid, melt, and fluid fractions plus coherent or unconsolidated
structure without defining a full rock-cycle engine.

[Sparse 3D Geological World](world-generation/SPARSE_3D_GEOLOGICAL_WORLD.md)
establishes how those causes occupy physical space: geological truth is
three-dimensional and history-bearing beneath the map-first interface, without
committing to uniform voxels or a final geometry and refinement model.

[Geological Geometry Operators](world-generation/GEOLOGICAL_GEOMETRY_OPERATORS.md)
establishes how events change that inherited 3D state through a small,
composable operator language. It preserves chronology and cross-cutting
relationships without choosing a geometry engine or full volumetric physics.

[Canonical Geological State and Refinement](world-generation/CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md)
separates authoritative present truth from compact provenance and disposable
presentation data. Unmaterialized detail remains constrained and can be refined
deterministically without rewriting established geology.

[Adaptive Spatial Partitioning](world-generation/ADAPTIVE_SPATIAL_PARTITIONING.md)
separates continuous geological identity from computational domains and
system-specific sampling cells. Different regions may use different compatible
refinement levels without creating artificial geological boundaries.

[Depth, Pressure, and Thermal State](world-generation/DEPTH_PRESSURE_AND_THERMAL_STATE.md)
defines absolute position before contextual depth, derives lithostatic pressure
from actual overburden, and treats temperature as adaptive history-bearing state
rather than a universal geothermal-gradient formula. Material properties
influence one continuous thermal field across bodies and adaptive domains, with
controlled feedback fidelity rather than universal multiphysics coupling.

## In scope

- Land shape, regions, coastlines, and elevation
- Bedrock, geology, and parent materials
- Soils and their practical properties
- Rivers, lakes, groundwater, wetlands, and drainage
- Temperature, rainfall, wind, seasonality, and other climate properties
- Forests, grasslands, vegetation, and ecosystems
- Minerals and other natural resources
- Natural energy potential
- Flooding, erosion, landslides, and related hazards
- Engineering conditions such as bearing capacity and drainage
- Harbour and infrastructure suitability

## Definition of complete

Version `0.1.0` is complete when the land exists as a coherent natural system,
even if humanity never appears, and local conditions can be explained through
underlying physical causes and dependencies between generated layers.

## Out of scope for this phase

- Human civilization, settlements, politics, and economies
- Detailed technology, industry, military, and trade systems
- Final multiplayer architecture
- Web3 mechanics
- A comprehensive game design document
- Simulation of every aspect of Earth science
- Arbitrary progression systems for future content
