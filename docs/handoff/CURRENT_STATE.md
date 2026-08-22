# Current State and Handoff

- **Snapshot date:** 2026-08-22
- **Project phase:** Natural-world foundation (`0.0.1`–`0.1.0`)
- **Immediate milestone:** Prototype v0.1
- **Implementation status:** No source code or completed implementation is
  documented in this workspace

## Settled direction

- The game simulates an autonomous sovereign nation; the player influences rather
  than directly controls all actors.
- Major domestic actors can initiate development, accumulate power, and pursue
  strategies independently; the ruler responds through sovereign authority,
  policy, negotiation, and opposition.
- Systems should preserve meaningful real-world causes and constraints.
- The nation itself is the progression display; prefer meaningful real
  measurements over invented levels and ratings.
- The map is the primary player experience.
- Bevy handles runtime and rendering; a pure-Rust core owns simulation/world logic.
- World generation is seed-based and versioned for reproducibility.
- Geography is generated before political territories.
- Physical layers are generated causally rather than independently; political
  territories reference physical space instead of owning geological features or
  sampling cells.
- Tectonic plates are the earliest useful physical-world abstraction. They
  represent moving lithosphere and provide broad physical properties, crustal
  character, and boundary interactions without attempting mantle convection,
  planetary accretion, or full geophysics.
- Boundary-relative motion produces tectonic interactions, which create
  persistent tectonic structures and geological provinces rather than final
  terrain. Tectonics creates structures; time and later surface processes shape
  the landscape eventually seen.
- Physical-world generation is a geological prehistory simulation. Events act on
  inherited state across coarse geological time, and the accumulated result
  becomes the starting physical world when the civilization era begins.
- Generated worlds share a fixed Earth-like physical framework. Planetary
  context is fixed where variation is not part of the game; geology, physical
  state, and history are generated. Causes and history are stored while
  consequences and classifications are derived wherever practical.
- Ordinary geological material uses compact bulk composition as causal state,
  with trace material kept separate. Mineral assemblages and named rocks are
  derived from composition, physical conditions, formation process, and history
  through a future tractable approximation.
- Geological material is not divided into exclusive rock, magma, sediment, and
  fluid types. Coexisting solid, melt, and fluid fractions describe phase state;
  coherent or unconsolidated structure describes consolidation.
- Geological truth is sparse and three-dimensional beneath the map-first
  interface. Surfaces and bounded bodies preserve subsurface structure and
  inherited relationships without requiring a uniform voxel world or final
  geometry representation.
- Geological events describe history while a small, composable language of
  geometric operators modifies inherited 3D surfaces, bodies, and contacts.
  Chronology determines cross-cutting and inheritance relationships; the final
  primitives, mathematics, and geometry engine remain unresolved.
- A compact history of important geological events and periods persists after
  generation. Geological age records when formation or change occurred rather
  than serving as decorative metadata.
- History generates the world; present geological state then becomes
  authoritative for normal queries. Compact history remains as causal
  provenance rather than requiring prehistory replay.
- Canonical truth includes both established facts and constraints over
  unresolved detail. Authority-driven deterministic refinement narrows those
  constraints, preserves parent truth, and promotes materially relevant results
  to stable canonical state; observation does not physically create geology.
- Renderer meshes, sampled map layers, LODs, client caches, and other query
  products are derived and disposable rather than canonical world truth.
- Resolution belongs to representations, not physical reality. Geological
  features retain continuous identity across computational domains, while cells
  are system-specific samples that query rather than own canonical geology.
- Different regions may hold different compatible canonical refinement levels.
  Required detail follows geological complexity, simulation relevance, and
  observation or gameplay needs—not attention alone.
- Canonical geometry uses absolute physical position relative to a planetary
  datum; depth below local ground or another reference is derived context.
- Lithostatic pressure normally derives from gravity and the actual material
  column above a query point. It remains distinct from pore-fluid pressure.
- Temperature is likely adaptive canonical present state because thermal history
  may not be reconstructible from present geometry. Geothermal gradient is a
  derived query, and stable background fields are distinct from transient
  thermal anomalies and future specialized thermo-fluid models.
- Temperature is canonical/query thermodynamic state represented through a
  spatial field. Bodies supply thermal properties rather than owning isolated
  temperatures. Ordinary contacts and computational boundaries must not create
  artificial discontinuities, while modeled interface physics may later justify
  specialized behavior.
- Geometry-changing events conservatively remap physically appropriate thermal
  content before reconstructing temperature and relaxing the new configuration;
  literal temperature need not be copied unchanged. Remapping and refinement
  conserve total energy except for modeled sources, sinks, or transport across
  the chosen control-volume boundary. Phase transformations may redistribute
  sensible and latent or internal energy but do not create or destroy it.
- Thermal anomalies may collapse only if the finest promised future canonical
  query remains supportable. Otherwise, small signals survive as constrained
  residual state, compact parameters, or sufficient provenance.
- Physical dependencies may contain feedback loops. Numerical evaluation may use
  one-pass staging, bounded iteration, or future specialized treatment according
  to how strongly coupling affects canonical truth.
- Compact provenance may retain important pressure-temperature peaks and
  episodes without preserving every timestep or obsolete numerical field.
- Elevation is derived from a semantic query over the upper boundary of the
  canonical solid-Earth or ground-material domain, not generated as an
  independent canonical heightmap or selected merely as the highest point with
  solid matter. Sampled elevation, rasters, and terrain meshes are query or
  presentation data. Canonical geometry may contain caves, overhangs, voids,
  and multiple vertical intersections.
- Broad relief responds to density and thermal structure across both crust and
  lithospheric mantle, relative to a versioned asthenospheric reference. Loads
  and causally derived lithospheric strength produce a regional flexural target;
  tectonic forcing, disequilibrium, and relaxation determine actual geometry.
- Isostasy is a secondary response to changed geometry, density, temperature,
  and loads—not a terrain operator. `Uplift / subside` remains a candidate but
  may often be a response or composition; do not double-count represented
  vertical causes.
- Sea-level datum, buoyancy reference state, and deep computational evaluation
  horizon are separate concepts. Full mantle convection is not required;
  optional deep-mantle support remains a separate future coarse field.
- Broad vertical response transforms affected canonical 3D bodies, contacts,
  faults, topology, material state, mass or volume accounting, thermal content,
  and provenance consistently before a new ground-material boundary and
  elevation are queried. It is not a surface-only offset.
- Regional deformation may cross domains and refinement levels. Shared mapping
  constraints must prevent seams or inconsistent material displacement while
  preserving feature identity, topology, mass/load balance, and thermal
  accounting.
- Singleplayer and eventual multiplayer share one authority model.
- The eventual multiplayer server generates and owns canonical world truth;
  clients receive relevant subsets and do not independently generate
  authoritative geology. Authoritative world generation is separated from
  client play cost.

## Current target

Implement the scoped map prototype in
`../architecture/PROTOTYPE_V0.1.md`. Its 500 m cells are provisional prototype
sampling units, not a final scale or the ontology of world truth.

The accepted physical-world conceptual chain is currently documented in
`../world-generation/EARTH_LIKE_PHYSICAL_FRAMEWORK.md`,
`../world-generation/GEOLOGICAL_PREHISTORY.md`,
`../world-generation/GEOLOGICAL_MATERIAL_COMPOSITION.md`,
`../world-generation/GEOLOGICAL_MATERIAL_STATE.md`,
`../world-generation/SPARSE_3D_GEOLOGICAL_WORLD.md`,
`../world-generation/GEOLOGICAL_GEOMETRY_OPERATORS.md`,
`../world-generation/CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md`,
`../world-generation/ADAPTIVE_SPATIAL_PARTITIONING.md`,
`../world-generation/DEPTH_PRESSURE_AND_THERMAL_STATE.md`,
`../world-generation/BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md`,
`../world-generation/TECTONIC_PLATES.md`, and
`../world-generation/TECTONIC_STRUCTURES_AND_PROVINCES.md`. These define domain
intent and illustrative Rust-facing vocabulary only; temporal representation,
algorithms, taxonomies, and storage remain open.

## Important boundaries

- Do not start human civilization or economic simulation in the current phase.
- Do not couple simulation data to Bevy or egui types.
- Do not treat open questions as accepted decisions.
- Do not let optional Web3 ideas shape foundational simulation design.
- Do not extend the tectonic-plate note into downstream geology, landforms,
  hydrology, soils, resources, political areas, or human systems.
- Do not treat tectonic structures or geological provinces as final terrain, and
  do not extend them into continents or later surface systems yet.
- Do not extend geological prehistory into a final event taxonomy or any
  geological, surface, resource, continent, political, or human algorithm.
- Do not turn the Earth-like framework into a generic planet, atmosphere,
  climate, hydrology, or ocean simulator.
- Do not extend geological material composition into final mineral/rock
  taxonomies, full thermodynamics, ore generation, resources, or later surface
  and human systems.
- Do not extend geological material state into a full rock cycle, final process
  enum, phase-equilibrium solver, poromechanics, or surface/resource systems.
- Do not turn sparse 3D geological truth into a commitment to uniform voxels,
  final meshes, topology, coordinates, precision, storage, or refinement rules.
- Do not design renderer internals, network protocols, databases, or downstream
  subsurface gameplay from the authority and 3D-world decisions.
- Do not turn the geological-operator vocabulary into a final enum, geometry
  engine, deformation algorithm, event taxonomy, or volumetric-physics model.
- Do not equate canonical geology with renderer data, eager maximum-resolution
  storage, or replay of geological prehistory during normal queries.
- Do not let refinement rewrite established truth, reroll on observation, or
  become an implementation of storage, serialization, procedural noise,
  meshing, networking, or downstream subsurface gameplay.
- Do not treat any cell size as geological ontology, align geological identity
  to chunk boundaries, or let spatial partition boundaries create physical
  discontinuities that geology did not create.
- Do not turn adaptive spatial partitioning into a chosen tree/index structure,
  database, serialization format, Bevy chunk system, refinement algorithm, or
  resolution-tuning exercise.
- Do not equate absolute position with depth, derive pressure from depth alone,
  collapse pore-fluid and lithostatic pressure, or make a fixed geothermal
  gradient canonical world truth.
- Do not extend thermal state into final heat solvers, uniform geological
  timesteps, fluid-flow models, climate implementation, mineral transformations,
  melting, resource formation, or downstream human systems.
- Do not store temperature independently per geological body, let computational
  boundaries or ordinary contacts create artificial thermal discontinuities,
  copy temperature as though it were necessarily the conserved remapping
  quantity, discard residual anomaly information promised to future canonical
  queries, assume all anomalies combine linearly, or freeze an
  evaluation/convergence workflow as implementation.
- Do not generate canonical elevation as noise or a disconnected heightmap,
  stop ordinary buoyancy at the Moho, make crust thickness a direct elevation
  formula, compensate every column independently, or conflate the elevation
  datum, buoyancy reference, and deep evaluation horizon.
- Do not treat isostasy as an independent terrain generator, force actual
  geometry into instantaneous equilibrium, double-count uplift already caused
  by thickening or another represented process, or turn broad vertical response
  into mantle convection, final flexure mechanics, terrain meshing, or later
  surface-process algorithms.
- Do not apply broad response only to a rendered or queried surface while
  leaving canonical subsurface geometry unchanged, assume every response is a
  uniform vertical translation, or choose a deformation-field representation,
  constitutive law, mass-conservation algorithm, or solver prematurely.
- Do not define canonical ground as the highest point containing any solid
  fraction, force it into a single-valued height function, or collapse ground,
  seafloor, ice, water, vegetation, structures, and rendered terrain into one
  unresolved surface concept.

## Recommended next actions

1. Create the Rust workspace with separate simulation/world and Bevy application
   crates or modules.
2. Define versioned seed inputs and prototype coordinate/domain/sampling IDs.
3. Implement and test prototype coordinate-to-domain-to-sample mapping.
4. Build the seeded landmass render and map camera controls.
5. Measure the provisional sampling and spatial-domain choices without treating
   them as geological ontology.

## Before continuing work

Read the prototype specification and the relevant open decisions. If a task would
resolve an open decision, record both the rationale and consequences instead of
only changing code.
