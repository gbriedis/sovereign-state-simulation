---
id: PROTO-001
type: implementation-specification
status: accepted
scope: First map interaction and spatial-mapping prototype
authority: Owns the required outcome, success criteria, and exclusions for the first implementation milestone
implementation: not-started
last_reviewed: 2026-08-22
---

# Map and Spatial Model Prototype

## Required outcome

Build a Bevy application that:

1. Opens a map window and generates a procedurally shaped landmass from a seed.
2. Renders the landmass clearly against water.
3. Provides smooth mouse panning and cursor-centered zooming.
4. Divides space into spatial domains and provisional `500 m × 500 m` sampling
   cells. These sample prototype world data; they do not define geological
   identity.
5. Displays world coordinates plus the selected spatial-domain and sampling-cell
   identifiers when the player selects a location.

## Success criteria

- Navigation and inspection are responsive and legible.
- Coordinate-to-domain-to-cell mapping is correct and covered by automated tests.
- Prototype world data does not depend on Bevy types.
- The same seed, inputs, and compatible generator/ruleset version reproduce the
  same foundational landmass.

## Out of scope

- National simulation
- Multiplayer networking
- Polished player-facing interface
- Final terrain-generation algorithms
- Final sampling resolution or spatial-domain dimensions
