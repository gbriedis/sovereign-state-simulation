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
uppermost solid boundary
↓
ground / seafloor surface
↓
sampled elevation field
↓
map raster / terrain mesh
```

The physical surface is the upper boundary of canonical solid geological
material against atmosphere, water, ice, or another overlying non-solid domain.
At a location, surface elevation is derived from where the canonical solid Earth
ends relative to the elevation datum. A heightmap, sampled elevation field, or
Bevy terrain mesh is derived query or presentation data, not canonical physical
truth. The exact surface-query representation remains open.

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

The actual broad solid-Earth geometry is canonical. Its uppermost solid boundary
defines the physical ground or seafloor surface. Elevation samples, heightmaps,
rasters, and terrain meshes are derived. Preferred response and vertical
disequilibrium may also need canonical active state when they are necessary to
determine later geometry; the persisted-versus-derived split remains open.

Regional flexural response can cross geological and computational boundaries.
Adaptive refinement must preserve established broad geometry, total relevant
loads, shared response constraints, and compatibility with coarser regional
support. Refining a local surface must not silently change its regional mass
balance or create an elevation seam. Exact adaptive representation remains open.

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
uppermost solid boundary
↓
proto-surface elevation
```

Later surface processes may modify that physical boundary.

## Scope boundary

This note does not define full mantle convection, finite-element plate
mechanics, a viscoelastic lithosphere solver, final flexure equations, dynamic
topography, terrain meshing, erosion, rivers or drainage, weathering, sediment
transport, glaciation, volcanism, climate, soils, resources, ecosystems,
continents as a generated system, political territories, or human systems.
