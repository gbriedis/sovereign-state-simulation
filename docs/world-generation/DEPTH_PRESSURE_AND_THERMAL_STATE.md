# Depth, Pressure, and Thermal State

- **Status:** Accepted conceptual model; representation and numerics unresolved
- **Scope:** Geological position, overburden pressure, and multiscale heat state
- **Last reviewed:** 2026-08-22

## Position before depth

> **Canonical geometry uses absolute physical position/elevation relative to a
> planetary datum. Depth is a derived contextual measurement.**

An absolute coordinate such as `z = -2000 m` does not inherently mean
`depth = 2000 m`, because the local surface varies. Useful measurements include:

- absolute elevation or radial position;
- depth below the local ground surface;
- depth below sea level or another chosen datum.

```text
absolute elevation: +800 m
depth below local surface: 1200 m
```

These describe different relationships. The final planetary coordinate system
and datum definition remain unresolved.

## Lithostatic pressure follows overburden

> **Depth is geometry. Lithostatic pressure is a consequence of gravity and the
> actual material column above a location.**

```text
3D geometry
+ material density
+ gravity
        ↓
overburden load
        ↓
lithostatic / confining pressure
```

A fixed depth-only equation must not define world truth. Material columns with
different density may produce different lithostatic pressure at the same
contextual depth.

```text
burial / deposition
→ additional overburden
→ pressure rises

erosion / exhumation
→ overburden removed
→ pressure falls
```

Pressure history therefore emerges from changing geometry, material, and
gravity through geological history.

Lithostatic pressure is usually derived from geometry, gravity, density or
material state, and the material column above a query point. It need not be a
permanently sampled field everywhere. Caching or persistence may later be
justified by performance or active physics; that boundary remains open.

## Pore-fluid pressure is separate

```text
lithostatic / confining pressure
≠
pore-fluid pressure
```

Fluids in pores or fractures may carry their own pressure state. That distinction
may later matter to effective mechanical stress, fault behavior, compaction,
hydrothermal systems, groundwater, permeability, or flow. This note does not
define poromechanics or fluid-pressure systems.

## Temperature is a field with history

> **Temperature with depth emerges from a thermal state/field; it is not defined
> by one universal geothermal gradient.**

The following may be a temporary prototype approximation, but it must not become
canonical ontology:

```text
temperature = surface_temperature + depth × fixed_gradient
```

The causal model leaves room for:

```text
surface thermal boundary
+ deep / basal heat input
+ radiogenic heat production
+ material thermal conductivity
+ geological thermal history
+ local thermal anomalies
+ fluid heat transport where relevant
        ↓
present thermal state
```

Not every term needs immediate implementation.

## Thermal properties follow material causes

Thermal behavior should derive from geological material where practical:

```text
bulk composition
+ mineral / phase state
+ porosity / fluid state where relevant
        ↓
thermal conductivity
```

Conductivity should not be an unrelated random property when a tractable
material-based estimate is possible. Its exact model remains unresolved.

> **Radiogenic heat production should derive from relevant material chemistry
> where practical rather than being an unrelated random regional value.**

```text
U abundance
+ Th abundance
+ K-bearing composition
        ↓
radiogenic heat production
```

This is a causal direction, not isotope-level physics or a final heat-production
equation.

## Thermal memory

> **Present thermal state retains geological memory.**

Regions with similar present geometry may differ thermally because of recent
intrusion, rifting, burial, rapid exhumation, young lithosphere, or long-lived
crustal heat production.

```text
magma intrusion
→ hot material introduced
→ surrounding geology heats
→ thermal anomaly
→ gradual conductive cooling
→ anomaly weakens
→ eventual equilibration
```

An old intrusion may be thermally negligible while a recent one remains hot.
Present temperature therefore may not be uniquely reconstructible from present
geometry alone.

## Canonical thermal state and derived queries

> **Temperature is likely part of canonical present physical state because it
> may not be uniquely reconstructible from present geometry alone.**

This does not require per-cell or per-voxel storage. The canonical representation
might eventually use a regional field, sparse anomaly fields, body-influenced
field parameters, or another queryable continuous form. Heat crosses
geological-body boundaries, so a body does not necessarily own one isolated
temperature value.

> **Geothermal gradient is a derived query product of the thermal field, not the
> fundamental state variable.**

```text
canonical temperature field
        ↓
temperature change with depth
        ↓
local geothermal gradient
```

Likewise, temperature at a chosen depth is a query into canonical thermal state.

## Multiscale thermal evolution

### Background thermal model

Stable geology may use a steady or quasi-steady conductive approximation based
on surface boundary temperature, deep or basal heat input, radiogenic heat, and
material conductivity.

```text
background heat sources
+ conductive material column
        ↓
background thermal field
```

### Transient thermal anomalies

Major thermal events may create time-dependent state. Examples include magmatic
intrusion, major rifting, rapid burial or exhumation, young-lithosphere
formation, and other large thermal disturbances. A tractable model may use
simplified conductive diffusion or another approximation; the method is open.

### Specialized thermo-fluid systems

Strong hydrothermal or advective heat transport may eventually require a
specialized model.

```text
ordinary crust
→ conductive background

major thermal event
→ transient thermal evolution

strong fluid heat transport
→ later specialized model
```

This note does not design thermo-fluid simulation.

## Event- and scale-appropriate time

> **Thermal evolution should use event- and scale-appropriate progression rather
> than tiny uniform timesteps across hundreds of millions of years.**

Thermal systems may advance over meaningful intervals or use analytical or
approximate relaxation where appropriate. They need not solve the entire planet
for every small timestep. Exact numerical methods remain unresolved.

Transient detail may simplify as its present effect decays:

```text
thermal event
↓
detailed transient anomaly
↓
cooling / diffusion
↓
weak residual anomaly
↓
effect becomes negligible
↓
collapse into simpler background representation
```

This follows the canonical-state rule: retain present state that still matters
and compact provenance, while temporary numerical detail may be discarded once
it no longer affects present truth. Thresholds and collapse rules remain open.

## Adaptive thermal detail

A stable ancient region may use coarse thermal representation, while a young
intrusive or tectonically active region may require finer spatial or temporal
treatment.

> **Use the coarsest thermal representation that preserves the canonical
> physical truth required at that location and time.**

No universal thermal resolution applies to the planet. Coarse and fine thermal
representations must remain compatible across their boundaries.

## Surface boundary condition

Climate may later supply the upper thermal boundary:

```text
surface thermal history
→ shallow thermal influence

deep tectonic / magmatic / internal heat
→ deeper thermal influence
```

Short-lived weather should not automatically propagate into deep geology. This
note does not design climate.

## Pressure-temperature-time history

Future material transformations may depend on the path, not only present
pressure and temperature:

```text
burial
→ pressure rises

heating
→ temperature rises

peak burial / heating
→ peak P–T conditions

uplift / erosion
→ decompression

cooling / exhumation
→ lower present P–T
```

Compact provenance may eventually retain peak pressure, peak temperature,
approximate peak timing, and important burial, heating, cooling, or exhumation
episodes without recording every timestep. The final history schema remains
open.

## Preferred causal chain

```text
ABSOLUTE POSITION / DATUM
        ↓
present 3D geometry

geometry
+ material density
+ gravity
        ↓
lithostatic pressure

thermal boundary conditions
+ heat sources
+ material conductivity
+ thermal history
        ↓
canonical present thermal state
        ↓
temperature at position

pressure
+ temperature
+ composition
+ volatile state
        ↓
future material response
```

This note does not define that future material response.

## Scope boundary

This note does not define mineral stability, metamorphic facies, final rock
classification, partial melting, magma chemistry, deposits or fuels, industrial
valuation, nuclear physics, hydrology, groundwater, hydrothermal CFD, climate
implementation, terrain emergence, ecosystems, or human systems.
