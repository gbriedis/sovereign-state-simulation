# Active Workstreams

- **Ledger owner:** Project Steward
- **Snapshot date:** 2026-08-22
- **Canonical integration branch:** `main`
- **Operating rules:** [Project Operating Model](OPERATING_MODEL.md)

This is the compact live coordination ledger, not a historical backlog. It
contains active cross-agent work and the next few startable packets. Product
scope stays in roadmaps; completed history stays in Git, review records, and
ADRs.

## Record contract

Each heading uses `AREA-NNN — Short outcome`. IDs are permanent and never
reused. A live record contains these fields in order:

| Field | Rule |
| --- | --- |
| `Type` | `Packet` for one branch-sized delivery; `Initiative` only as a coordination envelope with child packets |
| `DRI` | Exactly one accountable agent or role |
| `State` | `Proposed`, `Ready`, `Active`, `Blocked`, `Review`, `Integration`, `Done`, or `Cancelled` |
| `Priority` | `P0` critical path, `P1` next, `P2` useful, `P3` parked |
| `Updated` | Date of the last material state change (`YYYY-MM-DD`) |
| `Outcome` | Observable result, not an activity |
| `Done when` | Canonical artifact and validation/acceptance evidence |
| `Base` | Actual starting commit once active; initiatives may use `N/A` |
| `Branch / worktree` | Named branch and worktree, or who must assign them before activation |
| `Write scope` | Exact paths or artifact boundary; shared files name one writer |
| `Dependencies` | Work IDs, ADRs, or canonical inputs and required state |
| `Review gate` | Independent reviewer/domain acceptance required |
| `Art / Technical Art impact` | `Action required`, `Consulted`, `Informed`, or `N/A — <specific rationale>`; never blank |
| `Routing` | `Action required`, `Consulted`, and `Informed` recipients |
| `Evidence` | Links to canonical artifacts, validation, or current-state fact |
| `Next action` | One owner and one executable next step |
| `Blocker` | `None`, or a concrete unavailable authority/external state with owner |

The DRI supplies accurate evidence at every handoff and state change. The
Project Steward is the sole serialized ledger writer: it applies those updates,
audits each integration wave, resolves overlapping write scopes, and removes
`Done` or `Cancelled` records after one review cycle. Issues, pull requests, and
task messages are linked execution evidence, not parallel status truth. Until a
packet links one, its section here is the durable handoff endpoint. A stale
record is a Steward task; it is never silently treated as current.

## OPS-001 — Install the autonomous project control plane

- **Type:** Packet
- **DRI:** Project Steward
- **State:** Done
- **Priority:** P0
- **Updated:** 2026-08-22
- **Outcome:** Repository-native ownership, routing, decision, handoff, review,
  and Git rules let departments coordinate without Product Owner micromanagement.
- **Done when:** The operating documents, agent entry rules, governance checks,
  and initial records are canonical on `main`; links and metadata validate; all
  departments are informed.
- **Base:** `main@127fa07`.
- **Branch / worktree:** Integrated by
  [PR #20](https://github.com/gbriedis/state-of-consequence/pull/20);
  exact submitted head `fc35db3` was squash-merged as `9578f28`, and both task
  branches were retired after proof.
- **Write scope:** `docs/operations/`, `docs/decisions/`, repository agent
  guidance, governance automation, and the required-check orchestration in
  `.github/workflows/`, with one writer per file.
- **Dependencies:** [ADR-0001](../decisions/ADR-0001-project-control-plane.md).
- **Review gate:** Dev Review plus affected department leads for their Team APIs;
  Art & Technical Art must accept its standing contract and enforcement routes.
- **Art / Technical Art impact:** Action required — this packet establishes the
  Art Team API, routing triggers, handoff contract, and automated gate.
- **Routing:** Action required — Project Steward, integration DRI, and Dev
  Review; Consulted — World Generation, Systems Architecture, Art & Technical
  Art, and Marketing; Informed — all other agents.
- **Evidence:** [Operating model](OPERATING_MODEL.md),
  [dependency routes](DEPENDENCIES.md), and
  [decision system](../decisions/README.md). World Generation's initial domain
  review and the Systems Architecture, Art & Technical Art, Marketing, and
  independent control-plane reviews returned `Accept`; strict governance
  validation passed. Hosted CI exposed a sequential cold-build timeout; Systems
  Architecture accepted splitting lint and tests into parallel gates. The
  required `rust-gate` now skips hosted compilation for documentation-only work
  and waits for every Rust gate when code, Cargo, or toolchain paths change.
  [PR #20](https://github.com/gbriedis/state-of-consequence/pull/20)
  passed `project-governance` and `rust-gate`, auto-merged under protected-main
  rules, and triggered successful post-merge workflows. Eleven targeted
  department/lane handoffs were delivered.
- **Next action:** Project Steward retains this `Done` record for one review
  cycle, then removes it from the live ledger while Git and ADR-0001 preserve
  history.
- **Blocker:** None — Art & Technical Art accepted the corrected standing
  contract, routes, packet, templates, and enforcement on 2026-08-22.

## OPS-002 — Reconcile the canonical Git baseline and detached worktrees

- **Type:** Packet
- **DRI:** Project Steward
- **State:** Done
- **Priority:** P0
- **Updated:** 2026-08-22
- **Outcome:** Every worktree and unique commit has an owner and disposition;
  local and intended remote `main` agree on the canonical project baseline.
- **Done when:** Useful work is integrated or attached to a named recovery/task
  branch, obsolete clean worktrees are safely removed, metadata is pruned,
  canonical validation passes, and the remote contains the intended baseline.
- **Base:** `main@127fa07` at the 2026-08-22 inventory; re-inspect before acting.
- **Branch / worktree:** Closed through `ops/close-project-control-plane` in a
  dedicated closure worktree; no active department worktree was deleted.
- **Write scope:** Git refs, upstream state, and worktree registrations only.
- **Dependencies:** Active packet owners must finish or hand off before their
  worktrees are removed.
- **Review gate:** Cleanliness and reachability proof; Dev Review for any rescued
  content before it is integrated.
- **Art / Technical Art impact:** N/A — this packet changes Git refs, upstream
  state, and worktree registrations only; it does not change visual product or
  asset behavior.
- **Routing:** Action required — owners of dirty or unique work; Consulted —
  integration DRI for conflicting valid changes; Informed — all agents when the
  canonical baseline changes.
- **Evidence:** `main@9578f28` equals `origin/main`; PR #20's exact task head and
  squash merge were proven; the remote task branch and verified local branch
  were retired. World Core, Bevy Client, Rust Platform, Brand Steward, Audience
  Intelligence, and Visual Brand & Capture each re-inspected and synchronized
  its clean detached worktree to `9578f28`. All six remained clean, owned, and
  free of unique commits; they were preserved because their pinned tasks remain
  active. Post-merge `Rust` and `Project Governance` workflows passed.
- **Next action:** Each active owner creates its packet branch in its preserved
  worktree when work begins. Project Steward retains this `Done` record for one
  review cycle, then removes it from the live ledger.
- **Blocker:** None.

## WG-001 — Close the prototype seed and spatial contract

- **Type:** Packet
- **DRI:** World Generation Lead
- **State:** Ready
- **Priority:** P0
- **Updated:** 2026-08-22
- **Outcome:** The prototype has explicit versioned seed inputs and provisional
  coordinate, domain, and sampling identifiers without treating cells as
  geological ontology.
- **Done when:** The World Generation Lead accepts a canonical semantic contract
  with invariants, examples, open limits, reproducibility expectations, and
  implementation acceptance tests; Systems Architecture confirms
  implementability and Dev Review clears blocking findings without taking
  authority over world meaning.
- **Base:** `main@127fa07`; refresh to current canonical `main` when claimed.
- **Branch / worktree:** DRI creates `docs/WG-001-prototype-spatial-contract` in
  one task worktree before durable edits.
- **Write scope:** New
  `docs/world-generation/PROTOTYPE_SEED_AND_SPATIAL_CONTRACT.md`; a proposed ADR
  uses its own declared path and the Steward alone updates shared indexes.
- **Dependencies:** [Prototype v0.1](../architecture/PROTOTYPE_V0.1.md),
  [Architecture Overview](../architecture/ARCHITECTURE_OVERVIEW.md),
  [Adaptive Spatial Partitioning](../world-generation/ADAPTIVE_SPATIAL_PARTITIONING.md),
  and relevant questions in [Open Decisions](../architecture/OPEN_DECISIONS.md).
- **Review gate:** Dev Review for long-term blocks; Systems Architecture for
  implementability and boundary compatibility; Art & Technical Art for visible
  quantities, classification, uncertainty, and future diagnostic implications.
- **Art / Technical Art impact:** Consulted — seed, domain, sample, and query
  semantics will shape honest visual interpretation and diagnostics.
- **Routing:** Action required — World Core and Dev Review after acceptance;
  Consulted — Systems Architecture and Art & Technical Art; Informed — Bevy
  Client and Rust Platform.
- **Evidence:** [Prototype v0.1](../architecture/PROTOTYPE_V0.1.md) defines the
  seed, mapping, and provisional 500 m behavior; [Adaptive Spatial
  Partitioning](../world-generation/ADAPTIVE_SPATIAL_PARTITIONING.md) defines the
  accepted distinction between physical identity, domains, and samples.
- **Next action:** The specification developer turns the designer's accepted
  direction into invariants and testable examples, then sends one bounded packet
  through Dev Review.
- **Blocker:** None.

## WG-002 — Establish the Earth-like planetary contract

- **Type:** Packet
- **DRI:** World Generation specification DRI
- **State:** Done
- **Priority:** P1
- **Updated:** 2026-08-22
- **Outcome:** Level 0 supplies bounded Earth-like causes and boundary
  conditions while generated history supplies downstream consequences.
- **Done when:** The focused contract, ADR-0002, architecture and roadmap links,
  open questions, and concise handoff pointer are canonical on `main`; required
  domain reviews and governance checks pass; affected owners are informed; and
  the exact merged branch and worktree are safely retired.
- **Base:** Began at `main@127fa07`; synchronized through canonical
  `main@c8434a4` before integration.
- **Branch / worktree:** Integrated by
  [PR #21](https://github.com/gbriedis/state-of-consequence/pull/21);
  exact submitted head `b9aa7c1` was squash-merged as `66b5d4f`. The remote and
  verified local task branches and the clean task worktree were retired.
- **Write scope:** `docs/world-generation/EARTH_LIKE_PLANETARY_CONTRACT.md`,
  `docs/world-generation/EARTH_LIKE_PHYSICAL_FRAMEWORK.md`,
  `docs/architecture/ARCHITECTURE_OVERVIEW.md`,
  `docs/architecture/OPEN_DECISIONS.md`,
  `docs/ROADMAP_WORLD_FOUNDATION.md`,
  `docs/decisions/ADR-0002-earth-like-planetary-contract.md`, and assigned
  decision-index, current-state, and workstream propagation.
- **Dependencies:** Product Owner acceptance recorded in
  [ADR-0002](../decisions/ADR-0002-earth-like-planetary-contract.md); OPS-001 and
  repository-rename registry correction are canonical.
- **Review gate:** Product Owner accepted the product boundary; Systems
  Architecture, World Core, and Art & Technical Art returned `Accept`; Dev
  Review approved both the world-contract diff and final synchronized head
  `b9aa7c1`.
- **Art / Technical Art impact:** Consulted — accepted. Future visual profiles
  remain derived from canonical causes and cannot become world truth.
- **Routing:** Action required — Product Owner, World Core, Dev Review, and
  Project Steward; Consulted — Systems Architecture and Art & Technical Art;
  Informed — Bevy Client and Marketing through the merged canonical record and
  PR handoff.
- **Evidence:** [PR #21](https://github.com/gbriedis/state-of-consequence/pull/21)
  records the exact review findings and resolutions. Local and hosted project
  governance passed; impact-aware CI correctly classified the change as
  documentation-only. Post-merge `Rust` and `Project Governance` workflows
  passed on `main@66b5d4f`.
- **Next action:** Project Steward retains this `Done` record for one review
  cycle, then removes it from the live ledger while Git and ADR-0002 preserve
  history.
- **Blocker:** None.

## CORE-001 — Implement deterministic prototype spatial mapping

- **Type:** Packet
- **DRI:** World Core lane lead
- **State:** Proposed
- **Priority:** P0
- **Updated:** 2026-08-22
- **Outcome:** Renderer-independent code maps world coordinates to provisional
  domains and 500 m samples deterministically and exposes stable query results to
  the client.
- **Done when:** `crates/world_core` contains Bevy-free types and mapping logic,
  boundary/property tests pass, same seed/version inputs reproduce results, and
  the exported contract passes review.
- **Base:** Not started; record canonical `main` when `WG-001` is accepted.
- **Branch / worktree:** Unassigned until `Ready`; expected branch
  `feat/CORE-001-prototype-spatial-mapping`.
- **Write scope:** `crates/world_core/`; manifest or lockfile changes route to
  Rust Platform as a separately serialized scope.
- **Dependencies:** `WG-001` accepted and any resulting ADR in `Accepted` state.
- **Review gate:** Dev Review, World Generation semantic check, and Systems
  Architecture contract acceptance; Art & Technical Art checks render-query
  semantics and visual interpretation when applicable.
- **Art / Technical Art impact:** Consulted — exported query semantics and data
  availability can constrain or distort visual interpretation.
- **Routing:** Action required — Bevy Client and Dev Review on the exported API;
  Consulted — World Generation, Systems Architecture, and Art & Technical Art;
  Informed — Rust Platform.
- **Evidence:** [Prototype success criteria](../architecture/PROTOTYPE_V0.1.md)
  require correct, testable mapping without Bevy coupling.
- **Next action:** Project Steward marks this packet `Ready` when `WG-001` is
  accepted; the World Core DRI then claims a current base and implements without
  waiting for Product Owner dispatch.
- **Blocker:** None — this remains `Proposed` until its declared dependency is
  accepted.

## ART-001 — Establish the world-generation visual contract

- **Type:** Packet
- **DRI:** Art / Technical Art Lead
- **State:** Done
- **Priority:** P0
- **Updated:** 2026-08-22
- **Outcome:** The prototype has an accepted, semantically honest in-game visual
  foundation and a feasible technical-art contract without silently choosing
  unresolved world, architecture, or product decisions.
- **Done when:** `docs/art/ART_DIRECTION.md`,
  `docs/art/MAP_AND_CAMERA_LANGUAGE.md`,
  `docs/art/TECHNICAL_ART_PIPELINE.md`, and
  `docs/art/ART_OPEN_DECISIONS.md` are canonical; World Generation accepts
  semantic honesty, Systems Architecture and Bevy Client accept feasibility,
  Marketing accepts the external-visual boundary, and Dev Review clears
  blocking findings.
- **Base:** Began at `main@c8434a4`; synchronized through `main@66b5d4f`
  before integration.
- **Branch / worktree:** Integrated by
  [PR #24](https://github.com/gbriedis/state-of-consequence/pull/24);
  exact submitted head `52fdfa6` was squash-merged as `8f3ca26`. The hosted
  task branch was deleted, and no local branch or registered worktree remains
  at the submitted head.
- **Write scope:** The four new `docs/art/` files named in `Done when` only;
  Project Steward alone updates the shared ledger and decision index.
- **Dependencies:** [Art & Technical Art Team API](../art/README.md),
  [Project Vision](../PROJECT_VISION.md),
  [Design Principles](../DESIGN_PRINCIPLES.md),
  [Prototype v0.1](../architecture/PROTOTYPE_V0.1.md), accepted architecture,
  relevant World Generation documents, and the
  [Brand Foundation](../brand/BRAND_FOUNDATION.md).
- **Review gate:** Passed — independent Art & Technical Art accepted; World
  Generation accepted semantic honesty; Systems Architecture, Bevy Client, and
  Rust Platform accepted feasibility; Marketing accepted the external-visual
  boundary; independent Dev Review returned `Approve` with no findings.
- **Art / Technical Art impact:** Action required — Accepted; this packet
  establishes the in-game visual-contract and technical-art-pipeline
  foundations while leaving `ART-D001` through `ART-D013` open.
- **Routing:** Action required — Art & Technical Art (Accepted), Bevy Client
  (foundation feasible; consume it through `CLIENT-001`), and Dev Review
  (`Approve`); Consulted — World Generation (semantic honesty Accepted),
  Systems Architecture (feasibility Accepted), World Core (no implementation
  required now), Rust Platform (Accepted; no toolchain change), and Marketing
  (external-visual boundary Accepted); Informed — Project Steward.
- **Evidence:** [Art direction](../art/ART_DIRECTION.md),
  [map and camera language](../art/MAP_AND_CAMERA_LANGUAGE.md),
  [technical-art pipeline](../art/TECHNICAL_ART_PIPELINE.md), and
  [open decisions](../art/ART_OPEN_DECISIONS.md) are canonical.
  [PR #24](https://github.com/gbriedis/state-of-consequence/pull/24) added
  exactly those four files. Hosted and post-merge governance and `rust-gate`
  checks passed. Submitted head `52fdfa6` and squash `8f3ca26` share exact tree
  `4a5cf9d`; current canonical `main` descends from that merge and retains the
  submitted artifacts unchanged.
- **Next action:** Project Steward retains this `Done` record for one review
  cycle, then removes it from the live ledger while Git and PR #24 preserve
  history.
- **Blocker:** None.

## CLIENT-001 — Deliver smooth map panning and cursor-centered zoom

- **Type:** Packet
- **DRI:** Bevy Client lane lead
- **State:** Active
- **Priority:** P0
- **Updated:** 2026-08-22
- **Outcome:** The existing map window supports responsive mouse panning and
  cursor-centered zooming without owning world truth.
- **Done when:** Interaction behavior meets the prototype criteria, focused tests
  cover extractable camera math, manual behavior is recorded, and no simulation
  type depends on Bevy.
- **Base:** Claimed at `main@9578f28`; synchronized through
  `main@089924f` during implementation.
- **Branch / worktree:** `feat/CLIENT-001-map-camera-navigation` in the Bevy
  Client task worktree.
- **Write scope:** `crates/client/`; no `world_core`, root manifest, lockfile, or
  CI edits without a newly routed scope.
- **Dependencies:** Existing Bevy window and
  [Prototype v0.1](../architecture/PROTOTYPE_V0.1.md); independent of final
  geological and sampling choices. `ART-001` is `Done`; this packet must satisfy
  the accepted [map and camera contract](../art/MAP_AND_CAMERA_LANGUAGE.md) and
  obtain Art acceptance before integration.
- **Review gate:** Art & Technical Art visual acceptance, Dev Review, and Systems
  Architecture boundary check.
- **Art / Technical Art impact:** Action required — camera, panning, zoom, and
  player-visible interaction are accepted visual contracts.
- **Routing:** Action required — Art & Technical Art and Dev Review; Consulted —
  Systems Architecture, World Core only if a core query is introduced, and Rust
  Platform only if a build contract changes; Informed — Marketing after behavior
  is demonstrable and capture-safe.
- **Evidence:** [Current State](../handoff/CURRENT_STATE.md) confirms the window
  exists. The named task branch is active and clean with a coherent camera
  navigation implementation commit; ART-001 supplies its canonical evidence
  and acceptance contract.
- **Next action:** Bevy Client DRI completes automated and manual camera
  evidence, then routes the exact implementation head through Art, independent
  Dev Review, and Systems Architecture before integration.
- **Blocker:** None.

## MKT-001 — Coordinate claims evidence and private capture readiness

- **Type:** Initiative
- **DRI:** Marketing Agent
- **State:** Active
- **Priority:** P1
- **Updated:** 2026-08-22
- **Outcome:** Two independently owned packets produce a maintainable claims
  ledger and an honest private capture brief for Marketing synthesis.
- **Done when:** `MKT-002` and `MKT-003` are integrated; the Marketing Agent
  verifies their evidence states agree and assigns any public action to an
  explicitly approved packet.
- **Base:** N/A — child packets claim their own canonical bases.
- **Branch / worktree:** No initiative branch; `MKT-002` and `MKT-003` use their
  existing separate task worktrees and named branches when claimed.
- **Write scope:** Coordination envelope only; child packets have disjoint exact
  files.
- **Dependencies:** [Marketing Department](../marketing/MARKETING_DEPARTMENT.md),
  [Brand Foundation](../brand/BRAND_FOUNDATION.md), and verified implementation
  evidence from the responsible lane.
- **Review gate:** Marketing Agent confirms the two child artifacts remain
  consistent; relevant implementation owners verify every material claim; Art &
  Technical Art accepts any gameplay capture or in-game visual interpretation.
- **Art / Technical Art impact:** Consulted — the initiative crosses the
  in-game-art, gameplay-capture, and public-visual boundary.
- **Routing:** Action required — Marketing Agent, and Product Owner only if a
  master-identity, publication, spend, or commercial gate is proposed;
  Consulted — Art & Technical Art and the relevant World Generation or Systems
  evidence owner; Informed — Project Steward.
- **Evidence:** Marketing's accepted operating model identifies claims discipline
  and honest capture as current-stage responsibilities.
- **Next action:** Project Steward dispatches `MKT-002` and `MKT-003` to their
  separate owners; Marketing Agent synthesizes only after both are reviewed.
- **Blocker:** None.

## MKT-002 — Build the claims-and-evidence ledger

- **Type:** Packet
- **DRI:** Brand Steward
- **State:** Ready
- **Priority:** P1
- **Updated:** 2026-08-22
- **Outcome:** Every material candidate claim is tied to canonical evidence and
  an explicit product-evidence state.
- **Done when:** `docs/marketing/CLAIMS_AND_EVIDENCE.md` records claim, source,
  evidence state, verifier, expiry/recheck trigger, and allowed use; Marketing
  Agent and named evidence owners accept it.
- **Base:** Record current canonical `main` when the packet is claimed.
- **Branch / worktree:** `docs/MKT-002-claims-evidence-ledger` in the Brand
  Steward task worktree.
- **Write scope:** New `docs/marketing/CLAIMS_AND_EVIDENCE.md` only.
- **Dependencies:** [Marketing Department](../marketing/MARKETING_DEPARTMENT.md),
  [Brand Foundation](../brand/BRAND_FOUNDATION.md), and canonical implementation
  evidence from each named owner.
- **Review gate:** Marketing Agent plus each owner whose behavior supports a
  material claim.
- **Art / Technical Art impact:** Consulted — whenever a claim uses in-game
  visual evidence; text-only claims remain Marketing-owned.
- **Routing:** Action required — Marketing Agent and named evidence owners;
  Consulted — Audience Intelligence for audience interpretation, plus Dev Review
  when a material public claim is proposed, plus Art & Technical Art when
  in-game visual evidence is used; Informed — Visual Brand & Capture and Project
  Steward.
- **Evidence:** Marketing's evidence order prohibits planned work from being
  described as demonstrated.
- **Next action:** Brand Steward claims the current base, creates the named
  branch, and drafts the ledger without modifying the capture brief.
- **Blocker:** None.

## MKT-003 — Define private capture readiness

- **Type:** Packet
- **DRI:** Visual Brand & Capture
- **State:** Ready
- **Priority:** P1
- **Updated:** 2026-08-22
- **Outcome:** Marketing has a private capture brief grounded in demonstrable
  build behavior and explicit asset provenance.
- **Done when:** `docs/marketing/PRIVATE_CAPTURE_BRIEF.md` distinguishes gameplay,
  concept, and planned shots; records source/rights requirements; and is accepted
  by the Marketing Agent and relevant implementation owner.
- **Base:** Record current canonical `main` when the packet is claimed.
- **Branch / worktree:** `docs/MKT-003-private-capture-readiness` in the Visual
  Brand & Capture task worktree.
- **Write scope:** New `docs/marketing/PRIVATE_CAPTURE_BRIEF.md` only.
- **Dependencies:** [Marketing Department](../marketing/MARKETING_DEPARTMENT.md),
  [Brand Foundation](../brand/BRAND_FOUNDATION.md), the
  [Art Team API](../art/README.md), and demonstrated client behavior from the
  Bevy Client owner.
- **Review gate:** Marketing Agent, Bevy Client for capture feasibility, and
  Art & Technical Art for visual fidelity, and Brand Steward for claims
  consistency.
- **Art / Technical Art impact:** Action required — gameplay capture and its
  depiction must satisfy in-game visual truth and quality criteria.
- **Routing:** Action required — Marketing Agent, Art & Technical Art, and Bevy
  Client; Consulted — Brand Steward; Informed — Project Steward. Product Owner
  becomes action-required only if publication, spend, account mutation, or
  master identity enters scope.
- **Evidence:** The current build can open a Bevy map window; world generation
  and map interaction are not yet demonstrated.
- **Next action:** Visual Brand & Capture claims the current base, creates the
  named branch, and drafts the private brief without modifying the claims ledger.
- **Blocker:** None.
