---
id: WG-025
type: world-generation-specification
status: accepted
scope: Level 0 Earth-like planetary boundary conditions inherited by generated history
authority: Owns bounded per-world planetary causes, their semantic limits, and their relationship to downstream history
implementation: unresolved
concept_state: accepted
coverage: partial
related: ADR-0002, WG-001
last_reviewed: 2026-08-23
---

# Earth-Like Planetary Contract

## Decision

> **The simulation generates Earth histories, not planets.**

Every generated world begins inside an Earth-like planetary envelope. Controlled
variation within that envelope supplies different initial causes; geological and
later histories produce the consequences.

```text
Earth-like planetary envelope
+ controlled causal variation
+ generated history
        ↓
different Earth-like worlds
```

This is **Level 0** of world generation. It answers:

```text
What kind of Earth-like planetary environment is this?
```

Later levels answer:

```text
What happened within that environment?
```

Level 0 does not generate tectonic structures, continents, mountains, climate,
resources, biomes, or civilization. It establishes the boundary conditions
those later histories inherit.

## Fixed rules, constrained parameters, generated history

Three categories must remain distinct.

### Fixed or inherited physical rules

Worlds do not use different universes. Compatible rulesets share the physical
and chemical behavior the simulation chooses to represent, including universal
constants and the accepted approximations for gravity, thermodynamics,
radiation, and chemistry. These rules are not procedural world traits.

### Earth-like planetary constraints

A world-creation profile starts from Earth-like defaults and may select bounded
Earth-like values or tendencies for:

- stellar profile or constrained type and incoming-energy context;
- planetary radius, mass, and surface gravity;
- orbit and rotation;
- axial orientation and resulting seasonality tendency;
- broad chemistry envelope;
- total water inventory;
- broad volatile inventory and atmospheric potential.

The exact variables, ranges, correlations, and values that remain permanently
fixed are unresolved. Variation must remain inside the supported Earth-like
envelope; it does not turn the game into an arbitrary exoplanet generator.

### Generated history

The selected contract becomes inherited context for generated tectonic and
geological history. Later accepted layers may eventually add surface, climate,
biological, and civilization history. Their outcomes are not Level 0 inputs.

```text
fixed physical rules
+ selected Earth-like planetary contract
        ↓
geological history
        ↓
later inherited histories
```

## External stellar and orbital context

The star is an external boundary condition, not a simulated world object with
its own formation or evolution model. Level 0 need only provide enough stellar
profile, orbital relationship, orientation, and time context to derive the
incoming stellar-energy boundary condition used by later systems.

```text
star profile
+ orbit
+ orientation
+ time
        ↓
incoming stellar-energy context
```

Orbital distance and period, eccentricity, axial tilt, and rotation are causes.
They may later influence solar forcing, energy balance, and climate; they are
not direct climate classifications or biome controls. Slow stellar evolution
and orbital cycles during generated prehistory remain open rather than assumed.

## Planetary scale

Radius, mass, and gravity establish the scale and curved geometry inherited by
the solid-Earth model. They may later affect atmosphere retention, pressure,
water behavior, erosion, climate, and life, but Level 0 does not generate those
consequences. Supported variation remains bounded and Earth-like; exact ranges
and whether some quantities remain fixed are open.

## Water and volatile inventories

> **Water inventory is a cause, not a requested ocean-coverage percentage.**

Level 0 may supply a total water inventory or bounded tendency. Its eventual
distribution follows from inherited causes such as gravity, thermal and
atmospheric conditions, and generated surface geometry.

```text
water inventory
+ gravity
+ thermal and atmospheric state
+ generated surface geometry
        ↓
later water distribution
```

Likewise, the planetary contract supplies a broad volatile inventory and
atmospheric potential, not a final surface pressure, greenhouse state, or
atmospheric composition. Those may later evolve through geological cycling,
surface exchange, and future biological history. Their representation and
evolution remain unresolved.

## World-creation variance

An authority selects the Earth-like profile before geological generation. A
future server may expose causal tendencies such as:

- drier / baseline / wetter water inventory;
- cooler / baseline / warmer internal thermal tendency;
- mild / baseline / stronger seasonal forcing tendency.

These are illustrative directions, not accepted settings, ranges, or guaranteed
outcomes. A named tendency must map to underlying causes rather than directly
painting its label onto the generated world.

> **Players choose causes, not consequences.**

Suitable future controls might express water inventory, atmospheric potential,
seasonality, or planetary-activity tendencies. Controls such as “more
mountains,” “more iron,” “more forests,” “more rivers,” “more deserts,” or
“better climate” would bypass the causal architecture.

This specification does not decide whether players vote on, customize, or even
see these controls.

## Contract output and layered identity

Level 0 supplies only:

- incoming stellar-energy boundary context;
- bounded planetary physical parameters;
- water inventory;
- volatile inventory and atmospheric potential;
- the selected Earth-like variance profile.

The exact storage and serialization contract remain open. These causes become
part of the world's durable identity because all later histories inherit them.

```text
cosmic context
→ Earth-like planetary contract
→ geological history
→ later climate history
→ later biological history
→ later civilization history
```

World generation starts from an already formed Earth-like planet ready for
meaningful geological history. It does not replay planetary accretion or an
early universe. Whether the starting state represents a young mature active
planet, an abstract geological baseline, or another pre-civilization geological
epoch remains open.

## Relationship to existing geological architecture

The [Earth-Like Physical Framework](EARTH_LIKE_PHYSICAL_FRAMEWORK.md) defines
the minimal Level 0 context currently consumed by geological reasoning. The
accepted geological-prehistory, canonical-state, thermal, spatial, and
elevation contracts remain downstream and unchanged:

```text
Level 0: Earth-like planetary environment
        ↓
Level 2: solid-Earth evolution and geological prehistory
        ↓
Level 3+: later surface environment and transformation
```

The numbering reserves conceptual room without defining a missing layer or
implementation pipeline.

> **Store causes and history; derive consequences and classifications wherever
> practical.**

## Scope boundary

This specification does not define stellar evolution or formation, galaxies,
cosmology, an orbital-dynamics engine, atmospheric evolution or circulation, a
climate solver, oceans, hydrology, weather, weathering, erosion, biology,
resources, continents, civilization, multiplayer voting, exact parameter
ranges, or a serialization schema.
