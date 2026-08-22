---
id: DOCS-WORKFLOW
type: collaboration-protocol
status: accepted
scope: Development and independent review of durable project knowledge
authority: Owns the two-role workflow used to create or materially change authoritative documentation
last_reviewed: 2026-08-22
---

# Knowledge Development Workflow

Material documentation changes use two distinct agent roles. The roles apply to
world generation, architecture, product design, simulation systems, and future
project domains. They are not tied to Rust implementation.

The user requests an outcome, not a role. In a fresh task, repository bootstrap
automatically makes the root agent the Knowledge Workflow Coordinator. The
coordinator then invokes the two workers with explicit role envelopes. No worker
may infer its identity from conversational context.

## Role 1: Systems Knowledge Developer

The Systems Knowledge Developer turns a question, idea, constraint, or observed
implementation need into precise durable project knowledge.

Responsibilities:

- identify the document and concept that own the subject;
- investigate upstream causes and downstream consumers;
- distinguish facts, assumptions, proposals, accepted truth, and implementation;
- define new terms before relying on them;
- develop competing models far enough to compare their consequences;
- write direct decisions and explicit open questions;
- update every affected authoritative owner, index, glossary entry, and handoff;
- remove temporary or obsolete documentation after its unique value moves;
- provide a change packet for independent review.

The developer does not self-approve a new concept, a reversal of accepted truth,
or a material expansion of an authoritative specification.

## Role 2: Systems Coherence Reviewer

The Systems Coherence Reviewer independently tests whether the proposed
knowledge can safely guide future humans and agents.

Responsibilities:

- verify that claims are placed in the correct authority;
- compare the change with vision, principles, glossary, indexes, accepted
  decisions, open questions, and related specifications;
- detect contradictions, duplicated ownership, hidden assumptions, and vague
  certainty;
- test terminology for one stable meaning;
- examine causal order and interface boundaries;
- identify downstream systems that the change constrains unintentionally;
- look for storage, performance, compatibility, migration, or refinement risks
  that the conceptual wording may create later;
- check whether examples or illustrative types silently became requirements;
- confirm that rejected or superseded material will not remain in the active
  reading path;
- issue a review outcome with prioritized findings.

The reviewer does not replace the developer's proposal with unexplained personal
preference. Every challenge must identify the affected truth, risk, or governing
rule.

## Changes that require both roles

Independent review is required for:

- a new recognized topic becoming proposed or accepted;
- a change to accepted meaning;
- a new authoritative document;
- a changed authority boundary or glossary definition;
- selection of an implementation architecture;
- deletion or consolidation that could remove unique knowledge;
- a change with material downstream compatibility consequences.

Pure spelling, formatting, link repair, metadata normalization, and other
editorial changes may use one worker when meaning and authority do not change.
Validation still applies.

## Worker separation

Use two separate agent workers when the environment supports them.

- The Systems Knowledge Developer is the only worker that edits the proposed
  files during the review loop.
- The Systems Coherence Reviewer works read-only and reviews the current diff
  plus all affected authoritative documents.
- Both workers return their exact role-card output to the coordinator. The
  coordinator persists and routes it; workers do not bypass the coordinator.
- The reviewer does not create competing edits in the proposed files.
- The coordinator finalizes the change only after the reviewer returns `accept`.

If an independent worker is unavailable, the developer may prepare a proposal
but must not mark a new concept or changed truth accepted. It remains proposed
until independent review occurs.

## Persistent role cards

Exact identity, activation, context, and output contracts live in these role
cards:

- [Knowledge Workflow Coordinator](../roles/KNOWLEDGE_WORKFLOW_COORDINATOR.md)
- [Systems Knowledge Developer](../roles/SYSTEMS_KNOWLEDGE_DEVELOPER.md)
- [Systems Coherence Reviewer](../roles/SYSTEMS_COHERENCE_REVIEWER.md)

The coordinator assigns roles through the envelope defined in its card. Do not
copy role prompts into unrelated documents; the role cards are their single
owners.

The developer and reviewer role cards are the sole owners of the exact
`DEVELOPER_HANDOFF` and `REVIEW_OUTCOME` schemas. During an active workflow, the
coordinator copies their complete latest outputs into the transient
[Knowledge Workflow State](../../operations/KNOWLEDGE_WORKFLOW_STATE.md) checkpoint so a
fresh task can resume. Accepted rationale with lasting value belongs in an
authoritative specification or decision record; the checkpoint is cleared when
the workflow finishes.

## Reviewer finding severity

Severity means:

- **blocking** — contradicts accepted truth, changes an idea without authority,
  loses unique knowledge, or makes the documentation unsafe to follow;
- **major** — creates ambiguity, duplicated ownership, misleading status, or a
  credible long-term design or maintenance problem;
- **minor** — weakens clarity or consistency without changing the intended model;
- **polish** — optional editorial improvement.

## Convergence loop

1. The developer returns its exact handoff and proposed documentation to the
   coordinator.
2. The coordinator persists that handoff and creates a transient accepted-change
   manifest that fingerprints the complete candidate and its deterministic final
   idle checkpoint.
3. The coordinator records the manifest path and ID, then assigns a separate
   reviewer.
4. The reviewer verifies that manifest against the current candidate and returns
   its exact outcome to the coordinator: `revise`, `accept`,
   or `open-decision-required`.
5. The coordinator persists and routes the outcome. For each finding, the
   developer records one response:
   - `accepted` — revise the documentation;
   - `resolved-by-evidence` — provide evidence that removes the concern;
   - `disputed` — state the competing interpretation and its consequences;
   - `deferred` — create or update an identified open-decision packet.
6. The reviewer checks the actual revision and responses, then issues another
   outcome.
7. Repeat until the acceptance conditions are met or the unresolved disagreement
   is recorded as an open decision.

If the same material disagreement survives two review rounds without new
evidence or a changed model, the next outcome must be `open-decision-required`.
This prevents an endless wording loop.

The goal is not compromise wording. The goal is one model both workers can
defend as truthful and durable. If evidence does not support convergence, retain
the disagreement explicitly; do not blend incompatible ideas into ambiguous
language.

## Acceptance conditions

The reviewer may return `accept` only when:

- no blocking or major finding remains;
- every accepted statement has one authoritative owner;
- concept state, document status, coverage, and implementation state tell the
  same factual story;
- terminology matches the glossary or introduces an approved precise definition;
- upstream dependencies and downstream consequences are identified;
- remaining uncertainty has an open-decision identifier;
- temporary and superseded documents are removed from the active reading path;
- the handoff reports only current operational effects;
- documentation validation passes.
- the accepted-change manifest verifies the full review snapshot and the
  reviewer identifies its exact ID.

Acceptance means the documentation is safe to use at its declared coverage. It
does not mean the subject is complete or that future evidence cannot revise it.

## Finalization

The developer must include indexes, metadata, links, decision records, handoffs,
removal of superseded material, and validation in the candidate submitted for
review. Reviewer acceptance applies to that complete repository state.

After acceptance, the coordinator records the outcome, verifies the review
snapshot again, materializes the manifest's exact final idle checkpoint, verifies
the final worktree against the same manifest, runs `./scripts/check-docs.ps1`
against that materialized state, and returns one
coherent result to the user. The manifest lives under Git's private metadata,
not in the committed project, and remains available after the checkpoint reset.
If any accepted byte, Git mode, path, addition, deletion, or move state changes,
the coordinator must create a new manifest and request another review.

## Git recording is separate

The [Repository Git Steward](../roles/REPOSITORY_GIT_STEWARD.md) is not a third
knowledge-development role and cannot approve documentation. Invoke it only when
the current user explicitly requests staging or a local commit. For material
knowledge, invocation occurs only after reviewer acceptance, the exact idle
checkpoint reset, final validation, and a successful manifest worktree check.
The coordinator passes the accepted manifest path and ID to the steward. The
steward verifies the worktree before staging, the index after staging, the
created commit, and the post-commit worktree. A hook-induced mismatch blocks
success. Completing this workflow does not by itself authorize any Git mutation.
