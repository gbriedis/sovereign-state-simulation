---
id: DOCS-001
type: documentation-standard
status: accepted
scope: Repository documentation governance
authority: Owns document types, subject-folder taxonomy, precedence, metadata, wording rules, and update workflow
last_reviewed: 2026-08-26
---

# Documentation Standard

This repository is the durable project memory for humans and autonomous agents.
Chat history is not project authority. A statement becomes project truth only
when it is recorded in the document that owns its subject.

## Required reading order

1. Read [Knowledge Workflow State](operations/KNOWLEDGE_WORKFLOW_STATE.md) and obey
   any active review lock before relying on project authority.
2. Read [Current State](operations/CURRENT_STATE.md) for the active milestone and
   immediate work.
3. Read the relevant source-of-truth index:
   [World Generation](world-generation/README.md) for natural-world work or
   [Architecture Overview](architecture/ARCHITECTURE_OVERVIEW.md) for software
   boundaries.
4. Read the authoritative document linked for each concept the task changes.
5. Read [Open Architecture Decisions](architecture/OPEN_DECISIONS.md) before
   choosing an unresolved design.
6. Read [Project Vision](foundations/PROJECT_VISION.md) and
   [Design Principles](foundations/DESIGN_PRINCIPLES.md) before changing product behavior.
7. Read [Brand Foundation](brand/BRAND_FOUNDATION.md) for public-facing work.

The [Document Index](INDEX.md) lists every active document and its role. The
[Glossary](foundations/GLOSSARY.md) defines terms that must retain one meaning across files.
Material knowledge changes follow the proportional
[Knowledge Workflow](governance/workflows/KNOWLEDGE_WORKFLOW.md).

## Subject-folder taxonomy

Keep `docs/README.md` and `docs/INDEX.md` as stable entry points. Place active
documents by the subject they own:

| Location | Document types | Subject |
| --- | --- | --- |
| `docs/README.md` | `documentation-standard` | Documentation governance and taxonomy |
| `docs/INDEX.md` | `document-index` | Repository-wide active-document routing |
| `foundations/` | `product-vision`, `design-principles`, `glossary` | Enduring product direction, design principles, and shared terminology |
| `planning/` | `phase-roadmap` | Phase roadmaps and evolving completion targets |
| `governance/workflows/` | `collaboration-protocol` | Durable documentation and collaboration procedures |
| `governance/roles/` | `agent-role` | Exact agent identities, activation rules, and work contracts |
| `operations/` | `operational-handoff`, `workflow-state` | Replaceable current state and resumable workflow checkpoints |
| `architecture/` | `architecture-overview`, `implementation-specification`, `open-decision-register` | Software boundaries, prototypes, and unresolved technical decisions |
| `brand/` | `brand-standard` | Public identity and messaging |
| `decisions/` | `decision-record-index`, `decision-record` | Durable accepted decision records |
| `world-generation/` | `source-of-truth-index`, `authoring-protocol`, `world-generation-specification`, `world-generation-exploration` | Natural-world concept registry, protocols, and specifications |

Do not create a new top-level subject folder for a single file when an existing
owner fits. Do not move a domain-specific protocol out of its domain merely
because it is a workflow; for example, world-generation authoring remains with
world-generation authority.

The table is exhaustive. Before introducing a new document type, update this
standard with its one governed location and update the documentation validator
in the same independently reviewed change. An unlisted type or a listed type in
another folder is invalid; agents must not infer placement from a filename.

## Active review lock

An active knowledge-workflow checkpoint temporarily review-locks every item listed
in its **Affected entries** section. Each entry must be either a stable
documentation ID or an explicit repository-relative path. An ID locks the
document it identifies; a path locks that exact repository artifact. The
working-tree versions are candidates until the recorded reviewer accepts them.
Existing `status: accepted` metadata continues to describe the last accepted
document; it does not approve the unreviewed diff.

While a lock is active, other tasks must not consume candidate wording as truth,
modify a locked entry, or create knowledge that depends on it. Non-material work
may continue only when it is independent of all locked entries. A second material
knowledge workflow must wait until the active checkpoint returns to `idle`.

## Authority and precedence

Authority follows ownership, not file length, recency, or specificity alone.

1. **Vision** owns enduring product intent and boundaries.
2. **Principles** own rules used to judge designs and implementations.
3. **Accepted decisions and specifications** own their declared technical or
   product scope.
4. **Roadmaps** own milestone scope and completion criteria, but cannot alter an
   accepted decision.
5. **Open-decision registers** identify unresolved choices; their options are
   not accepted design.
6. **Handoffs** report current activity and link to authority; they never
   redefine it.

A narrower accepted decision may refine a broader accepted decision only inside
its declared scope. If two authoritative documents genuinely conflict, stop the
affected implementation, record the conflict in the open-decision register, and
resolve it explicitly. Do not choose whichever wording appears more specific.

## One idea, one owner

Every material idea has one authoritative owner. Indexes may provide a concise
truth statement and route readers to that owner. Other documents should link to
the owner instead of reproducing its detailed explanation.

When changing an idea:

1. Change its authoritative document.
2. Update the relevant index if its truth statement, status, or routing changed.
3. Update affected roadmap or handoff links without copying the full decision.
4. Move unresolved choices into the open-decision register.

New concepts, changed accepted truth, new authority boundaries, and deletion
that could lose unique knowledge use Governed delivery with separate Systems
Knowledge Developer and Systems Coherence Reviewer workers. Read-only idea
formation uses Explore. Clear, reversible editorial work that cannot change
meaning may use Fast delivery.

## Document status

The `status` metadata field accepts only:

- `draft` — incomplete and non-authoritative;
- `proposed` — ready for a decision but not accepted;
- `accepted` — authoritative within the declared scope;
- `superseded` — retained only when historical traceability is required and
  linked to its replacement.

Approval is separate from implementation. Use an `implementation` field when
needed, with plain factual values such as `not-started`, `partial`, `implemented`,
or `not-applicable`.

Unresolved mechanics do not make an accepted concept tentative. State the
accepted concept as a definite decision and list unresolved mechanics under an
explicit **Open questions** section or in the open-decision register.

World-generation concepts also have a separate `concept_state` governed by the
[World-Generation Authoring Protocol](world-generation/AUTHORING_PROTOCOL.md).
An accepted document can have `coverage: partial`; accepted means its stated
truth is authoritative, not that the physical topic is completely designed.

## Required metadata

Every active Markdown document under `docs/` begins with YAML front matter:

```yaml
---
id: UNIQUE-ID
type: document-type
status: accepted
scope: What this document governs
authority: The exact information this document owns
last_reviewed: YYYY-MM-DD
---
```

Use `implementation`, `supersedes`, or `related` only when they add factual
information. Metadata describes the document; it must not hide design decisions.

## Truthful wording

- Use **must** for an accepted requirement or invariant.
- Use **should** for a governing preference that permits justified exceptions.
- Use **may** for permission or a real possibility, not for uncertainty.
- Put uncertain ideas under **Open questions**, labelled options, or proposals.
- Do not place `likely`, `probably`, `possibly`, or `candidate` inside a settled
  decision statement.
- Distinguish conceptual acceptance from selected algorithms and data layouts.
- Label examples, pseudocode, and Rust-facing vocabulary as normative or
  illustrative. Illustrative material cannot silently create requirements.
- State what owns a concept and what does not.
- Prefer one defined term over clusters of near-synonyms.
- Use American English in technical documentation.

## Standard specification shape

Authoritative specifications should use the following sections where relevant:

1. **Decision** — the accepted truth in direct language.
2. **Rationale** — why the decision exists.
3. **Model** — relationships, constraints, and terminology.
4. **Consequences** — what downstream work must respect.
5. **Open questions** — explicitly unresolved choices.
6. **Out of scope** — boundaries that prevent accidental expansion.

## Handoff rule

`operations/CURRENT_STATE.md` is a replaceable operational snapshot, not a design
archive. Keep it short. It records the current milestone, observed repository
state, work in progress, blockers, and next actions, with links to authority.

## Validation

Run the documentation check after documentation changes:

```powershell
./scripts/check-docs.ps1
```

The check rejects missing or duplicate IDs, invalid statuses, missing metadata,
broken relative links, obsolete terminology, an oversized current handoff, and
an invalid or non-resumable knowledge-workflow checkpoint.

After changing workflow-state rules or their validator, also run:

```powershell
./scripts/test-docs-workflow-validator.ps1
```

After changing taxonomy or accepted-change recording, also run:

```powershell
./scripts/test-docs-taxonomy.ps1
./scripts/test-change-manifest.ps1
```
