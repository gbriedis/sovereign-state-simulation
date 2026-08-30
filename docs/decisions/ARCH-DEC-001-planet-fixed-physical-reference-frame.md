---
id: ARCH-DEC-001
type: decision-record
status: accepted
scope: Conceptual canonical physical reference frame and the boundary between physical position and derived spatial representations
authority: Owns the selected planet-centered, planet-fixed three-dimensional frame for canonical physical positions and its rationale
related: ARCH-DEC-002, ARCH-OPEN-001, ARCH-OPEN-007, WG-001, WG-005, WG-009, WG-013
last_reviewed: 2026-08-30
---

# Adopt a Planet-Fixed Physical Reference Frame

## Decision

Canonical physical positions belong to one planet-centered, planet-fixed
three-dimensional reference frame. The frame is conceptually centered on the
generated planet's center of mass, oriented by its rotation axis and an agreed
prime-meridian direction, and measures physical positions in meters.

Within that frame, the
[accepted Earth-like reference ellipsoid](ARCH-DEC-002-earth-like-reference-ellipsoid.md)
supplies the stable mathematical shape for derived geodetic queries and owns
that choice's complete meaning.

Geodetic latitude, longitude, and reference height; flattened-atlas positions;
local rendering coordinates; spatial-domain identifiers; sampling-cell
identifiers; and political-territory membership are derived representations or
queries over canonical physical position. They are not alternative physical
truth.

Elevation and depth remain contextual queries. Each must name the datum, ground,
sea level, or other explicit reference surface against which it is measured.

This decision selects no numeric encoding, precision, serialization, projection
formula, local-origin strategy, spatial index, sampling resolution, storage
layout, rendering technique, or network representation. Those choices remain
open in `ARCH-OPEN-001`, `ARCH-OPEN-007`, and their related packets.

## Context

The game requires one continuous curved Earth-like planet, stable physical
locations, meaningful distance and direction, physically significant poles,
subsurface geometry, and derived flattened maps. Previous authority required
absolute planetary position but left the reference frame itself open.

Leaving canonical position ambiguous would force the prototype, persistence,
geology, simulation, and presentation layers to make incompatible assumptions.
Making a map projection, sampling grid, spatial domain, or political territory
canonical would instead turn a derived tool or mutable jurisdiction into
physical reality.

## Rationale

A planet-fixed physical frame gives surface, subsurface, natural, and human
systems one stable answer to `where?` without making any presentation or
computational partition authoritative. Centering the conceptual frame on the
planet's mass center and orienting it by durable planetary directions keeps it
tied to the generated planet rather than to a renderer, map sheet, region,
territory, or client session.

Measuring physical position in meters preserves a common physical relationship
for distance, geometry, and later simulation while leaving the machine encoding
and precision budget to evidence-driven implementation decisions. Derived
geodetic, elevation, depth, atlas, local, domain, cell, and territory queries
can then serve their own purposes without moving canonical features when those
representations change.

## Consequences

- Canonical physical geometry and stable location identity must refer to this
  frame across world generation, persistence, simulation, and authority-owned
  queries.
- A change to a projection, local rendering origin, spatial index, domain
  hierarchy, sampling grid, or political border must not move canonical
  physical positions.
- Geodetic latitude, longitude, reference height, elevation, and depth APIs must
  declare their transformation, ellipsoid, datum, or reference surface rather
  than masquerade as raw canonical position.
- `PROTO-001` may treat the conceptual frame as accepted and must gather evidence
  only for the unresolved encodings, derived views, navigation behavior, and
  implementation choices.
- Persisted locations and established physical truth must survive compatible
  generator and representation changes.
- `ARCH-OPEN-001` and `ARCH-OPEN-007` remain open because this record does not
  select their numeric, projection, query, indexing, or implementation choices.

## Rejected options

### Geodetic latitude, longitude, and reference height as canonical position

These values are useful derived queries against the accepted reference
ellipsoid, but they do not by themselves provide the one
presentation-independent three-dimensional physical truth required for
subsurface geometry and local computation.

### A flattened atlas as canonical position

Every flattened atlas introduces projection and seam behavior. Making it
canonical would make physical truth depend on a selected presentation.

### Spatial domains or sampling cells as canonical position

Domains and cells support computation and measurement. Making their identifiers
canonical would confuse implementation partitions and system-specific
resolution with physical identity.

### Political territory as canonical position

Territories and borders change through history. Making membership canonical
position would cause jurisdictional change to redefine the natural world.

### Local rendering coordinates as canonical position

Local coordinates may be useful for precision and rendering, but they depend on
a chosen origin and client context. They cannot own persistent planetary truth.
