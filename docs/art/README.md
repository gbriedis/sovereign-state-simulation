# Art and Technical Art Department

- **Status:** Accepted Team API
- **Adopted:** 2026-08-22
- **Department lead:** Art / Technical Art Lead
- **Owned repository path:** `docs/art/`
- **Operating authority:** [Project Operating Model](../operations/OPERATING_MODEL.md)
- **Dependency routes:** [Cross-Team Dependency Map](../operations/DEPENDENCIES.md)

This document defines the Art and Technical Art Team API established by
`OPS-001`. It defines ownership and review boundaries only. It does not select a
visual style, projection, camera model, layer taxonomy, shader, material, asset,
or player-interface design. Those choices require their own evidence and
accepted work or decision records.

## Mission

Make canonical project and world meaning visually legible, coherent,
accessible, and technically reproducible without turning a rendered view into
canonical world truth. Art and Technical Art own the in-game visual language
and the specifications, production pipeline, and validation evidence that carry
that language into runtime presentation.

The Art / Technical Art Lead is accountable for this Team API, routine domain
decisions inside accepted direction, cross-team consultation, and Art review
acknowledgements. The Product Owner retains the product and external approval
rights defined in the operating model.

## Ownership boundary

Art and Technical Art own:

- in-game art direction and visual language after it is accepted;
- visual semantics for world quantities, map layers, classifications,
  uncertainty, diagnostic views, and semantic zoom;
- art-facing requirements for projection, camera, zoom, picking, selection,
  and player-facing interface presentation;
- visual continuity requirements across chunks, refinement, streaming, and
  levels of detail;
- shader, material, runtime-art-asset, and technical-art pipeline
  specifications, including provenance and accessibility requirements;
- visual acceptance criteria, reference frames, test cards, review evidence,
  and fidelity decisions; and
- gameplay-capture fidelity review: whether a capture honestly depicts the
  implemented visual result and any material visual limitations.

Art and Technical Art do not own canonical physical-world meaning, simulation
algorithms, product mechanics, Rust/Bevy application implementation, public
brand identity, marketing claims, publication, or release authority.

### Boundary with Bevy Client

[Bevy Client](../operations/OPERATING_MODEL.md) owns the Rust/Bevy runtime
implementation of the window, input, camera behavior, rendering integration,
picking, UI behavior, performance, and its consuming side of world queries.
Art and Technical Art own what those systems must communicate visually, the
art-facing contracts and assets they consume, and the evidence used for visual
acceptance.

Neither team may silently decide the other's contract. A Bevy Client change can
be technically correct and still require Art acceptance; an Art specification
can be visually coherent and still require Client and Systems Architecture
confirmation that its runtime contract is implementable.

### Boundary with Marketing Visual Brand and Capture

[Marketing Visual Brand & Capture](../marketing/MARKETING_DEPARTMENT.md) owns
external visual identity, campaign applications, capture planning, public asset
specifications, and brand consistency. Art and Technical Art own the actual
in-game visual language, world presentation, runtime art pipeline, and visual
fidelity of the implemented player surface.

Marketing supplies a capture or brand brief and decides whether an approved
capture serves its communication goal. Art verifies in-game visual fidelity and
limitations; the implementing lane verifies build behavior; Marketing must not
reclassify concept work as gameplay or redefine in-game semantics. Art does not
approve public release, claims, spend, or master-brand changes.

### Boundary with World Generation

World Generation owns the physical and semantic meaning of world quantities,
units, classifications, uncertainty, provenance, and valid query behavior. Art
owns how accepted meaning is encoded for a viewer. A palette, symbol, label,
mesh, texture, or screen-space effect must never become the source of world
truth.

Consultation is deliberately bidirectional:

- World Generation consults Art before accepting a new or changed visible
  quantity, classification, layer, uncertainty signal, cross-scale behavior, or
  art-facing query contract.
- Art consults World Generation before accepting a visual encoding whose
  meaning depends on physical values, derived categories, units, ranges,
  missing-data behavior, uncertainty, or scale.
- World Generation accepts semantic correctness. Art accepts visual semantics,
  legibility, accessibility, and continuity. Neither acknowledgement substitutes
  for the other.

## Inputs and outputs

| Direction | Contract |
| --- | --- |
| Input from Product | Accepted product intent, player outcome, scope, and approval boundaries from [Project Vision](../PROJECT_VISION.md) and [Design Principles](../DESIGN_PRINCIPLES.md) |
| Input from World Generation / World Core | Versioned semantic definitions, units, classifications, uncertainty, query behavior, revision identity, and representative test data |
| Input from Systems Architecture / Bevy Client | Implementable render-query and client boundaries, platform constraints, performance evidence, interaction behavior, and current build evidence |
| Input from Marketing | Accepted brand or capture brief, target audience/use, claims constraints, and external asset requirements |
| Art output | Accepted or proposed in-game visual-language specifications with decisions and open questions clearly separated |
| Technical Art output | Versioned asset, material, shader, source/export, provenance, and validation-pipeline contracts |
| Cross-team output | Art-facing query requirements, visual acceptance criteria, reference evidence, review acknowledgement, risks, and exact follow-up action |

Inputs that are merely proposed, planned, or exploratory retain that state. Art
may prototype their presentation but may not make the underlying product or
world decision by depicting it.

## Mandatory Art review triggers

Every work packet, RFC, and pull request must declare Art / Technical Art impact.
The following changes are always Art-impacting unless the Art Lead records a
specific exception:

| Trigger | Required Art involvement |
| --- | --- |
| A world quantity becomes visible, changes meaning, units, range, uncertainty, or missing-data behavior | Consult before contract acceptance; Art acknowledgement before integration |
| A map layer, overlay, classification, legend, diagnostic view, or visual taxonomy is added or changed | Art acceptance of visual semantics and legibility |
| Projection, datum presentation, camera, zoom, semantic zoom, picking, selection, or viewport behavior changes | Art consultation during specification and visual acceptance of the result |
| A world-to-render or render-query contract changes | Art and semantic-owner consultation before acceptance; Art review of representative output |
| Chunk, refinement, streaming, cache, or LOD behavior can create visible transitions or discontinuities | Art acceptance of continuity criteria and evidence |
| A shader, material, texture, mesh, symbol, font, runtime art asset, import/export rule, or asset provenance record changes | Technical Art review; relevant legal or brand gate remains separate |
| Player-facing UI presentation or accessibility behavior changes | Art review plus the owning product/client acceptance gate |
| Gameplay capture, screenshot, footage, or visual evidence is prepared for Marketing | Art fidelity acknowledgement, implementing-lane verification, then Marketing review |
| A packet claims visual completion, visual quality, capture readiness, or visual acceptance | Art acceptance linked to reproducible evidence |

An Art review finding identifies the violated contract, evidence, severity, and
required response. Reviewers do not silently take over the implementing branch.

## Art handoff payload

An Art-impacting handoff is actionable only when it carries the fields below.
Use `N/A` with a reason where a field genuinely does not apply; omission is not
an implicit approval.

- work or decision ID, accountable owner, state, branch, base/head revisions,
  and canonical artifact links;
- named Art recipient and addressable execution channel (linked issue, pull
  request, or task), required response condition, and merge/decision gate;
- intended viewer and mode: player-facing, diagnostic, review, or capture;
- visible quantities, layers, classifications, and the semantic owner of each;
- definitions, units, valid ranges, uncertainty, missing/no-data behavior, and
  classification or schema version;
- world identity, generator/ruleset version, seed or fixture identity, canonical
  revision, and query/result version needed to reproduce the view;
- spatial reference, datum and projection assumptions, camera and zoom context,
  picking/selection behavior, and viewport or platform constraints;
- world-query and render-query contract changes, including cache identity and
  whether any refinement is requested or merely displayed;
- chunk, refinement, streaming, and LOD behavior plus continuity invariants and
  known transition risks;
- changed shaders, materials, source assets, runtime exports, generated
  artifacts, provenance, licences, and tool/version requirements;
- accessibility, performance-budget, and device/aspect-ratio constraints that
  affect visual acceptance;
- visual acceptance criteria, representative fixtures, reproduction steps,
  before/after evidence, validation results, and known limitations;
- decisions made or still open, dependencies, required merge order, rollback or
  recovery notes, next owner, and exact next action; and
- acknowledgement evidence: responder, date, `Accepted`, `Blocked`, or
  `Action required`, linked findings, and closure evidence.

Silence is never Art acceptance. If no issue or pull request exists, the work
record must name the receiving task and retain its acknowledgement link or
message identifier.

## ART-001 foundation

`ART-001` established the first accepted Art and Technical Art foundation through
[PR #24](https://github.com/gbriedis/state-of-consequence/pull/24). Its four
canonical documents are:

1. `docs/art/ART_DIRECTION.md` — in-game art-direction goals, boundaries,
   accessibility principles, decision states, and visual acceptance language.
2. `docs/art/MAP_AND_CAMERA_LANGUAGE.md` — world/map visual semantics, layer and
   classification grammar, camera/zoom/picking concerns, and evidence criteria.
3. `docs/art/TECHNICAL_ART_PIPELINE.md` — source/export/runtime asset separation,
   materials and shaders, provenance, tooling, validation, and ownership seams.
4. `docs/art/ART_OPEN_DECISIONS.md` — Art discovery inventory whose questions
   become accepted only through the project decision process.

The Project Steward records `ART-001` as `Done` in
[Active Workstreams](../operations/WORKSTREAMS.md). Its accepted foundation does
not settle the visual choices catalogued as `ART-D001` through `ART-D013`; those
remain open until separately scoped evidence and the required decision and
review gates accept them. Future Art work must continue to preserve unresolved
product, world, architecture, and visual choices as open rather than filling
them with plausible defaults.

## Enforcement and temporary identity model

Until distinct GitHub team identities exist, `CODEOWNERS` would not reliably
represent these department boundaries or provide independent acknowledgement.
The enforceable interim mechanism is:

1. every work packet, RFC, review finding, and pull request declares
   `Art / Technical Art impact` as `Action required`, `Consulted`, `Informed`,
   or `N/A — <specific reason>`;
2. every `Action required` or `Consulted` change names an Art reviewer and links
   the handoff payload;
3. the Art acknowledgement or blocking finding is recorded before the relevant
   merge or decision gate;
4. the project-governance validator checks that the Team API, mandatory routes,
   impact declaration, and `N/A` rationale exist; and
5. the Project Steward verifies addressable acknowledgement evidence during
   integration.

When distinct GitHub identities and stable ownership exist, the Project Steward
may add `CODEOWNERS` as an additional enforcement layer. It supplements this
Team API and handoff evidence; it does not replace them.
