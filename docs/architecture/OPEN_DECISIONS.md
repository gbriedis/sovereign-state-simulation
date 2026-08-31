---
id: ARCH-OPEN
type: open-decision-register
status: accepted
scope: Unresolved architecture and world-generation implementation choices
authority: Owns the inventory of unresolved technical choices; listed options are not accepted design
last_reviewed: 2026-08-30
---

# Open Architecture Decisions

Items in this file are not accepted architecture. Each decision packet has a
stable `ARCH-OPEN-*` identifier. When a packet is resolved, create an accepted
record in [Decision Records](../decisions/README.md), update the affected
authoritative specification, and remove the resolved questions from this file.

## Spatial model

### ARCH-OPEN-001 — Spatial foundations

- Numeric encoding, type, precision, serialization, versioning, and stable
  identifier strategy for positions in the accepted planet-fixed physical
  reference frame
- Independent and derived reference-ellipsoid parameter representation; exact
  parameters and supported ranges; common versus bounded per-world parameter
  policy; and numeric types, precision, serialization, and version identifiers
- How the agreed prime-meridian direction is established, identified, and
  versioned for each generated planet
- Exact forward and inverse conversion algorithms; stopping and acceptance
  tolerances; iteration limits; accuracy and error bounds; longitude
  normalization; singular, ambiguous, and unsupported domains; and public error
  behavior for canonical physical position and derived geodetic queries against
  the accepted ellipsoid
- Derived flattened projection or projections and round-trip mapping to
  authoritative planetary position
- Globe, flattened map, or combined presentation at each player scale
- Physical and navigational behavior at both poles
- East-west continuity, projection seams, and transitions between views or
  levels of detail
- Representation and simulation cadence from continental to city scale
- Spatial-domain hierarchy, dimensions, indexing approach, and relationship to
  level of detail
- System-specific sampling grids, cells, scales, and relationship to spatial
  domains
- Surface and subsurface position, refinement, and query relationships
- Measurements, fixtures, acceptance bounds, and prototype evidence required to
  resolve any of these choices

Candidate evidence, not accepted architecture: `PROTO-001` records an isolated,
uncommitted implementation observed on 2026-08-31. It uses `f64`; independent
semi-major-axis and flattening inputs; an EPSG method 9602 forward relationship;
a Bowring-initialized safeguarded Newton inverse with bisection fallback, an
eight-`f64`-epsilon angular stopping threshold, and a 64-iteration limit; WGS 84
test parameters; explicit supported-domain and error behavior; and test
tolerances of `1e-12` radians, `1e-6` meters, and `0.002` meters for their named
fixtures. These choices and values remain candidates until the retrospective
readiness packet compares alternatives and a governed architecture decision
explicitly retains, replaces, or removes them.

### ARCH-OPEN-002 — Sparse 3D geological representation

- Exact representation of geological surfaces, bounded bodies, and volumes
- Topology and contact relationships between bodies, surfaces, and faults
- Fault displacement and the cutting, overlap, nesting, truncation, burial,
  intrusion, and erosion of inherited geometry
- Three-dimensional spatial indexing and cross-section or volume-query models
- Numeric encoding, precision, and derived depth-query representation for
  subsurface truth in the accepted planet-fixed physical reference frame
- Relationship between system-specific surface sampling grids and subsurface
  structure

### ARCH-OPEN-003 — Adaptive spatial partitioning

- Exact refinement-level hierarchy
- Powers-of-two or another nesting scheme for refinement levels
- Two-dimensional quadtree, three-dimensional octree, BVH, R-tree, or another
  spatial-indexing approach
- Relationship between surface and subsurface spatial hierarchies
- Exact chunk and refinement-domain dimensions
- Independence or coupling of chunk size and refinement resolution
- Shared-feature boundary-contract representation
- Continuity constraints across coarse and fine neighbors
- Treatment of shared faults, contacts, and surfaces across refinement boundaries
- Context or halo size and generation rules
- Spatial indexing of very large geological entities
- Ownership of local or partial entity representations
- Loading and unloading of partial geological representations
- Persistence granularity for spatial representations
- Reconciliation of coarse and fine queries
- Topology and relationship indexing across spatial partitions
- Promotion rules when finer detail becomes canonical
- Prevention of refinement thrashing
- Performance trade-offs of adaptive resolution

### ARCH-OPEN-004 — Canonical geological state and refinement

- Exact canonical geological-state schema
- Which canonical state is generated eagerly, lazily, or through a hybrid
- Geometry and topology that must be persisted versus regenerated
- Persisted versus derived physical properties
- Treatment of active present geological-process state
- Representation of canonical uncertainty and constraints
- Refinement hierarchy, levels, spatial partitions, and ownership
- Propagation of constraints from parent to child refinement
- Validation of refined state against established parent truth
- Deterministic seed derivation by region and target refinement level
- Point at which refined detail becomes permanently persisted canonical state
- Storage and performance trade-offs
- Cache invalidation for non-canonical derived and materialized data
- Coexistence and querying of coarse and fine canonical representations

### ARCH-OPEN-005 — Geological geometry operators

- Final primitive operator set
- Which candidate operators are true primitives and which are compositions
- Mathematical representation of deformation
- Parameterization of extension, compression, uplift, and subsidence
- Fault-surface representation and associated displacement fields
- Fold and warp representation
- Generation of erosion and truncation surfaces
- Representation of deposition and accommodation space
- Generation of intrusion geometry
- Geological-body split and merge behavior
- Storage of chronology, inheritance, and cross-cutting relationships
- Deterministic replay of operator sequences
- Local refinement of previously applied operations
- Interaction between overlapping or concurrent geological events
- Performance implications of event-driven 3D geometry changes

## Natural-world generation

### ARCH-OPEN-006 — Surface systems

- Terrain-generation algorithms
- Exact river and drainage model

### ARCH-OPEN-007 — Position, pressure, and thermal state

- Numeric encoding, precision, and serialization of positions in the accepted
  planet-fixed physical reference frame
- Exact reference surfaces and policies for elevation, geodetic reference
  height, geoid-related height, and depth queries
- Transformation and query behavior among canonical physical position,
  geodetic latitude/longitude/reference height, local positions, ground, sea
  level, and other explicit references
- Representation and derivation of a future geoid, including its relationship
  to the accepted reference ellipsoid, sea level, elevation, and gravity
- Detailed gravity representation, including variation with position or depth
  and its relationship to mass distribution, the reference ellipsoid, a future
  geoid, and pressure
- Lithostatic-pressure approximation and query strategy
- Whether and where lithostatic pressure is cached or persisted
- Pore-fluid pressure representation distinct from lithostatic pressure
- Canonical thermal-field representation
- Regional and basal heat-flow representation
- Thermal-conductivity model derived from material state
- Radiogenic-heat approximation from material chemistry
- Thermal-anomaly representation
- Transient heat-solver approximation
- Event-driven and scale-appropriate thermal stepping
- Thermal relaxation and anomaly-collapse criteria
- Canonical thermal accuracy classes and the finest promised future query scale
- Residual thermal-state representation and compact parameters
- Thermal provenance required for later reconstruction or refinement
- Promotion and demotion rules between explicit anomalies and constrained
  residual thermal state
- Adaptive spatial and temporal thermal resolution
- Compatibility across coarse and fine thermal boundaries
- Compact history representation for pressure-temperature-time paths
- Thermal quantities that must persist versus remain derived or cached
- Future boundary coupling to climate and fluid heat transport
- Convergence criteria for coupled thermal and material updates
- Maximum-iteration policy
- Behavior when convergence is poor
- Error and tolerance scaling with refinement level
- Treatment of temperature-dependent conductivity and other nonlinear properties
- Total-energy accounting across adaptive thermal boundaries,
  geometry-changing remapping, and chosen control-volume boundaries
- Conserved thermal quantity during geometric remapping
- Energy or enthalpy representation
- Conservation and internal energy partition during material transformation
- Reconstruction of temperature after thermal remapping
- Treatment of latent heat in future phase changes
- Strategy for combining background state and overlapping thermal anomalies
- Thermal-state mapping during geometric deformation
- Mechanical-work exchange with internal or thermal state during compression,
  expansion, compaction, inelastic deformation, and fault friction
- Criteria for neglecting deformation-work heating or cooling at a promised
  canonical accuracy level
- Local versus broader regional recomputation after major events
- Numerical stability across long geological intervals

### ARCH-OPEN-008 — Broad elevation and isostatic response

- Exact buoyancy reference column or asthenospheric state
- Versioned Earth-like calibration of the reference state
- Practical deep evaluation horizon
- Density-integration method through locally varying lithosphere
- Treatment of water loading
- Treatment of atmosphere and ice loading where relevant
- Local versus regional isostatic approximation
- Effective lithospheric-strength representation
- Flexural-response approximation
- Spatial support kernel or operator
- Adaptive resolution of broad vertical response
- Relaxation timescale and model
- Persistence of vertical disequilibrium
- Interaction between active tectonic forcing and relaxation
- Numerical treatment of repeated loading and unloading
- Treatment of optional deep-mantle dynamic support
- Prevention of uplift double-counting
- Final status of uplift and subsidence in the primitive operator vocabulary
- How broad solid-Earth geometry constrains later surface-process refinement
- Representation of regional displacement and deformation fields
- Mass and volume preservation during flexure
- Topology preservation during broad deformation
- Mapping of fault and contact geometry
- Treatment of compaction versus volume-preserving deformation
- Remapping of material properties and thermal content
- Mechanical-work and total-energy accounting during non-rigid broad response
- Coarse/fine deformation-boundary compatibility
- Deformation of partially resolved regions
- Interaction between broad vertical response and later local refinement
- Exact definition of the canonical ground-material domain
- Surface-query behavior for caves, overhangs, water, ice, regolith, and future
  soil
- Distinction between ground, seafloor, ice surface, water surface, and rendered
  terrain

### ARCH-OPEN-009 — Earth-like physical framework

- Exact standard Earth reference values, precision, and units used by the
  versioned ruleset
- Exact equatorial and polar radii or equivalent scale and flattening parameters
  for the accepted Earth-like oblate reference ellipsoid, including supported
  Earth-like ranges
- Minimum mantle reference conditions required by the lithosphere abstraction
- Whether a surface-pressure datum is required before later atmospheric work
- Minimum water and volatile reference assumptions required by current geology
- Equations and approximations used to derive pressure, density, buoyancy,
  melting tendency, strength, rheology, and effective lithosphere thickness
- Which derived values are calculated on demand, cached, summarized, or persisted
- Criteria for deriving continental-like and oceanic-like crust classifications

### ARCH-OPEN-010 — Tectonic plate layer

- Plate-count and plate-size distributions
- Planar, spherical, or projected representation of plate geometry
- Representation of plate shapes, shared boundaries, and topology
- Representation of generated crust composition and spatial variation from which
  continental-like or oceanic-like classifications may be derived
- Representation and units for lithospheric age, thickness, speed, density, and
  buoyancy
- Whether boundary interaction is stored, derived from relative motion and plate
  properties, or represented by a combination of both
- How interactions vary along a shared boundary and weaken into plate interiors
- How plate motion and plate properties change through geological time
- Calibration and validation criteria for deciding whether the abstraction is
  sufficiently coherent for later geology

### ARCH-OPEN-011 — Tectonic structures and geological provinces

- Final taxonomy of tectonic structures and provinces
- Rules that derive collision, subduction, divergence, transform-dominated, and
  oblique interactions from relative plate motion and plate properties
- Representation of changing and mixed interaction along one boundary
- Storage layout and precise geometry representation for structures and provinces
- Whether structures and provinces overlap, nest, merge, or record multiple
  overprinting geological episodes
- Relationship between boundary interactions, structures, province identity, and
  accumulated geological history
- Representation of geological age and time without committing to a full
  time-stepped simulation
- Meaning, units, and calibration of broad physical and elevation tendencies
- How later modification preserves, weakens, or obscures tectonic inheritance
- Elevation, erosion, sedimentation, weathering, glaciation, volcanism, and
  rock-generation algorithms

### ARCH-OPEN-012 — Geological prehistory

- Fixed-timestep, event-driven, or hybrid temporal representation
- Whether and how timestep size varies across geological time and processes
- Analytical long-duration processing versus iterative simulation
- How plate motion changes through time
- How geological events begin, evolve, and end
- Geological-event representation and final process vocabulary
- Amount and granularity of historical detail retained after generation
- Generator performance and scaling strategy
- Total generated geological duration
- Geological year or age numbering
- Mapping between geological age and the eventual civilization calendar and
  playable-era date
- Storage and query model for compact regional and geological-body histories

### ARCH-OPEN-013 — Geological material composition

- Exact major-component basis
- Oxide fractions, elemental fractions, or another bulk representation
- Treatment of total iron and iron oxidation state
- Volatile vocabulary, state, and representation
- Trace-element vocabulary and storage
- Composition ownership by geological body, material parcel, field, or a hybrid
- Spatial variation within geological bodies
- Method for deriving tractable mineral assemblages from composition, pressure,
  temperature, volatiles, formation process, and history
- How texture, grain size, cooling rate, and deformation later participate in
  rock classification
- Precision, normalization, and conservation rules
- Rock-body storage layout, spatial references, continuous fields, and
  interpolation strategy
- Performance implications of composition and history tracking

### ARCH-OPEN-014 — Geological material state

- Exact representation of solid, melt, and fluid phase fractions
- Conservation and normalization rules
- Phase-change thresholds and tractable approximations
- Whether porosity becomes explicit
- Whether structural and consolidation state is binary, continuous, or derived
- Representation of cohesion, packing, grain size, and texture
- How fluids occupy pores, fractures, and geological bodies
- When material bodies split, merge, or transform
- Representation and transport of mobile fluid composition
- Performance implications of tracking multi-phase material state
- Interaction between phase/structural state, geological-body ownership, and
  spatial resolution

### ARCH-OPEN-019 — Earth-like planetary contract

- Exact parameters, units, supported Earth-like ranges, and correlations
- Which planetary-scale quantities remain fixed and which may vary by world
- Whether reference-ellipsoid parameters are common to all supported worlds or
  vary within a bounded Earth-like envelope, and how they correlate with radius,
  mass, rotation, and other planetary-contract causes
- Versioned representation and serialization of the selected contract
- Exact stellar profile and incoming-energy boundary representation
- Whether stellar evolution or orbital cycles matter during generated prehistory
- Supported orbit, rotation, axial-orientation, and seasonality causes
- Water and volatile inventory representation and later conservation boundaries
- Meaning and derivation of atmospheric potential before atmospheric evolution
- Whether world-creation controls are exposed, who selects them, and how named
  tendencies map to causes without guaranteeing consequences
- Starting geological epoch or abstract initial-state boundary
- Propagation of planetary-contract causes into a future climate model
- Compatibility and migration policy when the contract schema changes

## ARCH-OPEN-015 — Territory allocation

- Territory-slot count, server nation-capacity target, and allocation
- Placement constraints
- Expansion, contraction, division, combination, and narrow transfer rules
- Representation of mutable borders without making a spatial domain or sampling
  grid the indivisible unit of territory
- Relationship among sovereignty, claims, administrative jurisdiction,
  resource rights, leases, military access, religious authority, and other
  potentially overlapping relationships

## ARCH-OPEN-016 — Persistence and compatibility

- Persistence format
- Save-compatibility policy
- Compatibility and migration rules for reference-ellipsoid definitions while
  forbidding silent reinterpretation of an existing world's physical positions
- Stable location identity across generator, ruleset, and spatial-representation
  changes
- Persistence model for canonical geological state and compact history
- Generator-version compatibility for deterministic refinement
- Migration rules for still-unresolved regions
- Migration rules for already-resolved or interacted-with regions
- Compatibility rules for established non-geological physical truth, including
  mountains, rivers, and resources
- Distinction between changes caused by modeled history and changes proposed by
  a generator or representation upgrade
- Whether old generator versions must remain executable
- What canonical detail may be deterministically regenerated
- Architecture of authoritative world-creation jobs
- World-generation and refinement checkpointing and recovery strategy
- Acceptable world-creation duration
- Server memory and storage budgets for hierarchical geological detail

## ARCH-OPEN-017 — Networking

- Protocol and state-diff representation
- Synchronization cadence
- Rollback model
- Anti-cheat strategy
- Streaming and serialization of relevant geological subsets or derived views
- Selection and synchronization of world and simulation information according
  to player relevance, visibility, and knowledge
- Disclosure changes produced by diplomacy, embassies, alliances, trade,
  intelligence, or other relationships
- Client caching and invalidation of authority-provided world data
- Boundary between canonical geometry/state and renderer-ready data
- Whether any canonical detail is deterministically materialized on demand by
  the authority

## ARCH-OPEN-018 — Player interface

- Final player-facing UI approach beyond the accepted map-first principle
- Presentation of the globe, flattened map, and transitions selected through
  `ARCH-OPEN-001`
- Navigation and selection continuity from continental context to city scale
- Presentation of unknown, stale, uncertain, or relationship-gated foreign
  information without implying that hidden geography does not exist
- Infrastructure goal, corridor, alternative-comparison, and commitment
  interface
