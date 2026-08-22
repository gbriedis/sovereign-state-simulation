# Art and Technical Art Open Decision Inventory

- **Status:** Discovery inventory — not accepted visual direction or committed
  implementation
- **Foundation status:** Accepted inventory established by `ART-001`
- **Adopted:** 2026-08-22
- **Work packet:** `ART-001`
- **Inventory owner:** Art / Technical Art Lead
- **Last reviewed:** 2026-08-22

## Purpose

This file keeps unresolved Art and Technical Art choices visible without
allowing a plausible default, mockup, current engine behavior, or reference
image to become a silent decision.

It is not a backlog, priority order, implementation specification, or permission
to modify code or assets. Work begins only after the Project Steward creates or
activates a bounded packet with one DRI, write scope, dependencies, review gates,
and acceptance evidence. Material cross-domain choices receive an ADR under
[the decision process](../decisions/README.md).

The broader unresolved technical questions remain in
[Open Architecture Questions](../architecture/OPEN_DECISIONS.md). This inventory
records their Art-facing consequence and routes authority back to the owning
domain rather than answering them here.

## Decision-entry contract

When an item becomes actionable, its packet or ADR records:

- one decision question and accountable decision owner;
- affected viewer, mode, layers, assets, interfaces, and consumers;
- accepted product and domain constraints;
- options worth testing, including the current provisional behavior;
- prerequisites and the decision or work IDs that supply them;
- representative fixtures, prototypes, measurements, and accessibility checks;
- safe provisional behavior and rollback while the choice remains open;
- World Generation semantic, Systems/Client feasibility, Art, Marketing, Product,
  legal, and Dev Review gates as applicable;
- the canonical document that changes after acceptance.

An illustrative option is not a recommendation. An Art recommendation does not
accept a World Generation, Systems Architecture, Product, Marketing, or legal
decision.

Entries below may name several authorities because they own different
consequences. When an item is activated, its work packet or ADR names exactly
one accountable decision owner; the other authorities remain explicit review or
acceptance gates.

## Near-term prototype decisions

### ART-D001 — Prototype view model, projection, and datum presentation

- **State:** Open — blocked on spatial and surface-query inputs
- **Decision owners:** Systems Architecture for coordinate/projection boundary;
  World Generation for datum and query meaning; Art for accepted visual
  presentation
- **Needed for:** Stable land/water presentation, world-coordinate inspection,
  scale meaning, future global navigation, and reproducible camera evidence
- **Unresolved question:** Which view and projection contract communicates the
  provisional world honestly without preventing the accepted sparse 3D and
  Earth-like direction?
- **Inputs required:** Accepted `WG-001` coordinate, datum, spatial-ID, and
  query semantics; World Core feasibility; intended prototype extent and
  representative fixtures
- **Options to investigate:** 2D, 2.5D, or 3D presentation; orthographic or
  perspective view; planar/local, spherical, or projected world handling;
  seam, wrap, orientation, scale, and distortion disclosure
- **Evidence required:** Distance/area/direction distortion examples;
  land/water and selection fixtures near boundaries/seams; camera reproducibility;
  readable scale/reference treatment; implementation and performance evidence
- **Safe provisional behavior:** A labelled local 2D diagnostic view may be used
  without claiming a final global projection or datum
- **Acceptance gates:** World Generation semantic acceptance, Systems
  Architecture and Bevy Client feasibility, Art acceptance, Dev Review; Product
  only if the choice materially changes the player experience
- **Canonical outputs after acceptance:**
  [Map and Camera Language](MAP_AND_CAMERA_LANGUAGE.md) plus an ADR when the
  cross-domain consequence is material

### ART-D002 — Camera pan, zoom, focus, and picking interaction

- **State:** Open — `CLIENT-001` may gather reversible evidence in parallel
- **Decision owner:** Art for the interaction/visual contract; Bevy Client for
  implementation; Systems Architecture for boundary consequences
- **Needed for:** Prototype v0.1 smooth panning, cursor-centered zoom, and click
  inspection
- **Unresolved question:** Which bindings, direction conventions, zoom mapping,
  bounds, focus behavior, motion behavior, and selection feedback should become
  the accepted map-navigation language?
- **Inputs required:** Provisional camera implementation; `WG-001`/`CORE-001`
  identities when picking real data; accepted viewport and accessibility target
  profiles when available
- **Options to investigate:** Primary/middle/alternate drag; direct or inverted
  drag preference; discrete-wheel and high-resolution trackpad normalization;
  sensitivity and multiplicative curve; inertia/damping; center fallback;
  pointer capture/cancellation; keyboard and remapping paths
- **Evidence required:** Anchor-invariance and bounds tests; four-direction pan;
  center/edge/corner zoom; wheel/trackpad paths; focus-loss and pointer ownership;
  narrow/wide/high-DPI viewports; frame-pacing measurements; limitations
- **Safe provisional behavior:** Client may use the reversible defaults and
  evidence contract in [Map and Camera Language](MAP_AND_CAMERA_LANGUAGE.md);
  numeric tuning and bindings remain provisional
- **Acceptance gates:** Art visual acceptance of the actual result, Bevy Client
  evidence, Systems boundary check, Dev Review; World Generation when picking
  or displayed coordinates use an accepted semantic contract
- **Canonical outputs after acceptance:**
  [Map and Camera Language](MAP_AND_CAMERA_LANGUAGE.md), relevant Client tests,
  and the `CLIENT-001` review record

### ART-D003 — First prototype layers, diagnostics, legend, and selection grammar

- **State:** Open — semantic contracts incomplete
- **Decision owners:** World Generation for land/water, coordinates, chunks,
  samples, ranges, and uncertainty; Art for encoding and legend; Bevy Client for
  implementation
- **Needed for:** Clear land against water and click display of world
  coordinates plus provisional chunk/cell IDs
- **Unresolved question:** Which minimum player-facing and diagnostic layer set
  proves the prototype while keeping provisional infrastructure visibly
  distinct from physical truth?
- **Inputs required:** `WG-001` and `CORE-001` semantic/query contracts,
  representative seed fixtures, missing/no-data behavior, query versions, and
  accepted view assumptions
- **Options to investigate:** Base land/water treatment; optional outlines or
  contours; diagnostic chunk/sample overlay; pointer/selection feedback;
  contextual legend and coordinate/ID readout
- **Evidence required:** Same-seed reproduction; clear land/water distinction;
  zero/no-data/pending/failure states; boundary selection; diagnostic labels;
  grayscale/color-vision and contrast checks; layer registry completeness
- **Safe provisional behavior:** A labelled synthetic land mask, grid, and
  marker may test camera behavior but cannot be presented as generated geology
- **Acceptance gates:** World Generation semantic acceptance, World Core and
  Systems contract feasibility, Bevy Client implementation evidence, Art
  acceptance, Dev Review
- **Canonical outputs after acceptance:**
  [Map and Camera Language](MAP_AND_CAMERA_LANGUAGE.md) and the first versioned
  semantic registry entries

### ART-D004 — Runtime palette, contrast, and uncertainty channels

- **State:** Open — no accepted runtime palette
- **Decision owner:** Art; Marketing consulted where brand motifs are reused;
  Bevy Client confirms runtime feasibility
- **Needed for:** Accessible base map, overlays, selection, status, and evidence
- **Unresolved question:** Which color and redundant-channel system remains
  legible across layers, uncertainty, display contexts, and color-vision needs?
- **Inputs required:** First accepted layer meanings and compositing cases;
  target display profiles; contrast and accessibility criteria
- **Options to investigate:** Luminance hierarchy, categorical and sequential
  families, patterns/hatching, line and shape redundancy, dark/light contexts,
  controlled use or rejection of brand colors
- **Evidence required:** Measured contrast, grayscale, representative
  color-vision-deficiency views, simultaneous-layer stress tests, selection and
  uncertainty cases, narrow/wide/high-DPI captures
- **Safe provisional behavior:** Current or exploratory colors remain labelled
  implementation/concept defaults and carry no palette authority
- **Acceptance gates:** Art accessibility and visual acceptance, Bevy Client
  feasibility, semantic-owner review of encoded ranges/classes, Marketing
  boundary review if public brand colors are adopted, Dev Review
- **Canonical outputs after acceptance:**
  [Art Direction](ART_DIRECTION.md), layer registry, and a future token/palette
  artifact in its own packet

## World-view and cross-scale decisions

### ART-D005 — Ground, seafloor, water, ice, and subsurface presentation

- **State:** Open — surface-query and domain ownership unresolved
- **Decision owners:** World Generation for semantic surfaces and query policy;
  Art for visual presentation; Systems/Client for feasible views
- **Needed for:** Honest elevation, bathymetry, terrain, cross-section, cave, and
  later surface-layer presentation
- **Unresolved question:** Which semantic surface is shown in each view, and how
  are multiple intersections and distinct overlying domains communicated?
- **Inputs required:** Accepted ground-material domain, datum, surface-query
  behavior, water/ice/other domain ownership, multi-intersection fixtures, and
  query uncertainty
- **Options to investigate:** Selected surface map, explicit multi-surface
  inspection, cross-section, local 3D inspection, separate water/ice/ground
  layers, disclosed vertical exaggeration
- **Evidence required:** Cave/overhang/void fixtures; ground versus seafloor,
  water, and ice cases; datum/depth labels; missing/unresolved surfaces;
  projection and picking behavior
- **Safe provisional behavior:** A labelled derived prototype land mask may show
  land against water without being called canonical terrain or the final ground
  query
- **Acceptance gates:** World Generation semantic acceptance, Systems/World Core
  query feasibility, Bevy Client implementation feasibility, Art acceptance,
  Dev Review
- **Canonical outputs after acceptance:**
  [Map and Camera Language](MAP_AND_CAMERA_LANGUAGE.md), relevant World
  Generation query document, and an ADR where required

### ART-D006 — Semantic zoom, render LOD, streaming, and refinement continuity

- **State:** Open — hierarchies, queries, and runtime budgets unresolved
- **Decision owners:** Art for presentation/continuity; World Generation for
  canonical refinement meaning; Bevy Client for render LOD/streaming; Systems
  Architecture for shared boundaries
- **Needed for:** Stable world identity and legibility from broad map views to
  future local inspection
- **Unresolved question:** What may change visually at each scale, and how are
  pending, coarse, fine, streamed, cached, and canonically refined states
  distinguished without false seams or events?
- **Inputs required:** Accepted query aggregation and scale validity; refinement
  identity/version contract; performance profiles; representative cross-domain
  and mixed-detail fixtures
- **Options to investigate:** Layer appearance/disappearance, aggregation,
  decluttering, label density, transition and hysteresis techniques, render LOD
  families, loading/fallback treatments
- **Evidence required:** One feature across chunks and unequal detail; stable
  selection; pan/zoom/reload cycles; seam and topology checks; no-data and
  pending states; performance/frame-pacing traces
- **Safe provisional behavior:** Camera zoom may change only the view transform;
  diagnostic representation changes are labelled and cannot claim canonical
  refinement
- **Acceptance gates:** World Generation semantic acceptance, Systems/World Core
  contract feasibility, Bevy Client implementation evidence, Art continuity and
  accessibility acceptance, Dev Review
- **Canonical outputs after acceptance:**
  [Map and Camera Language](MAP_AND_CAMERA_LANGUAGE.md),
  [Technical Art Pipeline](TECHNICAL_ART_PIPELINE.md), and affected query/Client
  contracts

### ART-D007 — Typography, symbols, labels, and legend system

- **State:** Open — depends on layer grammar and target profiles
- **Decision owner:** Art; Marketing consulted for shared identity; Bevy Client
  confirms text/symbol implementation
- **Needed for:** Coordinates, IDs, quantities, classifications, legends,
  selection, warnings, and later player-facing map meaning
- **Unresolved question:** Which runtime typography and symbol grammar remains
  readable, scalable, localizable, and semantically distinct from external brand
  applications?
- **Inputs required:** Accepted layer registry, units/formatting, target scripts
  and localization direction when scoped, viewport/display profiles, font rights
- **Options to investigate:** Runtime font families, size/weight hierarchy,
  symbols and line conventions, label collision/priority, unit formatting,
  legend placement and disclosure
- **Evidence required:** Small/large/high-DPI views, dense labels, missing glyphs,
  category and uncertainty cases, grayscale/color-vision checks, font
  provenance and runtime cost
- **Safe provisional behavior:** Engine/default diagnostic text may display
  prototype values but is not accepted runtime typography
- **Acceptance gates:** Art accessibility/visual acceptance, semantic-owner
  formatting review, Bevy Client and Rust Platform feasibility, Marketing
  external-identity boundary review as affected, separate rights/legal review
  as affected, Dev Review
- **Canonical outputs after acceptance:** Future runtime type/symbol standards
  and affected layer registry entries

## Technical-art production decisions

### ART-D008 — Shader, material, texture, mesh, and procedural surface language

- **State:** Open — blocked on view model, layers, target profiles, and evidence
- **Decision owners:** Art / Technical Art for the visual/material contract;
  Bevy Client for runtime implementation; Rust Platform for dependency/build
  consequences
- **Needed for:** Any treatment beyond basic procedural prototype geometry
- **Unresolved question:** Which render and asset techniques communicate the
  accepted layers at the lowest justified runtime and production cost?
- **Inputs required:** `ART-D001`, `ART-D003`, `ART-D004`, representative camera
  scales, platform profiles, semantic inputs, and measured prototype evidence
- **Options to investigate:** Unlit/cartographic, PBR, or hybrid materials;
  authored textures, procedural patterns, vector/procedural geometry, or mixed
  approaches; lighting and atmosphere only when required
- **Evidence required:** Semantic-input audit; close/far and multi-layer test
  cards; accessibility; filtering/seam checks; GPU/CPU/memory/loading measures;
  fallback behavior; source and rights provenance
- **Safe provisional behavior:** Procedural lines, polygons, symbols, and
  engine-generated geometry may support the prototype; no Blender, texture set,
  or custom shader is presumed
- **Acceptance gates:** Art/Technical Art acceptance, Bevy Client and Rust
  Platform feasibility, World Generation semantic review for world-driven
  effects, Dev Review, separate rights/legal review for third-party assets, and
  Marketing external-use review for public applications as affected
- **Canonical outputs after acceptance:**
  [Technical Art Pipeline](TECHNICAL_ART_PIPELINE.md), material/shader contracts,
  and separately scoped runtime/asset packets

### ART-D009 — Authoring tools, formats, repository layout, and import pipeline

- **State:** Open — no production asset family yet requires a choice
- **Decision owner:** Technical Art; Rust Platform owns build/CI policy; Bevy
  Client owns importer/runtime integration
- **Needed for:** First authored or third-party runtime asset and reproducible
  world-derived product family
- **Unresolved question:** Which source, interchange, runtime, manifest, build,
  and generated-art conventions meet editing, rights, determinism, portability,
  and recovery needs?
- **Inputs required:** Accepted asset family and consumers; target platforms;
  tool/dependency policy; rights/provenance requirements; repository-size and
  build constraints
- **Options to investigate:** DCC/image/vector tools; source/interchange/runtime
  formats; committed versus generated exports; manifest representation; color
  management; importer/build/validation integration
- **Evidence required:** Round-trip/re-export; deterministic output where
  required; import/runtime proof; licence/provenance completeness; repository and
  build cost; fallback/migration/recovery exercise
- **Safe provisional behavior:** Keep ART-001 documentation-only and introduce
  no binary, tool, format, path hierarchy, dependency, or CI requirement
- **Acceptance gates:** Technical Art acceptance, Bevy Client and Rust Platform
  feasibility, Systems boundary check, legal review when needed, Dev Review
- **Canonical outputs after acceptance:**
  [Technical Art Pipeline](TECHNICAL_ART_PIPELINE.md), a manifest/schema or ADR,
  and tool-specific packets

### ART-D010 — Target profiles, visual budgets, and degradation order

- **State:** Open — no measured workload or accepted device target
- **Decision owners:** Product for material platform scope; Systems Architecture,
  Bevy Client, and Rust Platform for performance contracts; Art for visual and
  accessibility consequences
- **Needed for:** Pass/fail thresholds for frame pacing, memory, assets, layers,
  LOD, streaming, text, and capture
- **Unresolved question:** Which target profiles and budgets preserve the
  intended experience, and what degrades first when a profile is constrained?
- **Inputs required:** Measured representative scenes, platform/product target,
  camera/layer contracts, accessibility needs, build profiles, and capture use
- **Options to investigate:** Resolution/DPI/aspect profiles; frame-time and
  memory envelopes; layer/feature density; texture/mesh/generated-product
  budgets; fallback and quality levels
- **Evidence required:** CPU/GPU frame time and pacing, query versus render
  latency, memory/residency, upload/compile/loading stalls, draw/geometry cost,
  visual comparisons, accessibility at each degradation level
- **Safe provisional behavior:** Record measurements and visible failures without
  inventing a pass threshold
- **Acceptance gates:** Product when platform scope changes, Systems/Client/
  Platform feasibility, Art visual/accessibility acceptance, Dev Review
- **Canonical outputs after acceptance:** Performance architecture/ADR and
  [Technical Art Pipeline](TECHNICAL_ART_PIPELINE.md) profile references

### ART-D011 — Visual regression, gameplay capture, and evidence packaging

- **State:** Open — minimum handoff fields accepted; tooling and thresholds open
- **Decision owners:** Art for visual acceptance/fidelity; Bevy Client for build
  verification; Marketing for external brief/use; Product Owner for publication
- **Needed for:** Reproducible Art review, regression detection, honest private
  capture, and later public evidence
- **Unresolved question:** Which fixtures, capture state, comparison method,
  tolerances, storage, and approval record make visual claims reproducible and
  maintainable?
- **Inputs required:** Accepted view/layer/pipeline versions; representative
  fixtures; target profiles; Marketing capture brief when applicable
- **Options to investigate:** Still and motion test cards; exact/reference or
  perceptual comparison; metric overlays; automated or manual capture; storage
  and retention policy
- **Evidence required:** Repeat capture from pinned seed/fixture, world/query/
  style/build revisions, camera/viewport/profile state, limitations, rights,
  gameplay/diagnostic/concept classification, and reviewer acknowledgement
- **Safe provisional behavior:** Manual pinned captures may serve as review
  evidence; concept or AI-generated imagery remains clearly non-gameplay
- **Acceptance gates:** Art fidelity acceptance, Bevy Client verification,
  Marketing claims/brand/rights review for external use, Product approval for
  publication or external commitment, Dev Review for automation/contracts
- **Canonical outputs after acceptance:**
  [Technical Art Pipeline](TECHNICAL_ART_PIPELINE.md), capture/evidence standard,
  and Marketing's private capture brief as affected

## Later player-surface decisions

### ART-D012 — In-game and external-brand relationship

- **State:** Open — no runtime visual system exists to compare
- **Decision owners:** Art for in-game adoption; Marketing for external identity;
  Product Owner for material master-brand change
- **Needed for:** Consistent but non-confused runtime, capture, store, campaign,
  and community applications
- **Unresolved question:** Which brand motifs, colors, typography, and compositional
  principles should enter the game, and which remain external-only?
- **Inputs required:** Accepted runtime palette/type/layer system, tested brand
  applications, accessibility and performance evidence, capture use cases
- **Options to investigate:** Shared motifs with separate systems; selective
  token adoption; intentionally distinct in-game and campaign treatments
- **Evidence required:** Side-by-side runtime and external applications;
  accessibility; semantic conflicts; player comprehension; provenance/rights;
  capture fidelity
- **Safe provisional behavior:** Treat the brand direction as inspiration and
  constraint, not as runtime palette/type specification
- **Acceptance gates:** Art and Marketing boundary acceptance, Bevy Client
  feasibility, Product Owner for material identity change, Dev Review as needed
- **Canonical outputs after acceptance:**
  [Art Direction](ART_DIRECTION.md),
  [Brand Foundation](../brand/BRAND_FOUNDATION.md), or a scoped application
  standard according to ownership

### ART-D013 — Final player-facing map interface composition

- **State:** Deferred — Prototype v0.1 explicitly excludes polished UI
- **Decision owners:** Product for player tasks and scope; Art for visual and
  interaction language; Bevy Client for implementation
- **Needed for:** Later contextual inspection, governance, overlays, timelines,
  autonomous-actor feedback, and country-as-progression experience
- **Unresolved question:** How should map, contextual panels, tools, time,
  notifications, selection, and future player authority compose without
  becoming a dashboard-first or omnipotent-cursor interface?
- **Inputs required:** Demonstrated natural-world map, accepted player systems,
  information architecture, input/accessibility targets, and user evidence
- **Options to investigate:** Contextual map-attached controls, panels, modes,
  timelines, and other compositions after their gameplay tasks exist
- **Evidence required:** Task flows, prototypes using demonstrated data,
  comprehension/accessibility studies, viewport/input profiles, performance,
  and Product acceptance
- **Safe provisional behavior:** Keep prototype controls and diagnostics minimal,
  labelled, and non-authoritative as final UI direction
- **Acceptance gates:** Product, Art, Bevy Client, affected semantic domains,
  accessibility review, Dev Review; Marketing only for external capture/use
- **Canonical outputs after acceptance:** A future player-interface work packet
  and focused design/decision documents

## Unscheduled Art discovery

The following topics remain unscheduled until a recurring need supplies an
owner and evidence:

- natural-world lighting, atmosphere, weather, water, ice, vegetation, and
  surface-process art direction;
- subsurface and geological-history exploration beyond diagnostic fixtures;
- architecture, people, infrastructure, culture, and historical-era direction;
- animation, VFX, audio-visual coordination, and cinematics;
- localization, user customization, modding, and user-generated visual content;
- key art, store capsules, public reveal, and campaign production.

Their presence here does not expand the current natural-world or ART-001 scope.

## Review and maintenance

World Generation reviews entries that depend on physical meaning. Systems
Architecture, World Core, Bevy Client, and Rust Platform review feasibility and
ownership where affected. Marketing reviews external-brand and capture
boundaries. Art maintains the inventory and ensures a mockup cannot close an
item by implication.

After a decision is accepted, link its ADR or accepted packet here, update the
focused canonical documents, and remove or mark the open question resolved
without deleting the preserved rationale.
