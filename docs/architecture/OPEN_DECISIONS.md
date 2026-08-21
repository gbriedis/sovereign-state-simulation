# Open Architecture Decisions

- **Status:** Unresolved
- **Last reviewed:** 2026-08-21

Items in this file are not accepted architecture. When one is resolved, record
the decision and rationale in the architecture overview (or a dedicated decision
record) and remove it from this list.

## Spatial model

- Final cell size and chunk dimensions
- Coordinate system and world projection
- Representation and simulation cadence at each level of detail

## Natural-world generation

- Terrain-generation algorithms
- Exact river and drainage model

### Tectonic plate layer

- Plate-count and plate-size distributions
- Planar, spherical, or projected representation of plate geometry
- Representation of plate shapes, shared boundaries, and topology
- Whether crust type remains categorical or supports mixed/spatially varying
  composition
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

## Territory allocation

- Territory-slot count and capacity
- Placement constraints
- Expansion rules

## Persistence and compatibility

- Persistence format
- Generator migration strategy
- Save-compatibility policy

## Networking

- Protocol and state-diff representation
- Synchronization cadence
- Rollback model
- Anti-cheat strategy

## Player interface

- Final player-facing UI approach beyond the accepted map-first principle
