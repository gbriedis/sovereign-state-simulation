# In-Game Art Direction Foundation

- **Status:** Accepted foundation
- **Adopted:** 2026-08-22 through `ART-001`
- **Work packet:** `ART-001`
- **Accountable owner:** Art / Technical Art Lead
- **Scope:** In-game visual direction for the natural-world foundation and
  Prototype v0.1
- **Decision boundary:** Foundation requirements only; unresolved visual choices
  remain in [Art Open Decisions](ART_OPEN_DECISIONS.md)

## Purpose

This document defines what the in-game visual language must accomplish before a
specific style is selected. It does not choose a palette, typeface, projection,
camera model, map-layer taxonomy, shader, material, texture, mesh treatment, or
player-interface composition.

The foundation translates the accepted [Project Vision](../PROJECT_VISION.md),
[Design Principles](../DESIGN_PRINCIPLES.md), architecture, and World Generation
meaning into Art requirements. It cannot make an unresolved product, physical,
or implementation choice true by depicting it.

## Decision language

The following labels apply throughout the Art foundation:

- **Foundation requirement** — normative after `ART-001` is accepted.
- **Provisional implementation** — reversible behavior used to gather evidence;
  it is not accepted Art direction.
- **Illustrative** — an example that carries no decision authority.
- **Open** — requires the owner, evidence, and gates recorded in
  [Art Open Decisions](ART_OPEN_DECISIONS.md).

Mockups, reference images, current runtime defaults, and generated captures do
not change those states by existing.

## Product grounding

### The map is the primary game surface

The player should experience a place rather than operate a dashboard with a map
attached. Geography and the country that eventually develops across it are the
principal carriers of state, change, and consequence. Contextual panels may
support the map, but Art must not make them the default progression surface.

The current phase contains no nations, settlements, politics, or economies.
`ART-001` establishes a natural-world visual foundation and must not fabricate
later civilization content to make the prototype look complete.

### The world should have visible reasons

Visual treatment should help a viewer connect present conditions to meaningful
causes, measurements, classifications, uncertainty, and retained history. It
must not turn a causal simulation into unrelated decorative layers or arbitrary
levels.

Art may organize and simplify information for a viewer. It may not invent a
physical relationship, imply precision the query does not provide, or present a
derived classification as a more fundamental fact than its semantic owner has
accepted.

### Influence is not omnipotence

Later player-facing visual language must support governing autonomous systems,
not imply that everything on the map is a direct cursor-owned object. Selection,
highlighting, and future command feedback must distinguish inspection,
influence, authority, prediction, and completed change when those concepts enter
scope. Their exact treatment remains open.

## Foundation requirements

### 1. Presentation remains downstream of truth

Canonical world and simulation meaning belongs to the renderer-independent
domain. Meshes, rasters, heightmaps, textures, shaders, symbols, labels, LODs,
GPU resources, screenshots, and client caches are derived presentation.
Deleting or replacing one must not alter world truth.

Every visual encoding of a world quantity or classification requires a named
semantic owner and a versioned query or fixture contract. Color, texture,
geometry, opacity, animation, or a label must never become the only place where
the represented meaning exists.

### 2. Visible meaning is explicit

A viewer must be able to distinguish, where relevant:

- canonical present state;
- compact causal provenance or history;
- a derived quantity or classification;
- a computational diagnostic such as a chunk, sample, cache, or refinement
  boundary;
- established truth, constrained unresolved truth, and truly unspecified
  information;
- coarse but valid representation, unloaded or pending data, stale derived
  data, query failure, out-of-scope information, no data, and a legitimate zero;
- player-facing, diagnostic, review, concept, and capture artifacts.

The exact visual grammar is open, but these states may not silently collapse
into the same blank, transparent, dark, or water-like appearance.

### 3. Physical and computational boundaries stay distinct

Geological features retain identity across spatial domains and representation
levels. A chunk is computational locality; a cell is a system-specific sample;
neither is a geological object.

Chunk, tile, cache, streaming, or refinement boundaries must not read as
physical seams unless a diagnostic view deliberately displays them and labels
their infrastructure meaning. Finer presentation may reveal compatible detail,
but it must not make observation look like the physical cause of new geology or
offer a visual reroll.

### 4. Scale changes preserve semantic identity

Zoom, semantic zoom, render LOD, streaming, and canonical refinement are
different mechanisms. Across any of them:

- established feature identity and selection remain stable;
- classifications do not change without a versioned semantic reason;
- aggregation does not invent sub-resolution precision;
- coarse and fine neighbors do not contradict one another or create seams;
- a transition communicates pending, coarse, or changed representation without
  depicting a physical event that did not occur.

Specific zoom bands, thresholds, transition techniques, and budgets remain
open.

### 5. Accessibility is part of visual correctness

Color alone must not carry a required distinction. Depending on the task and
scale, redundant channels may include luminance, pattern, line treatment,
shape, symbol, label, position, or interaction feedback.

Visual acceptance requires evidence appropriate to the surface, including:

- measured contrast for relevant base, overlay, text, hover, focus, and
  selection states;
- grayscale and representative color-vision-deficiency checks;
- legibility at supported viewport sizes, display scale factors, and zoom
  contexts;
- non-color differentiation for required categories, uncertainty, and
  selection;
- readable motion and a documented reduced-motion or non-animated behavior
  where animation carries information;
- input-focus and non-pointer limitations recorded rather than hidden.

Exact numeric standards and target profiles are open until Product, Art, Bevy
Client, and Systems Architecture accept them. Lack of a numeric threshold does
not permit unreviewed color-only meaning or unreadable evidence.

### 6. Fidelity includes continuity and performance

A visually polished still is insufficient when motion, frame pacing, query
latency, loading, shader compilation, or LOD transitions break comprehension.
Art acceptance examines the implemented surface under representative pan, zoom,
selection, loading, and aspect-ratio conditions.

Numeric frame, memory, texture, geometry, and streaming budgets require measured
Client and Platform evidence. Art defines the visual consequence and acceptable
degradation behavior; it does not choose the runtime architecture or fabricate a
budget.

### 7. Reproducible evidence outranks an attractive anecdote

A review image or capture must identify enough state to reproduce its visual
claim:

- work and head revision;
- world seed or fixture and compatible generator/ruleset version;
- canonical revision and query or schema version;
- projection, datum, camera, zoom, viewport, display scale, and layer state;
- asset, material, shader, style, and pipeline versions;
- relevant LOD, refinement, streaming, and cache state;
- intended evidence mode and known limitations.

Concept imagery and AI-generated imagery must be labelled as such and must never
be presented as implemented gameplay.

## Evidence modes

| Mode | Purpose | Required truth boundary |
| --- | --- | --- |
| Player-facing | Communicate information and interaction intended for play | Uses only accepted player meanings and clearly marks provisional behavior |
| Diagnostic | Inspect generation, queries, partitions, performance, or implementation | Labels infrastructure and debug quantities so they cannot be mistaken for physical ontology |
| Review | Prove a scoped visual or technical-art acceptance condition | Pins revisions, fixtures, settings, reproduction steps, and limitations |
| Capture | Record implemented gameplay for an approved internal or Marketing use | Requires Art fidelity acknowledgement and implementing-lane verification before Marketing use |
| Concept / exploration | Investigate an unresolved direction | Cannot be described as gameplay, acceptance evidence, or a decided visual contract |

One artifact may support more than one mode only when each intended use and its
limitations are explicit.

## Relationship to brand direction

The accepted public brand is cartographic, institutional, human, and
history-bearing. Its contours, watersheds, boundaries, networks, and change over
time are useful inputs. They are not automatic runtime decisions.

The brand palette is not the player-interface palette, public typography does
not select runtime fonts, and campaign composition does not define the game
camera. Art owns in-game adoption; Marketing owns external identity and use.
Any shared motif must pass in-game semantic, accessibility, feasibility, and
performance review independently.

## Visual acceptance rubric

A visual result is accepted only when the applicable evidence supports all of
the following:

| Dimension | Acceptance question | Required owner |
| --- | --- | --- |
| Semantic honesty | Does the depiction preserve definitions, units, ranges, uncertainty, missing-data behavior, scale, and canonical-versus-derived meaning? | World Generation or other semantic owner |
| Visual semantics | Can the intended viewer correctly distinguish the required states and relationships? | Art & Technical Art |
| Task legibility | Can the intended task be completed without reconstructing hidden meaning? | Art plus owning Product/Client lane |
| Accessibility | Do required distinctions survive the accepted contrast, color, scale, motion, and input checks? | Art plus affected implementation owner |
| Continuity | Do camera, zoom, LOD, streaming, and refinement changes preserve identity and avoid false seams or events? | Art plus World Generation/Client as affected |
| Feasibility | Is the contract implementable inside accepted architecture and measured constraints? | Systems Architecture, Bevy Client, and Rust Platform as affected |
| Reproducibility | Can another reviewer recreate the result from pinned inputs and revisions? | Workstream DRI and reviewer |
| Provenance | Are source, rights, tool versions, transformations, and generated status traceable? | Technical Art; legal/Marketing gates remain separate |

Passing Art review does not replace semantic, implementation, Product, legal,
Marketing, or release authority.

## Explicitly open direction

The following remain open and are routed through
[Art Open Decisions](ART_OPEN_DECISIONS.md):

- final visual character, realism, abstraction, lighting, atmosphere, and
  material treatment;
- runtime palette, typography, iconography, symbols, labels, and legends;
- projection, camera model, orientation, tilt, rotation, zoom behavior, and
  picking feedback;
- player-facing layer and overlay taxonomy, semantic-zoom behavior, and final
  interface composition;
- ground, water, ice, subsurface, cross-section, and multiple-surface
  presentation;
- shader, material, texture, mesh, procedural-art, DCC, and asset-format choices;
- platform profiles, visual-quality targets, budgets, and degradation policy;
- final relationship between in-game presentation and public brand applications.

No current Bevy default, illustrative example, mockup, or reference image is an
answer to these questions.

## ART-001 acceptance gates

Acceptance of this foundation required:

1. World Generation accepts the semantic-honesty boundary.
2. Systems Architecture and Bevy Client accept the implementation boundary.
3. Marketing accepts the in-game versus external-visual boundary.
4. An independent Art review confirms that open choices remain open.
5. Dev Review clears blocking contradictions and missing evidence.
