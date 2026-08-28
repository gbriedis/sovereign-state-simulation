# Repository Agent Bootstrap

These instructions apply in every fresh task in this repository. Repository
files, not chat history, supply durable project context.

## Start here

Before using project authority, read
`docs/operations/KNOWLEDGE_WORKFLOW_STATE.md`. If it records an active workflow,
the listed paths and document IDs are review-locked candidates. Do not treat
their working-tree wording as accepted truth outside that workflow.

For ordinary product or implementation work, then read:

1. `docs/operations/CURRENT_STATE.md`
2. `docs/INDEX.md`
3. The authoritative document linked for the subject
4. `docs/architecture/OPEN_DECISIONS.md`

For world-generation work, also read:

- `docs/world-generation/README.md`
- `docs/world-generation/AUTHORING_PROTOCOL.md`

An absent world-generation topic is unexplored, not rejected. Never invent a
decision merely because no document covers it.

## Default responsibility

For a non-trivial request, the root agent is the **Outcome Lead**. The user does
not need to assign roles or provide a complete checklist. The lead must infer
the intended result from the request and repository evidence, recommend missing
checklist items, and choose the lightest mode that can reach the result safely.

Read `docs/governance/roles/OUTCOME_LEAD.md` and
`docs/governance/workflows/KNOWLEDGE_WORKFLOW.md` before material documentation
work. Those files own routing, confirmation, delegation, review, and resumption.

The three modes are:

- **Explore** — read-only investigation while direction is forming.
- **Fast delivery** — one agent completes a bounded, reversible change that
  does not alter accepted meaning or require independent judgment.
- **Governed delivery** — one developer writes a material change and one
  independent reviewer accepts or returns it once. One bounded correction is
  allowed; another failure returns to planning.

Use temporary workers only when their capability is needed. Give each worker a
written assignment containing the outcome, bounded step, relevant authorities,
permissions, risks, stop conditions, and required output. Only one worker may
edit a given candidate. Parallel workers must be read-only or own disjoint
artifacts.

Material documentation includes new or changed accepted truth, authority,
terminology, architecture, or deletion that could lose unique knowledge. It
must use Governed delivery and independent review. Spelling, formatting,
metadata normalization, and link repair may use Fast delivery when meaning is
unchanged.

## Confirmation and authority

A clear, bounded, low-risk request authorizes ordinary in-scope edits. When a
material choice, unclear outcome, destructive effect, external mutation, cost,
or major risk remains, recommend a concrete plan and wait for confirmation.
Do not make the user invent the plan.

Minor discoveries may be handled within the confirmed boundary. Stop and
replan when evidence changes the route, required capability is unavailable, or
the consequence becomes major or irreversible.

## Git operations

Read `docs/governance/roles/GIT_PUBLISHER.md` only when the current user
explicitly requests a commit, push, pull request, or other Git mutation.
Read-only status, diff, and history inspection do not activate that role.

The Git Publisher transports an already validated result. It does not design,
review, reconcile, or approve content. For governed knowledge, invoke it only
after independent acceptance and an idle workflow checkpoint.

Never force-push. If direct publication is rejected or the target has moved,
preserve the local work and report the exact condition with the safest next
route. Prefer a feature branch and pull request when repository policy requires
review. Merging or resolving divergent content is a new implementation task,
not a publication retry.

## Documentation completion

Update the authoritative owner of an idea in the same change that alters the
idea. Link from indexes and handoffs instead of duplicating detailed decisions.
Remove superseded files after preserving their unique value; Git history is the
archive for obsolete governance.

After documentation changes, run:

```powershell
./scripts/check-docs.ps1
```

The task is not complete while this check fails.
