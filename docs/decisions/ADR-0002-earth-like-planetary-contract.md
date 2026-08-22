# ADR-0002: Adopt an Earth-like planetary contract

- **Status:** Proposed
- **Date:** 2026-08-22
- **Decision owner:** World Generation Lead
- **DRI:** WG-002 specification DRI
- **Scope:** Level 0 world-generation meaning and downstream boundary conditions
- **Art / Technical Art impact:** Consulted
- **Consulted:** Systems Architecture; Art & Technical Art
- **Informed:** Product Owner; Project Steward; World Core; Bevy Client; Marketing
- **Supersedes:** None
- **Related work:** `WG-002`

## Context

The existing Earth-like physical framework fixed the minimal context needed by
geological prehistory but did not distinguish invariant physical rules from
planetary causes that may vary between Earth-like worlds. Leaving every
planetary parameter fixed would narrow world identity unnecessarily; allowing
arbitrary planetary variation would expand the game into an exoplanet simulator
and detach later outcomes from supported physical assumptions.

## Decision

The simulation generates Earth histories, not arbitrary planets. Level 0
combines common physical rules with an Earth-like planetary contract selected
before geological history. That contract may vary causal parameters only inside
a supported Earth-like envelope and supplies stellar-forcing context,
planetary-scale parameters, water inventory, volatile inventory, atmospheric
potential, and a variance profile.

Geology and later histories inherit those causes. Level 0 does not directly
select continents, mountains, oceans, climate, resources, biomes, or
civilization. Future world-creation controls must express causes rather than
requesting those consequences. Exact ranges, representation, algorithms, and
which parameters remain permanently fixed are unresolved.

## Team impact and routing

| Team or lane | Route | Required action or consequence |
| --- | --- | --- |
| World Generation | Action required | Own causal meaning, limits, and later domain specifications. |
| Systems Architecture | Consulted | Confirm the contract remains an upstream input rather than an outcome generator. |
| World Core | Action required | Treat a future versioned contract as authoritative input; do not implement this ADR alone. |
| Art & Technical Art | Consulted | Keep visual encoding derived from canonical causes and history; presentation cannot become world truth. |
| Project Steward | Informed | Record WG-002 status and route acknowledgements. |
| Bevy Client and Marketing | Informed | Do not present unresolved profiles as implemented behavior or demonstrated claims. |

## Alternatives considered

### Fix every world to one exact Earth baseline

This preserves a narrow physical model but makes variation depend almost
entirely on history and prevents bounded planetary causes from contributing to
world identity.

### Build a generic planet generator

This permits broad novelty but requires unsupported star, orbit, atmosphere,
planet-formation, and non-Earth physics. It expands scope beyond the game and
weakens the reality-first causal chain.

## Consequences

### Enables

- Different Earth-like worlds can inherit different causes before geology.
- Existing geological models receive explicit, durable boundary conditions.
- Future server configuration can expose bounded causal tendencies without
  guaranteeing desired terrain, climate, or resources.

### Costs and risks

- Parameter bounds and correlations need later scientific and systems review.
- Every downstream generator must distinguish contract inputs from derived
  state and history.
- Poorly named profile controls could imply guaranteed outcomes unless their
  causal mapping remains explicit.

## Adoption and verification

The canonical meaning is defined in
[Earth-Like Planetary Contract](../world-generation/EARTH_LIKE_PLANETARY_CONTRACT.md).
The architecture overview, world-foundation roadmap, and Earth-like physical
framework link the new Level 0 boundary to accepted geological architecture.
Open questions remain in
[Open Architecture Question Inventory](../architecture/OPEN_DECISIONS.md).

No implementation is adopted by this decision. A later packet must define a
versioned data contract and acceptance tests before World Core consumes it.

## Reversal or supersession

This is documentation-only and can be reversed before implementation by
superseding this record and restoring the fixed-baseline contract. Evidence
that bounded planetary variance cannot remain coherent, testable, or affordable
would trigger reconsideration. Any move toward generic planet generation or a
permanently fixed single baseline requires a superseding ADR.
