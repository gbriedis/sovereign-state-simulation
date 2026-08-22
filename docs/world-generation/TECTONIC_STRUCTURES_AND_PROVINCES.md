# Tectonic Structures and Geological Provinces

- **Status:** Focused design direction; taxonomy and algorithms unresolved
- **Layer:** After lithospheric plates and their relative interactions
- **Last reviewed:** 2026-08-22

## Purpose

Plate interactions do not directly paint final terrain. Relative plate motion
and the resulting tectonic interactions create persistent tectonic structures
and geological provinces. These preserve broad physical tendencies and the
history that later geological and surface processes inherit.

> **Tectonics creates structures; time and surface processes shape the landscape
> we eventually see.**

The same kind of tectonic structure can contribute to very different present-day
landscapes. A young mountain belt and a very old mountain belt should not
necessarily look alike. Time, erosion, sedimentation, weathering, glaciation,
volcanism, and other later processes may substantially modify a structure before
the present-day landscape exists.

This layer records tectonic inheritance. It does not generate final visible
terrain or define any of those later processes.

## Causal position

The working causal model is:

```text
planet
→ lithospheric plates
→ plate motion
→ boundary-relative motion
→ tectonic interaction
→ tectonic structures / geological provinces
→ inherited geometry / material / thermal state
→ broad buoyancy and vertical-response tendencies
→ later surface processes
→ present-day terrain
```

This dependency model operates within the generated timeline described in
[Geological Prehistory](GEOLOGICAL_PREHISTORY.md). It does not commit to a fixed
timestep, event algorithm, or other temporal representation.

Tectonic episodes may eventually apply compositions of the reusable operations
described in [Geological Geometry Operators](GEOLOGICAL_GEOMETRY_OPERATORS.md).
For example, rifting can involve extension, faulting, changed loads, possible
intrusion, and secondary subsidence response, while collision can involve
compression, folding, faulting, thickening, and secondary uplift response.
These are causal compositions, not final algorithms or event categories.

## Boundary-relative motion

A boundary's behavior follows from the relative motion of the plates along that
boundary:

- **Convergence** is the broad condition in which plates move toward one another.
  Collision and subduction are possible convergent outcomes; convergence is not
  itself synonymous with either outcome.
- **Divergence** is separation across the boundary.
- **Transform motion** is relative tangential or shearing motion along the
  boundary.

Real boundaries need not fit one perfectly uniform label. Relative motion can
contain both normal and tangential components, producing oblique interactions.
Its character and strength may also vary along the length of one boundary.

The final representation of this variation and the rules that determine a
convergent outcome remain unresolved.

## Tectonic structures

Tectonic interactions can leave persistent structures. Examples currently
recognized by the design include:

- collision orogens and mountain belts;
- volcanic arcs;
- continental rifts;
- mid-ocean ridges;
- transform fault zones;
- sedimentary basins.

This list preserves known concepts, not a final or exhaustive taxonomy. A
structure may reflect more than one interaction or geological episode, and not
every structure should be assigned through a one-to-one lookup from a boundary
label.

## Geological provinces

A geological province is a region with a coherent tectonic origin and
accumulated geological history. It groups physical space by shared formation and
development rather than by present-day appearance or political ownership.

Provinces may preserve evidence of active boundaries, past boundaries, stable
interiors, or several overprinting episodes. Their history may later influence
rock character and broad elevation tendencies while remaining distinct from the
terrain ultimately visible at the surface.

Those tendencies are not fixed elevation bonuses attached to structure or
province labels. Tectonic history changes thickness, geometry, density, thermal
state, and loads; broad elevation responds through the causal model documented
in [Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md).

Cratons are examples of stable lithospheric and geological provinces. Shields
are the exposed regions of their ancient crystalline interiors. They belong to
the province and accumulated-history concept, not to the tectonic-structure
example list above.

Geological provinces may later contribute to continent formation. This note does
not define, identify, or generate continents.

## Minimal Rust-facing vocabulary

The following types illustrate the domain concepts implied so far. They are not
accepted storage layouts, geometry choices, algorithms, or a final taxonomy.

```rust
struct BoundaryRelativeMotion {
    normal_rate: SignedSpeed,
    tangential_rate: SignedSpeed,
}

enum ConvergentOutcome {
    Collision,
    Subduction { descending_plate: PlateId },
}

struct TectonicStructure {
    id: TectonicStructureId,
    geometry: StructureGeometry,
    origin: TectonicOrigin,
    history: GeologicalHistoryRef,
    tendencies: BroadPhysicalTendencies,
}

enum TectonicOrigin {
    Convergent(ConvergentOutcome),
    Divergent,
    Transform,
    MultiStage,
}

struct GeologicalProvince {
    id: GeologicalProvinceId,
    geometry: ProvinceGeometry,
    structures: Vec<TectonicStructureId>,
    history: GeologicalHistoryRef,
    tendencies: BroadPhysicalTendencies,
}
```

`SignedSpeed`, geometries, history references, physical tendencies, overlap,
hierarchy, and the relationship between structures and provinces are deliberately
undefined. The recognized examples above are not encoded as a final enum because
their taxonomy remains an open decision.

## Scope boundary

This layer establishes the distinction between relative motion, tectonic
interaction, persistent structure, geological province, and final landscape. It
does not specify:

- final terrain or elevation formulas;
- geological time simulation;
- erosion, sedimentation, weathering, glaciation, or volcanism algorithms;
- rock-generation systems;
- rivers, hydrology, climate, soils, ecosystems, or resources;
- continents, political territories, or human systems.
