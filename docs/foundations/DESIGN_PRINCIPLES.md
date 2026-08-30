---
id: PRINCIPLES-001
type: design-principles
status: accepted
scope: Governing product and technical design rules
authority: Owns the principles used to evaluate product, simulation, and architecture choices
last_reviewed: 2026-08-30
---

# Design Principles

## Christian design foundation

*State of Consequence* has a Christian design foundation. The game should seek
to honor God by treating creation as an ordered reality with causes,
relationships, limits, and consequences rather than as disconnected material
for arbitrary mechanics. Creation exists independently of the player, and
natural systems precede and constrain human systems.

This foundation does not require infinite simulation detail, and Scripture must
not be treated as a numerical physics manual. Abstraction is necessary, but it
should preserve the relationships that matter to governing a nation. Systems
should arise from meaningful causes wherever the intended experience depends on
those causes.

The player is a limited human ruler within creation, not an omniscient creator
standing outside it. Governing should substantially concern cultivation,
stewardship, peaceful development, cooperation, institutions, and living within
natural limits. War belongs in the world, but it should not become the primary
source of enjoyment or the standard answer to national development.

The principles below apply this foundation to product and technical choices.

## Reality-first systems

Before inventing a mechanic, ask how its real-world equivalent works. Abstract
where necessary, but do not replace causality with arbitrary progression unless
there is a strong, documented reason.

The simulation does not need to reproduce every detail of reality. It should
preserve the causes, constraints, and relationships that matter to governing a
nation.

## Capability-based progression

Progression represents changes in capability, knowledge, organization, and
physical assets—not arbitrary levels. Farms, roads, factories, institutions,
military units, and settlements should be described through meaningful
properties instead of labels such as “Level 5.”

Where practical, advanced systems should emerge from underlying causes.

The nation itself is the progression display. Change should be legible through
real capabilities and outcomes over time, not through an external ruler level,
industry tier, or experience-point track.

## Prefer meaningful measurements

When reality already provides an understandable and useful measurement, use it
instead of inventing a game abstraction.

A police station is better described by officer count, vehicle availability,
budget, response time, and clearance rate than by “Level 4.” A road is better
described by construction, surface, capacity, condition, maintenance, terrain,
and drainage than by “Road Quality 7.”

Not every real measurement deserves simulation. Include measurements that create
meaningful causes, constraints, choices, or feedback for governing the nation.

## Spatial presence

The map is the primary game surface. Player-facing systems should reinforce the
feeling of inhabiting and governing a place rather than defaulting to a web-style
dashboard.

## Autonomous actors

People, companies, institutions, and major actors have their own incentives and
constraints. Player intent influences them but does not directly determine every
outcome.

Major actors may initiate development, accumulate power, and pursue their own
strategies. The ruler governs their activity through sovereign tools and
negotiation rather than manually originating every investment or institution.

## Technical design laws

1. **Simulation does not depend on presentation.** The core must run without a
   renderer or graphical client.
2. **Geography precedes politics.** Natural processes shape land before
   territories divide it.
3. **Detail follows need.** Compute and memory scale with physical complexity,
   simulation relevance, and observation or gameplay needs—not the total
   theoretical world size.
4. **One authority model.** Singleplayer and multiplayer share simulation
   concepts; only the location of authority changes.
5. **Seeds are durable identities.** Results are reproducible within an explicitly
   versioned generator and ruleset.
6. **Resolution must earn its cost.** Finer detail is adopted only when it enables
   meaningful simulation or interaction.
7. **Resolution belongs to representation.** Geological continuity, computational
   partitioning, and sampling resolution remain distinct concepts.
