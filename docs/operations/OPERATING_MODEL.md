# Project Operating Model

- **Status:** Accepted
- **Adopted:** 2026-08-22
- **Control-plane owner:** Project Steward
- **Decision record:** [ADR-0001](../decisions/ADR-0001-project-control-plane.md)

## Purpose

This model lets several capable agents work at once without making the Product
Owner dispatch tasks, reconcile handoffs, choose merge timing, or clean up Git.
The repository is durable shared memory; chat, agent memory, and unmerged
worktrees are temporary working context.

The control plane consists of this operating model, the live
[workstream ledger](WORKSTREAMS.md), the
[dependency and notification map](DEPENDENCIES.md), and the
[decision record system](../decisions/README.md). Product truth remains in the
focused vision, roadmap, architecture, world-generation, art, brand, and
marketing documents. The control plane routes work; it does not redefine that
truth.

## Operating laws

1. **One outcome, one DRI.** Every active packet has exactly one directly
   responsible individual or agent. Contributors may be many; accountability is
   singular through integration and cleanup.
2. **Work through Team APIs.** Departments publish what they own, accept, and
   produce. Work crosses a boundary through an explicit input or output, not an
   assumed conversation.
3. **Parallelize independent scopes.** Agents may read globally but declare a
   narrow write scope. Shared contracts and high-contention files have one
   writer at a time.
4. **Canonical artifacts beat summaries.** A decision, interface, or product
   fact is not handed off until it is recorded in its authoritative repository
   document and linked from the work packet.
5. **Evidence closes work.** “Done” means integrated, validated, routed to
   affected consumers, and cleaned up—not merely written in a worktree.
6. **Reversible routine decisions are autonomous.** Qualified agents choose
   task decomposition, reviewers, merge order, conflict mechanics, and safe Git
   cleanup. They do not delegate those chores to the Product Owner.
7. **Escalate authority, not uncertainty.** Agents investigate ambiguity and
   recommend a resolution. Escalation occurs only when the decision belongs to
   another authority or would create material irreversible consequences.

## Roles and decision rights

### Product Owner

Owns the product vision, player promise, material scope or priority changes,
commercial commitments, public release, and irreversible external actions. The
Product Owner is informed of meaningful outcomes and asked only for decisions
that genuinely require product authority.

The Product Owner does **not** own branch management, worktree disposal, routine
merge timing, reviewer selection, document placement, task routing, or
reversible implementation choices.

### Project Steward

Owns flow across departments. The Steward maintains the live ledger, detects
overlap and stale baselines, routes dependency changes, appoints an integration
DRI, confirms handoffs, and keeps repository state recoverable and current.

The Steward may split, sequence, pause, reassign, integrate, and close routine
work. It cannot overrule a domain owner on domain meaning, silently change
product direction, or become the only holder of project context.

### Department lead

Owns accepted meaning inside a durable domain boundary, maintains its Team API,
and decides routine domain questions. A lead consults consumers before changing
an exported contract and supplies evidence when another department depends on
its output.

### Workstream DRI

Owns one ledger outcome from readiness through integration, notification, and
cleanup. The DRI supplies an accurate update whenever state, scope, dependencies,
base, or next action changes; the Project Steward serializes it into the
canonical ledger. Delegation does not transfer accountability unless the ledger
names a new DRI.

### Integration DRI

The workstream DRI integrates by default. The Project Steward may appoint a
different integration DRI for cross-department or high-contention work, but the
handoff must name that person or agent explicitly.

## Work lifecycle

```text
Proposed -> Ready -> Active -> Review -> Integration -> Done
                 \-> Blocked -> Ready/Active
Any live state -------------------------------> Cancelled
```

| State | Meaning | Exit condition |
| --- | --- | --- |
| `Proposed` | Useful outcome identified; not safe to start | Scope, DRI, dependencies, and completion evidence are defined |
| `Ready` | Can start from current canonical truth | DRI claims a current base and write scope |
| `Active` | Work is being produced | Acceptance evidence is ready for an independent check |
| `Blocked` | Progress requires unavailable authority or external state | Blocker and owner are resolved; ordinary uncertainty is not a blocker |
| `Review` | Dev Review or a required domain owner is checking the result | Blocking findings are resolved and required decisions recorded |
| `Integration` | Approved result is being reconciled with canonical `main` | Merge/push succeeds, canonical validation passes, routes are delivered |
| `Done` | Outcome is canonical, verified, communicated, and cleaned up | May be removed from the live ledger after one review cycle |
| `Cancelled` | Outcome is intentionally abandoned or replaced | Rationale and replacement, if any, are recorded |

Large outcomes are initiatives. Before implementation, the Steward splits an
initiative into bounded packets with independent write scopes. One packet must
not hide several competing DRIs.

## Autonomous execution loop

### 1. Frame

The DRI supplies the outcome, “done when” evidence, owner, consumers,
dependencies, write scope, and review gate. The Steward records it in
`WORKSTREAMS.md` during the serialized ledger window. If the outcome would
settle a material unresolved choice, the DRI opens an ADR before coding.

### 2. Establish a safe base

The DRI reads the current handoff and relevant canonical documents, fetches
available remote state, and inspects branches, worktrees, and overlapping live
packets. It records the actual base commit and creates a named branch before the
first durable commit.

Preferred branch form is `type/WORK-ID-short-description`, where `type` is such
as `docs`, `feat`, `fix`, `refactor`, or `ops`. One packet uses one branch and
one primary worktree. The integration checkout stays on `main` when practical.

### 3. Produce and synchronize

The DRI commits coherent increments, keeps the packet narrow, and rebases or
merges current canonical state often enough to expose conflicts early. A change
to an exported contract triggers the routes in `DEPENDENCIES.md`; it does not
wait for final review.

### 4. Review and decide

The independent Dev Review gate checks correctness, accepted architecture,
maintainability, hidden long-term blocks, migration risk, and validation. Domain
owners decide meaning at their boundary. Material decisions receive an ADR;
routine implementation detail stays in the change and its tests.

### 5. Integrate and route

The integration DRI updates from canonical `main`, resolves mechanical conflicts,
reruns proportionate validation, and merges through the repository's protected
workflow. If no hosted pull-request gate exists, the same review and validation
evidence is still required before updating `main` and the remote.

After integration, the DRI sends each action-required, consulted, or informed
recipient a link to the canonical diff or ADR. A chat summary without a durable
link is not a handoff.

### 6. Close and clean

The DRI proves the exact submitted task head was integrated. Ancestry proves a
merge/rebase; for a squash, the merged PR must record the same task head, its
merge commit must be on canonical `main`, and the task branch must have no later
commits. The DRI then removes the clean worktree and branch, prunes stale
metadata, and supplies closure evidence for the Steward to mark `Done`. This
happens without a Product Owner prompt.

## Git recovery and housekeeping

Agents resolve routine Git state themselves using evidence, not age or guesswork:

1. Inspect cleanliness, HEAD, branch attachment, upstream, unique commits, and
   reachability from canonical `main`.
2. Never discard dirty files, unmerged commits, or unpublished unique work.
3. Attach useful detached or unique work to a named task or `rescue/` branch,
   record its owner in the ledger, then review and integrate or cancel it.
4. For stale but valid work, update from canonical `main`, resolve conflicts
   inside the packet's ownership boundary, validate, and integrate. A semantic
   conflict goes to the relevant domain owner, not automatically to the Product
   Owner.
5. Remove a clean worktree only after its useful changes are reachable from a
   retained ref or represented by the exact head of a merged squash PR, and no
   live packet names it. Prefer safe branch deletion. If `git branch -d` rejects
   only because a verified squash is not an ancestor, `git branch -D` is allowed
   for that exact branch after proving no post-submission commits exist.
6. Publish the intended canonical baseline and confirm local/remote agreement.
   Unavailable network state is recorded and retried by the Steward.

The Project Steward performs a repository-state check before each integration
wave and after it closes. Agents do not ask the Product Owner whether an old
branch “looks safe” to merge or delete; they establish whether it is safe.

## Handoff contract

A handoff is complete when the next owner can act without reconstructing chat.
It contains:

- work ID, outcome, DRI, and exact requested next action;
- canonical artifact plus base/head commits and branch;
- decisions made, still open, or superseded;
- exported contracts, invariants, or product facts changed;
- validation and review evidence;
- risks, blockers, and rollback or recovery path; and
- routing: `Action required`, `Consulted`, and `Informed` recipients.

Each workstream section is the default durable handoff endpoint until it links a
packet issue or pull request. The receiving DRI acknowledges through that linked
execution channel; the Project Steward records the acknowledgement in the sole
canonical ledger, follows missing responses, and reroutes work. The Product
Owner is not the reminder system.

## Escalation boundary

Resolve at the lowest authority that owns the consequence:

| Decision class | Decider | Examples |
| --- | --- | --- |
| Routine and reversible | Workstream DRI | Local structure, naming, test shape, conflict mechanics, branch cleanup |
| Domain contract | Department lead | World invariant, core API, client interaction, build policy, brand application |
| Cross-domain | Named owner in an ADR, coordinated by Steward | Authority boundary, persistence contract, shared data model |
| Product or irreversible | Product Owner or qualified external authority | Player promise, material scope tradeoff, publication, spend, legal commitment, destructive external action |

Escalate immediately for credible security/privacy exposure or unrecoverable
data loss. Otherwise, a Product Owner escalation must present one concrete
decision, a recommended default, viable alternatives, and consequences. “What
should I do next?” is not an escalation packet.

## Team APIs

### Project Steward

- **Mission:** Maintain coherent flow, current shared state, and safe
  integration across departments.
- **Owns:** Workstream ledger, dependency routing, integration assignment,
  cross-team handoffs, repository-state audit, and operational ADRs.
- **Accepts:** Desired outcomes, domain artifacts, review findings, dependency
  changes, and repository-state evidence.
- **Produces:** Ready packets, routed decisions, integration order, closed
  handoffs, and a clean canonical baseline.
- **Does not own:** Product meaning, scientific/world meaning, architecture
  meaning, implementation inside a lane, or marketing truth.

### World Generation

- **Mission:** Define a causal, coherent natural world before implementation
  freezes its abstractions.
- **Owns:** World-generation intent, physical dependency models, causal rules,
  invariants, terminology, scope boundaries, and decision-ready specifications
  under `docs/world-generation/`.
- **Accepts:** Vision and design principles, scientific evidence, prototype
  questions, systems constraints, and Dev Review findings.
- **Produces:** Canonical design notes, explicit invariants, provisional
  contracts, acceptance examples, unresolved questions, and implementation
  requirements for Systems Architecture.
- **Internal flow:** Designer develops the causal model; specification developer
  makes it testable and explicit; one World Generation DRI owns the combined
  result through review.
- **Does not own:** Rust implementation, Bevy presentation, platform policy, or
  final architecture choices outside world meaning.

### Systems Architecture

- **Mission:** Translate accepted product and world intent into sustainable
  technical boundaries and an integrated executable system.
- **Owns:** Architecture contracts, dependency direction, authority boundaries,
  cross-lane technical decisions, non-functional constraints, and the technical
  delivery map.
- **Accepts:** Accepted domain specifications, prototype success criteria,
  performance or portability evidence, and lane proposals.
- **Produces:** Architecture decisions, interface contracts, allocated packets,
  integration plans, and verified system behavior.
- **Does not own:** Product vision, world-generation meaning, brand decisions,
  or every implementation detail inside a stable lane contract.

#### World Core lane

- **Owns:** `crates/world_core`, renderer-independent world/simulation types and
  algorithms, deterministic behavior, core tests, and exported query contracts.
- **Produces:** Bevy-free APIs, reproducibility evidence, fixtures, and semantic
  world data.
- **Must consult:** World Generation when physical meaning changes; Systems
  Architecture and Bevy Client before changing an exported contract; Art &
  Technical Art when queries, classifications, LOD, refinement, or derived data
  alter visual interpretation.
- **Does not own:** Rendering, input, UI lifecycle, or Bevy types.

#### Bevy Client lane

- **Owns:** `crates/client`, Bevy runtime, map rendering, cameras, input,
  selection, presentation adapters, and client-side diagnostics.
- **Produces:** Demonstrable player-visible behavior, capture-ready evidence,
  and client requirements on World Core APIs.
- **Must consult:** World Core on queries and data semantics; Systems
  Architecture on boundary changes; Art & Technical Art on player-visible
  behavior or visual contracts; Marketing when behavior becomes a public claim.
- **Does not own:** Canonical world truth, simulation rules, or acceptance of
  in-game visual language.

#### Rust Platform lane

- **Owns:** Workspace manifests, toolchain, dependency and feature policy, CI,
  release/build mechanics, portability checks, and shared developer tooling.
- **Produces:** Reproducible builds, enforced quality gates, dependency-change
  evidence, and platform guidance.
- **Must consult:** Every affected crate owner before a shared dependency,
  feature, toolchain, or CI contract changes; Art & Technical Art when an asset,
  shader, material, capture, or rendering-tool pipeline changes.
- **Does not own:** Domain behavior or application architecture solely because
  it maintains the build.

The three lanes remain under Systems Architecture until recurring independent
backlogs and stable contracts justify separate departments. Lane-local work is
autonomous inside accepted contracts.

### Art & Technical Art

- **Mission:** Make the simulated world legible, coherent, feasible to produce,
  and visually honest without converting presentation into canonical truth.
- **Owns:** Accepted in-game visual contracts and player-visible
  interpretation: map and camera language, projection and zoom behavior,
  picking feedback, rendering conventions, shaders, materials, assets,
  LOD/streaming presentation, technical-art pipelines, visual acceptance, and
  the visual truth of gameplay capture. The canonical boundary is
  [Art & Technical Art](../art/README.md).
- **Accepts:** Canonical world meaning, World Core query contracts, client and
  platform constraints, prototype goals, performance evidence, brand guidance,
  and review findings.
- **Produces:** Visual contracts, reference states, asset and pipeline
  requirements, acceptance evidence, technical-art decisions, and bounded
  implementation requirements for Systems Architecture and Bevy Client.
- **Must consult:** World Generation whenever a depiction asserts physical or
  simulation meaning; Systems Architecture and World Core on data/query
  feasibility; Bevy Client and Rust Platform on runtime and pipeline
  feasibility; Marketing when gameplay capture becomes market-facing material.
- **Does not own:** Canonical world or simulation truth, Rust/Bevy architecture,
  public positioning, campaign strategy, or final product authority.

<!-- ART-CONTRACT: IMPACT-DECLARATION -->
Every meaningful packet, decision RFC, review finding, and pull request declares
`Art / Technical Art impact` as `Action required`, `Consulted`, `Informed`, or
`N/A — <rationale>`. Art is action-required for accepted player-visible visual
contracts and gameplay capture, consulted for upstream changes that can alter
visual interpretation, and informed when an accepted visual consumer is merely
receiving a semantically neutral implementation update.
<!-- ART-CONTRACT: REVIEW-GATE -->
`Action required` blocks acceptance and integration until the Art & Technical
Art owner records `Accepted`. For depictions of world or simulation meaning,
the owning domain also verifies semantic honesty. A concrete `N/A` rationale is
required when the gate does not apply; leaving the field blank is not routing.

### Marketing

- **Mission:** Turn verified project truth into distinctive positioning,
  credible demand, and useful market learning.
- **Owns:** The accepted brand system, audience evidence, market-facing visual
  applications, claims discipline, capture briefs, and marketing recommendations
  described in [Marketing Department](../marketing/MARKETING_DEPARTMENT.md).
- **Accepts:** Canonical product truth, implementation evidence, approved brand
  direction, Art-accepted gameplay capture, research, and capture artifacts.
- **Produces:** Evidence-labelled claims, research briefs, brand applications,
  capture plans, and publication-ready recommendations.
- **Must consult:** The implementing or domain owner for every material product
  claim and Art & Technical Art for gameplay capture or in-game visual meaning.
  Public release, spend, account mutation, or commercial commitment remains
  Product Owner gated.
- **Does not own:** Product design, in-game visual acceptance, implementation
  status, legal clearance, or permission to describe planned work as
  demonstrated.

### Dev Review gate

Dev Review is an independent gate, not a downstream department and not a second
implementation owner.

- **Mission:** Find correctness faults, accepted-architecture violations,
  maintainability traps, hidden long-term blocks, migration hazards, and missing
  evidence before integration.
- **Accepts:** The scoped artifact, acceptance criteria, relevant ADRs, diff,
  tests or document checks, and the author's known-risk statement.
- **Produces:** `Approve`, `Request changes`, or `Decision required`, with each
  finding tied to evidence and an owner.
- **Blocking findings:** Correctness, security, data loss, accepted contract
  violation, unrecoverable migration risk, or unmet completion criteria.
- **Non-blocking findings:** Preferences, optional polish, and unrelated scope
  expansion. These become follow-up packets only when worthwhile.
- **Does not own:** Rewriting the work, changing product direction, or keeping a
  packet in indefinite review.

Review independence means the reviewer did not author the material being
approved. Review depth follows consequence: focused documents and local code
receive focused review; shared contracts and irreversible migrations receive a
broader gate.

## Department lifecycle

A new department or standing lane requires a recurring backlog, a stable
ownership boundary, named inputs and outputs, identifiable consumers, and enough
cognitive load to justify permanent coordination cost. Temporary expertise is
a workstream contributor or review gate. The Steward retires empty structures
and returns their durable artifacts to the nearest owning Team API.
