# Architecture Overview

- **Status:** Living / accepted direction
- **Scope:** Initial architecture
- **Last reviewed:** 2026-08-21

## Experience boundary

The world map dominates the game window. Players pan, zoom, select geography,
and inspect or govern through contextual overlays. Lines, polygons, cells,
symbols, and procedural geometry form the core visual language.

## Runtime and simulation core

- **Bevy** provides windowing, cameras, input, meshes, picking, shaders, and
  presentation.
- The **simulation and world core** is pure Rust, deterministic where practical,
  and independent of Bevy types and lifecycle.
- **egui** is limited to development tools: inspectors, generation controls,
  profiling, and diagnostics. It is not the main player interface.

This boundary keeps the simulation testable, portable, and suitable for a future
authoritative server without requiring a renderer.

## Deterministic world generation

A seed is the root identity of a generated world. Compatible generator and
ruleset versions must reproduce the same foundational world from the same seed
and inputs.

```text
world seed
└── physical world
    └── continents and physical regions
        └── chunks
            └── cells

political allocation
└── country territories / settlement slots
    └── references to areas of the physical world
```

Natural geography is generated before political borders. Coastlines, elevation,
drainage, rivers, climate, and biomes establish physical regions. Territories and
country slots are fitted to that geography rather than forcing geography into
arbitrary borders.

Cells and chunks belong to the physical world, not to countries. Political
territories reference physical space and may change without regenerating it. A
river, watershed, geological formation, ecosystem, or hazard can cross any
number of political boundaries and must not terminate at a territory edge.

## Spatial scale and levels of detail

The initial measurement target is a **500 m × 500 m cell**. It is provisional,
not a final decision. Finer resolution is acceptable only when it creates
meaningful play and remains affordable.

Detail is chunked, lazy, and multi-resolution:

- The player's nation is generated and simulated at high detail.
- Visible or actively inspected areas receive detail on demand.
- Distant states remain coarse summaries sufficient for cross-border systems
  such as diplomacy, trade, demographics, and military strength.
- Detail may be materialized, cached, unloaded, or regenerated deterministically
  according to focus and relevance.

The architecture must not require every cell of every nation to exist at once.

## Continents and country allocation

Continents provide a bounded allocation layer inspired by Ikariam. Each continent
contains a designed or generated set of country territories or slots. A player
occupies a slot and receives a sovereign territory shaped by physical geography.
Exact capacity and allocation rules remain open.

## Authority and multiplayer

The eventual multiplayer model is server-authoritative. The server owns canonical
simulation state, validates commands, and distributes an appropriate level of
state to each client.

Singleplayer follows the same model locally: a local authority runs the world and
simulation. Networking is not required for the first prototype, but commands and
state boundaries must not assume direct UI ownership.

## Architectural consequences

This direction requires early discipline in deterministic generation, spatial
indexing, and simulation/render separation. It enables a detailed personal
nation, large worlds, focused resource use, headless simulation, and a credible
path from local singleplayer to authoritative multiplayer.
