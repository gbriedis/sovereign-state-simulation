---
id: ARCH-DEC-002
type: decision-record
status: accepted
scope: Stable Earth-like oblate mathematical reference shape for the planet-fixed frame and derived geodetic queries
authority: Owns the selected Earth-like oblate reference ellipsoid, its world-lifetime stability, its distinctions from physical and gravity surfaces, and its rationale
related: ARCH-DEC-001, ARCH-OPEN-001, ARCH-OPEN-007, ARCH-OPEN-009, ARCH-OPEN-016, ARCH-OPEN-019, WG-001, WG-025
last_reviewed: 2026-08-30
---

# Adopt an Earth-Like Reference Ellipsoid

## Decision

Each generated server world uses one stable Earth-like oblate reference
ellipsoid as the mathematical planetary reference shape for its accepted
planet-fixed physical frame. The ellipsoid is centered at that frame's origin,
and its symmetry axis follows the planet's rotation axis. Derived geodetic
longitude uses the frame's agreed prime-meridian direction. The ellipsoid
remains unchanged for the world's lifetime.

Geodetic latitude, geodetic longitude, and geodetic reference height are derived
against this ellipsoid. They remain queries over canonical planet-fixed physical
position rather than competing physical truth.

The reference ellipsoid is not generated ground, seafloor, actual water, sea
level, a gravity reference surface, a future geoid, or a representation of the
planet's detailed gravity field. Those physical and contextual surfaces or
models remain distinct even where later queries relate them to the ellipsoid.

This decision selects no exact equatorial or polar radius, flattening value or
supported range, policy for common versus bounded per-world parameter values,
numeric type, precision, serialization, geodetic conversion algorithm, geoid
representation, or detailed gravity model. Those choices remain open in
`ARCH-OPEN-001`, `ARCH-OPEN-007`, `ARCH-OPEN-009`, and `ARCH-OPEN-019`.
Compatibility policy for later ruleset definitions remains open in
`ARCH-OPEN-016` without permitting an existing world's reference to change.

## Context

`ARCH-DEC-001` established one planet-centered, planet-fixed three-dimensional
frame but intentionally left derived latitude, longitude, and height references
open. A stable mathematical reference shape is needed so those geodetic queries
do not inherit the irregularity and historical change of terrain, water, ice,
or generated solid-Earth geometry.

A perfect sphere would erase the accepted Earth-like oblate direction. Using a
physical surface instead would make geodetic meaning change when geology,
erosion, water, ice, or sea-level policy changes. Treating a geoid or gravity
model as the same object would also resolve physical behavior that has not yet
been designed.

## Rationale

An Earth-like oblate ellipsoid provides a simple, continuous mathematical shape
that respects the planet's rotation-axis orientation without making generated
terrain or water authoritative for geodetic coordinates. Keeping it stable for
the world lifetime preserves the meaning of persisted locations and derived
geodetic queries across natural history, political change, and compatible
generator or representation upgrades.

Separating the conceptual shape from its exact parameters and conversion
implementation permits later evidence to determine precision, supported world
variation, and query algorithms without reopening the accepted distinction
between mathematical reference and physical world.

## Consequences

- The world identity must retain an unambiguous, versioned reference-ellipsoid
  definition for its lifetime, whether its eventual parameter values are common
  to all supported worlds or selected per world.
- Generator, ruleset, or representation upgrades must not silently replace a
  world's reference ellipsoid or change the geodetic meaning of established
  canonical positions.
- Geodetic conversion APIs must name the ellipsoid and distinguish geodetic
  reference height from elevation, depth, sea level, ground, and geoid-related
  height.
- Ground, seafloor, water, ice, and other physical surfaces remain generated or
  simulated state and may lie above, below, or intersect the mathematical
  reference shape.
- `PROTO-001` treats the oblate reference-shape choice as accepted and gathers
  evidence only for the open parameters, encodings, conversions, precision, and
  derived presentation behavior.
- Gravity and any future geoid require their own accepted models; neither may be
  inferred solely from the ellipsoid.

## Rejected options

### A perfect sphere as the reference shape

A sphere is continuous but does not express the accepted Earth-like oblate
reference direction. It may remain useful as an explicitly approximate test or
presentation aid, but it is not the world's accepted geodetic reference shape.

### Generated ground, seafloor, or water as the reference shape

These are irregular physical surfaces that may change through history. Using
them as the planetary mathematical reference would make geodetic coordinates
depend on generated outcomes and later physical events.

### Sea level, a geoid, or gravity as the same reference

Sea level requires a declared physical or policy meaning, while a geoid and a
detailed gravity field require unresolved mass and gravity models. Conflating
them with the ellipsoid would silently select systems outside this decision.

### Replacing the ellipsoid after world creation

Changing the reference shape or parameters would change derived geodetic
meaning for established physical positions and undermine persistence. A new
ruleset may define later worlds differently only within future accepted
compatibility rules; it must not silently reinterpret an existing world.
