$ErrorActionPreference = 'Stop'

$checker = Join-Path $PSScriptRoot 'check-docs.ps1'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('workflow-state-test-' + [guid]::NewGuid().ToString('N') + '.md')
$checks = 0

function New-State {
    param(
        [string]$Stage = 'developing',
        [string]$Owner = 'systems-knowledge-developer',
        [string]$Correction = 'no',
        [string]$Manifest = 'none'
    )
    $text = @"
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Test checkpoint
authority: Test checkpoint
workflow_state: $Stage
workflow_id: KW-20990101-001
mode: governed
objective: Test compact workflow validation
current_owner: $Owner
correction_used: $Correction
manifest_id: $Manifest
last_completed_workflow_id: none
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

## Outcome

- Definition of done: Compact state validates.
- Route: Test route.

## Authorized changes

- docs/README.md

## Risks and stop conditions

- Risk: Test risk. Mitigation: Test mitigation.
- Stop: Test stop.

## Progress

- Completed evidence: Test fixture created.
- Remaining blocker: Validation.
- Next action: Run validator.

## Affected entries

- DOCS-001
"@
    if ($Stage -in @('reviewing','final-review','finalizing')) {
        $text += @'

## Review packet

```text
DEVELOPER_HANDOFF
workflow_id: KW-20990101-001
objective: Test compact workflow validation
affected_entries: DOCS-001
accepted_truth_preserved: Test truth
truth_added_changed_or_removed: Test change
assumptions: None
downstream_consumers: Test reviewer
open_questions: None
review_finding_dispositions: None
files_added_changed_renamed_or_removed: Test file changed
validation: Test validation passed
ready_for_review: yes
```
'@
    }
    return $text
}

function Invoke-Fixture([string]$Name, [string]$Content, [bool]$ShouldPass) {
    [IO.File]::WriteAllText($temporary, $Content, [Text.UTF8Encoding]::new($false))
    $output = & pwsh -NoProfile -File $checker -WorkflowStatePath $temporary 2>&1 | Out-String
    $passed = $LASTEXITCODE -eq 0
    if ($passed -ne $ShouldPass) { throw "Workflow validator fixture '$Name' produced the wrong result.`n$output" }
    $script:checks++
}

try {
    Invoke-Fixture 'valid developing' (New-State) $true
    Invoke-Fixture 'invalid stage' (New-State -Stage 'replanning') $false
    Invoke-Fixture 'wrong owner' (New-State -Owner 'outcome-lead') $false
    Invoke-Fixture 'review missing manifest' (New-State -Stage 'reviewing' -Owner 'systems-coherence-reviewer') $false
    $validReview = New-State -Stage 'reviewing' -Owner 'systems-coherence-reviewer' -Manifest ('a' * 64)
    Invoke-Fixture 'valid review' $validReview $true
    Invoke-Fixture 'review missing packet' ([regex]::Replace($validReview, '(?ms)^## Review packet\r?\n.*\z', '')) $false
    Invoke-Fixture 'review incomplete packet' ($validReview.Replace('validation: Test validation passed', 'validation:')) $false
    Invoke-Fixture 'review cross-workflow packet' ($validReview.Replace("DEVELOPER_HANDOFF`nworkflow_id: KW-20990101-001", "DEVELOPER_HANDOFF`nworkflow_id: KW-20990101-002")) $false
    Invoke-Fixture 'review packet not ready' ($validReview.Replace('ready_for_review: yes', 'ready_for_review: no')) $false
    Invoke-Fixture 'correction not marked used' (New-State -Stage 'correcting') $false
    Invoke-Fixture 'valid correction' (New-State -Stage 'correcting' -Correction 'yes') $true
    $validFinalReview = New-State -Stage 'final-review' -Owner 'systems-coherence-reviewer' -Correction 'yes' -Manifest ('b' * 64)
    Invoke-Fixture 'valid final review' $validFinalReview $true
    Invoke-Fixture 'final review missing packet' ([regex]::Replace($validFinalReview, '(?ms)^## Review packet\r?\n.*\z', '')) $false
    Invoke-Fixture 'final review incomplete packet' ($validFinalReview.Replace('downstream_consumers: Test reviewer', 'downstream_consumers:')) $false
    Invoke-Fixture 'missing progress evidence' ((New-State).Replace('- Completed evidence: Test fixture created.', '')) $false

    $idle = @'
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Persistent state of the current material-knowledge workflow
authority: Owns the minimum factual checkpoint required to resume active governed documentation work
workflow_state: idle
workflow_id: none
mode: none
objective: none
current_owner: none
correction_used: no
manifest_id: none
last_completed_workflow_id: KW-20990101-001
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

No material knowledge workflow is active.

Last completed workflow: `KW-20990101-001`.
'@
    Invoke-Fixture 'valid idle' $idle $true
    Invoke-Fixture 'idle retains packet' ($idle + "`n## Review packet`n`nretained packet`n") $false
} finally {
    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
}

Write-Host "Knowledge workflow validator tests passed: $checks/17." -ForegroundColor Green
exit 0
