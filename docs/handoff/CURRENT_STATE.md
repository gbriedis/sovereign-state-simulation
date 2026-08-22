# Current State and Handoff

- **Last verified:** 2026-08-22
- **Control-plane work packet:** OPS-001
- **Project phase:** Natural-world foundation (`0.0.1`–`0.1.0`)
- **Immediate product milestone:** Prototype v0.1
- **Implementation state:** Rust workspace and initial Bevy map window exist;
  world generation and map interaction are not implemented

This is the operational catch-up page, not a duplicate architecture document.
Follow its links for canonical detail. The Project Steward refreshes
this page after meaningful integrations; task agents update their own canonical
artifacts and handoff records.

## Operating state

- The repository is the durable project memory; chat history is temporary.
- Project-wide agent behavior is governed by `../../AGENTS.md`.
- Ownership, decision rights, review gates, and department boundaries are in
  `../operations/OPERATING_MODEL.md`.
- Active work, owners, branches, blockers, and merge order are in
  `../operations/WORKSTREAMS.md`.
- Cross-department dependencies and notification triggers are in
  `../operations/DEPENDENCIES.md`.
- Significant decisions and their rationale are indexed in
  `../decisions/README.md`.
- In-game visual meaning, technical-art boundaries, and mandatory Art review
  triggers are defined in `../art/README.md`.
- Routine Git synchronization, integration, recovery, and cleanup are agent
  responsibilities. The user is not the Git coordinator.

## Current product truth

| Concern | Canonical source |
| --- | --- |
| Product intent and boundaries | `../PROJECT_VISION.md` |
| Governing design laws | `../DESIGN_PRINCIPLES.md` |
| Current natural-world phase | `../ROADMAP_WORLD_FOUNDATION.md` |
| Level 0 planetary boundary | `../world-generation/EARTH_LIKE_PLANETARY_CONTRACT.md` |
| Accepted technical direction | `../architecture/ARCHITECTURE_OVERVIEW.md` |
| Prototype outcome and success criteria | `../architecture/PROTOTYPE_V0.1.md` |
| Unscoped architecture questions | `../architecture/OPEN_DECISIONS.md` |
| In-game visual and technical-art ownership | `../art/README.md` |
| Accepted public identity and claims | `../brand/BRAND_FOUNDATION.md` |
| Marketing ownership and workflow | `../marketing/MARKETING_DEPARTMENT.md` |

The accepted physical-world conceptual chain is documented in the focused notes
under `../world-generation/`. Those documents define domain intent and
constraints; their unresolved algorithms, numerical methods, taxonomies, and
storage choices are not accepted implementation decisions.

World histories begin inside the accepted Level 0 Earth-like planetary
contract: common physical rules plus bounded Earth-like causal variation supply
boundary conditions for geological prehistory. This does not authorize a
generic planet generator or move geological, climate, surface, biological, or
civilization outcomes into Level 0.

## Implemented foundation

- Rust `1.97.1`, rustfmt, and Clippy are pinned in `rust-toolchain.toml`.
- Bevy `0.19.1` is the only direct external dependency and is currently limited
  to the required 2D feature set.
- `crates/world_core` is a renderer-independent Rust library boundary.
- `crates/client` opens the prototype window with a 2D map camera.
- Windows CI checks formatting, Clippy warnings, workspace tests, documentation
  tests, and the committed lockfile.
- A core-only Linux CI job protects the renderer-independent portability
  boundary without building the client.
- Project-governance validation checks the control-plane structure, Markdown
  links, and decision-record conventions.

No world-generation algorithm, coordinate system, domain size, sampling scale,
spatial index, persistence format, or final player-facing UI implementation has
been selected by the bootstrap. The current window presentation is provisional.

## Active focus

The next product work remains the scoped map prototype in
`../architecture/PROTOTYPE_V0.1.md`. Its 500 m cells are provisional sampling
units for prototype validation, not the ontology of physical or geological
truth.

Current work packets, including coordination work and their dependency order,
must be read from `../operations/WORKSTREAMS.md` rather than copied here.

## Non-negotiable boundaries

- Do not start civilization, economics, politics, or other human simulation in
  the current natural-world phase.
- Do not couple world/simulation data to Bevy or egui types.
- Do not treat proposals, illustrative Rust vocabulary, open questions, or
  long-term direction as implemented or accepted decisions.
- Do not let optional Web3 exploration shape the foundational simulation.
- Do not reduce canonical physical truth to renderer meshes, heightmaps,
  sampling cells, uniform voxels, or eager maximum-resolution storage.
- Do not let computational or political boundaries create physical
  discontinuities that the modeled world did not create.
- Do not implement unresolved geometry, thermal, material, persistence,
  networking, or refinement mechanisms merely because a conceptual note names
  candidate approaches.
- Preserve deterministic, versioned world identity and the dependency direction
  from client to pure-Rust world core.
- If work would settle an open choice, create or update a decision record with
  context, alternatives, rationale, consequences, owner, and affected domains.

Task-specific boundaries remain authoritative in the focused domain document and
must be checked before implementation.

## Next product actions

1. Define versioned seed inputs and explicitly provisional coordinate, domain,
   and sampling identifiers through an accepted specification or decision.
2. Implement and test prototype coordinate-to-domain-to-sample mapping.
3. Establish the first accepted world-generation visual and technical-art
   contract.
4. Add smooth map panning and cursor-centered zooming under Art visual review.
5. Build the seeded, non-canonical prototype landmass render.
6. Measure the provisional sampling and spatial-domain choices without promoting
   them into geological ontology.

## Before continuing work

Read the current workstream entry, the prototype specification, and relevant
open questions. Perform the Git/worktree preflight in `../../AGENTS.md`, declare
the write set, and own the task through integration, propagation, and cleanup.
