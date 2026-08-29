---
id: DOCS-WORKFLOW
type: collaboration-protocol
status: accepted
scope: Proportional exploration, delivery, review, and resumption of durable project knowledge
authority: Owns workflow modes, routing, confirmation, worker separation, convergence, and completion for documentation changes
last_reviewed: 2026-08-29
---

# Knowledge Workflow

This workflow turns incomplete user direction into a recommended result without
making every task pay the cost of a multi-agent process. The Outcome Lead owns
the result. Workers own only their assigned steps.

## Choose one mode

### Explore

Use Explore when the direction is still forming or the user asks for analysis.
It is read-only. The lead may ask temporary specialists to investigate
independent questions and then synthesizes one recommendation.

Exploration ends with:

```text
EXPLORATION_RESULT
question:
evidence:
recommendation:
uncertainties:
likely_affected_documents:
next_decision:
```

Exploration does not create accepted truth, reserve a future design, or make
external changes.

### Fast delivery

Use Fast delivery only when every condition below is true:

- the result and affected artifacts are clear;
- the change is local and reversible;
- accepted meaning, authority, architecture, and shared terminology do not
  change;
- no unique knowledge is deleted;
- one qualified agent can complete and validate it safely;
- no destructive or external mutation lacks current-user authorization.

Typical examples are spelling, formatting, link repair, factual handoff refresh,
and mechanical metadata normalization. If any condition fails, use Governed
delivery. Fast delivery is never a shortcut around material review.

### Governed delivery

Use Governed delivery for new or changed accepted meaning, authority boundaries,
shared definitions, architecture decisions, or consolidation that could lose
unique knowledge.

The sequence is fixed:

```text
Outcome Lead plans and confirms when required
    -> one Systems Knowledge Developer edits
    -> deterministic checks run
    -> one Systems Coherence Reviewer reviews read-only
    -> accept, or one bounded correction
    -> accept, or return to planning
```

There is one initial review and at most one bounded correction followed by one
final review. A further `revise` is not another writing round. The Outcome Lead
must change the route, narrow the objective, obtain a missing capability, record
an open decision, or ask the user about a genuine choice.

## Outcome contract

Before editing, record enough information to prevent workers from optimizing for
an internal artifact instead of the requested result:

```yaml
objective: user-visible result
definition_of_done:
  - observable completion condition
mode: explore | fast | governed
route: shortest viable safe approach
authorized_changes:
  - exact area or artifact
non_goals:
  - excluded outcome
risks:
  - condition, consequence, mitigation
current_owner: lead or assigned worker
next_action: exact resumable step
```

The lead proposes missing checklist items. Confirmation is required only when
the request leaves a material choice, authority gap, destructive or external
effect, meaningful cost, or major risk. A clear low-risk request may proceed
after a short commentary plan.

## Worker qualification and assignments

A role name is not proof of capability. Before assigning work, the lead checks
that the worker has the needed domain context, tools, permissions, and a route
that can reach the outcome.

### Model and reasoning selection

Model selection and reasoning effort are separate decisions. For every worker,
the Outcome Lead selects the least costly available model with evidence that it
can reach the assigned outcome, then selects only as much reasoning effort as
the assignment's ambiguity, consequence, and verification difficulty require.
Do not use a role name, a previous worker choice, or defensive habit as model
evidence. Do not record model prices; availability and cost can change.

Use these observable routing conditions for the available model family:

- `gpt-5.6-luna` fits tightly bounded, low-ambiguity work with established
  authorities, straightforward validation, and low consequence if a defect is
  missed.
- `gpt-5.6-terra` fits bounded work that needs balanced judgment across known
  authorities, nontrivial validation, or moderate consequence if a defect is
  missed.
- `gpt-5.6-sol` fits work with high ambiguity, difficult cross-authority
  reconciliation, complex reasoning or verification, or high consequence if a
  defect is missed.

Choose reasoning effort independently: use the lightest available effort that
can perform the necessary analysis and checks. Increase effort for ambiguity,
interacting constraints, or difficult verification; do not increase the model
solely to obtain more reasoning. If the task evidence changes, the worker stops
and requests escalation rather than silently changing its model, reasoning
effort, scope, or safety boundary.

For review, select the reviewer model and reasoning effort from the consequence
of a missed defect and the difficulty of detecting it. The review selection is
independent of the developer's selected model and reasoning effort; reviewer
independence also still requires a different worker and read-only review.

Each assignment must state:

```text
WORKFLOW_ID:
ASSIGNED_ROLE:
OBJECTIVE:
DEFINITION_OF_DONE:
ASSIGNED_STEP:
AUTHORITIES:
AUTHORIZED_CHANGES:
SELECTED_MODEL:
REASONING_EFFORT:
MODEL_JUSTIFICATION:
ESCALATION_CONDITIONS:
RISKS_AND_MITIGATIONS:
STOP_CONDITIONS:
REQUIRED_OUTPUT:
```

`MODEL_JUSTIFICATION` cites the observable routing conditions and evidence for
the chosen model. `ESCALATION_CONDITIONS` state the evidence that makes the
chosen capability inadequate and requires the worker to stop and request a new
assignment. The lead does not pre-authorize a silent model change.

Workers acknowledge that envelope before acting. Use the Systems Knowledge
Developer for material writing and the Systems Coherence Reviewer for independent
review. Other specialists are temporary and task-qualified; do not create a
permanent role merely because a task needs advice once.

Only one worker edits the candidate. Parallel work is appropriate for
independent read-only investigation or disjoint implementation artifacts, not
for competing edits to the same truth.

Assignments and durable artifacts follow the
[Clear Language Standard](../standards/CLEAR_LANGUAGE.md). A role or tool name
may identify responsibility inside an assignment, but it must not replace a
plain statement of the intended outcome.

## Review boundary

Before review, the lead creates an accepted-change manifest with
`scripts/change-manifest.ps1`. The manifest fingerprints the complete candidate
and the expected idle workflow checkpoint. The lead also copies the complete
current `DEVELOPER_HANDOFF` into the checkpoint's **Review packet** section. The
packet is lossless: it uses the exact developer-role schema, contains every
field with its complete current value, matches the active workflow ID, and says
`ready_for_review: yes`. A summary or link to chat is not a review packet.
The manifest fingerprints this packet as well as the candidate; review
verification fails if either changes.

The reviewer verifies the manifested snapshot, persisted review packet,
governing authorities, and observable definition of done. Reviewing,
final-review, and finalizing checkpoints are invalid when the packet is absent,
incomplete, cross-workflow, or not ready. A correction replaces the preceding
packet with the corrected handoff before the final-review manifest is created;
the checkpoint never accumulates historical packets.

The reviewer returns `accept`, `revise`, or `open-decision-required`. A finding
must identify evidence, consequence, and required resolution. Optional hardening
and stylistic preference do not block delivery.

When the first review returns `revise`, the lead may authorize one bounded
correction containing only the listed findings. The developer records a factual
disposition for each finding. The final reviewer either accepts the corrected
candidate or returns control to planning.

## Compact workflow checkpoint

`docs/operations/KNOWLEDGE_WORKFLOW_STATE.md` is a replaceable checkpoint, not a
history ledger. While active it records only:

- workflow ID and mode;
- objective and definition of done;
- current stage and owner;
- authorized changes and review-locked entries;
- current route, risks, and stop conditions;
- completed evidence, remaining blocker, and next action;
- latest developer handoff, review outcome, and manifest identity when they
  exist;
- whether the single correction has been used.

Valid stages are `idle`, `developing`, `reviewing`, `correcting`, `final-review`,
and `finalizing`. Git history retains completed workflow history. Do not copy old
rounds or replaced plans into the active checkpoint.

The complete current developer handoff is stored under **Review packet** only
while review evidence is needed. It is replaced after a correction and removed
when the checkpoint returns to idle.

## Completion

After acceptance, make no material candidate edits. The lead verifies the
manifest, writes the manifest's expected idle checkpoint, reruns documentation
validation, and confirms every definition-of-done item.

Journal impact exists when a change alters the represented system inventory; a
represented system's ID, name, purpose, kind, parent, authorities, document or
concept coverage, knowledge state, coverage, implementation state, attention,
relationships, or open decisions; the world-generation concept inventory or a
concept's lifecycle state, truth, owner, coverage, or implementation; the open-
decision inventory, title, or system association; the current review date,
focus, or milestone; runtime artifact evidence; or a historical account.
For Journal-impacting work, the developer updates the authoritative owner first,
then the registry when navigation or aggregation changed, and rebuilds generated
Markdown. The Sites owner then syncs generated website data. Before review, the
developer proves Markdown byte parity and website-data freshness. When no
Journal impact exists, the developer handoff states that conclusion and the
reviewer verifies it. The website remains derivative and owns no technical
truth.

The reviewer and lead require `scripts/build-project-journal.ps1 -Check` and the
site's read-only sync check. The fingerprint hashes the represented semantic
projection, so unrelated spelling-only source edits do not require regeneration.
It proves reconsideration of represented values, not semantic truth.

Acceptance authorizes no Git or external mutation. If the current user requested
Git delivery, invoke the Git Publisher only after the workflow is idle. Report
the real outcome, including any blocked external step; a passing test or local
commit is not a successful push.
