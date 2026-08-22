# Broad Elevation and Isostatic Response

- **Status:** Accepted conceptual model; mechanics and representation unresolved
- **Scope:** Lithospheric buoyancy, broad vertical response, and the solid-Earth surface
- **Last reviewed:** 2026-08-22

## Elevation follows 3D geology

> **Elevation is not generated independently. It is a property of the present
> 3D solid-Earth boundary produced by geological structure, buoyancy,
> deformation, loading, and surface modification.**

```text
canonical 3D geology
↓
upper boundary of the ground-material domain
↓
ground / seafloor surface
↓
sampled elevation field
↓
map raster / terrain mesh
```

> **The physical ground or seafloor is queried from the upper boundary of the
> canonical solid-Earth / ground-material domain.**

The ground-material domain may later include coherent rock, unconsolidated
sediment, regolith, and soil where those materials are accepted. Domain
semantics determine whether material counts as ground; the query must not merely
select the highest point containing any nonzero solid fraction.

Water, ice or glaciers, atmosphere, vegetation, artificial structures, and
suspended sediment may occupy separate overlying domains. Their final ownership
and surface relationships remain open.

> **Ground-surface queries depend on domain semantics, not merely on the highest
> spatial point containing solid matter.**

Canonical geometry is not required to be a single-valued height function. Caves,
overhangs, cliffs, voids, and multiple solid/void intersections along a vertical
line remain possible. A map layer may later select one elevation according to a
defined query policy, but that policy is unresolved. A heightmap, sampled
elevation field, or Bevy terrain mesh remains derived query or presentation
data, not canonical physical truth.

## Broad relief precedes detailed geomorphology

```text
lithosphere / tectonics / buoyancy
↓
first-order broad relief

then

weathering / erosion / transport / deposition
↓
progressively sculpted terrain
```

Broad solid-Earth geometry establishes the first-order setting for continents
and ocean basins, mountain belts, plateaus, rift basins, and broad regional
depressions. It does not create detailed valleys, drainage networks, cliffs,
alluvial surfaces, or local landforms. Those require later surface processes
that act on and modify the inherited physical boundary.

## Lithospheric buoyancy, not crust thickness alone

> **Broad elevation emerges from the buoyancy and loading of the relevant
> lithospheric column, not from crust thickness alone.**

```text
crust thickness
+ crust composition / density
+ lithospheric-mantle thickness
+ lithospheric-mantle density
+ thermal state
+ surface and subsurface loads
↓
lithospheric buoyancy state
↓
preferred vertical response
```

The relevant column includes both crust and explicitly modeled lithospheric
mantle. It does not stop at the Moho. Thick crust paired with cold, dense
lithospheric mantle may be less elevated than a crust-only rule implies;
warm or thinned lithospheric mantle may contribute positive buoyancy.

Density remains causal wherever practical:

```text
composition
+ phase / mineral state
+ temperature
+ pressure
↓
density
```

The buoyancy model consumes this derived physical state rather than assigning
unrelated buoyancy classes where causes are available. In particular,
`elevation = crust_thickness × constant` must not define canonical physics.

## Tectonics changes the causes

Tectonic interactions and geological operators first change geometry, material,
temperature, thickness, density, or load. Broad vertical response follows from
that changed state rather than from fixed elevation bonuses attached to event
labels.

```text
continental collision
→ shortening
→ crustal / lithospheric thickening
→ changed buoyancy
→ broad mountain-belt uplift tendency

rifting / extension
→ lithospheric thinning
→ subsidence tendency

rifting
→ heating / magmatism
→ thermal expansion / reduced density
→ temporary buoyancy support

later cooling
→ contraction / densification
→ long-term subsidence
```

Ocean-floor depth follows the same physical framework rather than an unrelated
bathymetry generator:

```text
young hot oceanic lithosphere
→ relatively buoyant
→ shallower seafloor

cooling with age
→ contraction / densification
→ deeper seafloor
```

Water loading also participates in the vertical balance.

## Isostasy responds to inherited state

> **Isostasy is a response to mass and buoyancy state, not an independent
> terrain-generation operator.**

Primary geological deformation includes fault displacement, folding,
shortening, extension, intrusion, and other direct tectonic geometry change.
The resulting geometry, material, density, temperature, and load state then
produces a secondary buoyancy and flexural response.

```text
primary geological operator
↓
new geometry / load / density state
↓
buoyancy and flexural response
```

Not every direct tectonic displacement routes through isostasy first.
`Uplift / subside` remains a candidate operator, but may often be a response or
composed outcome rather than a fundamental primitive. Possible causes include
thickening, thinning, thermal buoyancy, loading or unloading, fault
displacement, and deep mantle support. Its final status remains open.

> **Do not apply an arbitrary uplift response when the physical cause of that
> vertical displacement is already represented elsewhere.**

Avoid this double counting:

```text
collision
→ crustal thickening
→ arbitrary uplift operator
→ buoyancy response also uplifts
```

Prefer:

```text
collision
→ thickening / deformation
→ buoyancy changes
→ vertical response
```

unless an additional independent forcing is intentionally represented.

## Broad response transforms the 3D world

> **Isostatic, flexural, and other broad vertical responses must transform the
> affected canonical 3D geological state consistently; they must not merely
> move the visible surface.**

```text
buoyancy / loading / flexural response
↓
regional displacement or deformation field
↓
affected canonical 3D geology transforms
↓
new ground-material boundary
↓
derived elevation
```

The architecture must not establish `surface elevation += response` while
leaving subsurface geometry unchanged. A broad response eventually maps the
relevant geological bodies, contacts and bounding surfaces, faults and their
relationships, topology and continuity, material state, mass or volume
accounting, thermal content, canonical provenance relationships, and geometry
across adaptive spatial domains as appropriate.

> **Regional vertical response should be expressible as a spatial
> displacement/deformation mapping over the affected 3D domain.**

```text
D(x, y, z) → displaced / deformed position
```

This direction does not choose displacement grids, implicit transforms, finite-
element methods, elastic-plate equations, mesh deformation, or another numerical
representation.

Vertical response is also not synonymous with uniform translation. Future
processes may imply rigid or near-rigid translation, regional elastic-style
bending, distributed strain, compaction, thickening, thinning, fault-related
displacement, or another deformation mode. These transformations may affect
geometry and material volumes differently; their equations and final taxonomy
remain open.

> **Broad-response remapping must not accidentally create or destroy geological
> material, break body continuity, or corrupt topology unless the modeled
> physical process itself justifies such a change.**

Simple flexural bending must not accidentally stretch a body to an impossible
volume, detach contacts, create overlaps, erase a fault relationship, or sever
continuity. Compaction or distributed strain may legitimately change local
volume only through the modeled process. Exact mass, volume, topology, and
constitutive rules remain unresolved.

Thermal state follows the transformed material under the existing conservative
remapping contract:

```text
3D geological deformation
↓
material and conserved thermal content remap together
↓
temperature reconstructed in changed material state
↓
thermal relaxation continues
```

The thermodynamic details remain in
[Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md); this
note does not select them.

## Regional support and flexure

> **Column buoyancy establishes first-order vertical tendency; lithospheric
> strength determines how locally or regionally that response is supported.**

Every vertical column must not compensate independently. Loads may bend or be
supported by a broader surrounding region:

```text
load field
+ lithospheric strength
↓
regional flexural response
```

This regional support may later help explain broad features such as foreland
basins without placing them as unrelated terrain shapes.

Effective lithospheric strength should follow causes where practical:

```text
thermal state
+ lithosphere thickness
+ composition / rheology
+ deformation history
↓
effective lithospheric strength
```

An effective elastic thickness or another regional support parameter may later
provide a useful approximation. No exact mechanical quantity, equation, kernel,
or numeric range is selected. Qualitatively:

```text
hot / weak lithosphere
→ more localized flexural response

cold / strong lithosphere
→ load supported over broader distances
```

## Disequilibrium and relaxation

Preferred or equilibrium elevation is not necessarily actual elevation:

```text
current lithospheric state
↓
equilibrium / preferred vertical tendency

current actual geometry
↓
may differ from equilibrium

difference
↓
vertical disequilibrium
```

Active tectonic forcing, lithospheric strength, recent loading or unloading,
and finite adjustment time may keep the world out of equilibrium. The accepted
abstraction is:

```text
mass / buoyancy state
↓
preferred vertical response

+ regional lithospheric support
↓
flexurally distributed target response

current geometry vs target response
↓
vertical disequilibrium

time
↓
relaxation toward new state
```

The exact relaxation model and timescale remain open. During active orogenesis,
tectonic thickening may outpace erosion and relaxation. After forcing stops,
erosion and isostatic adjustment may continue. Actual geometry therefore need
not equal instantaneous equilibrium state.

Loads participate causally without defining their downstream process models:

```text
erosion → mass removed → rebound tendency
sediment deposition → added load → subsidence tendency
ice loading → depression
ice removal → rebound
volcanic construction → added load → regional flexural response
```

Together:

```text
tectonic forcing
+ loading / unloading
+ buoyancy tendency
+ flexural support
+ relaxation
↓
geometry evolution
```

## Reference state and evaluation horizon

> **Broad isostatic elevation should be evaluated from lithospheric buoyancy
> relative to a versioned Earth-like asthenospheric reference state or column,
> rather than a universal crust-only compensation depth.**

```text
surface
↓
crust
↓
lithospheric mantle
↓
reference asthenosphere
```

Generated columns may have different local lithosphere thicknesses. Old
cratonic roots, young oceanic lithosphere, rifts, and other regions integrate
their relevant density and thermal structure, then compare it with a common
Earth-like reference asthenospheric state.

Ordinary calculation may stop at a practical deep evaluation horizon below
which a common reference asthenospheric state is assumed. That horizon must be
deep enough to include explicitly modeled lithospheric density anomalies that
matter to broad elevation. It is a computational abstraction, not a physical or
geological boundary, and its exact depth remains open.

Three distinct reference concepts must not be conflated:

```text
SEA-LEVEL / ELEVATION DATUM
≠
BUOYANCY REFERENCE COLUMN / STATE
≠
DEEP COMPUTATIONAL EVALUATION HORIZON
```

The elevation datum defines the coordinate reference. The buoyancy reference
defines the physical comparison. The deep horizon defines where the ordinary
approximation stops. One ambiguous `reference_depth` must not serve all three.

## Optional deeper support

> **Ordinary isostatic and flexural calculations should not require full mantle
> convection. Long-wavelength deep-mantle support or depression may later be
> represented by a separate coarse dynamic-support field.**

```text
explicit lithosphere
→ ordinary buoyancy / flexure

deeper mantle dynamics
→ optional coarse long-wavelength support
```

Keeping these layers separate avoids double-counting deep density effects. This
note does not implement or otherwise define dynamic topography.

## Canonical and adaptive state

The actual broad solid-Earth geometry is canonical. The semantic upper boundary
of its ground-material domain supplies physical ground or seafloor queries.
Elevation samples, heightmaps, rasters, and terrain meshes are derived.
Preferred response and vertical disequilibrium may also need canonical active
state when they are necessary to determine later geometry; the
persisted-versus-derived split remains open.

Regional flexural response can cross geological and computational boundaries.
Adaptive refinement must preserve established broad geometry, total relevant
loads, shared displacement or deformation constraints, canonical feature
identity, topology, thermal accounting, and compatibility with coarser regional
support. A regional field must cross computational boundaries without geometric
seams or inconsistent material displacement. Refining a local domain must not
silently change regional mass balance. Exact boundary interpolation and adaptive
representation remain open.

## Preferred causal chain

```text
material + thermal state
↓
density structure

density structure + thickness
↓
lithospheric buoyancy relative to reference asthenosphere

+ loads
↓
equilibrium vertical tendency

+ lithospheric strength
↓
regional flexural target

+ tectonic forcing
+ current disequilibrium
+ relaxation
↓
actual broad solid-Earth geometry

↓
upper boundary of canonical ground-material domain
↓
proto-surface elevation
```

Later surface processes may modify that physical boundary.

## Scope boundary

This note does not define full mantle convection, finite-element plate
mechanics, a viscoelastic lithosphere or displacement solver, final flexure
equations, constitutive laws, mass-conservation algorithms, dynamic topography,
mesh deformation, terrain generation, cave generation or surface-query policy,
erosion, rivers or drainage, weathering, sediment transport, glaciation, water
simulation, volcanism, climate, soils, resources, ecosystems, continents as a
generated system, artificial construction, political territories, or human
systems.
