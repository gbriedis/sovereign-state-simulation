$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'change-manifest.ps1'
$repo = Join-Path ([IO.Path]::GetTempPath()) ('change-manifest-test-' + [guid]::NewGuid().ToString('N'))
$manifest = Join-Path $repo '.git/codex/test-manifest.json'
$checks = 0
$utf8 = [Text.UTF8Encoding]::new($false)

function Write-TestFile([string]$RelativePath, [string]$Content) {
    $path = Join-Path $repo $RelativePath
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
    [IO.File]::WriteAllText($path, $Content.Replace("`r`n", "`n"), $utf8)
}

function Invoke-TestGit([string[]]$Arguments) {
    $output = @(& git -C $repo @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Test Git failed: git $($Arguments -join ' ')`n$($output -join "`n")" }
    return $output
}

function Check([string]$Name, [string[]]$Arguments, [bool]$ShouldPass) {
    $output = & pwsh -NoProfile -File $scriptPath @Arguments -RepositoryRoot $repo 2>&1 | Out-String
    $passed = $LASTEXITCODE -eq 0
    if ($passed -ne $ShouldPass) { throw "Manifest test '$Name' produced the wrong result.`n$output" }
    $script:checks++
}

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
last_completed_workflow_id: none
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

No material knowledge workflow is active.

Last completed workflow: `none`.
'@

$active = @'
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Persistent state of the current material-knowledge workflow
authority: Owns the minimum factual checkpoint required to resume active governed documentation work
workflow_state: developing
workflow_id: KW-20990101-001
mode: governed
objective: Test manifest
current_owner: systems-knowledge-developer
correction_used: no
manifest_id: none
last_completed_workflow_id: none
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

## Outcome

- Definition of done: Manifest works.
- Route: Test.

## Authorized changes

- `a.txt`

## Risks and stop conditions

- Risk: Mutation. Mitigation: Fingerprint.
- Stop: Mismatch.

## Progress

- Completed evidence: Candidate written.
- Remaining blocker: Review.
- Next action: Create manifest.

## Affected entries

- `a.txt`

## Review packet

```text
DEVELOPER_HANDOFF
workflow_id: KW-20990101-001
objective: Test manifest
affected_entries: a.txt
accepted_truth_preserved: Base truth
truth_added_changed_or_removed: Test change
assumptions: None
downstream_consumers: Test reviewer
open_questions: None
review_finding_dispositions: None
files_added_changed_renamed_or_removed: a.txt changed
validation: Test validation passed
ready_for_review: yes
```
'@

try {
    $null = New-Item -ItemType Directory -Path $repo -Force
    $null = Invoke-TestGit @('init','-q')
    $null = Invoke-TestGit @('config','user.name','Manifest Test')
    $null = Invoke-TestGit @('config','user.email','manifest@example.invalid')
    $null = Invoke-TestGit @('config','core.autocrlf','false')
    Write-TestFile 'a.txt' "base`n"
    Write-TestFile 'delete.txt' "delete`n"
    Write-TestFile 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' $idle
    $null = Invoke-TestGit @('add','--','a.txt','delete.txt','docs/operations/KNOWLEDGE_WORKFLOW_STATE.md')
    $null = Invoke-TestGit @('commit','-q','-m','baseline')

    Write-TestFile 'a.txt' "changed`n"
    Write-TestFile 'new.txt' "new`n"
    Remove-Item -LiteralPath (Join-Path $repo 'delete.txt')
    Write-TestFile 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' $active

    Check 'create' @('-Action','Create','-WorkflowId','KW-20990101-001','-ManifestPath',$manifest) $true
    Check 'verify review' @('-Action','VerifyReview','-ManifestPath',$manifest) $true
    $activeStatePath = Join-Path $repo 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md'
    $activeStateText = Get-Content -Raw -LiteralPath $activeStatePath
    Write-TestFile 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' ($activeStateText.Replace('validation: Test validation passed', 'validation: Different validation claim'))
    Check 'detect review packet mutation' @('-Action','VerifyReview','-ManifestPath',$manifest) $false
    Write-TestFile 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' $activeStateText
    Write-TestFile 'a.txt' "mutated`n"
    Check 'detect review mutation' @('-Action','VerifyReview','-ManifestPath',$manifest) $false
    Write-TestFile 'a.txt' "changed`n"

    $document = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json
    [IO.File]::WriteAllBytes((Join-Path $repo $document.payload.final_workflow_state_path), [Convert]::FromBase64String($document.payload.final_workflow_state_base64))
    Check 'verify final worktree' @('-Action','VerifyWorktree','-ManifestPath',$manifest) $true

    $null = Invoke-TestGit @('add','-A','--','.')
    Check 'verify index' @('-Action','VerifyIndex','-ManifestPath',$manifest) $true
    $null = Invoke-TestGit @('commit','-q','-m','candidate')
    $commit = (Invoke-TestGit @('rev-parse','HEAD') | Out-String).Trim()
    Check 'verify commit' @('-Action','VerifyCommit','-ManifestPath',$manifest,'-CommitId',$commit) $true
} finally {
    Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Accepted-change manifest tests passed: $checks/7." -ForegroundColor Green
