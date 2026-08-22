---
id: DOCS-INDEX
type: document-index
status: accepted
scope: Active repository documents
authority: Owns the inventory and routing of active project documentation
last_reviewed: 2026-08-22
---

# Document Index

Every file listed here is active and has a defined job. Superseded compatibility
files are removed rather than left in the normal reading path; Git retains their
history.

## Project foundations

| ID | Document | Owns |
| --- | --- | --- |
| `VISION-001` | [Project Vision](foundations/PROJECT_VISION.md) | Enduring player fantasy and product direction |
| `PRINCIPLES-001` | [Design Principles](foundations/DESIGN_PRINCIPLES.md) | Governing product and technical principles |
| `DOCS-GLOSSARY` | [Glossary](foundations/GLOSSARY.md) | Canonical meaning of shared terms |

## Brand

| ID | Document | Owns |
| --- | --- | --- |
| `BRAND-001` | [Brand Foundation](brand/BRAND_FOUNDATION.md) | Public name, positioning, voice, and visual direction |

## Planning

| ID | Document | Owns |
| --- | --- | --- |
| `ROADMAP-001` | [Natural-World Foundation Roadmap](planning/NATURAL_WORLD_FOUNDATION_ROADMAP.md) | Current phase scope and definition of complete |
| `PROTO-001` | [Map and Spatial Model Prototype](architecture/MAP_SPATIAL_PROTOTYPE.md) | First implementation milestone and success criteria |

## Operational state

| ID | Document | Owns |
| --- | --- | --- |
| `HANDOFF-CURRENT` | [Current State](operations/CURRENT_STATE.md) | Current repository facts and immediate actions |
| `HANDOFF-KNOWLEDGE-WORKFLOW` | [Knowledge Workflow State](operations/KNOWLEDGE_WORKFLOW_STATE.md) | Active workflow identity and resumable state |

## Architecture

| ID | Document | Owns |
| --- | --- | --- |
| `ARCH-001` | [Architecture Overview](architecture/ARCHITECTURE_OVERVIEW.md) | Accepted software and authority boundaries |
| `ARCH-OPEN` | [Open Architecture Decisions](architecture/OPEN_DECISIONS.md) | Unresolved technical choices |
| `DECISION-INDEX` | [Decision Records](decisions/README.md) | Durable architecture and world-generation change records |

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
| `DOCS-WORKFLOW` | [Knowledge Development Workflow](governance/workflows/KNOWLEDGE_DEVELOPMENT_WORKFLOW.md) | Two-role authoring and coherence-review loop |
| `AGENT-COORDINATOR` | [Knowledge Workflow Coordinator](governance/roles/KNOWLEDGE_WORKFLOW_COORDINATOR.md) | Fresh-task activation, orchestration, persistence, and final handoff |
| `AGENT-DEVELOPER` | [Systems Knowledge Developer](governance/roles/SYSTEMS_KNOWLEDGE_DEVELOPER.md) | Material knowledge development and revision |
| `AGENT-REVIEWER` | [Systems Coherence Reviewer](governance/roles/SYSTEMS_COHERENCE_REVIEWER.md) | Independent read-only coherence review |
| `AGENT-GIT-STEWARD` | [Repository Git Steward](governance/roles/REPOSITORY_GIT_STEWARD.md) | User-authorized safe staging and local commit execution |
