---
id: WG-AUTHORING
type: authoring-protocol
status: accepted
scope: Creation, exploration, acceptance, revision, and retirement of world-generation ideas
authority: Owns the workflow future agents must follow when adding or changing world-generation knowledge
last_reviewed: 2026-08-22
---

# World-Generation Authoring Protocol

World generation is in early exploration. The existing specifications record
accepted concepts discovered so far; they do not imply that the natural-world
design is complete, closed, or fully bounded.

This protocol lets agents explore freely while preventing an unfinished idea
from becoming authoritative merely because it was written down.

## Three independent dimensions

Every topic has a **concept state**, **coverage**, and an **implementation state**.
Do not combine them into one vague status.

### Concept state

| State | Meaning | Authority |
| --- | --- | --- |
| `recognized` | The topic matters and has a clear question, but exploration has not produced a model. | None |
| `exploring` | Constraints, evidence, and competing models are being investigated. | None |
| `proposed` | One explicit model is recommended for acceptance. | None until accepted |
| `accepted` | The conceptual truth is authoritative within its declared scope. | The linked specification |
| `superseded` | A later accepted decision replaced the concept. | The replacement |

### Coverage

| Value | Meaning |
| --- | --- |
| `exploratory` | The question, constraints, or competing models are still being discovered. |
| `partial` | The stated ideas are useful at their declared authority, but the physical topic is not fully designed. |
| `complete-at-scope` | The declared scope has enough accepted detail for all currently promised consumers and completion tests. It does not claim all of world generation is complete. |

### Implementation state

Use factual values such as:

- `not-investigated`
- `unresolved`
- `not-started`
- `partial`
- `implemented`
- `verified`

An accepted concept can have unresolved implementation. A working algorithm can
also exist as an experiment without becoming accepted architecture.

## Before starting a world-generation task

1. Read the [Documentation Standard](../README.md).
2. Read the [Knowledge Workflow](../governance/workflows/KNOWLEDGE_WORKFLOW.md).
3. Read the [World-Generation Source of Truth](README.md).
4. Find the relevant `WG-*` concept and read its detailed owner.
5. Read the related packet in
   [Open Architecture Decisions](../architecture/OPEN_DECISIONS.md).
6. Check the [Glossary](../foundations/GLOSSARY.md) before introducing a new term.

If the topic is absent from the registry, absence means **not yet explored**. It
does not mean rejected or outside world generation.

## Adding a new topic

### 1. Recognize the question

Add the next unused `WG-*` identifier to the **Recognized exploration topics**
table in the source-of-truth index. Write one bounded question that explains why
the topic matters and what it must eventually connect to.

Do not state a preferred model at this stage.

### 2. Create an exploration document when needed

Create a document only when the topic has enough substance to need durable
reasoning. Use a precise filename describing the physical subject. Begin with:

```yaml
---
id: WG-000
type: world-generation-exploration
status: draft
concept_state: exploring
coverage: exploratory
scope: Exact physical question being investigated
authority: Non-authoritative exploration; owns no accepted project decision
implementation: not-investigated
last_reviewed: YYYY-MM-DD
---
```

Use this body structure:

```markdown
# Topic name

## Question
## Known constraints
## Connections to accepted concepts
## Competing models
## Evidence and assumptions
## Consequences for later systems
## Recommendation
## Open questions
## Excluded for now
```

Separate physical facts, project constraints, assumptions, and design choices.
Do not use an illustrative model as though it were already accepted.

### 3. Propose one explicit model

Set `status: proposed` and `concept_state: proposed` only when the document:

- states one direct recommendation;
- explains why it fits accepted upstream concepts;
- identifies downstream consequences;
- separates unresolved mechanics from the proposed conceptual truth;
- names alternatives and why they were not recommended.

### 4. Accept or reject deliberately

Acceptance is an explicit project decision, not an inference an agent makes from
polished prose.

The Systems Knowledge Developer submits the proposal to a separate Systems
Coherence Reviewer. Acceptance requires the convergence loop and conditions in
the [Knowledge Workflow](../governance/workflows/KNOWLEDGE_WORKFLOW.md).

When accepted:

1. Set `type: world-generation-specification`, `status: accepted`, and
   `concept_state: accepted`.
2. Replace exploratory language with a direct **Decision** section.
3. Give the document an exact `authority` statement.
4. Change the registry row from recognized/exploring to accepted and link the
   detailed owner.
5. Move remaining implementation choices to an identified open-decision packet.
6. Add or update glossary terms.
7. Remove temporary exploration documents that no longer contain unique value;
   Git retains their history.

When rejected, remove the topic document if it has no durable value. Create a
decision record only when the rejection rationale is important enough to prevent
future repetition.

## Updating an accepted concept

First classify the change.

### Editorial clarification

The meaning does not change. Update the authoritative owner, refresh
`last_reviewed`, and run validation. Do not create a decision record.

### Compatible extension

The new idea adds detail without contradicting accepted truth. Update the owner,
its scope or authority metadata when necessary, and the registry truth statement
if the summary is materially incomplete.

### Changed or reversed truth

Do not silently rewrite accepted history. Create a `WG-DEC-*` record in
[Decision Records](../decisions/README.md) explaining the previous truth, new
truth, evidence, rationale, and consequences. Then update the specification,
registry, affected links, and any supersession metadata in the same change.

### Selected implementation

Resolve the corresponding open-decision packet through an `ARCH-DEC-*` or
`WG-DEC-*` record. Update the implementation field and specification. An
implementation experiment does not resolve a decision until it is explicitly
accepted.

## Writing rules for physical ideas

- Begin with causal relationships, not data structures.
- Distinguish physical identity, computational representation, and presentation.
- Name the datum, frame, boundary, conserved quantity, or reference whenever a
  statement depends on one.
- State whether a quantity is canonical, derived, cached, constrained, or
  illustrative.
- Explain where history matters and what present state cannot reconstruct.
- State feedback explicitly; do not force a one-way pipeline for convenience.
- Use real measurements where they create meaningful causes or constraints.
- Mark algorithms, taxonomies, thresholds, and Rust types as unresolved or
  illustrative until selected.
- Connect the topic to upstream causes and downstream consumers.
- Put genuine uncertainty in an open question, never inside a settled sentence.

## Completion checklist

Before finishing any world-generation documentation task:

- The source registry reflects the topic's current concept state.
- Exactly one document owns each accepted truth.
- Recognized or exploring ideas are not phrased as requirements.
- Accepted decisions use direct wording.
- Open mechanics have stable decision-packet IDs.
- New terminology is defined once in the glossary.
- Roadmaps and handoffs link to authority instead of repeating it.
- Obsolete documents are removed when their unique information has moved.
- `./scripts/check-docs.ps1` passes.
