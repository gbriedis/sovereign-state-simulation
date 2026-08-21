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
- Whether generation produces only a present-day state, a compact geological
  history, or any time-stepped plate motion
- Calibration and validation criteria for deciding whether the abstraction is
  sufficiently coherent for later geology

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
