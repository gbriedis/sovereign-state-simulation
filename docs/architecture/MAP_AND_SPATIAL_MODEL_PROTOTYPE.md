---
id: PROTO-001
type: implementation-specification
status: accepted
scope: First evidence-gathering milestone for planetary representation and multiscale navigation
authority: Owns the spatial learning objective, design-readiness gate, prototype evidence, success criteria, and exclusions
implementation: partial
last_reviewed: 2026-08-31
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

## Gate status and provisional implementation evidence

The design-readiness gate did not pass before planetary spatial-reference code
began. This sequence mismatch must not be rewritten as retrospective compliance.
Integration and expansion of that code must remain frozen until the
retrospective readiness work below is complete and a later governed architecture
decision determines which, if any, implementation choices should be retained.

Read-only inspection on 2026-08-31 found provisional evidence in the isolated
worktree
`C:/Users/legion/.codex/worktrees/cf36/state-of-consequence`, based at commit
`8bfe4c63bfbe0f449d0f59e4ebcdf6dec1b1de83`. The evidence consists of seven
uncommitted source and test changes:

- `src/lib.rs`
- `src/world/mod.rs`
- `src/world/planetary_reference/mod.rs`
- `src/world/planetary_reference/position.rs`
- `src/world/planetary_reference/ellipsoid.rs`
- `src/world/planetary_reference/conversion.rs`
- `tests/planetary_reference.rs`

The main worktree does not contain these planetary-reference changes. The
isolated implementation currently uses `f64` Cartesian and geodetic values, accepts
semi-major axis and flattening as independent ellipsoid inputs, implements the
EPSG method 9602 forward relationship, and implements a Bowring-initialized
safeguarded Newton inverse with bisection fallback, an eight-`f64`-epsilon
angular stopping threshold, and a 64-iteration limit. Its public boundaries
also define validation and error behavior for non-finite values, invalid
ellipsoid inputs, out-of-range latitude, ambiguous deep normal coordinates, the
planet center, non-finite calculation, and inverse non-convergence.

Twelve public-contract tests were observed passing in that isolated worktree.
They cover an EPSG 9602 WGS 84 fixture; representative forward and inverse round
trips; exact and near-pole behavior; antimeridian normalization; negative
ellipsoidal heights; independent ellipsoid-input validation; and explicit error
behavior. Test tolerances include `1e-12` radians for representative angular
round trips, `1e-6` meters for representative physical round trips, and `0.002`
meters for the rounded EPSG fixture.

These observations are evidence about one provisional implementation, not accepted architecture,
not proof that the readiness gate passed, and not proof that the complete
prototype succeeds. `f64`, independent parameter representation, WGS 84 test
values, both conversion procedures, stopping and test tolerances, iteration
limits, supported domains, longitude conventions, and error behavior remain
unresolved in [ARCH-OPEN-001](OPEN_DECISIONS.md).

Before integration or expansion, a retrospective readiness and evidence packet
must:

1. map every existing implementation choice and test to the original readiness
   requirements and identify requirements that have no evidence;
2. compare the implemented choices with credible alternatives without treating
   the implementation as the default;
3. distinguish test fixtures and provisional thresholds from
   requirement-derived acceptance bounds;
4. record singular, ambiguous, unsupported, and non-convergent domains plus the
   behavior callers require at each boundary;
5. identify which original multiscale navigation, presentation, player-
   knowledge, identity, measurement, and performance observations remain
   entirely untested; and
6. give a later governed architecture decision enough evidence to retain,
   replace, or remove each implemented choice explicitly.

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
