---
id: DOCS-GLOSSARY
type: glossary
status: accepted
scope: Terms shared across project documentation
authority: Owns the canonical meaning and preferred usage of shared terms
last_reviewed: 2026-08-30
---

# Glossary

Use the preferred term when precision matters. Public copy may use a listed
synonym only when it does not change the underlying meaning.

| Term | Meaning | Usage rule |
| --- | --- | --- |
| **nation** | The living social, economic, institutional, and political simulation governed by a player. | Preferred player-facing term. |
| **country** | The nation understood together with its territory and visible development. | Acceptable in public prose; do not use as a technical type without defining it. |
| **state** | The governing institutions and sovereign authority within a nation. | Do not use as a synonym for physical simulation state in the same sentence. |
| **political territory** | The mutable geographic area under a state's jurisdiction. | It references physical space; it does not own geography. |
| **political border** | The mutable boundary of a political territory or another declared jurisdiction. | A border may follow a natural or constructed feature, but that feature does not own the border. |
| **country slot** | A future allocation opportunity through which a player may receive a political territory. | Allocation concept only; not a geological or spatial partition. |
| **physical world** | All authoritative natural physical reality represented by the simulation. | Includes but is not limited to geology. |
| **planet-fixed physical reference frame** | The accepted canonical frame for physical positions, owned by [ARCH-DEC-001](../decisions/ARCH-DEC-001-planet-fixed-physical-reference-frame.md). | Use this exact term; geodetic latitude/longitude/reference height, atlas, local, domain, cell, and territory representations remain derived. |
| **Earth-like reference ellipsoid** | The stable oblate mathematical reference shape used with a generated world's planet-fixed frame, owned by [ARCH-DEC-002](../decisions/ARCH-DEC-002-earth-like-reference-ellipsoid.md). | Geodetic latitude, longitude, and reference height derive against it; do not use it as ground, seafloor, water, sea level, gravity reference, geoid, or detailed gravity truth. |
| **natural feature** | A physical entity or relationship shaped by natural processes, such as a river, watershed, ecosystem, or geological body. | Its identity and shape do not belong to political territories, spatial domains, or sampling cells. |
| **geographic position** | The authoritative physical location of something on or within the planet-fixed physical reference frame. | Answers `where?`; numeric encoding, precision, serialization, and derived coordinate queries remain open. |
| **geological world** | The three-dimensional, history-bearing geological portion of the physical world. | Use when the claim is specifically geological. |
| **canonical truth** | Authoritative facts and constraints that define the world independently of presentation. | Do not use for caches, meshes, or disposable query products. |
| **canonical present state** | The canonical truth required to describe what exists now and continue relevant evolution without replaying all prehistory. | Distinct from provenance. |
| **provenance** | Compact causal history retained to explain or refine present truth. | Not a complete timestep log. |
| **spatial domain** | A computational partition used for indexing, locality, loading, or refinement. | Preferred technical term; `chunk` may be used only as an implementation-facing synonym. |
| **sampling cell** | A system-specific unit that queries canonical truth for analysis or presentation. | A cell does not own geological identity. |
| **player knowledge** | The information about canonical world or simulation truth that the authority makes available to a player. | Limited knowledge changes what the player can know, not what exists. |
| **map presentation** | A player-facing derived view of planetary truth, including a flattened map when used. | It does not own physical geometry, political territory, or player knowledge. |
| **geological feature** | A continuous canonical geological entity such as a body, contact, fault, or structure. | Its identity may cross spatial domains and sampling grids. |
| **ground-material domain** | The semantic portion of the physical world whose upper boundary can answer ground or seafloor queries. | Never shorten this to `domain` where it could be confused with a spatial domain. |
| **ground boundary** | The queried upper boundary of the ground-material domain under an explicit surface policy. | Not automatically the highest solid point or a heightmap. |
| **elevation** | A contextual position relative to a declared datum or reference surface. | A query result derived from canonical physical position, not an independent canonical heightmap or a synonym for geodetic reference height. |
| **depth** | Distance below a declared local reference such as ground or sea level. | Derived from canonical physical position and the selected reference. |
| **world core** | The presentation-independent Rust code that owns world generation and physical-world logic. | Use this exact term. |
| **simulation core** | The presentation-independent Rust code that evolves gameplay simulation state. | It may share a crate or boundary with the world core, but the responsibilities remain distinct. |
| **document authority** | The single active document that owns a project claim within a declared scope. | Recorded by the document's `authority` metadata; other documents link to it rather than restating it. |
| **simulation authority** | The runtime process that owns and validates canonical world and simulation state. | Local in singleplayer; server-side in multiplayer. Use the full term when documentation ownership could also be meant. |
| **affected entry** | A stable documentation ID or explicit repository-relative path governed by an active knowledge workflow. | List every authority or artifact whose working-tree bytes the workflow may change. |
| **review lock** | The temporary restriction that prevents other tasks from consuming or changing an affected entry before independent review finishes. | Applies while the knowledge-workflow checkpoint is active; it is not a permanent ownership lock. |
| **natural-world foundation** | The active `0.0.1`–`0.1.0` development phase that creates the pre-human physical world. | Use this exact phase name. |
| **map and spatial model prototype** | Milestone `PROTO-001`, which gathers evidence about encoding, querying, presenting, and navigating the accepted planet-fixed physical reference frame after a design-readiness gate. | Do not call it `v0.1`; that resembles release `0.1.0`. |
| **Project Journal** | The generated human-readable entry point for current project navigation and dated historical posts. | It links to authority and owns no product or technical truth. |
| **Project System Map** | The system hierarchy and dependency view embedded in the Project Journal. | Keep knowledge, coverage, implementation, and attention as separate states. |

## Writing convention

Technical documentation uses American English: `neighbor`, `behavior`, and
`modeling`. Existing scientific symbols and domain-specific names are unchanged.
