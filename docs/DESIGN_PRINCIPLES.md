# Design Principles

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

## Spatial presence

The map is the primary game surface. Player-facing systems should reinforce the
feeling of inhabiting and governing a place rather than defaulting to a web-style
dashboard.

## Autonomous actors

People, companies, institutions, and major actors have their own incentives and
constraints. Player intent influences them but does not directly determine every
outcome.

## Technical design laws

1. **Simulation does not depend on presentation.** The core must run without a
   renderer or graphical client.
2. **Geography precedes politics.** Natural processes shape land before
   territories divide it.
3. **Detail follows attention.** Compute and memory scale with relevance, not the
   total theoretical world size.
4. **One authority model.** Singleplayer and multiplayer share simulation
   concepts; only the location of authority changes.
5. **Seeds are durable identities.** Results are reproducible within an explicitly
   versioned generator and ruleset.
6. **Resolution must earn its cost.** Finer detail is adopted only when it enables
   meaningful simulation or interaction.
