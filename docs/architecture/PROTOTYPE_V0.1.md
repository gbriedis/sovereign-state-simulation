# Prototype v0.1

- **Status:** In progress
- **Purpose:** Validate map interaction and the initial spatial model

## Required outcome

Build a Bevy application that:

1. Opens a map window and generates a procedurally shaped landmass from a seed.
2. Renders the landmass clearly against water.
3. Provides smooth mouse panning and cursor-centered zooming.
4. Divides space into chunks and provisional 500 m sampling cells that query
   prototype world data rather than defining geological identity.
5. On click, displays world coordinates and the selected chunk and cell IDs.

## Success criteria

- Navigating and inspecting a generated world feels responsive and legible.
- Coordinate-to-chunk-to-cell mapping is correct and testable.
- The simulation/world data used by the prototype does not depend on Bevy types.
- Repeating a run with the same seed and compatible generator version reproduces
  the same foundational landmass.

## Explicitly excluded

- National simulation
- Multiplayer networking
- Polished player-facing UI
- Final terrain-generation algorithms
- Final sampling resolution or spatial-domain dimensions
