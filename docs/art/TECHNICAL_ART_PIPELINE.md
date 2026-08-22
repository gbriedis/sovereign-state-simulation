# Technical Art Pipeline Foundation

- **Status:** Accepted foundation
- **Adopted:** 2026-08-22 through `ART-001`
- **Work packet:** `ART-001`
- **Accountable owner:** Art / Technical Art Lead
- **Scope:** Asset, material, shader, generated-presentation, validation, and
  evidence contracts
- **Decision boundary:** Lifecycle and ownership requirements only; tools,
  formats, schemas, budgets, and runtime implementation remain open

## Purpose

This document defines how Art inputs and world-derived presentation products
must remain reproducible, reviewable, and separate from canonical world truth.
It does not introduce an asset, dependency, DCC tool, shader, material, texture,
mesh, importer, directory layout, CI job, or Bevy implementation.

At base `9578f280205d07c5ef1a2468c25f20f4f398a622`, the demonstrated client is a
provisional Bevy 2D window and camera. The repository has no accepted runtime
Art assets, custom shaders, materials, texture set, terrain geometry, asset
pipeline, or world-derived render product. Current window dimensions, theme,
clear color, and Bevy defaults are implementation evidence, not Art direction.

## Governing pipeline

```text
semantic contract or Art requirement
        ↓
editable source / generator source
        ↓ controlled transform
interchange or export artifact
        ↓ validation / build integration
runtime asset or world-derived render product
        ↓ loading / LOD / cache / GPU representation
implemented view
        ↓ pinned capture
review evidence
```

Every arrow is a traceable transformation. A runtime result must be attributable
to its semantic inputs, source, tools, settings, and versions. Generated and
cached artifacts remain reproducible or explicitly disposable.

## Artifact classes

| Class | Purpose | Authority and retention |
| --- | --- | --- |
| Editable source | Human- or tool-authored working source with the information needed to revise an asset | Art-owned source; not assumed loadable at runtime |
| Interchange/export | Deterministic or controlled output passed between tools or into the build | Rebuildable from pinned source and settings where practical |
| Runtime asset | Format and variants consumed by the Client | Presentation only; versioned and replaceable without changing world truth |
| World-derived render product | Raster, mesh, contour, vector, tile, buffer, or other product generated from a world query | Derived from pinned world/query/style inputs; never source Art or canonical state |
| Disposable cache/GPU representation | Residency, compiled, batched, mip, LOD, or device-specific data | May be invalidated and regenerated; cannot be sole holder of meaning |
| Reference/test evidence | Test card, approved reference state, screenshot, footage, measurement, or comparison | Pins the state needed to reproduce an acceptance claim |
| Concept/exploration | Image or artifact used to investigate an unresolved direction | Labelled non-gameplay; cannot prove implementation or acceptance |
| Marketing application | External identity, campaign, capsule, or publication asset | Marketing-owned use; gameplay components still require Art fidelity and implementation verification |

A single binary must not silently serve several classes. If a source file is
also committed as a runtime artifact, both roles and their update rules must be
explicit.

## Source, export, and runtime separation

For each Art-controlled asset or generated presentation family, the eventual
pipeline must identify:

- the authoritative editable source, when one exists;
- deterministic generator source and inputs, when generated;
- export/interchange products and whether they are committed or rebuilt;
- runtime products and platform variants;
- disposable caches and generated directories;
- reference evidence and the accepted visual contract it proves;
- ownership, review trigger, replacement, migration, and retirement behavior.

Exact repository paths and generated-file policy remain open under `ART-D009`.
ART-001 creates no binary artifacts and requires no DCC installation.

## Asset and generated-product manifest requirements

The eventual manifest representation is open, but each applicable artifact
must carry or link the following fields:

| Field | Requirement |
| --- | --- |
| Stable identity | Asset/product ID, version, semantic role, owner, lifecycle state, and replacement/supersession link |
| Origin and provenance | Authored, commissioned, third-party, generated, or AI-assisted status; creator/source; source location; retrieval or creation date |
| Rights | Licence text or identifier, allowed-use evidence, attribution obligations, modification/redistribution constraints, and separate legal review where required |
| Source environment | Source path, authoring/generator tool and version, plug-ins, scripts, fonts, and other required dependencies |
| Transform | Export command or procedure, settings, coordinate/unit transforms, color-space conversions, packing, naming, and deterministic inputs |
| Runtime product | Runtime path or logical ID, format, dimensions, variants, material/shader schema compatibility, import settings, and checksum/content version |
| Semantic inputs | Semantic registry entry, world/fixture identity, canonical revision, query/schema version, spatial reference, range/classification version, and style version as applicable |
| Presentation behavior | Scale validity, filtering/interpolation policy, no-data and fallback behavior, LOD/streaming relationships, and known discontinuity risk |
| Constraints | Target platform/profile, viewport context, accessibility notes, measured size/cost, and accepted budget reference when one exists |
| Validation | Automated checks, visual fixtures, reproduction steps, reviewer, result, date, limitations, and regeneration/recovery procedure |

An artifact is not production-ready merely because an engine can import it.

## World-derived presentation products

Land masks, elevation samples, map rasters, contours, geological overlays,
terrain meshes, cross-sections, vector fields, layer textures, and similar
outputs are query products. Their cache identity includes, as applicable:

```text
world identity
+ generator / ruleset version
+ canonical revision
+ query and schema version
+ semantic classification / range version
+ spatial reference and query extent
+ sample support / representation level
+ projection and view assumptions
+ style / material / shader version
+ runtime pipeline version
```

Changing a semantic input invalidates affected derived output even if the file
name or screen appearance happens to remain similar.

Filtering, interpolation, procedural noise, texture detail, normal treatment,
or shader effects must not:

- bridge no-data or unloaded regions without an accepted rule;
- invent sub-resolution geology or false certainty;
- change a category's meaning;
- turn a smooth visual blend into a claim of smooth physical transition;
- create chunk, tile, LOD, refinement, or artificial material-contact seams;
- erase or change stable feature identity and selection;
- encode authoritative meaning only in pixels, vertices, or shader state.

World Generation accepts semantic transformation and aggregation. Technical Art
accepts visual reproducibility, continuity, and accessibility. Neither review
replaces the other.

## Shader and material contract

A future shader or material consumes versioned presentation inputs. It must not
infer an undocumented physical classification from color, texture names, mesh
topology, or incidental numeric ranges.

An accepted shader/material family requires:

- declared semantic inputs, units/ranges or class versions, uncertainty and
  no-data behavior;
- parameter meanings, defaults, valid bounds, color spaces, and precision;
- material/shader/schema and engine compatibility versions;
- layer compositing and transparency/depth assumptions;
- LOD, streaming, fallback, and unsupported-device behavior;
- accessibility consequences and redundant encodings;
- representative fixtures, compilation/runtime checks, performance evidence,
  and visual acceptance.

PBR, unlit/cartographic, hybrid, lighting, atmosphere, water, terrain,
subsurface, and post-processing approaches remain open. The current Bevy 2D
feature set does not imply acceptance of any shader stack or permission to add
features and dependencies without Client and Rust Platform review.

## Texture, mesh, and procedural-detail policy

No asset earns acceptance through nominal resolution or polygon count. Use the
least costly representation that passes the accepted visual, accessibility, and
continuity evidence at its intended camera scales and target profile.

Accordingly:

- a `4K` label is neither a quality requirement nor proof of suitability;
- texture dimensions, texel density, tiling, atlasing, mip behavior,
  compression, color space, and channel packing remain measured decisions;
- mesh density, topology, simplification, collision/picking relationship, and
  LOD generation remain measured decisions;
- procedural detail may enrich a presentation but may not imply unsupported
  world detail or hide query uncertainty;
- Blender or another DCC tool becomes a dependency only when an accepted visual
  contract and pipeline evaluation justify it;
- Prototype v0.1 may be investigated with procedural lines, polygons, symbols,
  or engine-generated geometry without requiring external textures or models.

These statements do not select a final 2D, 2.5D, or 3D representation.

## Third-party and zero-cost assets

Price alone does not establish usable rights or production fitness. Before a
third-party asset enters the repository or runtime, record its source,
creator, licence, licence evidence, allowed use, attribution, modification and
redistribution terms, included source files, technical properties, and review
status.

The project may prefer no-cost sources, procedural generation, or original
assets, but this document does not approve a provider, licence interpretation,
download, or asset. Ambiguous "free" or personal-use-only material is not an
acceptable provenance record. Legal clearance remains outside Art authority.

AI-assisted or generated assets require tool/model and workflow provenance,
human review, rights/risk recording, and clear concept-versus-gameplay status.
They cannot be presented as gameplay until they are integrated and captured
from the verified build.

## LOD, streaming, and degradation contract

Art defines what visual meaning and continuity must survive under constrained
runtime conditions. Bevy Client and Rust Platform own how the implementation
meets that contract.

For each applicable asset or generated-product family, later accepted work
records:

- representation levels and the semantic information preserved at each;
- transition and selection-stability criteria;
- loading, fallback, missing, stale, and failure treatments;
- cache identity, invalidation, residency, and regeneration behavior;
- device/profile-specific variants and degradation order;
- measured CPU, GPU, memory, upload, storage, and frame-pacing evidence;
- known cases in which fidelity cannot be maintained.

No quadtree, octree, tile pyramid, cache strategy, prefetch radius, mip policy,
cross-fade, geomorph, or streaming technique is selected here.

## Validation stages

The eventual pipeline validates in proportion to the artifact:

### 1. Provenance and manifest validation

- identity, owner, source, rights evidence, versions, and required fields exist;
- references resolve and replacements do not orphan consumers;
- generated and third-party status is explicit.

### 2. Source/export validation

- the required tool/version can open or reproduce the source;
- units, coordinates, transforms, color spaces, alpha, naming, and export
  settings are explicit;
- repeated export from pinned inputs is deterministic where the contract
  requires it, or known nondeterminism is recorded.

### 3. Runtime validation

- the engine imports and loads the intended product and fallback;
- shader/material schema and asset versions are compatible;
- dimensions, variants, memory/storage cost, compilation, and loading behavior
  are measured;
- no missing-reference, unsupported-format, or silent substitution occurs.

### 4. Semantic and visual validation

- World Generation or another owner verifies the represented meaning;
- Art checks legend, range, classification, uncertainty/no-data, accessibility,
  and cross-scale continuity;
- representative camera, viewport, LOD, streaming, and selection states match
  the accepted contract.

### 5. Capture and regression evidence

- fixture, revisions, settings, profile, and reproduction steps are pinned;
- before/after or reference comparisons expose intentional and unintended
  changes;
- gameplay, diagnostic, concept, and Marketing uses are labelled;
- known limitations accompany the evidence.

Exact validators, tolerances, visual-diff methods, commands, and CI integration
remain open.

## Ownership seams

| Owner | Owns in this pipeline | Must not silently decide |
| --- | --- | --- |
| World Generation / semantic domain | Definitions, units, ranges, classifications, uncertainty, query validity, aggregation meaning, and representative truth fixtures | Visual encoding, runtime assets, or Art acceptance |
| World Core | Renderer-independent query/API implementation, stable identities, versions, and fixtures | Bevy representation or player-facing appearance |
| Systems Architecture | Dependency and authority boundaries, feasibility constraints, shared contract decisions | World meaning or final visual direction |
| Bevy Client | Import/loading, render integration, camera, picking, UI behavior, runtime LOD/cache/streaming, and performance implementation | Canonical truth or in-game visual acceptance |
| Rust Platform | Toolchain, dependencies, build/CI integration, packaging, and platform policy | Domain semantics or Art direction |
| Art & Technical Art | Visual contracts, asset/source/export requirements, material/shader semantics, accessibility, continuity, provenance process, and visual acceptance | Rust/Bevy architecture, legal clearance, or public release |
| Marketing Visual Brand & Capture | External briefs, campaign applications, brand consistency, asset-use context, and Marketing provenance | In-game visual language, runtime-art pipeline, or gameplay fidelity |
| Product Owner / qualified authority | Product direction, spend, publication, commercial commitment, and required legal approval | Routine pipeline implementation |

## Recovery and change control

An asset or pipeline change that affects visible meaning, compatibility,
provenance, budget, loading, capture, or reproducibility requires a versioned
change record and the routes in the [Art Team API](README.md).

Recovery information identifies the last accepted source/runtime versions,
rebuild procedure, compatible consumer revision, and safe rollback. Removing a
source, tool dependency, or generated product requires proof that accepted
runtime and evidence artifacts remain reproducible or a recorded migration.

## Open decisions

Formats, tools, paths, manifests, shaders, materials, texture and mesh policy,
color management, import/export, build integration, LOD/streaming, performance
profiles, automated validation, visual regression, and capture tooling remain
open in [Art Open Decisions](ART_OPEN_DECISIONS.md).

## ART-001 acceptance gates

Acceptance of this foundation required:

1. World Generation accepts the derived-product and semantic-input boundary.
2. Systems Architecture, Bevy Client, and Rust Platform accept the ownership and
   feasibility seams.
3. Marketing accepts the gameplay-versus-external-asset and capture boundary.
4. Art accepts the provenance, accessibility, continuity, and evidence
   requirements.
5. Dev Review clears blocking ambiguity or accidental implementation choices.
