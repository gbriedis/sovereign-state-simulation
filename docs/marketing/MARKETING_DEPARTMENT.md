# Marketing Department

- **Status:** Accepted operating model
- **Adopted:** 2026-08-22
- **Department lead:** Marketing Agent
- **Standing desks:** Brand Steward, Audience Intelligence, Visual Brand & Capture

## Mission

Turn project truth into a distinctive identity, credible demand, and useful
market learning. Marketing makes *State of Consequence* understandable and
desirable without advertising imagined features as present reality.

> Marketing may sharpen the promise, but it may never outrun the build.

The department lead owns synthesis, priorities, cross-department coordination,
and final Marketing recommendations. The user retains approval over material
brand-foundation or master-identity changes, commercial commitments, publication,
spend, and account-level actions; routine applications inside the accepted brand
system are Marketing-owned.

## Standing desks

### Brand Steward

**Owns:** positioning, naming usage, messaging architecture, voice, technical-to-
player narrative, claims discipline, copy review, and brand briefs.

**Produces:** revisions to the brand foundation, a claims-and-evidence ledger,
message frameworks, feature-benefit-proof cards, copy standards, naming
assessments, and clear creative briefs.

**Does not own:** product vision, game mechanics, legal clearance, or visual
asset production. It escalates product conflicts to the relevant owner and
routes in-game visual meaning or production requirements through the standing
[Art & Technical Art Team API](../art/README.md).

### Audience Intelligence

**Owns:** audience hypotheses, player language, category and competitor
research, market signals, research plans, interview and playtest synthesis, and
evidence behind positioning or channel recommendations.

**Produces:** sourced market briefs, audience profiles, comparison maps,
validation questions, research summaries, and implications for the lead.

**Does not own:** product design, roadmap priority, unsupported market-size
claims, or final brand decisions. Time-sensitive findings must be sourced and
dated; assumptions must be labeled as assumptions.

### Visual Brand & Capture

**Owns:** the external visual identity system, typography and palette
exploration, accessible brand applications, campaign asset specifications,
screenshot and footage briefs, visual templates, and marketing-asset
provenance.

**Produces:** identity explorations, visual standards, asset templates, capture
briefs, capsule and key-art specifications, and source and usage-rights records.

**Does not own:** in-game UX, fabricated gameplay, unapproved master identity or
key art, or publication. AI-generated or concept imagery must never be presented
as game footage. In-game visual language, runtime-art assets, technical-art
pipelines, and gameplay-capture fidelity route through the standing
[Art & Technical Art Team API](../art/README.md).

## Shared evidence order

Before acting, each desk reads:

1. `../handoff/CURRENT_STATE.md` for what exists now.
2. `../operations/WORKSTREAMS.md` and the assigned work packet for active scope,
   dependencies, and affected owners.
3. The task-relevant product, roadmap, architecture, and decision documents.
4. `../PROJECT_VISION.md` and `../DESIGN_PRINCIPLES.md` for enduring intent.
5. `../art/README.md` for in-game visual or gameplay-capture boundaries when the
   packet touches them.
6. `../brand/BRAND_FOUNDATION.md` for accepted public identity and claims rules.

When these sources conflict, the desk reports the conflict to the Marketing
Agent rather than silently resolving it. Proposed features, open decisions, and
long-term direction must never be described as implemented.

Material outward-facing claims must carry one of these evidence states while
they are being drafted or reviewed: `Demonstrated`, `In development`, `Planned`,
`Long-term direction`, or `Optional exploration`. The label need not appear in
finished prose when the status is already unmistakable, but it must remain in
the working brief or claims ledger.

## Decision rights and handoffs

| Concern | Accountable owner | Marketing responsibility |
| --- | --- | --- |
| Product truth and game direction | Product / user | Interpret accurately; do not redefine |
| Implemented-state evidence | Implementing department | Verify before making a claim |
| Brand system and public framing | Marketing Agent | Decide within accepted direction; escalate material changes |
| Brand consistency | Brand Steward | Review and recommend |
| Audience and market evidence | Audience Intelligence | Research, qualify, and synthesize |
| External visual brand and capture-brief system | Visual Brand & Capture | Design public applications, specify captures, and verify brand consistency and rights |
| In-game visual language, technical-art pipeline, and gameplay-capture fidelity | Art & Technical Art | Supply a brand/capture brief; consume Art-accepted visual evidence |
| Campaign and community plan | Marketing Agent | Plan now; form a dedicated desk after its activation gate |
| Pricing, packaging, partnerships, and commercial strategy | Marketing Agent | Develop recommendations with Audience Intelligence evidence |
| Legal clearance | User / qualified counsel | Identify the gate; never imply clearance |
| Public release, spend, or account mutation | User | Prepare and recommend; act only with approval |

Specialists submit their assigned packet branch and pull request to the
Marketing Agent for domain review. The Marketing Agent synthesizes the outputs;
the named packet Integration DRI lands each packet under Project Steward
serialization. No shared Marketing branch or cross-worktree commit sweep is
used.

Project-wide ownership, handoff, Git, and notification rules are governed by
`../operations/OPERATING_MODEL.md`, `../operations/DEPENDENCIES.md`, and the root
`AGENTS.md`. Marketing supplies accurate impact and evidence metadata; the
Project Steward handles routine integration and cleanup without asking the user
to coordinate Git. User approval remains required for the external actions and
product/brand decisions listed above.

## Operating loop

1. **Frame:** define the audience, desired response, decision, and success
   signal.
2. **Verify:** check current product evidence, accepted brand direction, and
   relevant market sources.
3. **Assign:** send focused work to the desk with the clearest ownership.
4. **Synthesize:** the Marketing Agent resolves overlaps and forms one
   recommendation.
5. **Review:** obtain product, systems, Art & Technical Art, legal, or user review where the
   decision crosses an ownership boundary.
6. **Release:** publish or spend only after explicit approval.
7. **Learn:** record outcomes, update the relevant durable document, and retire
   disproven assumptions.

## Current-stage priorities

During the natural-world foundation phase:

- **Brand Steward** protects the accepted identity and connects technical work
  to the player promise of consequential stewardship.
- **Audience Intelligence** validates audience language and category context
  without pretending there is launch-scale evidence.
- **Visual Brand & Capture** develops private identity directions and prepares
  honest capture briefs; it does not accept in-game visual fidelity, lock or
  publish a master identity, or bypass Art, clearance, and approval gates.

The Brand Steward may prepare **Before the Border** development stories using
verified foundation work. **The Country Reacts** waits for demonstrable actor or
institution responses; **Decades Later** waits for visible transformation across
simulated time.

Current measures should emphasize message comprehension, qualified interest,
research quality, development-story consistency, and the supply of honest visual
proof. Wishlist conversion, playtest acquisition, retention, paid efficiency,
and launch reach become primary only when the corresponding product and channels
exist.

## Department growth rule

Keep the department at three standing specialist desks until workload and proof
create a real recurring ownership boundary. Community & Campaigns activates
when testable footage or a build can support private research and an approved
public cadence. Storefront & Growth and Press & Creators activate at a stable,
capture-ready commercial vertical slice. Lifecycle, paid acquisition,
commercial operations, and localization become desks only when recurring work,
live channels, and sufficient evidence justify them.
