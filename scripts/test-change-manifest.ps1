$ErrorActionPreference = 'Stop'

$manifestScript = Join-Path $PSScriptRoot 'change-manifest.ps1'
$temporaryRepository = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-manifest-test-' + [guid]::NewGuid().ToString('N'))
$workflowId = 'KW-20990101-001'
$manifestPath = Join-Path $temporaryRepository '.git/codex/test-manifest.json'
$checksPassed = 0
$utf8 = [System.Text.UTF8Encoding]::new($false)

function Write-TestFile {
    param(
        [string]$RelativePath,
        [string]$Content
    )

    $path = Join-Path $temporaryRepository $RelativePath
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
    [System.IO.File]::WriteAllText($path, $Content, $utf8)
}

function Invoke-TestGit {
    param([string[]]$Arguments)

    $output = & git -C $temporaryRepository @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Test Git command failed: git $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return $output
}

function Initialize-IsolatedTestRepository {
    $template = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-template-' + [guid]::NewGuid().ToString('N'))
    $previousTemplate = $env:GIT_TEMPLATE_DIR
    try {
        $null = New-Item -ItemType Directory -Path $template -Force
        if (@([System.IO.Directory]::EnumerateFileSystemEntries($template)).Count -ne 0) { throw 'Manifest test template is not empty.' }
        Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue
        $output = @(& git -c init.templateDir= init -q "--template=$template" $temporaryRepository 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Could not initialize isolated manifest test repository.`n$($output -join "`n")" }
        if ((Test-Path -LiteralPath (Join-Path $temporaryRepository '.git/info/attributes')) -or
            ((Test-Path -LiteralPath (Join-Path $temporaryRepository '.git/hooks')) -and @([System.IO.Directory]::EnumerateFileSystemEntries((Join-Path $temporaryRepository '.git/hooks'))).Count -ne 0)) {
            throw 'Manifest test initialization inherited attributes or hooks.'
        }
    } finally {
        if ($null -eq $previousTemplate) { Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue } else { $env:GIT_TEMPLATE_DIR = $previousTemplate }
        Remove-Item -LiteralPath $template -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-ManifestCheck {
    param(
        [string]$Name,
        [string[]]$Arguments,
        [bool]$ShouldPass
    )

    $output = & pwsh -NoProfile -File $manifestScript @Arguments -RepositoryRoot $temporaryRepository 2>&1 | Out-String
    $didPass = $LASTEXITCODE -eq 0
    if ($didPass -ne $ShouldPass) {
        throw "Accepted-change manifest test '$Name' produced the wrong result.`n$output"
    }
    $script:checksPassed++
}

$idleStateBefore = @'
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Manifest test fixture
authority: Manifest test fixture
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
last_completed_workflow_id: none
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

No material knowledge workflow is active.

Last completed workflow: `none`.
'@

$activeState = @'
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Manifest test fixture
authority: Manifest test fixture
workflow_state: reviewing
workflow_id: KW-20990101-001
round: 1
objective: Test accepted-change manifest
developer_worker: systems-knowledge-developer
reviewer_worker: systems-coherence-reviewer
review_outcome: none
change_manifest_path: none
change_manifest_id: none
change_manifest_baseline: none
last_completed_workflow_id: none
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

Active test packet.
'@

try {
    $null = New-Item -ItemType Directory -Path $temporaryRepository -Force
    Initialize-IsolatedTestRepository
    $null = Invoke-TestGit -Arguments @('config', 'user.name', 'Manifest Test')
    $null = Invoke-TestGit -Arguments @('config', 'user.email', 'manifest-test@example.invalid')
    $null = Invoke-TestGit -Arguments @('config', 'core.autocrlf', 'false')

    Write-TestFile -RelativePath 'a.txt' -Content "base`n"
    Write-TestFile -RelativePath 'delete.txt' -Content "delete me`n"
    Write-TestFile -RelativePath 'move-source.txt' -Content "move me`n"
    Write-TestFile -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' -Content $idleStateBefore
    $null = Invoke-TestGit -Arguments @('add', '--', 'a.txt', 'delete.txt', 'move-source.txt', 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md')
    $null = Invoke-TestGit -Arguments @('commit', '-q', '-m', 'baseline')

    Write-TestFile -RelativePath 'a.txt' -Content "accepted change`n"
    Write-TestFile -RelativePath 'new.txt' -Content "new file`n"
    Remove-Item -LiteralPath (Join-Path $temporaryRepository 'delete.txt')
    Move-Item -LiteralPath (Join-Path $temporaryRepository 'move-source.txt') -Destination (Join-Path $temporaryRepository 'move-target.txt')
    Write-TestFile -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' -Content $activeState

    $hookMarker = Join-Path $temporaryRepository '.git/reviewer-hook-marker'
    $postIndexHook = Join-Path $temporaryRepository '.git/hooks/post-index-change'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $postIndexHook) -Force
    [System.IO.File]::WriteAllText($postIndexHook, "#!/bin/sh`nprintf 'executed\\n' >> .git/reviewer-hook-marker`n", $utf8)
    if (-not $IsWindows) {
        [System.IO.File]::SetUnixFileMode(
            $postIndexHook,
            [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::UserExecute
        )
    }

    $objectDatabaseBefore = (Invoke-TestGit -Arguments @('count-objects', '-v') | Out-String).Trim()
    Invoke-ManifestCheck -Name 'create complete manifest' -Arguments @('-Action', 'Create', '-WorkflowId', $workflowId, '-ManifestPath', $manifestPath) -ShouldPass $true
    Invoke-ManifestCheck -Name 'verify review candidate' -Arguments @('-Action', 'VerifyReview', '-ManifestPath', $manifestPath) -ShouldPass $true
    $createdManifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ($createdManifest.schema_version -ne 2 -or $createdManifest.payload.candidate_tree_oid -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') {
        throw 'Created manifest does not own a full candidate tree identity.'
    }
    $checksPassed++
    $objectDatabaseAfterReview = (Invoke-TestGit -Arguments @('count-objects', '-v') | Out-String).Trim()
    if ($objectDatabaseAfterReview -ne $objectDatabaseBefore) {
        throw "Create or VerifyReview mutated the real Git object database.`nBefore:`n$objectDatabaseBefore`nAfter:`n$objectDatabaseAfterReview"
    }
    $checksPassed++

    Write-TestFile -RelativePath 'a.txt' -Content "post-review mutation`n"
    Invoke-ManifestCheck -Name 'detect post-review byte mutation' -Arguments @('-Action', 'VerifyReview', '-ManifestPath', $manifestPath) -ShouldPass $false
    Write-TestFile -RelativePath 'a.txt' -Content "accepted change`n"

    $tamperedManifestPath = Join-Path $temporaryRepository '.git/codex/tampered-tree-manifest.json'
    $tamperedManifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $tamperedManifest.payload.candidate_tree_oid = '0000000000000000000000000000000000000000'
    $tamperedPayloadJson = $tamperedManifest.payload | ConvertTo-Json -Depth 8 -Compress
    $tamperedManifest.manifest_id = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($tamperedPayloadJson))).ToLowerInvariant()
    [System.IO.File]::WriteAllText($tamperedManifestPath, ($tamperedManifest | ConvertTo-Json -Depth 8), $utf8)
    Invoke-ManifestCheck -Name 'detect candidate tree identity mutation' -Arguments @('-Action', 'VerifyReview', '-ManifestPath', $tamperedManifestPath) -ShouldPass $false

    $manifestDocument = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    [System.IO.File]::WriteAllBytes(
        (Join-Path $temporaryRepository $manifestDocument.payload.final_workflow_state_path),
        [Convert]::FromBase64String($manifestDocument.payload.final_workflow_state_base64)
    )
    $expectedStateEntry = @($manifestDocument.payload.entries | Where-Object path -eq 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md')[0]
    $actualStateOid = (Invoke-TestGit -Arguments @('hash-object', '--path=docs/operations/KNOWLEDGE_WORKFLOW_STATE.md', '--', 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md') | Out-String).Trim()
    if ($actualStateOid -ne $expectedStateEntry.blob_oid) {
        throw "Test fixture idle state does not match the deterministic overlay: expected $($expectedStateEntry.blob_oid), got $actualStateOid."
    }
    Invoke-ManifestCheck -Name 'verify deterministic idle worktree' -Arguments @('-Action', 'VerifyWorktree', '-ManifestPath', $manifestPath) -ShouldPass $true
    if (Test-Path -LiteralPath $hookMarker) {
        throw 'Create, VerifyReview, or VerifyWorktree executed the repository post-index-change hook.'
    }
    $checksPassed++
    Remove-Item -LiteralPath $postIndexHook -Force

    $null = Invoke-TestGit -Arguments @('add', '-A', '--', '.')
    $objectDatabaseBeforeIndexVerify = (Invoke-TestGit -Arguments @('count-objects', '-v') | Out-String).Trim()
    $indexPath = Join-Path $temporaryRepository '.git/index'
    $indexHashBeforeVerify = (Get-FileHash -Algorithm SHA256 -LiteralPath $indexPath).Hash
    Invoke-ManifestCheck -Name 'verify staged tree' -Arguments @('-Action', 'VerifyIndex', '-ManifestPath', $manifestPath) -ShouldPass $true
    $objectDatabaseAfterIndexVerify = (Invoke-TestGit -Arguments @('count-objects', '-v') | Out-String).Trim()
    $indexHashAfterVerify = (Get-FileHash -Algorithm SHA256 -LiteralPath $indexPath).Hash
    if ($objectDatabaseAfterIndexVerify -ne $objectDatabaseBeforeIndexVerify -or $indexHashAfterVerify -ne $indexHashBeforeVerify) {
        throw 'VerifyIndex mutated the real Git object database or real index.'
    }
    $checksPassed++

    Write-TestFile -RelativePath 'new.txt' -Content "hook-like mutation`n"
    $null = Invoke-TestGit -Arguments @('add', '--', 'new.txt')
    Invoke-ManifestCheck -Name 'detect staged mutation' -Arguments @('-Action', 'VerifyIndex', '-ManifestPath', $manifestPath) -ShouldPass $false
    Write-TestFile -RelativePath 'new.txt' -Content "new file`n"
    $null = Invoke-TestGit -Arguments @('add', '--', 'new.txt')

    $null = Invoke-TestGit -Arguments @('commit', '-q', '-m', 'accepted candidate')
    $commitId = (Invoke-TestGit -Arguments @('rev-parse', 'HEAD') | Out-String).Trim()
    Invoke-ManifestCheck -Name 'verify committed tree' -Arguments @('-Action', 'VerifyCommit', '-ManifestPath', $manifestPath, '-CommitId', $commitId) -ShouldPass $true

    Write-TestFile -RelativePath 'a.txt' -Content "post-commit hook mutation`n"
    Invoke-ManifestCheck -Name 'detect post-commit worktree mutation' -Arguments @('-Action', 'VerifyWorktree', '-ManifestPath', $manifestPath) -ShouldPass $false
} finally {
    Remove-Item -LiteralPath $temporaryRepository -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Accepted-change manifest tests passed: $checksPassed/13." -ForegroundColor Green
