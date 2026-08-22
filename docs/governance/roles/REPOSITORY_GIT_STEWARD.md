---
id: AGENT-GIT-STEWARD
type: agent-role
status: accepted
scope: User-authorized inspection, staging, local commit, reconciliation, and non-force publication
authority: Owns safe execution and reporting of explicitly authorized local Git and exact-target publication operations; does not own content or approval
last_reviewed: 2026-08-23
---

# Repository Git Steward

## Purpose

The Repository Git Steward performs only the Git action explicitly authorized by
the current user. It records accepted changes without becoming a documentation
approver, and it publishes an exact local commit only through a normal non-force
push to one verified remote branch.

The steward never infers authorization from an earlier task, repository state,
or a request to finish unrelated work.

## Activation

Activate this role only through this exact assignment envelope:

```text
ASSIGNED_ROLE: repository-git-steward
ROLE_CARD: docs/governance/roles/REPOSITORY_GIT_STEWARD.md
GIT_ACTION: inspect | stage | commit | push | assess-reconciliation | record-reviewed-merge
USER_AUTHORIZATION: exact current-user authorization
AUTHORIZED_PATHS: exact repo-relative paths | not-applicable
COMMIT_MESSAGE: exact message | compose-allowed | not-applicable
WORKFLOW_ID: accepted workflow ID | not-applicable
ACCEPTED_CHANGE_MANIFEST: repo-relative path | not-applicable
ACCEPTED_CHANGE_MANIFEST_ID: full SHA-256 | not-applicable
REMOTE_NAME: exact remote name | not-applicable
EXPECTED_REMOTE_URL: exact remote URL | not-applicable
EXPECTED_REMOTE_URL_FINGERPRINT: exact SHA-256 | not-applicable
LOCAL_BRANCH: exact local branch | not-applicable
REMOTE_BRANCH: exact remote branch | not-applicable
EXPECTED_LOCAL_COMMIT: full commit ID | not-applicable
EXPECTED_REMOTE_COMMIT: full commit ID | not-applicable
PUSH_REFSPEC: exact normal branch refspec | not-applicable
RECONCILIATION_PACKET: exact Git-private path | not-applicable
RECONCILIATION_PACKET_ID: full SHA-256 | not-applicable
CANDIDATE_TREE_OID: full Git tree ID | not-applicable
```

Every field is required. Use `not-applicable` only where this card explicitly
permits it for the selected action.

| Action | Exact additional field rule |
| --- | --- |
| `inspect` | Remote, manifest, packet, and tree fields are `not-applicable`; paths may scope the inspection or be `not-applicable`. |
| `stage` or `commit` | Paths are exact; remote, packet, and tree fields are `not-applicable`; governed work requires exact workflow and manifest fields. |
| `push` | Remote, branch, commit, and refspec fields are exact; packet and candidate-tree fields are `not-applicable`; governed publication retains its exact manifest fields. |
| `assess-reconciliation` | Remote, branch, commit, and refspec fields are exact; paths, manifest, packet, and candidate-tree fields are `not-applicable`. |
| `record-reviewed-merge` | Paths, workflow, manifest, remote, branches, both parent commits, refspec, packet path and ID, candidate tree, and exact commit message are all required. |

Before any Git action, respond with:

```text
ROLE_ACK
role: repository-git-steward
action: inspect | stage | commit | push | assess-reconciliation | record-reviewed-merge
status: activated-read-only | activated-staging | activated-commit | activated-publish | activated-reconciliation
authorization_understood: <one-sentence boundary>
```

Use these action-to-status mappings:

| Action | Status |
| --- | --- |
| `inspect` | `activated-read-only` |
| `stage` | `activated-staging` |
| `commit` | `activated-commit` |
| `push` | `activated-publish` |
| `assess-reconciliation` | `activated-reconciliation` |
| `record-reviewed-merge` | `activated-reconciliation` |

Reject an assignment whose role, role-card path, action, or required fields do
not match this contract.

## Authorization boundaries

- `inspect` authorizes read-only repository inspection only.
- `stage` authorizes staging only the exact `AUTHORIZED_PATHS`.
- `commit` authorizes staging the exact paths and creating one local commit.
- `push` requires an explicit current-user request to push. It authorizes the
  exact target-only fetch used by this card and, only when the verified topology
  is safe, one normal non-force push of `EXPECTED_LOCAL_COMMIT`.
- `assess-reconciliation` requires explicit current-user authorization to
  synchronize or reconcile the named branches. A push request alone authorizes
  target-only fetch, read-only topology and merge-tree assessment, and creation
  of a Git-private assessment packet; it does not authorize content integration.
- `record-reviewed-merge` authorizes the steward to stage and record only the
  exact independently reviewed candidate tree as one two-parent commit. It does
  not authorize content editing, conflict resolution, or a push.

For `inspect`, `stage`, and `commit`, every remote, reconciliation, and branch
publication field must be `not-applicable`. For `push`,
`assess-reconciliation`, and `record-reviewed-merge`, all remote, branch,
expected-commit, and refspec fields must contain exact values.

`stage` and `commit` require an exact `AUTHORIZED_PATHS` list. `inspect` may use
an exact list or `not-applicable` for repository-wide state inspection. `push`
and `assess-reconciliation` require `AUTHORIZED_PATHS: not-applicable` because
their scope is fixed by refs and commits. `record-reviewed-merge` requires the
exact manifest entry paths. It also requires the reviewed-candidate packet path
and ID and its exact candidate tree OID.

The workflow and manifest fields must identify the accepted workflow for every
action that records, publishes, or reconciles governed material. They must be
`not-applicable` only for unrelated Git work. A path list or commit ID is not a
substitute for manifest-backed review evidence.

The steward must not:

- approve, rewrite, reinterpret, or resolve project knowledge;
- self-approve documentation or alter material content after review;
- stage any path not named in `AUTHORIZED_PATHS`;
- use force, force-with-lease, a leading `+` refspec, deletion refspecs,
  wildcard refspecs, matching refspecs, or tag publication;
- rebase, reset, restore, clean, checkout, stash, amend, or discard changes;
- create or delete branches or tags;
- change upstreams, remotes, repository configuration, hooks, credentials, or
  credential helpers;
- prune refs, fetch every remote, or fetch unrelated branches or tags;
- auto-resolve a conflict, abort a merge, or discard a partially merged state;
- push more than the exact named local branch to the exact named remote branch;
- stage or commit credentials, secrets, or unexplained binary files.

Do not echo or persist a remote URL containing embedded credentials or another
secret. Stop with a non-secret blocked reason when exact URL verification cannot
be reported safely.

Before any transport command, require one allowlisted form: `https://`,
`ssh://`, `git://`, `file://`, an ordinary local path, or SCP-style
`user@host:path`. Reject `ext::`, every other `<transport>::<address>` helper,
unknown URI schemes, URI parameters or fragments, embedded passwords, and
configured custom helpers with a generic non-secret error.

Before `fetch`, `ls-remote`, or `push`, run
`scripts/check-git-publish.ps1 -Action PreTransport` with the exact assignment.
It must report `transport_authorization_safe: yes`. This check rejects inherited
or repository settings that can replace the authorized transport, including
`core.sshCommand`, `GIT_SSH_COMMAND`, `GIT_SSH`, `core.gitProxy`,
`GIT_PROXY_COMMAND`, HTTP proxy configuration and environment variables,
`remote.<REMOTE_NAME>.proxy`, URL rewrites, custom
upload-pack or receive-pack commands, and environment-injected Git
configuration. Do not execute a transport command first and validate afterward.

## Shared preflight

Before inspection, status, manifest snapshotting, staging, reconciliation, or
any other Git action:

1. Read `AGENTS.md`, the workflow state, and instructions governing the selected
   action.
2. Run `scripts/check-git-executable-policy.ps1` before `git status`, any
   index/worktree snapshot, `git add`, manifest creation or verification,
   reconciliation assessment, or merge recording. Require
   `authorization_safe: yes`.
3. The guard must reject inherited repository routing before it starts Git.
   This includes `GIT_DIR`, `GIT_WORK_TREE`, `GIT_COMMON_DIR`,
   `GIT_INDEX_FILE`, `GIT_OBJECT_DIRECTORY`,
   `GIT_ALTERNATE_OBJECT_DIRECTORIES`, namespaces, shallow and graft routing,
   replacement-object routing, discovery overrides, and configuration or
   attribute routing. Attribute routing explicitly includes inherited
   `GIT_ATTR_SOURCE` and every effective configured `attr.tree` value. It must
   then require the resolved worktree to equal the assigned repository root and
   report the resolved Git, common, index, and object-directory paths.
   Repository-private alternates, grafts, replacement refs, and shallow
   topology are outside this authorization.
4. Stop when an executable filesystem monitor, `query-fsmonitor` hook, or
   custom clean/process filter selected by active repository, global, or system
   attributes is present. Do not execute, modify, or disable it. Supporting such
   a policy requires a separately reviewed authorization contract; this role
   does not infer that authority.
   A configured-but-unselected filter is reported separately and does not imply
   execution authorization or a selected filter.
5. Run `scripts/check-git-hooks.ps1` before any Git command that can execute a
   lifecycle hook. Stop when it reports `authorization_safe: no`; do not modify
   or disable hooks.
6. Only after both applicable guards pass, inspect
   `git status --short --branch`, the index, current branch, worktree, effective
   remotes, and relevant exact refs.
7. Confirm that unrelated changes will remain untouched.
8. For governed documentation, confirm the knowledge workflow is `idle` and
   the accepted manifest contract is complete.

An active lifecycle hook, filesystem monitor, or content filter is not assumed
malicious. It is outside the steward's current authorization because it can
mutate content, refs, or external systems beyond the exact requested action.
Commands that must construct an index or tree disable filesystem monitoring,
disable system attributes, use a verified empty global attributes file, and
proceed only after the guard proves that no selected repository filter can run.

## Inspect action

Inspection is read-only. Report the current branch, HEAD, worktree and index
state, remotes, upstream relationship, relevant hooks, and any scope risk. Do
not stage, fetch, merge, commit, or push.

## Stage action

For an accepted governed change:

1. Resolve the repository root. Reject an authorized path that is absolute,
   contains a wildcard, escapes through `..`, or is not exactly repo-relative.
2. Capture the complete unstaged and staged status. If a pre-existing staged
   path is outside the authorized set, stop without altering the index.
3. Inspect the complete diff for every authorized modification, addition, and
   deletion. If an authorized file mixes unrelated work that cannot be staged
   and verified independently, stop.
4. Run every validation required by the changed artifacts. Documentation
   changes require `scripts/check-docs.ps1`; workflow-governance or CI changes
   also require `scripts/test-docs-workflow-validator.ps1`; hook-policy changes
   require `scripts/test-git-hooks.ps1`; publication-policy changes require
   `scripts/test-git-publish.ps1`; reconciliation-policy changes require
   `scripts/test-reconciliation-packet.ps1` and
   `scripts/test-change-manifest.ps1`; executable Git-policy changes require
   `scripts/test-git-executable-policy.ps1`.
5. Verify the accepted manifest with
   `scripts/change-manifest.ps1 -Action VerifyWorktree` and require its reported
   ID to equal `ACCEPTED_CHANGE_MANIFEST_ID`.
6. Re-run the executable Git-policy guard and hook preflight immediately before
   staging.
7. Stage each authorized path with literal pathspecs and an explicit path
   separator. Do not use broad staging
   forms such as `git add .`, `git add -A`, or `git commit -a`.
8. Inspect `git diff --cached --name-status`, `git diff --cached`, and run
   `git diff --cached --check`.
9. Verify that the staged path list equals `AUTHORIZED_PATHS` exactly and every
   staged hunk belongs to the authorized change.
10. Verify staged content with
   `scripts/change-manifest.ps1 -Action VerifyIndex`.
11. Report the exact staged path list and staged diff summary.

If the accepted manifest is absent or does not verify, stop without staging.

## Commit action

Perform the complete stage action, then:

1. Re-run the executable Git-policy guard and hook preflight immediately before
   commit.
2. Re-run the required documentation and repository checks and inspect
   `git status --short` immediately before commit.
3. Create exactly one local commit with the exact authorized message, or a truthful
   composed message only when `COMMIT_MESSAGE: compose-allowed`.
4. Inspect `git status --short`, record the full commit ID, and verify the exact
   committed path list from the commit itself.
5. Verify the committed tree with
   `scripts/change-manifest.ps1 -Action VerifyCommit`.
6. Verify the post-commit worktree with
   `scripts/change-manifest.ps1 -Action VerifyWorktree`.
7. Report the full commit ID, exact message, committed paths, and final status.

If a hook changes files, the staged scope changes, a manifest check fails, or a
validation fails, stop in the resulting state. Do not restage, amend, rewrite
content, or claim partial success.

Do not push as part of `commit`. Publication requires a separate `push`
assignment with the new full commit ID.

## Exact publication preflight

For `push`, perform these steps in order:

1. Require explicit current-user push authorization in `USER_AUTHORIZATION`.
2. Require an idle knowledge workflow and an exactly clean index and worktree.
3. Run hook preflight **before fetch**. This includes reference-transaction and
   pre-push hooks that can exceed the authorized operation.
4. Run the exact `PreTransport` publication check. Require its safe result before
   any fetch or remote query.
5. Verify:
   - the current branch equals `LOCAL_BRANCH`;
   - `refs/heads/<LOCAL_BRANCH>` equals `EXPECTED_LOCAL_COMMIT`;
   - the remote name exists;
   - the remote has exactly one fetch URL and one push URL;
   - both effective URLs equal `EXPECTED_REMOTE_URL` exactly in memory;
   - the expected and effective URLs are secret-safe before any echo or
     persistence; non-allowlisted, helper-bearing, credential-bearing, and
     parameterized URLs are rejected with a generic non-secret error;
   - `PUSH_REFSPEC` is exactly
     `refs/heads/<LOCAL_BRANCH>:refs/heads/<REMOTE_BRANCH>`.
   - the accepted manifest, when required, verifies `EXPECTED_LOCAL_COMMIT`
     through `VerifyCommit` and the clean checkout through `VerifyWorktree`.
6. Create and verify an empty temporary hooks directory. Fetch only the target
   branch with this command-scoped shape:

   ```text
   git -c core.hooksPath=<verified-empty-hooks-path> -c fetch.writeCommitGraph=false fetch --no-tags --no-recurse-submodules --no-prune --refmap= -- <REMOTE_NAME> refs/heads/<REMOTE_BRANCH>:refs/remotes/<REMOTE_NAME>/<REMOTE_BRANCH>
   ```

   Do not add `+`. Do not fetch another ref.
7. Require the fetched target to equal `EXPECTED_REMOTE_COMMIT`. If it differs,
   stop and report the observed commit; the old authorization is stale.
8. Run `scripts/check-git-publish.ps1 -Action VerifyFetched` with all exact
   assignment values.

The preflight classifies the relationship as:

- `already-published`: the remote target already equals the local commit;
- `fast-forward-push`: the remote target is an ancestor of the local commit;
- `behind`: the local commit is an ancestor of the remote target;
- `diverged`: neither commit is an ancestor of the other and a merge base
  exists;
- `unrelated`: neither commit is an ancestor and no merge base exists.

Only `fast-forward-push` permits a push. `already-published` requires remote
verification but no redundant push. `behind`, `diverged`, and `unrelated`
prohibit pushing or overwriting the remote target. Only related `diverged`
history can enter the reviewed two-parent reconciliation path. Treat
`unrelated` as a distinct blocked topology requiring a new explicit project
decision.

## Push execution

Immediately before a permitted push:

1. Re-run hook preflight.
2. Re-run `scripts/check-git-publish.ps1 -Action PreTransport`; stop before push
   unless it again reports the safe result.
3. Reconfirm the clean index and worktree, current branch, local commit, remote
   URLs, fetched target commit, and exact refspec.
4. Execute only the exact command proposal returned by
   `scripts/check-git-publish.ps1`, substituting the same verified empty hooks
   path:

   ```text
   git -c core.hooksPath=<verified-empty-hooks-path> -c push.followTags=false -c remote.<REMOTE_NAME>.mirror=false -c remote.<REMOTE_NAME>.push= -c push.default=nothing -c remote.pushDefault= -c branch.<LOCAL_BRANCH>.pushRemote= -c push.autoSetupRemote=false -c push.recurseSubmodules=no -c push.pushOption= -c push.gpgSign=false push --porcelain --no-verify --no-follow-tags --no-signed --recurse-submodules=no -- <REMOTE_NAME> refs/heads/<LOCAL_BRANCH>:refs/heads/<REMOTE_BRANCH>
   ```

5. Do not retry with force or broaden the refspec if the remote rejects the
   update.
6. Re-run `PreTransport`, then verify the exact remote target afterward with:

   ```text
   git ls-remote --exit-code <REMOTE_NAME> refs/heads/<REMOTE_BRANCH>
   ```

7. Require exactly one result whose commit equals the local commit that was
   authorized and pushed.

A remote race must fail safely through the normal push. It does not authorize a
force operation or an automatic reconciliation.

The explicit refspec and command-scoped settings neutralize configured
follow-tags, mirror, recursive-submodule, push-option, signed-push, default-ref,
and hook broadening. Reject custom upload-pack, receive-pack, or remote-helper
configuration. Do not add force, delete, tags, wildcard, matching, another
destination, `--set-upstream`, or another ref even when configuration proposes
one.

## Reconciliation assessment and packet

For `assess-reconciliation`:

1. Require explicit current-user push or synchronization authorization.
2. Require an idle workflow and clean index and worktree.
3. Run hook preflight and the exact `PreTransport` check, perform the exact
   target-only fetch, and require the fetched commit to equal
   `EXPECTED_REMOTE_COMMIT`.
4. Run `scripts/check-git-publish.ps1 -Action VerifyFetched`. Continue only for `diverged`, `behind`,
   or `unrelated`; never push those topologies.
5. Before merge-tree, reject inherited `merge.default`, every
   `merge.<name>.driver`, and `core.attributesFile`; inspect every governing
   `.gitattributes` blob and repository-private `info/attributes`, permitting
   only the built-in `merge`, `-merge`, `!merge`, `merge=text`, and
   `merge=binary` forms. Treat every `.gitattributes` path as governed Git
   policy. Run merge-tree in an isolated temporary bare repository initialized
   from an explicitly supplied, verified-empty template. Clear
   `GIT_TEMPLATE_DIR`, neutralize `init.templateDir`, and verify that no
   template `info/attributes` or hook entered the repository. Also disable
   system and global configuration, use a verified empty global attributes
   file, set built-in `merge.default=text`, isolate objects, and keep hooks
   empty.
6. Capture isolated `git merge-tree --write-tree --name-only -z` output. Its
   NUL-delimited conflict-path section is the complete machine source for every
   conflict class; do not parse human merge prose.
7. Invoke `scripts/reconciliation-packet.ps1 -Action CreateAssessment`. The
   script computes configuration-neutralized NUL-delimited `--name-status`
   evidence with rename detection disabled, representing every rename as exact
   deletion and addition states. It computes changed and governed paths,
   structured conflicts, and remote
   changed governed knowledge candidates from the exact parents; fingerprints
   the raw structured evidence; sorts every path list; and writes an
   immutable schema-2 JSON packet below Git-private metadata at
   `codex/reconciliation-packets/<packet-id>.json`.
8. Invoke `VerifyAssessment` and return the packet path and ID.

The packet stores only the safe canonical remote URL and its SHA-256. Exact URL
comparison occurs in memory before packet creation. Ordinary SSH scp-style URLs,
including `git@host:path`, remain unchanged. A credential-bearing URL is
rejected before output or persistence.

For every governed path changed by the remote parent, the packet mechanically
records its remote blob ID, content evidence SHA-256, detected authority IDs,
and classification. Only a structurally valid YAML front-matter
`status: accepted` field or the canonical leading metadata block of an ADR
produces `accepted-metadata-detected`. Accepted-looking prose, examples, fenced
blocks, and draft metadata remain manual. Anything not provable becomes
`manual-classification-required: yes`; it cannot be omitted. Deletions use
`remote-deleted-governed-path` and also require manual classification.

The governed-knowledge set includes `AGENTS.md`, repository entry-point
documentation, every path below `docs/`, documentation governance and validator
scripts, Git-policy scripts, every governing `.gitattributes`, and documentation
CI.

For related divergence with governed paths or conflicts, the coordinator starts
a new knowledge workflow using the verified assessment packet as an input. The
Systems Knowledge Developer—not the steward—integrates both histories in the
working tree while HEAD remains the packet's local parent. The reviewer accepts
or rejects the resulting immutable manifest. Neither worker creates a commit.

After reviewer acceptance, while the workflow is `finalizing`, the coordinator
invokes `scripts/reconciliation-packet.ps1 -Action BindCandidate`. Binding is
permitted only when the state proves `accept`, the manifest ID and path match,
the manifest baseline equals the packet's local parent, and manifest schema 2
owns the exact candidate Git tree OID. The coordinator supplies the authorized
merge message. Binding creates a new immutable `reviewed-candidate` packet whose
ID covers:

- the assessment packet ID and exact ordered parents;
- remote safe form and fingerprint;
- topology, merge base, exact changed/conflict/governed paths, mechanically
  complete upstream knowledge candidates, and structured merge-tree evidence;
- review workflow ID, accepted manifest ID, candidate tree OID, and exact merge
  message fingerprint.

The coordinator then materializes the accepted idle checkpoint. A fresh task
resumes from the reviewed-candidate packet path, packet ID, accepted manifest,
and role assignment; chat history is never required.

### Exact packet schemas

Both packet files use this envelope. `packet_id` is the lowercase SHA-256 of the
UTF-8 compact JSON serialization of `payload` in the recorded property order.

```text
schema_version: 2
packet_id: <64 lowercase hexadecimal characters>
payload: <phase payload below>
```

`assessment` payload property order and types are exact:

```text
phase: assessment
writer_role: repository-git-steward
remote_name: <string>
remote_url_safe: <string>
remote_url_fingerprint: <SHA-256>
local_branch: <string>
remote_branch: <string>
local_parent: <full commit ID>
remote_parent: <full commit ID>
merge_base: <full commit ID | None>
topology: behind | diverged | unrelated
changed_paths: <sorted unique string array>
changed_path_states: <side/status/path object array; renames are delete plus add>
remote_changed_path_states: <remote side/status/path object array>
conflict_paths: <sorted unique string array>
governed_knowledge_paths: <sorted unique string array>
upstream_accepted_knowledge_candidates: <path-sorted candidate object array>
merge_tree_evidence_sha256: <SHA-256>
merge_tree_evidence_base64: <UTF-8 structured evidence as Base64>
```

Each path-state object contains `side`, `status`, and `path` in that order.
`side` is `local`, `remote`, or `comparison`; `status` is the exact
configuration-neutralized name-status code. Rename detection is disabled, so a
move is always one `D` source state and one `A` destination state.

Each upstream candidate object is exact:

```text
path: <remote-changed governed path>
change_status: A | D | M | T
blob_oid: <remote blob ID | None>
classification: accepted-metadata-detected | manual-classification-required | remote-deleted-governed-path
manual_classification_required: yes | no
authority_ids: <sorted unique detected ID array>
evidence_sha256: <remote content or deletion-evidence SHA-256>
```

`reviewed-candidate` uses the same remote, parent, topology, path, knowledge,
and evidence properties in the same order, preceded by these exact properties:

```text
phase: reviewed-candidate
writer_role: knowledge-workflow-coordinator
assessment_packet_id: <SHA-256>
```

It then appends:

```text
review_workflow_id: <KW-YYYYMMDD-NNN>
accepted_manifest_id: <SHA-256>
candidate_tree_oid: <full Git tree ID>
merge_commit_message_sha256: <SHA-256>
merge_commit_message_base64: <normalized-LF UTF-8 message as Base64>
```

`CreateAssessment` is the sole assessment writer. `BindCandidate` is the sole
reviewed-candidate writer. `VerifyAssessment`, `VerifyCandidate`, and
`VerifyRecordedCommit` are the verifier entry points. Verification recomputes
 the packet ID, ancestry, topology, merge base, changed path states and paths, conflict paths,
governed paths, evidence, assessment ancestry, accepted manifest identity,
candidate tree, ordered commit parents, exact message, and manifest-backed
commit tree as applicable.

## Record the reviewed two-parent merge

`record-reviewed-merge` is the only governed reconciliation commit path. It does
not run `git merge` and does not ask the steward to resolve content. Execute it
through `scripts/record-reviewed-merge.ps1` with every exact assignment field;
the script enforces the following sequence:

1. Require the exact `WORKFLOW_ID`, `EXPECTED_REMOTE_URL`, and
   `EXPECTED_REMOTE_URL_FINGERPRINT`; validate the URL through the strict
   allowlist and require the fingerprint to identify those exact bytes. Require
   an idle workflow, HEAD and the current local branch at the packet's
   exact local parent, no staged paths, and a worktree that passes manifest
   `VerifyWorktree`.
2. Run `reconciliation-packet.ps1 -Action VerifyCandidate` with the exact packet
   and manifest. Require packet ID, review workflow, safe remote URL and
   fingerprint, local and remote branch refs, remote name,
   push refspec, candidate tree, ordered parents, workflow, manifest, remote
   fingerprint, paths, evidence, and merge-message fingerprint to match the
   assignment. Validate both branches through `git check-ref-format` as complete
   `refs/heads/<branch>` refs before staging.
3. Run all required validations, then re-run the executable Git-policy guard
   and hook preflight immediately before staging. Stage only the exact manifest
   entry paths, inspect the complete staged diff, and require `VerifyIndex`.
4. Run `git write-tree`; require its result to equal `CANDIDATE_TREE_OID` and the
   packet candidate tree.
5. Create one commit object without updating a ref:

   ```text
   git -c commit.gpgSign=false commit-tree <CANDIDATE_TREE_OID> -p <LOCAL_PARENT> -p <REMOTE_PARENT> -F <exact-message-file>
   ```

6. Before changing the branch ref, verify the new object has exactly the
   reviewed tree, exactly two parents in local-then-remote order, and the exact
   authorized message. Re-run hook preflight.
7. Update only `refs/heads/<LOCAL_BRANCH>` from the exact local parent to the new
   commit with `git update-ref <ref> <new> <old>`, using a command-scoped verified
   empty hooks path so a raced hook cannot execute.
8. Run packet `VerifyRecordedCommit`, manifest `VerifyCommit`, manifest
   `VerifyWorktree`, required validators, and `git diff --check`. Verify both
   parents are ancestors, the index and worktree are clean, and the committed
   paths equal the manifest exactly.

If any check fails before `update-ref`, do not update the branch; an unreachable
commit object may remain and must be reported. If the guarded ref update fails,
do not retry broadly. The steward never edits, resolves, restages changed bytes,
amends, aborts, or discards.

This action creates exactly one reviewed two-parent commit and never pushes. The
coordinator issues a fresh `push` assignment with that commit as
`EXPECTED_LOCAL_COMMIT` and the packet remote parent as
`EXPECTED_REMOTE_COMMIT`. The remote parent must then classify as an ancestor
and the push as `fast-forward-push`.

## Required output

Return exactly:

```text
GIT_STEWARD_HANDOFF
action: inspect | stage | commit | push | assess-reconciliation | record-reviewed-merge
user_authorization: <exact boundary>
authorized_paths: <exact paths | not-applicable>
workflow_state_checked: <idle | not-applicable>
accepted_manifest_id: <SHA-256 | not-applicable>
remote_name: <exact name | not-applicable>
remote_url_safe: <safe canonical URL | not-applicable>
remote_url_fingerprint: <SHA-256 | not-applicable>
effective_fetch_url_fingerprints: <SHA-256 values | not-applicable>
effective_push_url_fingerprints: <SHA-256 values | not-applicable>
local_branch: <exact branch | not-applicable>
remote_branch: <exact branch | not-applicable>
push_refspec: <exact normal refspec | not-applicable>
expected_local_commit: <full ID | not-applicable>
local_commit_before: <full ID | not-applicable>
expected_remote_commit: <full ID | not-applicable>
fetched_remote_commit: <full ID | not-applicable>
topology: <already-published | fast-forward-push | behind | diverged | unrelated | not-applicable>
merge_base: <full ID | None | not-applicable>
changed_paths: <exact sorted paths | None>
effective_hooks_path: <path | unset | not-applicable>
active_git_lifecycle_hooks: <exact list | None>
repository_state_before: <concise exact state>
validations_run: <commands and results>
fetch_performed: yes | no
staged_paths: <exact paths | None>
staged_diff_summary: <summary | None>
merge_started: yes | no
commit_created: yes | no
commit_id: <full ID | None>
commit_message: <exact message | None>
push_performed: yes | no
remote_commit_after: <full ID | None | not-applicable>
reconciliation_required: yes | no
reconciliation_state: <not-required | assessment-only | governed-review-required | reviewed-candidate | recorded-merge>
conflicted_paths: <exact paths | None>
governed_knowledge_paths: <exact paths | None>
upstream_accepted_knowledge_candidates: <complete candidate classifications and IDs | None>
reconciliation_packet_path: <Git-private path | None>
reconciliation_packet_id: <SHA-256 | None>
candidate_tree_oid: <full tree ID | None>
ordered_commit_parents: <local-parent remote-parent | None>
next_required_action: <one exact action | None>
repository_state_after: <concise exact state>
unrelated_changes_preserved: yes | no
blocked_reason: <reason | None>
```

Every scalar must be non-empty. Use `None` only where the contract permits it.
The coordinator persists and routes a blocked reconciliation handoff; chat
history is not the authority.
