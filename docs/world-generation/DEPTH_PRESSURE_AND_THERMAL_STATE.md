---
id: WG-009
type: world-generation-specification
status: accepted
scope: Geological position, contextual depth, overburden pressure, and multiscale thermal state
authority: Owns position, depth, lithostatic pressure, pore-fluid pressure separation, and canonical thermal-state principles
implementation: unresolved
concept_state: accepted
coverage: partial
last_reviewed: 2026-08-22
---

# Depth, Pressure, and Thermal State

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

The local physical ground or seafloor is queried from the semantic upper
boundary of the canonical ground-material domain, not from an independently
generated height field or merely the highest point containing solid matter. Its
elevation and its role in contextual depth queries are documented in
[Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md).

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

> **Temperature belongs to canonical present physical state when present
> geometry and retained provenance cannot reconstruct the thermal truth promised
> to future queries.**

> **Temperature is a canonical/query thermodynamic state variable represented
> through a spatial field. Geological bodies influence that field through their
> material properties; they do not each own an isolated temperature value.**

```text
geological geometry / material state
        ↓ supplies

conductivity field
heat-capacity field
radiogenic heat-production field
other future transport properties

        ↓ influence

canonical temperature field T(x,y,z,t)
```

Computational boundaries and ordinary material contacts must not create
artificial thermal discontinuities. Genuine modeled physics may later produce
specialized interface behavior, including thermal contact resistance, phase
fronts, fracture-controlled fluid transport, or an explicitly modeled
interface discontinuity. This allowance does not define those systems.

The field does not require per-cell or per-voxel storage. A regional field,
sparse anomaly representation, body-influenced parameters, or another queryable
form may eventually represent the same physical state. The exact representation
remains open.

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

Background and event-induced state are inputs to a combined solution or
approximation, not necessarily independent values added linearly forever:

```text
background thermal state
+ event-induced perturbations
+ current material / geometry properties
        ↓
combined thermal solution or approximation
        ↓
canonical present thermal state
```

Weak perturbations may later permit linear superposition as an optimization.
Strong overlap, temperature-dependent properties, or materially changed geology
may require regional recomputation or bounded iteration. The method remains
open.

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

Thermal state also contributes causally to density, lithospheric buoyancy, and
effective strength. Heating during rifting may temporarily support broad relief;
later cooling and densification may contribute to subsidence. These are inputs
to the broad vertical-response model, not fixed event-label bonuses or a thermal
elevation formula. See
[Broad Elevation and Isostatic Response](BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md).

## Geometry changes remap thermal content

> **Temperature is a canonical/query thermodynamic state variable, but
> conservative transport or remapping may need to operate on energy, enthalpy,
> or another physically appropriate quantity.**

```text
material moves
↓
conserved thermal content is remapped consistently
↓
modeled mechanical work and other energy exchanges are applied where relevant
↓
temperature is reconstructed from thermal content + material state
↓
thermal relaxation in the new configuration
```

Isostatic, flexural, and other broad vertical deformation follows this same
contract: affected 3D material and conserved thermal content remap together;
non-rigid deformation may then exchange mechanical and internal or thermal
energy through explicitly modeled work before temperature is reconstructed and
thermal relaxation continues. The deformation and work representations remain
outside this note.

Literal temperature values therefore need not be copied unchanged with displaced
material. Materials with different density or heat capacity can store different
thermal energy at the same temperature; phase changes may exchange energy
between sensible and latent or internal phase state; and transformations may
change the relationship between stored thermal energy and temperature. The
conserved quantity, representation, reconstruction, and future latent-heat
treatment remain unresolved.

> **Thermal remapping and refinement must conserve total energy except for
> explicitly modeled energy sources, sinks, or transport across the chosen
> control-volume boundary. Phase transformations and mechanical work may
> exchange energy between represented forms but do not create or destroy total
> energy.**

These are four distinct parts of coupled energy accounting:

```text
radiogenic decay
→ energy source

boundary heat flux / advection
→ energy crosses control-volume boundary

phase transition
→ energy changes internal form
→ total energy remains conserved

compression / expansion / friction
→ mechanical work exchanges energy with internal or thermal state
→ total coupled energy remains conserved
```

Source and sink terms add or remove energy within the selected control volume.
Radiogenic heat production is an example of a volumetric source. Any future
sink term must likewise represent an explicit modeled process rather than
unaccounted numerical loss.

Conductive surface or deep heat flux, advective or fluid heat transport, and
material transport move existing energy across a selected control-volume
boundary. Magma entering or leaving that volume normally belongs to this
transport accounting. These terms are not energy creation or destruction,
although a coarser model may deliberately approximate documented boundary
transport as an equivalent source or sink.

Melting, crystallization, and other future phase transformations may redistribute
energy between sensible thermal state and latent or internal phase energy. They
remain internally energy-conserving. This establishes the accounting principle,
not an enthalpy implementation, latent-heat equation, phase-transition
algorithm, control-volume discretization, numerical conservation scheme, or
continuously coupled thermo-mechanical solver.

Non-rigid deformation may also perform mechanical work on material or allow
material to perform work. Compression, expansion, inelastic deformation, and
fault friction may therefore change internal or thermal energy without acting as
unaccounted sources or sinks. A future approximation may neglect a work term
only when the promised canonical accuracy permits it. The work calculation,
constitutive behavior, and coupling fidelity remain unresolved.

## Feedback and numerical evaluation

The physical dependency graph may contain feedback:

```text
temperature
→ mineral / phase state
→ density
→ pressure
→ material response

temperature
→ mineral / phase state
→ conductivity
→ heat transport
→ temperature

temperature
→ melting / fluid generation
→ transport properties
→ thermal evolution
```

This note does not define those downstream transformations.

> **Real physical feedback loops may require staged or iterative numerical
> evaluation.**

```text
CAUSAL PHYSICS
may contain feedback loops

NUMERICAL EVALUATION
must use a controlled ordering / iteration strategy
```

An illustrative future interval or event evaluation could begin with previous
canonical geometry and material state, derive provisional properties and
pressure, update thermal state, evaluate material response, refresh changed
properties, repeat affected stages when significant, and commit after adequate
convergence. This is not an implementation API or accepted sequence.

> **Physical feedback loops may require iteration, but simulation fidelity
> should scale with how strongly the feedback affects canonical truth.**

```text
weak coupling
→ one-pass or inexpensive staged approximation

moderate coupling
→ bounded iteration

strong / exceptional coupling
→ more specialized future treatment
```

Every region does not require a tightly coupled nonlinear multiphysics solver.
Use the coarsest representation and numerical treatment that preserves required
canonical truth.

## Event- and scale-appropriate time

> **Thermal evolution should use event- and scale-appropriate progression rather
> than tiny uniform timesteps across hundreds of millions of years.**

Thermal systems may advance over meaningful intervals or use analytical or
approximate relaxation where appropriate. They need not solve the entire planet
for every small timestep. Exact numerical methods remain unresolved.

A transient anomaly may simplify as its present effect decays, but current
attention, rendering resolution, or active query scale cannot alone determine
whether canonical information is disposable:

```text
thermal event
↓
detailed transient anomaly
↓
cooling / diffusion
↓
weak residual anomaly
↓
either:
  collapse safely into background
or
  retain constrained residual information
```

> **A thermal anomaly may be simplified only when doing so preserves all
> canonical information required by the finest future query class the world
> promises to support.**

A residual that is negligible for a coarse distant view may remain meaningful
to a future local or historical query. If it is too small to justify explicit
transient representation but cannot safely be reconstructed after collapse, it
may survive as a constrained unresolved thermal component, compact residual
parameters, or retained thermal provenance sufficient for later refinement.
Information outside the promised canonical accuracy contract need not remain
explicit, but information required by that contract must not be silently
discarded. Accuracy classes, residual representation, provenance, and
promotion/demotion rules remain open.

## Adaptive thermal detail

A stable ancient region may use coarse thermal representation, while a young
intrusive or tectonically active region may require finer spatial or temporal
treatment.

> **Use the coarsest thermal representation that preserves the canonical
> physical truth required at that location and time.**

No universal thermal resolution applies to the planet. Coarse and fine thermal
representations must remain compatible across their boundaries.

> **Computational boundaries and ordinary material contacts must not create
> artificial thermal discontinuities; genuine modeled physics may produce
> specialized interface behavior.**

```text
coarse domain
      ↕
shared thermal boundary contract
      ↕
fine domain
```

The future contract may need compatible temperature, heat flux, transport-
relevant material properties, and parent thermal constraints. Remapping and
refinement must conserve total energy except for explicitly modeled sources,
sinks, or transport across the chosen control-volume boundary. Internal phase
transformations may change energy form but not total energy. Interpolation and
conservation methods remain open.

> **Different thermal resolutions may coexist, but they must describe one
> compatible canonical thermal state.**

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
