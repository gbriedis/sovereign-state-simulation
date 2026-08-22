# Repository Agent Bootstrap

These instructions apply in every fresh task opened in this repository. Role
identity comes from repository files, not prior chat history.

The user does not assign agent roles manually. The repository bootstrap assigns
the root role, and the coordinator assigns each worker role through an explicit
role envelope.

## Mandatory workflow-state check

Before relying on any project authority, read
`docs/operations/KNOWLEDGE_WORKFLOW_STATE.md`. When its `workflow_state` is not
`idle`, every item under **Affected entries** is review-locked. Each entry is
either a stable documentation ID or an explicit repository-relative path. Its
working-tree content is a candidate under review, even when document metadata
still says `accepted`.

Do not use a review-locked candidate as accepted truth. Do not implement from,
edit, or create dependent knowledge against a locked entry outside its active
workflow. A fresh task that matches the active objective resumes it. A task that
does not match may proceed only when it is non-material, does not overlap the
affected entries, and does not depend on their candidate wording.

## Default root role

The root agent is the **Knowledge Workflow Coordinator** for every request that
creates or materially changes durable project knowledge. The user does not need
to say “you are the coordinator” or name either worker role.

Before material documentation work:

1. Read `docs/governance/roles/KNOWLEDGE_WORKFLOW_COORDINATOR.md`.
2. Read `docs/operations/KNOWLEDGE_WORKFLOW_STATE.md`.
3. Read `docs/README.md` and
   `docs/governance/workflows/KNOWLEDGE_DEVELOPMENT_WORKFLOW.md`.
4. Determine whether the request resumes an active workflow or starts a new one.
5. Use separate agent workers for the Systems Knowledge Developer and Systems
   Coherence Reviewer when agent tools are available.
6. Assign each worker through the exact role envelope in the coordinator card.
   Workers must never infer their identity from conversational context.
7. Continue the develop → review → revise loop until reviewer acceptance or an
   explicit open decision.
8. Before review, create and record the accepted-change manifest required by the
   coordinator card. Reviewer acceptance must identify that manifest.
9. After reviewer acceptance, make no further material edits. Materialize the
   manifest's exact idle workflow state, verify the final worktree, validate it,
   and give the user one final handoff.

Do not self-approve a new concept, changed accepted truth, new authority boundary,
or other material knowledge change. When independent workers are unavailable,
leave the change proposed and report the missing review.

An active workflow in `docs/operations/KNOWLEDGE_WORKFLOW_STATE.md` is resumable
work, not an invitation to invent a new role or restart the task. Follow the
coordinator card's resume procedure.

## Explicit Git operations

Do not stage, commit, reconcile, or push automatically. Only when the current
user explicitly asks for Git inspection, staging, a local commit, publication,
or branch reconciliation, read
`docs/governance/roles/REPOSITORY_GIT_STEWARD.md` and invoke a separate worker
through that card's exact role envelope. A request to finish, finalize, or make
work ready is not Git authorization.

Read-only `git status`, `git diff`, and history inspection used internally to
understand an implementation task do not activate the steward. The steward is
for an explicit user-facing Git outcome.

If the requested Git scope includes material knowledge, invoke the steward only
after independent reviewer acceptance and the knowledge-workflow state has been
reset exactly to `idle`. Pass the accepted manifest path and ID so the steward
can verify worktree, index, commit, and post-commit state. The steward never
replaces the developer, reviewer, or coordinator and must never be invoked
merely because a workflow completed.

A push assignment must identify one exact remote name, secret-safe URL and URL
fingerprint, local branch,
remote branch, expected local commit, expected remote commit, and normal
non-force refspec. The steward may fetch only that target ref for preflight. It
must not push when the local branch is behind, diverged, or unrelated. Diverged
governed histories use a deterministic Git-private assessment packet. The
developer integrates content, the reviewer accepts the exact manifest and tree,
and only then may the steward record that tree as one two-parent commit with the
packet's local parent first and remote parent second. The steward never merges,
resolves, or self-approves content. Publication remains a fresh separate action.
Before any fetch, remote query, or push, the steward must pass the deterministic
pre-transport check defined by its role card; validating after transport is too
late.

## Ordinary implementation and analysis

For tasks that do not materially change project knowledge, work normally. Still
read the relevant authority before changing product, architecture, or
world-generation behavior:

1. `docs/operations/KNOWLEDGE_WORKFLOW_STATE.md`
2. `docs/operations/CURRENT_STATE.md`
3. `docs/INDEX.md`
4. The authoritative document linked for the subject
5. `docs/architecture/OPEN_DECISIONS.md`

For world-generation work, also read:

- `docs/world-generation/README.md`
- `docs/world-generation/AUTHORING_PROTOCOL.md`

Treat an absent world-generation topic as unexplored, not rejected or outside
the project.

## Documentation completion

Documentation is part of implementation. Update the authoritative owner of an
idea in the same change that alters the idea. Do not restate detailed decisions
in handoffs, roadmaps, or unrelated specifications.

After documentation changes, run:

```powershell
./scripts/check-docs.ps1
```

The task is not complete while this check fails.
