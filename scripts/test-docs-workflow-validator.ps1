$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$checkerPath = Join-Path $PSScriptRoot 'check-docs.ps1'
$manifestScript = Join-Path $PSScriptRoot 'change-manifest.ps1'
$temporaryState = New-TemporaryFile
$manifestFixtureWorkflowId = 'KW-20990101-003'
$manifestFixtureRelativePath = ".git/codex/accepted-change-manifests/$manifestFixtureWorkflowId.json"
$manifestFixturePath = Join-Path $repositoryRoot $manifestFixtureRelativePath
$checksPassed = 0

$validRevisingState = @'
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Validator test fixture
authority: Validator test fixture
workflow_state: revising
workflow_id: KW-20990101-001
round: 2
objective: Test workflow validation
developer_worker: systems-knowledge-developer
reviewer_worker: systems-coherence-reviewer
review_outcome: revise
change_manifest_path: none
change_manifest_id: none
change_manifest_baseline: none
last_completed_workflow_id: none
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

## Active objective

Test workflow validation.

## Affected entries

- `AGENT-DEVELOPER`
- `scripts/check-docs.ps1`

## Input artifacts

- `docs/governance/roles/SYSTEMS_KNOWLEDGE_DEVELOPER.md`
- `docs/operations/KNOWLEDGE_WORKFLOW_STATE.md`

## Worker references

- Developer role token: `systems-knowledge-developer`
- Developer task-scoped reference: `unavailable`
- Reviewer role token: `systems-coherence-reviewer`
- Reviewer task-scoped reference: `unavailable`

## Accepted-change manifest

- Path: `none`
- ID: `none`
- Baseline commit: `none`
- Final workflow-state path: `none`

## Developer handoff

```text
DEVELOPER_HANDOFF
workflow_id: KW-20990101-001
round: 1
objective: Test workflow validation.
affected_entries: AGENT-DEVELOPER.
current_concept_state: Accepted test state.
proposed_concept_state: Accepted test state.
accepted_truths_preserved: Test truth.
truths_added_changed_or_removed: Test change.
assumptions: None.
alternatives_considered: None.
known_downstream_consumers: Documentation validator.
open_questions: None.
review_finding_dispositions: None.
files_added_changed_renamed_or_removed: None.
validation_command: Test fixture.
validation_result: Test fixture passed.
ready_for_review: yes
```

## Reviewer findings and outcome

```text
REVIEW_OUTCOME
workflow_id: KW-20990101-001
round: 1
outcome: revise
summary: Test revision required.
findings:
  - severity: major
    location: Test fixture.
    affected_concept_or_authority: Documentation validator.
    problem: Test problem.
    long_term_consequence: Test consequence.
    required_resolution_or_question: Test resolution.
validation_checked: Test fixture.
remaining_open_decisions: None.
accepted_manifest_id: None
```

## Next required action

Await the Systems Knowledge Developer revised DEVELOPER_HANDOFF for round 2; if the recorded task-scoped reference is unavailable, reconstruct the same revision assignment with the preceding REVIEW_OUTCOME.
'@

$validIdleState = @'
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Validator test fixture
authority: Validator test fixture
workflow_state: idle
workflow_id: none
round: 0
objective: none
developer_worker: none
reviewer_worker: none
review_outcome: none
change_manifest_path: none
change_manifest_id: none
change_manifest_baseline: none
last_completed_workflow_id: KW-20990101-001
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

No material knowledge workflow is active.

Last completed workflow: `KW-20990101-001`.
'@

$validDevelopingState = @'
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Validator test fixture
authority: Validator test fixture
workflow_state: developing
workflow_id: KW-20990101-002
round: 1
objective: Test developing workflow validation
developer_worker: systems-knowledge-developer
reviewer_worker: none
review_outcome: none
change_manifest_path: none
change_manifest_id: none
change_manifest_baseline: none
last_completed_workflow_id: KW-20990101-001
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

## Active objective

Test developing workflow validation.

## Affected entries

- `AGENT-DEVELOPER`

## Input artifacts

- `docs/governance/roles/SYSTEMS_KNOWLEDGE_DEVELOPER.md`
- `docs/operations/KNOWLEDGE_WORKFLOW_STATE.md`

## Worker references

- Developer role token: `systems-knowledge-developer`
- Developer task-scoped reference: `unavailable`
- Reviewer role token: `none`
- Reviewer task-scoped reference: `unavailable`

## Accepted-change manifest

- Path: `none`
- ID: `none`
- Baseline commit: `none`
- Final workflow-state path: `none`

## Developer handoff

Pending.

## Reviewer findings and outcome

Pending.

## Next required action

Await the Systems Knowledge Developer DEVELOPER_HANDOFF for round 1; if the recorded task-scoped reference is unavailable, reconstruct the same development assignment.
'@

function Invoke-ValidatorFixture {
    param(
        [string]$Name,
        [string]$Content,
        [bool]$ShouldPass
    )

    [System.IO.File]::WriteAllText($temporaryState.FullName, $Content)
    $output = & pwsh -NoProfile -File $checkerPath -WorkflowStatePath $temporaryState.FullName 2>&1 | Out-String
    $didPass = $LASTEXITCODE -eq 0
    if ($didPass -ne $ShouldPass) {
        throw "Workflow validator fixture '$Name' produced the wrong result.`n$output"
    }
    $script:checksPassed++
}

function Get-CommandResultField {
    param(
        [string]$Text,
        [string]$Field
    )

    foreach ($line in ($Text -split '\r?\n')) {
        $match = [regex]::Match($line, '^' + [regex]::Escape($Field) + ':[ \t]*(?<value>.*?)[ \t]*$')
        if ($match.Success) {
            return $match.Groups['value'].Value
        }
    }
    return $null
}

try {
    Invoke-ValidatorFixture -Name 'valid revising state' -Content $validRevisingState -ShouldPass $true

    $manifestCreateOutput = & pwsh -NoProfile -File $manifestScript -Action Create -WorkflowId $manifestFixtureWorkflowId 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create the real manifest validator fixture.`n$manifestCreateOutput"
    }
    $manifestFixtureId = Get-CommandResultField -Text $manifestCreateOutput -Field 'manifest_id'
    $manifestFixtureBaseline = Get-CommandResultField -Text $manifestCreateOutput -Field 'baseline_commit'
    if ($manifestFixtureId -notmatch '^[0-9a-f]{64}$' -or $manifestFixtureBaseline -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') {
        throw 'The real manifest validator fixture returned malformed identity fields.'
    }
    $manifestFixtureDocument = Get-Content -Raw -LiteralPath $manifestFixturePath | ConvertFrom-Json
    $generatedIdleState = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($manifestFixtureDocument.payload.final_workflow_state_base64))
    Invoke-ValidatorFixture -Name 'manifest-generated materialized idle checkpoint' -Content $generatedIdleState -ShouldPass $true

    $validReviewingState = $validRevisingState.Replace('workflow_state: revising', 'workflow_state: reviewing')
    $validReviewingState = $validReviewingState.Replace('KW-20990101-001', $manifestFixtureWorkflowId)
    $validReviewingState = $validReviewingState.Replace('round: 2', 'round: 1')
    $validReviewingState = $validReviewingState.Replace('review_outcome: revise', 'review_outcome: none')
    $validReviewingState = $validReviewingState.Replace('change_manifest_path: none', "change_manifest_path: $manifestFixtureRelativePath")
    $validReviewingState = $validReviewingState.Replace('change_manifest_id: none', "change_manifest_id: $manifestFixtureId")
    $validReviewingState = $validReviewingState.Replace('change_manifest_baseline: none', "change_manifest_baseline: $manifestFixtureBaseline")
    $validReviewingState = $validReviewingState.Replace('- Path: `none`', "- Path: ``$manifestFixtureRelativePath``")
    $validReviewingState = $validReviewingState.Replace('- ID: `none`', "- ID: ``$manifestFixtureId``")
    $validReviewingState = $validReviewingState.Replace('- Baseline commit: `none`', "- Baseline commit: ``$manifestFixtureBaseline``")
    $validReviewingState = $validReviewingState.Replace('- Final workflow-state path: `none`', '- Final workflow-state path: `docs/operations/KNOWLEDGE_WORKFLOW_STATE.md`')
    $validReviewingState = [regex]::Replace($validReviewingState, '(?ms)(^## Reviewer findings and outcome\r?\n).*?(?=^## Next required action)', "`$1`nPending.`n`n")
    $validReviewingState = $validReviewingState.Replace(
        'Await the Systems Knowledge Developer revised DEVELOPER_HANDOFF for round 2; if the recorded task-scoped reference is unavailable, reconstruct the same revision assignment with the preceding REVIEW_OUTCOME.',
        'Await the Systems Coherence Reviewer REVIEW_OUTCOME for round 1; if the recorded task-scoped reference is unavailable, reconstruct the same review assignment.'
    )
    Invoke-ValidatorFixture -Name 'reviewing state with real cross-platform manifest output' -Content $validReviewingState -ShouldPass $true
    $staleReviewingAction = $validReviewingState.Replace(
        'Await the Systems Coherence Reviewer REVIEW_OUTCOME for round 1; if the recorded task-scoped reference is unavailable, reconstruct the same review assignment.',
        'Create the accepted-change manifest and invoke the Systems Coherence Reviewer.'
    )
    Invoke-ValidatorFixture -Name 'reviewing state with already-completed next action' -Content $staleReviewingAction -ShouldPass $false

    $retiredRoleRoute = 'docs/' + 'agents/' + 'SYSTEMS_KNOWLEDGE_DEVELOPER.md'
    $historicalEvidenceState = $validRevisingState.Replace('problem: Test problem.', "problem: Historical evidence named retired route $retiredRoleRoute.")
    Invoke-ValidatorFixture -Name 'retired route in fenced worker contract evidence' -Content $historicalEvidenceState -ShouldPass $true

    $activeRouteState = $validRevisingState.Replace('- `docs/operations/KNOWLEDGE_WORKFLOW_STATE.md`', "- ``docs/operations/KNOWLEDGE_WORKFLOW_STATE.md```n- ``$retiredRoleRoute``")
    Invoke-ValidatorFixture -Name 'retired route in active input artifacts' -Content $activeRouteState -ShouldPass $false

    Invoke-ValidatorFixture -Name 'valid developing state' -Content $validDevelopingState -ShouldPass $true
    Invoke-ValidatorFixture -Name 'mismatched developing reviewer role token' -Content ($validDevelopingState.Replace('- Reviewer role token: `none`', '- Reviewer role token: `systems-coherence-reviewer`')) -ShouldPass $false
    Invoke-ValidatorFixture -Name 'missing developing reviewer reference' -Content ([regex]::Replace($validDevelopingState, '(?m)^- Reviewer task-scoped reference: `unavailable`\r?\n', '')) -ShouldPass $false
    Invoke-ValidatorFixture -Name 'invalid developing reviewer reference' -Content ($validDevelopingState.Replace('- Reviewer task-scoped reference: `unavailable`', '- Reviewer task-scoped reference: `none`')) -ShouldPass $false
    Invoke-ValidatorFixture -Name 'invalid revising outcome' -Content ($validRevisingState.Replace('review_outcome: revise', 'review_outcome: none')) -ShouldPass $false
    Invoke-ValidatorFixture -Name 'empty developer scalar' -Content ($validRevisingState.Replace('objective: Test workflow validation.', 'objective:')) -ShouldPass $false
    Invoke-ValidatorFixture -Name 'incomplete non-accept finding' -Content ([regex]::Replace($validRevisingState, '(?m)^    location: Test fixture\.\r?\n', '')) -ShouldPass $false
    Invoke-ValidatorFixture -Name 'malformed affected entry' -Content ($validRevisingState.Replace('- `AGENT-DEVELOPER`', '- Repository AGENT-DEVELOPER')) -ShouldPass $false

    $invalidReviewingState = $validReviewingState.Replace('ready_for_review: yes', 'ready_for_review: no')
    Invoke-ValidatorFixture -Name 'reviewing while not ready' -Content $invalidReviewingState -ShouldPass $false

    $idleWithStalePackets = $validRevisingState.Replace('workflow_state: revising', 'workflow_state: idle')
    $idleWithStalePackets = $idleWithStalePackets.Replace('workflow_id: KW-20990101-001', 'workflow_id: none')
    $idleWithStalePackets = $idleWithStalePackets.Replace('round: 2', 'round: 0')
    $idleWithStalePackets = $idleWithStalePackets.Replace('objective: Test workflow validation', 'objective: none')
    $idleWithStalePackets = $idleWithStalePackets.Replace('developer_worker: systems-knowledge-developer', 'developer_worker: none')
    $idleWithStalePackets = $idleWithStalePackets.Replace('reviewer_worker: systems-coherence-reviewer', 'reviewer_worker: none')
    $idleWithStalePackets = $idleWithStalePackets.Replace('review_outcome: revise', 'review_outcome: none')
    $idleWithStalePackets = $idleWithStalePackets.Replace('last_completed_workflow_id: none', 'last_completed_workflow_id: KW-20990101-001')
    Invoke-ValidatorFixture -Name 'idle state with stale packets' -Content $idleWithStalePackets -ShouldPass $false
    Invoke-ValidatorFixture -Name 'exact idle state' -Content $validIdleState -ShouldPass $true
} finally {
    Remove-Item -LiteralPath $temporaryState.FullName -Force
    Remove-Item -LiteralPath $manifestFixturePath -Force -ErrorAction SilentlyContinue
}

Write-Host "Workflow validator tests passed: $checksPassed/17." -ForegroundColor Green
