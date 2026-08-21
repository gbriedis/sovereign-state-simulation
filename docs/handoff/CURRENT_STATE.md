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
  territories reference physical space instead of owning its cells.
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
- A compact history of important geological events and periods persists after
  generation. Geological age records when formation or change occurred rather
  than serving as decorative metadata.
- Spatial detail is lazy, chunked, and proportional to attention.
- Singleplayer and eventual multiplayer share one authority model.
- The eventual multiplayer server is authoritative.

## Current target

Implement the scoped map prototype in
`../architecture/PROTOTYPE_V0.1.md`. The 500 m cell size is a measurement target,
not a final commitment.

The accepted physical-world conceptual chain is currently documented in
`../world-generation/EARTH_LIKE_PHYSICAL_FRAMEWORK.md`,
`../world-generation/GEOLOGICAL_PREHISTORY.md`,
`../world-generation/GEOLOGICAL_MATERIAL_COMPOSITION.md`,
`../world-generation/GEOLOGICAL_MATERIAL_STATE.md`,
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

## Recommended next actions

1. Create the Rust workspace with separate simulation/world and Bevy application
   crates or modules.
2. Define versioned seed inputs and coordinate/chunk/cell identifiers.
3. Implement and test coordinate-to-chunk-to-cell mapping.
4. Build the seeded landmass render and map camera controls.
5. Measure the provisional cell and chunk choices before resolving them.

## Before continuing work

Read the prototype specification and the relevant open decisions. If a task would
resolve an open decision, record both the rationale and consequences instead of
only changing code.
