# Documentation Guide

This directory is the durable project knowledge base. Information is separated
by purpose and change rate so humans and AI agents can identify what is
authoritative without reconstructing chat history.

Project-wide working behavior is defined in `../AGENTS.md`. The operating model,
active work, dependency routing, and decision system live under `operations/`
and `decisions/`.

## Canonical information map

1. **Vision** — enduring product intent and boundaries.
2. **Principles** — rules used to judge designs and implementations.
3. **Accepted decisions** — dated rationale and consequences for significant
   choices.
4. **Art, brand, and domain truth** — accepted in-game visual language, public
   identity, architecture, and focused world/system direction.
5. **Roadmaps and specifications** — milestone scope, contracts, and definitions
   of completion.
6. **Open-question inventories** — unresolved discovery material that is not yet
   accepted architecture or committed work.
7. **Operations** — ownership, review gates, live work, dependencies, and change
   routing.
8. **Handoffs** — concise operational snapshots pointing to the canonical
   artifacts above.

Give each fact one canonical home and link to it elsewhere. When documents
conflict, prefer the more specific accepted source. If equal-authority sources
conflict, stop the affected implementation, record the conflict in the work
packet, and route it to the accountable owner. Do not resolve it silently.

## Key operating documents

| Need | Canonical document |
| --- | --- |
| Catch up on present state | `handoff/CURRENT_STATE.md` |
| See active owners, branches, blockers, and merge order | `operations/WORKSTREAMS.md` |
| Understand departments, authority, and review gates | `operations/OPERATING_MODEL.md` |
| Route cross-department changes | `operations/DEPENDENCIES.md` |
| Understand in-game visual and technical-art authority | `art/README.md` |
| Understand or create a significant decision | `decisions/README.md` |
| See unresolved architecture discovery questions | `architecture/OPEN_DECISIONS.md` |

## Update rules

- Change `PROJECT_VISION.md` only when the Product Owner accepts a change to the
  product vision.
- Change `DESIGN_PRINCIPLES.md` only when a governing design rule changes.
- Change `brand/BRAND_FOUNDATION.md` only when the accepted public identity or
  messaging system changes.
- Change canonical files under `art/` only through the Art & Technical Art Team
  API and its required semantic, feasibility, and visual-acceptance gates.
- Change `marketing/MARKETING_DEPARTMENT.md` only when Marketing ownership,
  decision rights, or operating workflow changes.
- Update roadmaps and specifications when milestone scope, contracts, or
  completion criteria change.
- Record significant accepted choices in `decisions/`; update architecture or
  domain overviews with the resulting current truth.
- Treat `architecture/OPEN_DECISIONS.md` as an inventory, not a work queue.
  Promote an actionable choice into a work packet and decision record rather
  than silently implementing one of its options.
- The Project Steward maintains `operations/WORKSTREAMS.md`. Task owners supply
  accurate handoff data; they do not create competing global status summaries.
- The accountable producer and Project Steward maintain
  `operations/DEPENDENCIES.md` when a durable producer/consumer relationship or
  notification trigger changes.
- Refresh `handoff/CURRENT_STATE.md` after meaningful integration, phase, or
  priority changes. Keep it short and link to canonical detail.
- Include dates and verification references in operational snapshots and
  decision records, not in timeless prose unless the date is itself important.

## Agent catch-up order

For a general task, read:

1. `handoff/CURRENT_STATE.md`
2. `operations/WORKSTREAMS.md`
3. `operations/OPERATING_MODEL.md`
4. The task-relevant roadmap, specification, architecture, decision, and domain
   documents
5. `PROJECT_VISION.md` and `DESIGN_PRINCIPLES.md` when making design choices

For in-game visuals, world depiction, camera/zoom/picking behavior, runtime art,
or gameplay capture, also read `art/README.md`. For naming, public copy, public
visual identity, community messaging, or market-facing work, also read
`brand/BRAND_FOUNDATION.md` and `marketing/MARKETING_DEPARTMENT.md`.

Do not treat proposals, worktree state, open questions, accepted-but-unimplemented
decisions, or long-term direction as demonstrated product features.
