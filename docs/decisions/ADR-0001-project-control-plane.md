# ADR-0001: Adopt an autonomous project control plane

- **Status:** Accepted
- **Date:** 2026-08-22
- **Decision owner:** Product Owner
- **DRI:** Project Steward
- **Scope:** Cross-department coordination, handoffs, review, decisions, and Git
- **Art / Technical Art impact:** Action required — establishes the standing Art
  Team API, visual-review triggers, handoff payload, and enforcement contract
- **Consulted:** World Generation domain reviewer, Systems Architect, Art & Technical Art reviewer, Marketing Agent, and independent Dev Review
- **Informed:** All project contributors and agents
- **Supersedes:** None
- **Related work:** `OPS-001`, `OPS-002`

## Context

World Generation, specification development, Dev Review, Systems Architecture
and its World Core/Bevy Client/Rust Platform lanes, Art & Technical Art, and
Marketing now operate in parallel. This increases useful throughput but also
creates several risks:

- decisions and handoffs can remain trapped in agent conversations;
- departments can change a contract without reaching every consumer;
- several agents can write the same shared file from different baselines;
- detached or stale worktrees can contain unowned work; and
- routine integration and cleanup can fall back to the Product Owner.

The repository already serves as the project knowledge base and contains focused
vision, architecture, world-generation, handoff, art, brand, and marketing
records. The missing layer is an operational control plane that connects those
sources without becoming another product specification.

## Decision

Adopt a repository-native control plane with these parts:

1. A Project Steward maintains flow, the live workstream ledger, dependency
   routes, integration assignment, and safe repository housekeeping.
2. Every active delivery packet has one DRI, an observable outcome, a declared
   write scope, current base, dependencies, review gate, and completion evidence.
3. Departments expose Team APIs. Systems Architecture contains the World Core,
   Bevy Client, and Rust Platform lanes until recurring independent ownership
   justifies promotion. Art & Technical Art is a standing department that owns
   accepted in-game visual contracts and technical-art pipelines, distinct from
   Marketing's public identity and communications scope. Dev Review is an
   independent gate, not a department.
4. Changes route as `Action required`, `Consulted`, or `Informed` according to a
   maintained dependency matrix. Canonical links, not chat summaries, carry the
   handoff.
5. Material decisions use numbered ADRs. Focused documents remain authoritative
   for current product/domain truth; ADRs preserve rationale and consequences.
6. One delivery packet uses one named branch, one primary worktree, and one
   integration path. Agents autonomously reconcile current `main`, validate,
   merge, publish, and safely remove proven-obsolete work.
7. The Product Owner decides product-defining and materially irreversible
   choices. Qualified agents own routine task routing, implementation, review,
   conflict resolution, merge timing, and Git cleanup.

The complete behavior is defined in
[Project Operating Model](../operations/OPERATING_MODEL.md),
[Active Workstreams](../operations/WORKSTREAMS.md), and
[Dependencies and Notification Routing](../operations/DEPENDENCIES.md).

## Team impact and routing

| Team or lane | Route | Required action or consequence |
| --- | --- | --- |
| Project Steward | Action required | Maintain ledger, routes, integration waves, and repository hygiene |
| World Generation | Consulted | Use one DRI across designer/specification flow and export testable contracts |
| Systems Architecture | Consulted | Maintain lane contracts and assign cross-lane integration ownership |
| World Core | Informed | Declare API/write scopes and provide deterministic evidence |
| Bevy Client | Informed | Keep presentation separate and route demonstrable behavior |
| Rust Platform | Informed | Serialize shared build files and maintain governance checks |
| Art & Technical Art | Consulted | Accept its Team API, mandatory visual-review triggers, semantic-honesty handoffs, and gameplay-capture boundary |
| Marketing | Consulted | Continue evidence-led claims and consume only verified product truth |
| Dev Review | Action required | Operate as an independent, evidence-based gate |
| Product Owner | Informed | Receive outcomes; decide only product or irreversible escalations |

## Alternatives considered

### Product Owner as central dispatcher

This keeps authority obvious but turns routine routing, reminders, Git mechanics,
and merge decisions into Product Owner work. It does not scale with parallel
agents and was rejected.

### Independent department records without a shared control plane

This gives local autonomy but leaves cross-department dependencies, status, and
integration implicit. Contract drift would be detected late, so it was rejected.

### An external task tracker as the primary system

An external tracker could improve views and automation, but it would create a
second source of truth before repository discipline is established. External
views may be added later as projections of repository records, not replacements.

### Long-lived department branches

Permanent branches isolate teams but accumulate integration drift and obscure
which outcome owns a change. Short-lived outcome branches with explicit scopes
were selected instead.

## Consequences

### Enables

- Departments can act independently inside known boundaries.
- Consumers learn of material changes through deterministic routes.
- Review, integration, and Git cleanup have accountable owners.
- New agents can reconstruct current work from repository artifacts.
- Product Owner attention is reserved for product and irreversible decisions.

### Costs and risks

- The Steward and DRIs must keep a small amount of metadata current.
- The ledger and shared indexes can become contention points unless one writer is
  assigned during an integration wave.
- Process can become bureaucracy if every local detail becomes an ADR or packet;
  the model therefore limits records to meaningful outcomes and durable choices.
- The Project Steward can become a bottleneck if it hoards context; Team APIs,
  canonical links, and delegated integration prevent that dependency.

## Adoption and verification

- Install the three operational documents and ADR system.
- Reference the control plane from repository-level agent entry guidance.
- Validate ADR filenames/statuses, workstream metadata, and internal links in CI
  or an equivalent repository check.
- Reconcile the current canonical branch and detached worktree inventory under
  `OPS-002`.
- Review the model after the first completed multi-department integration wave
  and simplify any field that did not improve routing or recovery.

## Reversal or supersession

The system is repository-native and reversible: remove enforcement only after
all live packets and decisions have another canonical home. A later ADR may
supersede this model if operational evidence shows a different system improves
flow without restoring Product Owner micromanagement or creating competing
sources of truth.
