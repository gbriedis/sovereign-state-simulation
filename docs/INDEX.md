---
id: DOCS-INDEX
type: document-index
status: accepted
scope: Active repository documents
authority: Owns the inventory and routing of active project documentation
last_reviewed: 2026-08-30
---

# Document Index

Every file listed here is active and has a defined job. Superseded compatibility
files are removed rather than left in the normal reading path; Git retains their
history.

## Project foundations

| ID | Document | Owns |
| --- | --- | --- |
| `VISION-001` | [Project Vision](foundations/PROJECT_VISION.md) | Enduring player fantasy, persistent planetary experience, and product direction |
| `PRINCIPLES-001` | [Design Principles](foundations/DESIGN_PRINCIPLES.md) | Christian design foundation and governing product and technical principles |
| `DOCS-GLOSSARY` | [Glossary](foundations/GLOSSARY.md) | Canonical meaning of shared terms |

## Brand

| ID | Document | Owns |
| --- | --- | --- |
| `BRAND-001` | [Brand Foundation](brand/BRAND_FOUNDATION.md) | Public name, positioning, voice, and visual direction |

## Planning

| ID | Document | Owns |
| --- | --- | --- |
| `ROADMAP-001` | [Natural-World Foundation Roadmap](planning/NATURAL_WORLD_FOUNDATION_ROADMAP.md) | Current phase scope and definition of complete |
| `PROTO-001` | [Map and Spatial Model Prototype](architecture/MAP_AND_SPATIAL_MODEL_PROTOTYPE.md) | Spatial learning objective, design-readiness gate, experiment, and success or failure criteria |

## Operational state

| ID | Document | Owns |
| --- | --- | --- |
| `HANDOFF-CURRENT` | [Current State](operations/CURRENT_STATE.md) | Current repository facts and immediate actions |
| `HANDOFF-KNOWLEDGE-WORKFLOW` | [Knowledge Workflow State](operations/KNOWLEDGE_WORKFLOW_STATE.md) | Active workflow identity and resumable state |

## Project Journal

These files make the project easier to follow. They own no product or technical
truth; current views are generated from the registry and linked authorities.
The top-level `project-journal-site/` is the browser presentation of the same
derivative data. It is not a document authority and must be refreshed in the
same change whenever a listed Journal-impact field changes.

| ID | Document | Owns |
| --- | --- | --- |
| `JOURNAL-HOME` | [Project Journal and System Map](project-journal/README.md) | Generated current human navigation and complete system overview |
| `JOURNAL-WORLD-GENERATION` | [Current World-Generation Status](project-journal/WORLD_GENERATION_STATUS.md) | Generated current human view of world-generation knowledge, coverage, implementation, attention, and decisions |
| `JOURNAL-POST-20260829-WORLD-GENERATION-FOUNDATION` | [World Generation Has a Foundation, Not Yet a Generator](project-journal/posts/2026-08-29-WORLD_GENERATION_FOUNDATION.md) | Historical snapshot at the stated date and baseline commit; no current authority |

## Architecture

| ID | Document | Owns |
| --- | --- | --- |
| `ARCH-001` | [Architecture Overview](architecture/ARCHITECTURE_OVERVIEW.md) | Accepted software, planetary spatial, persistence, and authority boundaries |
| `ARCH-OPEN` | [Open Architecture Decisions](architecture/OPEN_DECISIONS.md) | Unresolved technical choices |
| `DECISION-INDEX` | [Decision Records](decisions/README.md) | Durable architecture and world-generation change records |
| `ARCH-DEC-001` | [Adopt a Planet-Fixed Physical Reference Frame](decisions/ARCH-DEC-001-planet-fixed-physical-reference-frame.md) | Canonical physical reference frame and derived spatial-representation boundary |
| `ARCH-DEC-002` | [Adopt an Earth-Like Reference Ellipsoid](decisions/ARCH-DEC-002-earth-like-reference-ellipsoid.md) | Stable oblate mathematical reference shape and its boundary from physical and gravity surfaces |
| `ADR-0002` | [Adopt an Earth-like Planetary Contract](decisions/ADR-0002-earth-like-planetary-contract.md) | Accepted Level 0 product boundary for bounded Earth-like planetary causes |

## World generation

The [World-Generation Source of Truth](world-generation/README.md) is the
required entry point. It maps every accepted concept to its detailed owner.
The [World-Generation Authoring Protocol](world-generation/AUTHORING_PROTOCOL.md)
governs how agents add and revise concepts.

## Documentation system

| ID | Document | Owns |
| --- | --- | --- |
| `DOCS-001` | [Documentation Standard](README.md) | Taxonomy, precedence, metadata, wording, and update rules |
| `DOCS-INDEX` | This document | Active document inventory and routing |
| `DOCS-CLEAR-LANGUAGE` | [Clear Language Standard](governance/standards/CLEAR_LANGUAGE.md) | Direct, stable naming for shared terms, documents, systems, and branches |
| `DOCS-WORKFLOW` | [Knowledge Workflow](governance/workflows/KNOWLEDGE_WORKFLOW.md) | Explore, Fast delivery, Governed delivery, bounded review, and resumption |
| `AGENT-OUTCOME-LEAD` | [Outcome Lead](governance/roles/OUTCOME_LEAD.md) | Outcome interpretation, proportional routing, qualified assignments, and completion verification |
| `AGENT-DEVELOPER` | [Systems Knowledge Developer](governance/roles/SYSTEMS_KNOWLEDGE_DEVELOPER.md) | Bounded development and correction of durable knowledge |
| `AGENT-REVIEWER` | [Systems Coherence Reviewer](governance/roles/SYSTEMS_COHERENCE_REVIEWER.md) | Independent review of the exact manifested candidate |
| `AGENT-GIT-PUBLISHER` | [Git Publisher](governance/roles/GIT_PUBLISHER.md) | Explicitly authorized commit, branch publication, or pull-request delivery |
