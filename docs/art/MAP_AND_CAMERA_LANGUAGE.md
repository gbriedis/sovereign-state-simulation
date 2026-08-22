# Map and Camera Language Foundation

- **Status:** Accepted foundation
- **Adopted:** 2026-08-22 through `ART-001`
- **Work packet:** `ART-001`
- **Accountable owner:** Art / Technical Art Lead
- **Scope:** Art-facing map, camera, zoom, picking, and cross-scale contracts
- **Implementation owner:** Bevy Client inside accepted Systems Architecture
- **Semantic owners:** World Generation and the renderer-independent world
  domains that provide each query

## Purpose

This document defines the information a map view must preserve and the evidence
required to accept its presentation. It does not choose a world projection,
planetary datum, final camera model, orientation, zoom bounds, layer taxonomy,
surface-query policy, visual grammar, or implementation algorithm.

The immediate consumer is [Prototype v0.1](../architecture/PROTOTYPE_V0.1.md),
which requires a clear seeded landmass, smooth mouse panning, cursor-centered
zoom, and click inspection of world coordinates plus provisional chunk and
500 m sample identifiers. Those prototype identifiers are diagnostics and do
not define geological identity.

## Map truth stack

The map is a presentation and query surface over the canonical world:

```text
canonical world meaning
        ↓ versioned query
semantic result
        ↓ view/projection contract
view-space representation
        ↓ visual encoding
rendered map
        ↓ interaction
selection / inspection request
```

No lower layer may silently redefine an upper layer. A shader does not create a
classification, a pixel does not create a sample, a mesh does not create
elevation, and a selection color does not create canonical identity.

## Required semantic registry

Every player-facing or diagnostic map layer requires a registry entry before
visual acceptance. The registry schema is a contract requirement, not a chosen
layer taxonomy or file format.

Before an owning world/query contract exists, a provisional diagnostic may use
`N/A — <specific owner or reason>` for an unavailable field. That exception must
identify the missing dependency and cannot support player-facing acceptance.

| Field | Requirement |
| --- | --- |
| Layer/view ID and version | Stable identifier for the visual contract, separate from display name |
| Intended mode and viewer | Player-facing, diagnostic, review, or capture; intended task and audience |
| Semantic owner | Domain that accepts the represented meaning |
| Meaning class | Present state, provenance/history, derived quantity, derived classification, or computational diagnostic |
| Definition | What is represented and what is explicitly excluded |
| Units and reference | Units, datum/reference, sign convention, valid range, precision, and whether values are scalar, vector, categorical, relational, or topological |
| State model | Legitimate zero, uncertainty, constrained unresolved state, truly unspecified state, no data, unloaded/pending data, stale cache, query failure, and out-of-scope behavior as applicable |
| Query contract | Source query, input parameters, canonical revision, query/schema version, aggregation, interpolation, and cache identity |
| Spatial validity | Coordinate reference, projection assumptions, valid extent, sample/support area, and scale or resolution at which the result remains meaningful |
| Cross-scale rule | What may aggregate, simplify, appear, disappear, or change encoding across camera scale, render LOD, streaming, and canonical refinement |
| Picking identity | Returned world position and semantic identity; never only a pixel, mesh index, Bevy entity, or color |
| Encoding and legend | Proposed visual channels, legend behavior, redundant accessibility channel, and relationships to other layers |
| Evidence | Named fixtures, camera/view states, acceptance checks, known limitations, and reviewers |

If the semantic owner cannot yet provide these fields, Art may create a labelled
diagnostic or concept treatment but cannot accept a player-facing encoding.

## World meanings the map must preserve

### Canonical 3D truth and derived surfaces

Canonical geology is sparse and genuinely three-dimensional. A heightmap,
sampled elevation field, raster, contour product, terrain mesh, cross-section,
or screen-space effect is a derived query or presentation product.

Ground and seafloor are queried from the semantic upper boundary of the accepted
ground-material domain. They are not necessarily the highest point with a solid
fraction, and the canonical world need not be a single-valued height function.
Water, ice, atmosphere, vegetation, artificial structures, and other overlying
domains remain distinct.

Any map that selects one surface from caves, overhangs, voids, or multiple
intersections must name the World Generation query policy. That policy, the
final domain ownership, and any vertical exaggeration remain open. If vertical
exaggeration is used provisionally, the view and evidence must disclose it.

### Feature, partition, and sample identity

The map language must preserve three different concepts:

| Concept | Meaning | Visual-honesty rule |
| --- | --- | --- |
| Geological feature | Continuous canonical body, fault, contact, structure, or other accepted entity | Identity and topology survive chunk and LOD changes |
| Spatial domain/chunk | Computational locality for queries, persistence, caching, refinement, or streaming | Visible only as a labelled diagnostic unless physical meaning independently coincides |
| Cell/sample | System-specific measurement or presentation unit | Must read as a sample/support area, not as the container of geology |

The provisional 500 m prototype cell is not a texture pixel, render tile,
canonical LOD, geological body, or final world resolution.

### Present state, provenance, and classification

A present-state layer answers what exists now. A provenance layer answers how
or when it formed. A derived classification organizes accepted causes for a
specific purpose. Their treatments must not imply that one is another.

Illustrative examples such as plate-boundary families, tectonic structures,
named rocks, phase mixtures, elevation tendency, temperature, geothermal
gradient, or geological age require their own accepted semantic registry
entries. Lists and Rust-facing vocabulary in World Generation notes are not
automatically final player taxonomies.

### Quantities with similar-looking but different meaning

The map must not visually collapse distinctions such as:

- absolute position, elevation relative to a datum, and contextual depth below
  a selected surface;
- lithostatic pressure and pore-fluid pressure;
- temperature and derived geothermal gradient;
- bulk composition, trace concentration, derived rock classification, and any
  future deposit classification;
- actual geometry, preferred vertical response, disequilibrium, and a
  displacement/deformation diagnostic;
- current physical state and compact historical provenance.

World Generation defines these meanings, units, ranges, and uncertainty before
Art accepts their encoding.

## Camera contract

The camera is a view transform and interaction surface, not world authority.
Camera behavior must be specified in viewer terms and implemented by Bevy
Client without leaking presentation types into World Core.

### Reproducible camera state

Review and capture evidence records, as applicable:

- view/projection contract ID and version;
- target or center in the declared world/spatial reference;
- orientation, rotation, pitch, and vertical exaggeration;
- zoom or scale in a declared convention;
- viewport bounds, resolution, aspect ratio, and display scale factor;
- pointer position and input path for anchored interaction evidence;
- visible layer versions, selection, and diagnostic state;
- world/fixture identity, canonical revision, and query versions.

The exact coordinate representation and serialized camera-state schema remain
open.

### Prototype navigation requirements

For Prototype v0.1:

- panning and zooming must feel responsive and legible;
- cursor-centered zoom preserves the world point beneath a valid in-map pointer
  across the zoom transform within a measured tolerance;
- zoom response remains continuous, monotonic, finite, and clamped to explicit
  provisional bounds;
- discrete wheel and high-resolution trackpad events normalize into one
  documented semantic zoom intent rather than assuming raw platform units are
  equivalent;
- active gestures end safely on release, cancellation, focus loss, or window
  deactivation and cannot remain stuck;
- map input does not fire when another interface surface owns the pointer;
- panning, zooming, and camera bounds do not alter world identity or imply that
  observation physically changes the world.

The following are permitted reversible Client choices for evidence gathering,
not accepted Art direction:

- pan button/gesture, drag threshold, pointer capture, sensitivity, and optional
  smoothing;
- a direct-manipulation default in which the displayed world follows the drag;
- wheel/trackpad sign normalization, multiplicative zoom sensitivity and curve,
  and numeric minimum/maximum scale;
- center-of-viewport anchoring when no valid in-map pointer exists;
- whether a captured drag continues outside the viewport or cancels at its
  edge, provided focus loss always cancels.

Final bindings, inversion preferences, inertia, damping, acceleration,
projection, wrapping, rotation, tilt, bounds, zoom curve, and accessibility
settings remain open under `ART-D002`.

## Semantic zoom, render LOD, and canonical refinement

These mechanisms must remain distinct:

1. **Camera zoom** changes the view transform.
2. **Semantic zoom** changes presentation emphasis or encoding for a viewer.
3. **Render LOD and streaming** change disposable client representation and
   residency.
4. **Canonical refinement** is an authority-owned deterministic materialization
   of constrained world truth.

Semantic zoom may change symbol density, labels, aggregation, or visual
emphasis only through an accepted layer rule. It may not silently change units,
classification meaning, feature identity, or query provenance.

Observation may request or trigger canonical refinement later, but the view
must not depict that computational act as a physical geological event. Unloading
and reloading must not offer visual rerolls.

### Continuity requirements

Across pan, zoom, LOD, refinement, cache, and streaming changes:

- shared canonical features reconnect across domain boundaries;
- selected semantic identity remains stable or explicitly reports invalidation;
- adjacent coarse and fine views do not create false elevation, topology,
  category, color, pattern, temperature, or material seams;
- filtering and interpolation do not bridge no-data regions or invent
  sub-resolution certainty;
- loading, unavailable, coarse, unresolved, and failed states remain visually
  distinguishable;
- transition technique and duration do not conceal a semantic change.

Cross-fade, geomorphing, skirts, blending, prefetching, hysteresis, or another
implementation technique is not selected here.

## Picking and selection

Picking maps a screen-space intent through a declared view transform to a
world-space request and a semantic result:

```text
pointer / focus intent
→ client view transform
→ world position or query region
→ renderer-independent query
→ semantic identity and result version
→ client-owned feedback
```

For Prototype v0.1, click inspection displays world coordinates and the selected
provisional chunk and cell IDs. Until `WG-001` and `CORE-001` accept their
contracts, any stand-in grid or ID is diagnostic and provisional.

Selection feedback must distinguish hover, active selection, unavailable query,
and invalidated result when those states apply. It requires a non-color cue when
selection is necessary to complete the task. Final hit policy, priority among
overlapping surface/subsurface features, precision, label formatting, and
interaction feedback remain open.

## Layer and legend grammar

A future visual grammar must support, without prescribing their appearance:

- continuous quantities;
- categorical classifications;
- boundaries, paths, networks, vectors, regions, points, and topological
  relationships;
- uncertainty, confidence, range, constrained unresolved state, and data
  availability;
- present state versus provenance/history;
- physical layers versus computational diagnostics;
- player-facing meaning versus review/debug annotations.

Legends are part of the semantic contract. They record meaning, units,
classification version, visual range, uncertainty/no-data states, and scale
validity. A hidden palette convention is not an adequate legend.

The exact layer taxonomy, compositing order, blend behavior, symbol system,
labels, contours, patterns, and legend layout remain open.

## Required semantic review fixtures

World Generation and World Core provide representative data when their contracts
exist. These fixtures gate the affected semantic layers when those layers enter
scope; they are not all prerequisites for Prototype v0.1 camera navigation.
Art-facing fixtures should cover:

1. one canonical feature crossing multiple chunks and unequal neighboring
   representation levels;
2. legitimate zero, established truth, constrained-unresolved truth, truly
   unspecified information, coarse-but-valid data, unloaded/pending data,
   stale derived data, no data, out-of-scope information, and query failure;
3. a ground query with a cave, overhang, void, or multiple intersections;
4. a boundary or quantity whose meaning varies spatially rather than fitting one
   uniform label;
5. two commonly confused meanings, such as temperature versus gradient or
   trace concentration versus a future deposit classification;
6. actual geometry versus preferred response or disequilibrium;
7. selection at boundaries, corners, and representation transitions;
8. the same seed, canonical revision, and feature identity across several
   camera scales and reloads.

These are fixture requirements, not claims that the current prototype already
implements the corresponding world systems.

## Prototype camera evidence

Art acceptance of `CLIENT-001` requires:

- automated checks for anchor invariance, pan direction, input normalization,
  finite/clamped zoom, repeated zoom reversal, and extractable cancellation
  behavior;
- diagnostic capture of pan in four directions under the declared drag
  convention;
- cursor-anchor evidence at center, edges/corners, and low/mid/high provisional
  zoom;
- discrete-wheel and high-resolution trackpad evidence where available, with an
  explicit limitation and event-level checks for unavailable hardware;
- repeated input at both provisional bounds and smooth reversal away from them;
- pointer release, leave/re-enter, focus loss, outside-map, and UI-consumption
  behavior, using `N/A` with a reason where no UI surface exists;
- 1280×720 plus at least one narrower and one wider viewport, with display scale
  recorded;
- measured frame pacing and visible-stall observations during continuous pan
  and rapid zoom, without inventing an unaccepted numeric budget;
- a labelled diagnostic grid or marker if accepted world data is unavailable.

The evidence also records the OS, input backend/device, and Bevy version when
they can affect wheel, trackpad, pointer-capture, focus, or display behavior.

## Open decisions

Projection, datum, camera/view model, final navigation behavior, layer grammar,
ground-query depiction, semantic zoom, LOD transitions, picking hierarchy,
palette, symbols, labels, legends, and final UI composition remain open in
[Art Open Decisions](ART_OPEN_DECISIONS.md).

## ART-001 acceptance gates

Acceptance of this foundation required:

1. World Generation confirms that the truth stack, semantic registry, and
   fixtures preserve accepted world meaning.
2. Systems Architecture confirms the world/query/view separation.
3. Bevy Client confirms that the camera, picking, evidence, and continuity
   contracts are implementable without selecting the open mechanisms.
4. Art accepts the visual-semantics and accessibility requirements.
5. Dev Review clears blocking ambiguity or contradiction.
