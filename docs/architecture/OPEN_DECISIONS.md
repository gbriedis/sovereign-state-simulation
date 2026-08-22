# Open Architecture Decisions

- **Status:** Unresolved
- **Last reviewed:** 2026-08-22

Items in this file are not accepted architecture. When one is resolved, record
the decision and rationale in the architecture overview (or a dedicated decision
record) and remove it from this list.

## Spatial model

- Final cell size and chunk dimensions
- Coordinate system and world projection
- Representation and simulation cadence at each level of detail

### Sparse 3D geological representation

- Exact representation of geological surfaces, bounded bodies, and volumes
- Topology and contact relationships between bodies, surfaces, and faults
- Fault displacement and the cutting, overlap, nesting, truncation, burial,
  intrusion, and erosion of inherited geometry
- Three-dimensional spatial indexing and cross-section or volume-query models
- Coordinate system, precision, and depth representation for subsurface truth
- Relationship between provisional 500 m surface cells and subsurface structure

### Canonical geological state and refinement

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

### Geological geometry operators

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

- Terrain-generation algorithms
- Exact river and drainage model

### Earth-like physical framework

- Exact standard Earth reference values, precision, and units used by the
  versioned ruleset
- Minimum mantle reference conditions required by the lithosphere abstraction
- Whether a surface-pressure datum is required before later atmospheric work
- Minimum water and volatile reference assumptions required by current geology
- Equations and approximations used to derive pressure, density, buoyancy,
  melting tendency, strength, rheology, and effective lithosphere thickness
- Which derived values are calculated on demand, cached, summarized, or persisted
- Criteria for deriving continental-like and oceanic-like crust classifications

### Tectonic plate layer

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

### Tectonic structures and geological provinces

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

### Geological prehistory

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

### Geological material composition

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

### Geological material state

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

## Territory allocation

- Territory-slot count and capacity
- Placement constraints
- Expansion rules

## Persistence and compatibility

- Persistence format
- Save-compatibility policy
- Persistence model for canonical geological state and compact history
- Generator-version compatibility for deterministic refinement
- Migration rules for still-unresolved regions
- Migration rules for already-resolved or interacted-with regions
- Whether old generator versions must remain executable
- What canonical detail may be deterministically regenerated
- Architecture of authoritative world-creation jobs
- World-generation and refinement checkpointing and recovery strategy
- Acceptable world-creation duration
- Server memory and storage budgets for hierarchical geological detail

## Networking

- Protocol and state-diff representation
- Synchronization cadence
- Rollback model
- Anti-cheat strategy
- Streaming and serialization of relevant geological subsets or derived views
- Client caching and invalidation of authority-provided world data
- Boundary between canonical geometry/state and renderer-ready data
- Whether any canonical detail is deterministically materialized on demand by
  the authority

## Player interface

- Final player-facing UI approach beyond the accepted map-first principle
