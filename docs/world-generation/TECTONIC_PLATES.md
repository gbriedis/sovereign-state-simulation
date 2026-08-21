# Tectonic Plates

- **Status:** Focused design direction; algorithms unresolved
- **Layer:** First physical-world abstraction
- **Last reviewed:** 2026-08-21

## Purpose

Tectonic plates provide the earliest useful physical history for world
generation. They divide the world's lithosphere into large, coherent moving
regions whose properties and interactions can later explain broad geological
structure.

A plate is not merely a visual polygon. It represents a connected section of
lithosphere—the crust and rigid uppermost mantle—with a shared broad motion and
physical character. Its shape, material tendency, and relationship to
neighbouring plates supply causes from which later geology may be derived.

This is a reality-first abstraction, not a full geophysics simulation. The game
does **not** simulate mantle convection, planetary accretion, or the complete
physics of plate deformation. Plates are the earliest layer at which enough
causal structure exists to give the later physical world a coherent history.

## Plate properties

Each plate likely needs the following meaningful properties:

- **Shape** — the area of physical space occupied by the plate and the edges it
  shares with neighbouring plates.
- **Crust material character** — a reference to or broad description of the
  underlying composition and material state from which continental-like or
  oceanic-like classifications may be derived.
- **Motion direction** — the plate's broad movement relative to the world or a
  defined reference frame.
- **Motion speed** — the magnitude of that movement in a real or clearly mapped
  unit.
- **Age and thickness** — enough lithospheric history to distinguish younger,
  thinner material from older or thicker material where that difference matters.
- **Density or buoyancy tendency** — a practical indication of how readily the
  plate tends to ride above or descend beneath neighbouring lithosphere.

These properties describe broad tendencies. They do not imply that every point
on a plate is identical or that the final model must store each property as one
uniform scalar. The required spatial variation remains unresolved.

Under the [Earth-Like Physical Framework](EARTH_LIKE_PHYSICAL_FRAMEWORK.md),
density, buoyancy, effective thickness, and crust classification should be
derived from physical causes and history wherever practical. Their appearance in
the illustrative vocabulary below means they are available domain quantities,
not necessarily independently generated or permanently stored fields.

## Interactions

Relative motion matters more than a plate's motion in isolation. Where plates
meet, their directions, speeds, lithospheric and crustal material, age,
thickness, and buoyancy tendency create different geological histories.

### Collision

Plates moving toward one another compress and deform lithosphere. The interaction
must be able to distinguish broad collision behavior from other boundary
behavior and retain which plates participate and how strongly they converge.

### Subduction

At some convergent boundaries, one plate tends to descend beneath another.
Relative density, buoyancy, age, thickness, crust composition, and material state
are relevant to that tendency. Subduction should arise from material properties
and relative motion, not from an unrelated random boundary label.

### Divergence

Plates moving apart create an extending boundary. The model must preserve the
direction and rate of separation so later geology can respond to a coherent
history.

### Transform motion

Plates can move laterally past one another. The boundary representation must be
able to express relative tangential motion rather than forcing every interaction
into convergence or divergence.

### Stable interiors

Areas well inside a plate are comparatively removed from active boundary
interaction. Stable does not mean geologically featureless or permanently
inactive; it means boundary-driven effects should generally weaken with distance
unless another later cause is introduced.

Boundary behavior may vary along one shared edge. The final representation of
that variation is an open decision.

## Causal role

The tectonic layer should preserve enough information for later geological work
to answer questions such as:

- Which lithospheric regions share a broad origin and motion?
- Where has lithosphere broadly converged, separated, or moved laterally?
- Which side of a convergent boundary tends toward subduction, and why?
- Which regions are close to active boundaries and which lie in stable interiors?

The plate layer should produce causes and history, not directly generate every
later physical feature. This note does not define continents, landforms, rivers,
soils, resources, political areas, or human systems.

Plate state and motion participate in the generated timeline described in
[Geological Prehistory](GEOLOGICAL_PREHISTORY.md). How plate motion changes over
that time remains unresolved.

## Minimal Rust-facing model

The following types express the minimum domain vocabulary currently implied by
the design. They are illustrative interfaces, not accepted storage formats or
final implementation.

```rust
struct TectonicPlate {
    id: PlateId,
    shape: PlateShape,
    material: LithosphereMaterialRef,
    motion: PlateMotion,
    age: LithosphereAge,
    thickness: LithosphereThickness,
    density: Density,
    buoyancy: BuoyancyTendency,
}

struct PlateMotion {
    direction: Direction,
    speed: Speed,
}

struct PlateBoundary {
    id: BoundaryId,
    plates: (PlateId, PlateId),
    path: BoundaryPath,
    interaction: BoundaryInteraction,
    relative_motion: RelativeMotion,
}

enum BoundaryInteraction {
    Collision,
    Subduction { descending_plate: PlateId },
    Divergence,
    Transform,
}
```

`PlateShape`, `LithosphereMaterialRef`, `BoundaryPath`, physical units, numeric
precision, spatial variation, and whether interaction type is stored or derived
are intentionally undefined. A material reference does not decide whether a
plate, geological body, field, or another structure owns composition. Stable
interiors are regions inferred from plate geometry and boundary influence, not a
boundary enum variant.

## Scope boundary

This layer establishes plates, their broad physical properties, and their
relative interactions. It does not yet specify:

- generation algorithms or plate-count distributions;
- a planar, spherical, or projected geometry representation;
- time-stepped plate simulation or reconstruction of complete geological eras;
- deformation, mantle dynamics, volcanism, erosion, or detailed rock formation;
- any later natural, political, economic, or human layer.

Those questions must remain open until their costs and downstream value can be
evaluated.
