# Dependencies and Notification Routing

- **Owner:** Project Steward
- **Status:** Accepted living matrix
- **Last reviewed:** 2026-08-22

This document makes change impact explicit. It routes decisions and accepted
contract changes to the departments that consume them without broadcasting
every internal edit to everyone.

## Routing levels

| Route | Required behavior |
| --- | --- |
| `Action required` | Recipient acknowledges in the workstream record and owns a named follow-up, compatibility check, or acceptance before dependent integration |
| `Consulted` | Recipient reviews before acceptance because its constraints or contract may change; the decision owner resolves the feedback |
| `Informed` | Recipient receives the canonical diff/ADR after merge; no acknowledgement is required |
| `None` | No material dependency; normal repository visibility is sufficient |

The Project Steward assigns an explicit response condition to consultations. If
a consulted owner is unavailable, reversible work may proceed with the absence
and assumptions recorded; irreversible or product decisions wait for the proper
authority. Silence never silently approves an action-required route.

## Team dependency map

| Producer | Exported output | Primary consumers | Consumer acceptance signal |
| --- | --- | --- | --- |
| Product Owner | Vision, player promise, material scope and priorities | World Generation, Systems Architecture, Art & Technical Art, Marketing | Canonical vision/roadmap change and, when material, accepted ADR |
| World Generation | Causal rules, invariants, provisional physical contracts, acceptance examples | Systems Architecture, World Core, Art & Technical Art | Systems feasibility, testable Core interpretation, and honest visual interpretation |
| Systems Architecture | Boundaries, interface/authority contracts, technical decisions, packet allocation | World Core, Bevy Client, Rust Platform, Art & Technical Art | Relevant lane and affected visual/pipeline owner accept the contract and evidence |
| World Core | Bevy-free APIs, deterministic world data, fixtures, reproducibility evidence | Bevy Client, Art & Technical Art, authority/server work later | Client/API checks plus Art review when data shape affects interpretation |
| Bevy Client | Player-visible interaction, rendering adapters, capture evidence, core query needs | Art & Technical Art, Systems Architecture, Marketing, World Core when requirements change | Art visual acceptance, demonstrated behavior, and boundary review |
| Rust Platform | Toolchain, manifests, dependency policy, CI/build/release contracts | All Rust lanes and integration DRI | Affected checks pass on canonical baseline |
| Art & Technical Art | In-game visual contracts, map/camera language, assets, pipeline requirements, visual acceptance | Bevy Client, World Core, Rust Platform, World Generation, Marketing | Feasibility checks plus World Generation confirmation when depiction conveys domain meaning |
| Marketing | Claims/evidence ledger, brand applications, research and capture briefs | Product Owner, Art & Technical Art, and relevant evidence owners | Claim verification, Art-accepted gameplay capture, and approval only for gated external action |
| Project Steward | Work packets, routing, decision links, integration baseline, handoff closure | All departments | Ledger acknowledgement for action-required work |
| Dev Review | Evidence-based approval or blocking findings | Workstream DRI and integration DRI | Findings resolved, accepted as follow-up, or routed to decision owner |

## Change-event routing matrix

`Owner` decides inside accepted authority. `AR`, `C`, and `I` abbreviate the
routing levels above. A blank cell means `None`.

<!-- ART-CONTRACT: IMPACT-DECLARATION -->
Every material change declares its Art / Technical Art impact in the packet and
pull request. The matrix below supplies the default route; a concrete `N/A`
rationale may override it only when the triggering condition demonstrably does
not apply.

| Material change event | Owner | Product | Steward | World Gen | Systems | Core | Client | Platform | Art / Tech Art | Marketing | Dev Review |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Vision, player promise, phase scope, or milestone definition | Product Owner | AR | C | C | C | I | I | I | C* | C | C |
| Accepted world causal rule, physical invariant, or generation contract | World Generation | I | I | AR | C | AR | I | I | C* | I* | AR |
| Architecture boundary, authority model, persistence contract, or cross-lane data model | Systems Architecture | I* | I | C | AR | AR | AR | C | C* | I | AR |
| World Core exported API, canonical-state meaning, determinism, or serialization behavior | World Core |  | I | C | C | AR | AR | C | C* | I* | AR |
| Bevy Client interaction, rendering contract, or player-visible behavior | Bevy Client |  | I | C* | C | C* | AR | C* | AR | I* | AR |
| Toolchain, root manifest, lockfile policy, shared dependency feature, CI, or release gate | Rust Platform |  | I |  | C | AR | AR | AR | C* |  | AR |
| In-game visual contract, map/camera language, shader, material, asset, LOD presentation, technical-art pipeline, or gameplay capture | Art & Technical Art | I* | I | C* | C | C* | AR | C* | AR | C* | AR |
| Brand foundation, material positioning, or public product claim | Marketing | AR* | I | C* | C* | C* | C* |  | C* | AR | C |
| Demonstrated implementation state that enables or invalidates a claim | Implementing lane |  | AR | I* | I | I* | I* | I* | AR* | AR | C |
| Ownership, Team API, work lifecycle, or routing-policy change | Project Steward | I* | AR | C | C | I | I | I | C | C | AR |
| Security/privacy exposure, unrecoverable data risk, legal commitment, spend, publication, or destructive external action | Qualified authority / Product Owner | AR | AR | I* | I* | I* | I* | I* | I* | I* | AR |

<!-- ART-CONTRACT: REVIEW-GATE -->
An `AR` route to Art & Technical Art blocks acceptance and integration until its
owner records `Accepted`. A World Generation `C*` on an Art-owned change is the
reverse semantic-honesty check: it blocks only when the visual treatment claims
physical or simulation meaning.

`*` means route only when the change materially affects that recipient:

- Product Owner is action-required for Marketing work only when it changes the
  material brand foundation or master identity, publishes externally, spends,
  or creates a commercial commitment.
- Art & Technical Art is consulted on world, Core, architecture, or platform
  changes when render/query shape, classifications, canonical-versus-derived
  ownership, LOD/refinement/streaming, assets, or visual interpretation change.
- Art & Technical Art is action-required for accepted player-visible client
  behavior, map/camera/projection/zoom/picking language, shaders, materials,
  assets, visual acceptance, and gameplay capture.
- World Generation is consulted on Art changes when a depiction communicates
  physical or simulation meaning; this prevents a visually polished but
  semantically false handoff.
- Marketing receives world or implementation changes only when they alter a
  player-visible promise, evidence state, capture opportunity, or public claim.
- Product Owner is action-required on architecture only when it changes product
  scope, player promise, material cost, or an irreversible commitment.
- World Generation is consulted on Core or Marketing changes only when physical
  meaning is interpreted or claimed.
- Core is consulted on Client work only when queries, semantics, or performance
  expectations change; Platform is consulted when dependencies or builds change.
- The implementing lane routes demonstrated-state evidence only to consumers
  whose current records or claims rely on it.
- Security/legal events are disclosed to affected owners on a need-to-act basis;
  sensitive details are not broadcast through a public document.

## High-contention paths

These paths are dependencies even when their textual changes are small:

| Scope | Serialization owner | Required consumers |
| --- | --- | --- |
| Root `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, `.github/workflows/` | Rust Platform | Every affected crate owner and integration DRI |
| `docs/handoff/CURRENT_STATE.md` | Project Steward | Every department whose status is changed |
| `docs/architecture/ARCHITECTURE_OVERVIEW.md` | Systems Architecture | Affected domain and lane owners |
| `docs/architecture/OPEN_DECISIONS.md` | Systems Architecture or named decision DRI | Owner of the focused canonical document and Project Steward |
| `docs/art/` | Art & Technical Art | World Generation for semantic meaning; Systems Architecture, World Core, Bevy Client, Rust Platform, and Marketing as affected |
| `docs/brand/BRAND_FOUNDATION.md` | Marketing / Brand Steward | Product Owner for material brand change and evidence owners for product claims |
| `docs/operations/` and `docs/decisions/README.md` | Project Steward | Affected department leads |

Only one active packet writes a serialized scope at a time. Other packets route
a requested delta to that writer or wait at integration; they do not create
parallel competing versions.

## Notification payload

Every routed notice contains only what the recipient needs to act:

1. Work ID and one-sentence outcome.
2. Canonical diff, artifact, or ADR link.
3. Changed contract, invariant, evidence state, or assumption.
4. Route level, including the Art / Technical Art impact declaration, and exact
   requested action.
5. Validation evidence and known risk.
6. Required-before condition, if the route is blocking integration.

The sender supplies action-required acknowledgement through the linked packet
channel; the Project Steward records it in `WORKSTREAMS.md`. New dependencies
discovered during work are supplied with the packet immediately and added to
this matrix by its Steward writer when they are durable. The Project Steward
owns delivery and follow-up; departments do not rely on the Product Owner to
relay messages.
