---
id: DOCS-GLOSSARY
type: glossary
status: accepted
scope: Terms shared across project documentation
authority: Owns the canonical meaning and preferred usage of shared terms
last_reviewed: 2026-08-22
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
| **country slot** | A future allocation opportunity through which a player may receive a political territory. | Allocation concept only; not a geological or spatial partition. |
| **physical world** | All authoritative natural physical reality represented by the simulation. | Includes but is not limited to geology. |
| **geological world** | The three-dimensional, history-bearing geological portion of the physical world. | Use when the claim is specifically geological. |
| **canonical truth** | Authoritative facts and constraints that define the world independently of presentation. | Do not use for caches, meshes, or disposable query products. |
| **canonical present state** | The canonical truth required to describe what exists now and continue relevant evolution without replaying all prehistory. | Distinct from provenance. |
| **provenance** | Compact causal history retained to explain or refine present truth. | Not a complete timestep log. |
| **spatial domain** | A computational partition used for indexing, locality, loading, or refinement. | Preferred technical term; `chunk` may be used only as an implementation-facing synonym. |
| **sampling cell** | A system-specific unit that queries canonical truth for analysis or presentation. | A cell does not own geological identity. |
| **geological feature** | A continuous canonical geological entity such as a body, contact, fault, or structure. | Its identity may cross spatial domains and sampling grids. |
| **ground-material domain** | The semantic portion of the physical world whose upper boundary can answer ground or seafloor queries. | Never shorten this to `domain` where it could be confused with a spatial domain. |
| **ground boundary** | The queried upper boundary of the ground-material domain under an explicit surface policy. | Not automatically the highest solid point or a heightmap. |
| **elevation** | A contextual position relative to a declared datum. | A query result, not an independent canonical heightmap. |
| **depth** | Distance below a declared local reference such as ground or sea level. | Derived from absolute position and the selected reference. |
| **world core** | The presentation-independent Rust code that owns world generation and physical-world logic. | Use this exact term. |
| **simulation core** | The presentation-independent Rust code that evolves gameplay simulation state. | It may share a crate or boundary with the world core, but the responsibilities remain distinct. |
| **document authority** | The single active document that owns a project claim within a declared scope. | Recorded by the document's `authority` metadata; other documents link to it rather than restating it. |
| **simulation authority** | The runtime process that owns and validates canonical world and simulation state. | Local in singleplayer; server-side in multiplayer. Use the full term when documentation ownership could also be meant. |
| **affected entry** | A stable documentation ID or explicit repository-relative path governed by an active knowledge workflow. | List every authority or artifact whose working-tree bytes the workflow may change. |
| **review lock** | The temporary restriction that prevents other tasks from consuming or changing an affected entry before independent review finishes. | Applies while the knowledge-workflow checkpoint is active; it is not a permanent ownership lock. |
| **natural-world foundation** | The active `0.0.1`–`0.1.0` development phase that creates the pre-human physical world. | Use this exact phase name. |
| **map and spatial model prototype** | Milestone `PROTO-001`, which validates navigation and provisional spatial mapping. | Do not call it `v0.1`; that resembles release `0.1.0`. |

## Writing convention

Technical documentation uses American English: `neighbor`, `behavior`, and
`modeling`. Existing scientific symbols and domain-specific names are unchanged.
