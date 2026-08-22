# Project Operating Instructions

These instructions apply to every human or AI contributor in this repository.
They define the default operating contract; more specific instructions may be
added deeper in the tree when a domain genuinely needs them.

## Operating expectation

Own assigned work end to end. Routine coordination is part of the job, including
repository orientation, task decomposition, synchronization, validation,
review, integration, status propagation, and safe Git cleanup.

Do not ask the user to choose routine Git commands, branch names, merge order,
worktree cleanup, test commands, file placement, or ordinary handoff mechanics.
Inspect the evidence, choose the safest conventional action, perform it, and
report the outcome. Escalate only when a choice changes product direction,
crosses an explicit approval boundary, risks unrecoverable loss, requires
credentials or authority that are unavailable, or remains genuinely ambiguous
after reasonable investigation.

The user is Product Owner and retains final authority over product vision,
material scope changes, public release, spending, commercial commitments, and
other irreversible external decisions. The Project Steward or lead agent owns
routine orchestration and integration.

## Canonical orientation

Before substantive work, read in this order:

1. `docs/handoff/CURRENT_STATE.md`
2. `docs/operations/WORKSTREAMS.md`
3. `docs/operations/OPERATING_MODEL.md`
4. The task-relevant roadmap, architecture, decision, and domain documents
5. `docs/PROJECT_VISION.md` and `docs/DESIGN_PRINCIPLES.md` when making design
   choices
6. `docs/art/README.md` for in-game visuals, visual interpretation, camera,
   rendering, assets, technical-art pipelines, or gameplay capture
7. `docs/brand/BRAND_FOUNDATION.md` and
   `docs/marketing/MARKETING_DEPARTMENT.md` for public identity, messaging, or
   market-facing work

Chats, agent summaries, worktree contents, proposals, and open questions are not
canonical merely because they exist. Promote durable conclusions into the
appropriate repository artifact.

## Truth and status

Keep these states distinct:

- Decision: `Proposed`, `Accepted`, `Rejected`, or `Superseded`.
- Delivery: `Proposed`, `Ready`, `Active`, `Blocked`, `Review`, `Integration`,
  `Done`, or `Cancelled`, using the lifecycle in
  `docs/operations/WORKSTREAMS.md`.
- Product evidence: `Demonstrated`, `In development`, `Planned`, `Long-term
  direction`, or `Optional exploration`.

An accepted decision is not implemented code. A merged implementation is not
verified product evidence until its required validation passes. Never convert an
open question into accepted architecture silently.

## Work lifecycle

For every meaningful work packet:

1. **Frame** — identify the outcome, accountable owner, acceptance criteria,
   dependencies, affected domains, and declared write set.
2. **Preflight** — inspect current Git state, relevant canonical documents,
   active work, and possible overlapping writers.
3. **Route** — consult owners before changing their contracts; notify only the
   consumers identified by `docs/operations/DEPENDENCIES.md`.
4. **Execute** — make the smallest coherent change that completes the outcome.
5. **Validate** — run proportionate tests and inspect the complete diff.
6. **Review** — apply the review gates in the operating model. Reviewers report
   findings; they do not silently take over another owner's branch.
7. **Integrate** — synchronize, resolve conflicts, land the change through the
   controlled mainline path, and confirm the integrated result.
8. **Propagate** — update canonical status/decisions and send targeted notices
   with links to the merged artifact.
9. **Close** — remove safe, obsolete branches/worktrees and leave no completed
   work stranded only in a chat or detached HEAD.

The lead agent is the default Project Steward for its task. Specialists return
bounded evidence or artifacts to that lead; the lead owns synthesis and closure.

## Parallel agents

Use parallel agents for independent, bounded workstreams. Prefer read-heavy
delegation for exploration, research, review, tests, and analysis. Parallel
writers must have disjoint declared write sets. If two tasks need the same file,
contract, manifest, lockfile, CI definition, or global index, serialize them or
appoint one writer and make the others reviewers.

Departments are durable ownership boundaries, not excuses to create recursive
agent hierarchies. Default to temporary specialists. Create or retain a standing
department only when it has a recurring backlog, stable artifact ownership, a
meaningful interface, and sufficient cognitive load.

## Art / Technical Art gate

Art & Technical Art is a standing domain authority distinct from Marketing. It
owns accepted in-game visual contracts and player-visible interpretation,
including map language, projection, camera and zoom behavior, picking feedback,
rendering conventions, shaders, materials, assets, LOD/streaming presentation,
technical-art pipelines, and the visual truth of gameplay capture. Marketing
owns public identity, framing, and campaign use; it does not accept in-game
visual semantics.

<!-- ART-CONTRACT: IMPACT-DECLARATION -->
Every meaningful packet, decision RFC, review finding, and pull request must
declare `Art / Technical Art impact` as `Action required`, `Consulted`,
`Informed`, or `N/A — <rationale>`. Art is action-required when a change defines
or accepts a player-visible visual contract or gameplay capture. Art is
consulted when world meaning, query shape, LOD, refinement, asset flow, or other
technical behavior could alter visual interpretation. `N/A` is valid only with
a concrete rationale.
<!-- ART-CONTRACT: REVIEW-GATE -->
An action-required Art change cannot be accepted or integrated until the Art &
Technical Art owner records `Accepted`. When Art depicts world or simulation
meaning, the owning domain also confirms semantic honesty. Art findings block
the affected visual scope; the DRI resolves and returns it for re-review rather
than routing around the gate.

## Autonomous Git protocol

The normal rule is:

> One work packet = one named branch = one worktree = one primary writer = one
> pull request.

### Preflight and synchronization

- Inspect `git status --short --branch`, `git rev-parse HEAD`, recent history,
  and `git worktree list --porcelain` before writing.
- Fetch and prune remote references when network access is available.
- Treat unpublished local commits and dirty files as valuable work. Never reset,
  overwrite, clean, or discard them to make synchronization easier.
- Determine the authoritative baseline from repository evidence. If local and
  remote main differ, reconcile them through preserved commits and reviewed
  integration; do not ask the user to choose a routine Git procedure.
- Record the base commit in the work packet or pull request.

### Branches and worktrees

- Reserve `main` as the authoritative integration line. Do not use long-lived
  department branches.
- Before the first durable commit, create a short-lived task branch. Codex-managed
  worktrees begin detached; attach completed work to a named branch or use the
  app handoff before it can become orphaned.
- Use descriptive names such as `rfc/WG-014-coordinate-contract`,
  `feat/CORE-021-seed-types`, `feat/CLIENT-008-pan-zoom`,
  `docs/MKT-006-claims-ledger`, or `fix/PLATFORM-004-windows-ci`.
- Never let two simultaneous writers share a branch or worktree. A branch
  isolates history; a worktree isolates files and index state. Both matter.
- Agents may read globally but must stage and commit only their declared scope.
  Never sweep unrelated user or agent changes into a commit.

### Commits, reviews, and integration

- Make coherent commits with explicit paths and meaningful messages. Include the
  work or decision ID when one exists.
- A task owner may update or rebase its own unpublished branch. Do not rewrite
  reviewed or shared history. Use `--force-with-lease` only on a solely owned,
  pre-review branch; never use unqualified force push.
- Push the task branch and use a pull request as the durable review and handoff
  record. Complete the repository PR template.
- Resolve ordinary conflicts autonomously when they fall within the declared
  scope. For cross-domain semantic conflicts, consult the affected owner and
  record the resolution; escalate to the user only if product authority is
  required.
- Required CI and validation must pass against current main. A stale green result
  is not enough when the base changed materially.
- The Project Steward serializes final integration in dependency order. Squash
  merge one logical work packet by default. The steward may merge routine,
  in-scope changes without user confirmation once gates pass.
- Contracts/specifications merge before dependent implementation; core/provider
  changes merge before consumers; verified implementation precedes public claims.

### Cleanup and recovery

Cleanup is an agent responsibility, not a user task.

- After integration, confirm the worktree is clean and prove the exact submitted
  task head was integrated. For ancestry-preserving merges, prove reachability
  from authoritative `main`. For squash merges, prove the hosted pull request is
  merged, its recorded head SHA equals the task head, the recorded merge commit
  is on `main`, and the branch has no post-submission commits.
- Before removing a worktree, resolve and verify its absolute path, inspect its
  status, and prove that every valuable change is either reachable from a
  retained ref or represented by the exact merged pull-request head above. Never
  delete a dirty worktree or unmatched unique work.
- Remove the worktree before its local branch. Prefer `git branch -d`; after the
  squash proof above, `git branch -D` is allowed solely to overcome the expected
  ancestry check. Never force-delete an unverified branch or use a broad target.
- For a stale detached worktree:
  - if dirty, preserve the changes on a named branch and finish or hand off the
    work;
  - if its HEAD contains unique commits, create/push a recovery branch before
    cleanup;
  - if clean and its HEAD is already an ancestor of authoritative main, it may be
    removed once no active or pinned Codex task owns it.
- Do not remove a Codex-managed worktree belonging to an active task. The owning
  lead closes or archives the task after integration, then performs or delegates
  cleanup.
- If CI or post-merge validation fails, the integrator owns immediate repair or a
  safe revert. Do not leave main knowingly broken while moving to unrelated work.

## Handoffs and change propagation

A handoff is complete only when the next owner can act without reconstructing
chat history. The pull request or work record must state:

- work ID, accountable owner, branch, base/head commits, and declared write set;
- completed outcome and canonical artifacts;
- decisions made, rejected, superseded, or still open;
- interfaces, invariants, and contracts changed;
- validation commands and results;
- risks, blockers, dependencies, and required merge order;
- affected departments classified as `Consulted`, `Informed`, or
  `Action required`;
- next owner and exact next action;
- working-tree state and recovery/revert notes when relevant.

Consulted owners participate before acceptance. Informed owners receive the
merged result. Action-required owners receive a concrete request and must
acknowledge or complete it. Do not broadcast every change to every department.

`docs/operations/WORKSTREAMS.md` is the sole canonical portfolio ledger, with
the Project Steward as its serialized writer. Issues, pull requests, and task
messages are linked execution evidence and acknowledgement channels; they do not
become competing status truth.

The Project Steward maintains global indexes and
`docs/handoff/CURRENT_STATE.md`; ordinary task agents should not turn those files
into merge hotspots unless status maintenance is part of their assigned scope.

## Decisions and documentation

- Record significant or cross-domain decisions under `docs/decisions/` using the
  ADR template and a stable `ADR-NNNN` identifier.
- Keep rationale, alternatives, consequences, owner, affected domains, and links
  to implementation evidence.
- Preserve rejected and superseded decisions; link their replacements rather
  than rewriting history.
- Give each fact one canonical home and link to it instead of copying it into
  summaries. Keep the current-state handoff short and operational.
- Update documentation in the same work packet when behavior, contracts, status,
  or public evidence changes.

## Validation baseline

Run checks in proportion to the change. For Rust or project-wide changes, the
baseline is:

```powershell
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --locked
cargo test --doc --workspace --locked
pwsh -File tools/project-governance.ps1 -Mode Validate
```

For documentation-only work, run the governance validator and inspect all changed
links, statuses, decision references, and the complete diff. Report exactly what
was and was not validated.
