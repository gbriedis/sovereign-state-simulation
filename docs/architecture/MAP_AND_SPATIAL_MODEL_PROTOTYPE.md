---
id: PROTO-001
type: implementation-specification
status: accepted
scope: First evidence-gathering milestone for planetary representation and multiscale navigation
authority: Owns the spatial learning objective, design-readiness gate, prototype evidence, success criteria, and exclusions
implementation: not-started
last_reviewed: 2026-08-30
---

# Map and Spatial Model Prototype

## Learning objective

`PROTO-001` must reduce this named uncertainty:

> **How should the accepted planet-fixed canonical physical frame be encoded,
> queried, presented, and navigated from continental scale down to city scale
> while preserving the physical measurements and continuity required by the
> game?**

The conceptual frame and its stable Earth-like oblate mathematical reference
shape are accepted in
[ARCH-DEC-001](../decisions/ARCH-DEC-001-planet-fixed-physical-reference-frame.md)
and [ARCH-DEC-002](../decisions/ARCH-DEC-002-earth-like-reference-ellipsoid.md).
Neither accepted choice is under test in this prototype.

The prototype exists to produce evidence about that question. It must not adopt
a numeric encoding, precision, exact reference-ellipsoid parameter policy,
geodetic conversion, projection, spatial index, sampling resolution,
pole-navigation behavior, storage layout, renderer technique, or final
globe-versus-map presentation merely to give implementation a starting point.

## Design-readiness outcome before spatial code

Before spatial representation or navigation code begins, produce a bounded
design-readiness packet that:

1. traces the experiment to the accepted requirements in `VISION-001`,
   `ARCH-001`, and the relevant world-generation spatial contracts;
2. compares plausible numeric encodings of the accepted frame and alternatives
   for ellipsoid-parameter handling, geodetic conversions, derived map
   projection, pole and seam behavior, globe-versus-map use, multiscale
   transitions, spatial domains, indexes, and system-specific sampling without
   selecting one as architecture;
3. defines deterministic test locations and paths against declared test
   ellipsoid parameters that exercise ordinary regions, east-west continuity,
   both poles, presentation seams, and zoom from continental context to city
   scale without accepting those parameters for a generated world;
4. identifies the measurements, round trips, discontinuities, identity changes,
   and performance observations that will distinguish the alternatives, together
   with how requirement-derived acceptance bounds will be obtained rather than
   invented;
5. traces canonical planetary truth through derived presentation and
   player-knowledge filtering so that hidden information cannot be mistaken for
   absent geography; and
6. names every decision the experiment cannot test and routes it to
   [Open Architecture Decisions](OPEN_DECISIONS.md).

The readiness outcome is sufficient only when a reviewer can tell which
observation would support or reject each alternative and which accepted
requirement each observation protects. If the packet cannot discriminate among
the alternatives, the next step is further design work, not spatial code.

## Prototype experiment

After the readiness gate passes, extend the existing Bevy application with the
smallest reversible presentation harness and presentation-independent world-core
fixture needed to run the defined tests. The fixture may use simplified,
deterministic land and landmark geometry; visual realism is not the learning
objective.

The experiment must:

- present the same stable locations from continental through city scale;
- exercise east-west travel, pole approaches, every tested presentation
  seam, and any globe/map or level-of-detail transition under test;
- compare authoritative distance, area, and direction with derived geodetic
  latitude, longitude, reference height, elevation, and player-facing readings;
- demonstrate that changing a map layer, sampling scheme, or presentation level
  does not change canonical position or physical truth;
- demonstrate a visible-but-information-limited foreign region whose hidden
  detail continues to exist in authority-owned state; and
- keep prototype world data and tests independent of Bevy types and lifecycle.

Spatial domains and sampling cells may be introduced only when an alternative or
measurement requires them. Any scale used in the experiment is local to that
test and is not a universal world grid or accepted architecture.

## Observable success criteria

The prototype succeeds only when its evidence shows all of the following:

- Every deterministic test location retains one stable identity across the
  tested scales, derived views, seams, and transitions.
- East-west traversal is continuous and round-trips to the same canonical
  location; a presentation seam does not become a physical break.
- Both poles are exercised as meaningful planetary locations, and the result is
  observably different from direct top-bottom wrapping on a torus.
- Derived distance, area, direction, geodetic latitude, longitude, reference
  height, and elevation observations meet the acceptance bounds established by
  the readiness packet for their governing use cases.
- Navigation remains legible from continental context through city scale; no
  building-level view is required.
- Changing presentation detail, a spatial domain, or a sampling scheme neither
  rerolls canonical state nor changes political or natural-feature identity.
- Restricting foreign player knowledge changes disclosed information without
  deleting or regenerating the underlying geography.
- Presentation-independent tests reproduce the same fixture and results from
  the same declared inputs and compatible ruleset version.

## Observable failure criteria

The prototype fails or returns to design when any of these conditions occurs:

- an alternative cannot preserve stable location identity or required physical
  measurements across the tested scale range;
- navigation creates an unexplained physical seam, discontinuity, reroll, or
  toroidal pole behavior;
- success depends on one universal sampling grid, on a client owning canonical
  truth, or on hidden geography ceasing to exist;
- the declared observations cannot distinguish the alternatives or cannot be
  related to an accepted requirement; or
- an unresolved decision must be silently selected before the experiment can
  run.

Successful prototype evidence does not by itself accept an implementation. A
later governed decision must interpret the evidence and resolve any architecture
choice.

## Out of scope

- Final numeric encoding, precision, serialization, reference-ellipsoid
  parameters or variation policy, geodetic conversion, derived physical or
  geoid reference surface, or projection
- Final globe-versus-map presentation, camera transitions, seams, or pole behavior
- Final spatial index, domain hierarchy, sampling scale, or level-of-detail model
- Final terrain, hydrology, climate, geology, settlement, or infrastructure algorithms
- National simulation, multiplayer networking, database design, or persistence format
- Building-level inspection or a polished player-facing interface
