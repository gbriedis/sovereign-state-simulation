---
id: ARCH-001
type: architecture-overview
status: accepted
scope: Software boundaries, planetary spatial truth, world authority, persistence, and presentation-independent architecture
authority: Owns accepted cross-cutting software, spatial, persistence, and runtime authority boundaries
implementation: partial
last_reviewed: 2026-08-30
---

# Architecture Overview

## Decision

The project separates authoritative world and simulation logic from presentation.
The same authority model supports local singleplayer and eventual multiplayer;
only the location of the authority changes.

Authoritative physical truth describes one curved Earth-like planet. A flattened
map, globe rendering, camera, mesh, raster, and other player view are derived
presentations or query products; none is the planet's physical geometry.

Canonical physical positions use the
[accepted planet-fixed physical reference frame](../decisions/ARCH-DEC-001-planet-fixed-physical-reference-frame.md).
That decision record owns the complete frame choice and rationale; this overview
owns its cross-cutting runtime consequence.

Derived geodetic queries use the world's stable
[Earth-like reference ellipsoid](../decisions/ARCH-DEC-002-earth-like-reference-ellipsoid.md).
That mathematical reference shape is not canonical ground, seafloor, water, sea
level, a gravity reference surface, a future geoid, or detailed gravity truth.

The [World-Generation Source of Truth](../world-generation/README.md) owns the
accepted physical-world concepts. This document owns how software authority,
persistence, and presentation interact with those concepts.

## Player experience boundary

The [Project Vision](../foundations/PROJECT_VISION.md) owns the nation-scale view,
continental-to-city zoom range, and foreign-information experience. The map is
the primary player surface. Players pan, zoom, select geography, and govern
through contextual map interactions.

The map presents and queries one continuous planetary world. It does not define
physical truth or make geography exist. The poles are physically meaningful,
and east-west continuity is required. Directly wrapping both map axes is not an
acceptable substitute for planetary continuity because it describes toroidal
topology. Exact projection, pole-navigation behavior, camera transitions,
presentation seams, and globe-versus-map use remain unresolved.

Distance, area, direction, latitude, elevation, climate, seasons, routing, and
other physical constraints must remain meaningful wherever they create
governing consequences. This requirement does not select a derived elevation
datum or reference surface, projection, numeric encoding, precision, numerical
method, or error tolerance.

The complete planet continues to exist independently of client detail or player
knowledge. A client receives information appropriate to relevance, visibility,
and knowledge; hiding or summarizing foreign information does not alter
canonical world or simulation truth.

## Runtime boundaries

- **Bevy application:** windowing, cameras, input, meshes, picking, shaders, and
  presentation.
- **World core:** presentation-independent Rust code that owns physical-world
  generation, canonical world truth, and world queries.
- **Simulation core:** presentation-independent Rust code that evolves gameplay
  simulation state.
- **Development interface:** egui inspectors, generation controls, profiling,
  and diagnostics. egui is not the primary player interface.

Neither the world core nor the simulation core may depend on Bevy or egui types
or lifecycle. They must remain testable without a renderer.

## Earth-like planetary input boundary

The selected Level 0 planetary contract supplies upstream causes and boundary
conditions; it is not an outcome generator. Continents, mountains, oceans,
climate, resources, biomes, and civilization must arise from their appropriate
later histories. The [Earth-Like Planetary Contract](../world-generation/EARTH_LIKE_PLANETARY_CONTRACT.md)
owns the exact conceptual boundary.

The world core therefore consumes common physical rules plus the selected
bounded Earth-like contract. It must not interpret the contract as permission
to randomize physical laws or directly paint requested downstream outcomes.

## Deterministic generation and persistence

A seed and selected
[Earth-like planetary contract](../world-generation/EARTH_LIKE_PLANETARY_CONTRACT.md)
form the root inputs of a generated world. The same seed, contract, declared
inputs, and compatible generator/ruleset version must reproduce the same
foundational world. [ADR-0002](../decisions/ADR-0002-earth-like-planetary-contract.md)
records why the contract may vary bounded causes without turning the project
into a generic planet generator.

Each server's generated planet is persistent. Once a location or materially
relevant physical detail becomes canonical, persisted truth takes precedence
over regeneration. A later algorithm version must not silently move stable
locations or replace established mountains, rivers, resources, geology, or
other canonical physical facts. Still-unresolved detail may use a compatible new
generator only when it preserves all established constraints.

The world's accepted reference ellipsoid is also stable for the world's
lifetime. A generator or representation upgrade must not silently replace its
definition or change the geodetic meaning of established physical positions.

Persistence does not freeze history. Forests, river courses, settlements,
roads, political borders, ownership, and other state may change through modeled
natural or human events while geographic position and unaffected established
truth remain stable. An algorithm upgrade is not such an event.

```text
seed + selected planetary contract + generator/ruleset version + declared inputs
→ authoritative geological prehistory
→ canonical present world + constraints + compact provenance
→ persisted authority-owned state
→ relevant queries and derived views
```

## Canonical and derived data

Canonical present state is the smallest presentation-independent authority
sufficient to describe what physically exists now and continue relevant
evolution without replaying all geological prehistory.

Canonical truth may include resolved facts, constraints over unresolved detail,
compact provenance, and active physical state. Renderer meshes, GPU buffers,
rasters, sampled layers, level-of-detail products, and client caches are derived
and disposable.

The detailed ownership and refinement rules are defined by `WG-005` through
`WG-010` in the [world-generation index](../world-generation/README.md).

## Spatial model

These questions and identities remain distinct:

- **Geographic position** answers where something is on or within the planet in
  the accepted canonical physical reference frame.
- **Canonical present state** answers what physically or socially exists there
  now, including constraints over unresolved physical detail.
- **Provenance and history** answer why that state exists and how it changed.
- **Natural features** have identities and shapes created by physical causes.
- **Political territories** are mutable human jurisdictions over physical
  space.
- **Spatial domains** support computation, indexing, loading, streaming, or
  refinement.
- **Sampling cells** are system-specific measuring or presentation units.
- **Player knowledge** limits what canonical information a player receives.
- **Map presentation and cameras** display derived views of the other concepts.

Geodetic latitude, longitude, and reference height against the accepted
ellipsoid; flattened-atlas position; local rendering coordinates; domain and
cell identifiers; and territory membership are derived representations or
queries. They must not compete with canonical physical position.

No spatial domain or sampling grid is a province, political territory, atom of
physical reality, or owner of a natural feature. No universal sampling cell
defines the world.

Political borders may follow rivers, ridges, roads, settlements, or negotiated
lines, but those features do not own the border. Borders may change without
regenerating or transferring ownership of natural geography, and narrow
territorial transfers must not be prohibited merely by a coarse computational
grid. Sovereignty, claims, administrative jurisdiction, resource rights,
leases, military access, religious authority, and similar relationships may
eventually overlap; their mechanics remain outside this architecture decision.

Cities, watersheds, ecosystems, geological bodies, infrastructure networks,
economic regions, and political territories retain independent identities and
shapes even when they influence one another. Geological features in particular
retain continuous canonical identity across computational domains and sampling
grids, as specified by `WG-005` and `WG-008`.

Subsurface position and geometry must be representable where geology,
groundwater, foundations, mining, tunnels, hazards, or energy systems require
them. This requirement does not demand uniform maximum-resolution subsurface
simulation. Detail follows physical complexity, simulation relevance, query
need, and available player knowledge without allowing knowledge to determine
what physically exists.

## Detail and refinement

Representation cost follows geological complexity, simulation relevance, and
declared query needs. The architecture must not require every possible sampling
cell or maximum-resolution geological representation to exist at once.

Refinement must preserve established canonical truth and shared constraints.
Observation may trigger refinement, but it does not physically create geology
or permit a reroll. Different regions may hold compatible levels of resolved
detail without creating artificial physical discontinuities.

## Authority model

The authority owns canonical world and simulation state, validates commands, and
performs authoritative generation and refinement.

- In singleplayer, the authority runs locally.
- In multiplayer, the authority runs on the server.
- Clients own presentation, input, local caches, and any later prediction around
  received state.
- Clients do not independently generate authoritative physical truth or
  reconstruct the complete world.
- The server supplies each client only the canonical subsets or derived data
  appropriate to that player's relevance, visibility, and knowledge.

Expensive world creation is separate from client play cost. This decision does
not select eager or lazy generation, persistence granularity, database design,
or a network protocol.

Web3 does not establish spatial persistence or simulation authority. The
[Project Vision](../foundations/PROJECT_VISION.md#long-term-product-direction)
keeps any Web3 economic or ownership layer optional and later unless the Product
Owner explicitly supersedes that boundary.

## Geography before politics

Natural geography is generated before political allocation. Coastlines,
elevation, drainage, rivers, climate, biomes, and other physical conditions
establish the world that later political territories must respect.

Continents may later provide bounded allocation areas containing country slots.
A player may occupy a slot and receive a political territory shaped by physical
geography. Capacity, allocation rules, and the final continent model remain open.

Political change acts on jurisdiction and relationships over the persistent
world. It must not regenerate physical geography or treat a territory transfer
as ownership transfer of the natural feature identities beneath it.

## Consequences

- Seed inputs, selected planetary contracts, and generator/ruleset versions must
  be explicit.
- Coordinate, spatial-domain, and sampling-cell mappings must be testable.
- Presentation code must query world/simulation APIs rather than own simulation
  truth.
- Persistence must distinguish canonical state from derived caches.
- Persistence and compatibility work must preserve stable locations and
  established physical truth, including the world's stable reference ellipsoid,
  across generator changes.
- Cross-domain features and refinement boundaries must preserve continuity.
- Player-knowledge filtering must never become a source of canonical existence.
- Political and computational partitions must remain independent.
- Implementation choices listed in
  [Open Architecture Decisions](OPEN_DECISIONS.md) remain unresolved until an
  accepted decision record resolves them.

## Out of scope

This overview does not select:

- numeric coordinate encoding, precision, serialization, projections, local
  origins, spatial indexes, or domain dimensions;
- exact reference-ellipsoid parameters, parameter-variation policy, geodetic
  conversions, geoid representation, or detailed gravity model;
- pole-navigation behavior, map seams, globe-versus-map transitions, or camera
  techniques;
- geological geometry, topology, numerical solvers, or refinement algorithms;
- terrain-generation, hydrology, climate, soil, ecosystem, or resource models;
- renderer internals, databases, serialization formats, or network protocols;
- country-slot capacity or political-allocation rules.
- infrastructure routing algorithms, interfaces, or playable-era dates.
