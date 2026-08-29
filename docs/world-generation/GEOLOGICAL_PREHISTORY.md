---
id: WG-002
type: world-generation-specification
status: accepted
scope: Geological history generated before the playable era
authority: Owns the temporal relationship between geological prehistory, canonical present state, and play
implementation: unresolved
concept_state: accepted
coverage: partial
last_reviewed: 2026-08-22
---

# Geological Prehistory

## Core decision

> **The physical world has a generated geological timeline. The present-day
> world is the accumulated result of that history. Civilization begins only
> after geological world generation reaches the designated playable era.**

World generation is a simulation whose output becomes the starting map and
physical state of the playable civilization simulation. It is not a sequence of
independent generators that paint unrelated final layers.

The causal framing is:

```text
initial planetary / lithospheric state
→ geological time begins
→ tectonic and geological events occur
→ world state changes
→ later events act on inherited state
→ accumulated geological history
→ present-day physical world
→ civilization begins
```

## Geological time

Generation may cover hundreds of millions of years, but it does not simulate
every individual year or perform hundreds of millions of ticks. Geological time
advances through meaningful events, epochs, suitably coarse intervals, or some
combination of these.

The exact time representation, total duration, year numbering, and date of the
playable era remain unresolved. Any duration mentioned before a decision is
illustrative.

> **History generates the world; current state becomes authoritative.**

Generation produces a persistent present state plus compact causal provenance.
Normal gameplay and simulation queries operate on that present state rather
than replaying geological prehistory. The distinction is documented in
[Canonical Geological State and Refinement](CANONICAL_GEOLOGICAL_STATE_AND_REFINEMENT.md).

## Prehistory and play

- **Geological prehistory** is generated before play and establishes the
  inherited physical world.
- **Civilization and human simulation** belong to the eventual playable era and
  begin only after the designated end of geological generation.

This boundary does not require geological processes to become irrelevant during
play. It defines which history is generated to create the initial world; the
behavior of geology during the playable era is not decided here.

## Persistent geological history

Generation must not discard all history after calculating the final physical
state. The world retains a compact record of important events and periods rather
than every timestep.

A region or geological body may eventually preserve a history resembling:

```text
crust formed
→ rifting
→ marine sedimentation
→ subduction-related magmatism
→ continental collision
→ metamorphism
→ erosion
→ renewed sedimentation
→ glaciation
```

This sequence is illustrative only. It does not establish the final geological-
event vocabulary or require every world to contain these events.

Events and their spatial effects are distinct. An event records what happened;
one or more reusable operations modify the inherited surfaces, bodies, and
contacts in the canonical 3D state. This accepted relationship is documented in
[Geological Geometry Operators](GEOLOGICAL_GEOMETRY_OPERATORS.md), without
settling the event taxonomy or geometry implementation.

The purpose of retained history is causal reuse. Later systems should be able to
ask which processes and sequences affected a region instead of relying on
unrelated random placement. For example, future resource logic may need evidence
of past heat, fluids, faults, burial, magmatism, sedimentation, or metamorphism.
This note does not design resource generation.

## Age is causal

Geological age refers to when something formed or changed during generated
prehistory. It is not decorative random metadata.

Concepts that may carry causal age include:

- lithosphere formation or modification;
- rock-body formation;
- tectonic events;
- sedimentary deposition periods;
- metamorphic events.

The exact age model and the objects that store age remain unresolved.

Pressure-temperature history is also causal. Burial, heating, uplift, erosion,
cooling, and exhumation can create a path whose important peaks and episodes may
matter after present pressure or temperature changes. Compact provenance may
retain meaningful P–T conditions and timing without every timestep. The final
history schema remains open; see
[Depth, Pressure, and Thermal State](DEPTH_PRESSURE_AND_THERMAL_STATE.md).

## Minimal Rust-facing vocabulary

The following types illustrate only the minimum temporal concepts. They are not
accepted schemas, storage layouts, or a final event model.

```rust
struct GeologicalEvent {
    start_age: GeologicalAge,
    end_age: GeologicalAge,
    affected_region: RegionRef,
    process: GeologicalProcess,
}

struct GeologicalHistory {
    events: Vec<GeologicalEvent>,
}
```

`GeologicalAge`, `RegionRef`, and `GeologicalProcess` are intentionally
undefined. In particular, `GeologicalProcess` must not become a final enum until
the event vocabulary is deliberately designed.

## Scope boundary

This note accepts the temporal architecture of world generation and nothing
more. It does not define:

- the geological-event taxonomy;
- plate-motion or geological-process algorithms;
- rock, mineral, erosion, sedimentation, volcanism, or resource systems;
- hydrology, climate, soils, or ecosystems;
- continents, political territories, civilization, or human systems.
