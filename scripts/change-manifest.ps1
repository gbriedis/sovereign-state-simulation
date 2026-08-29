param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Create','VerifyReview','VerifyWorktree','VerifyIndex','VerifyCommit')]
    [string]$Action,
    [string]$WorkflowId,
    [string]$ManifestPath,
    [string]$CommitId,
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
$root = if ($RepositoryRoot) { [IO.Path]::GetFullPath($RepositoryRoot) } else { Split-Path -Parent $PSScriptRoot }
$stateRelativePath = 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md'
$statePath = Join-Path $root $stateRelativePath

function Invoke-Git([string[]]$Arguments) {
    $output = @(& git -C $root -c core.quotepath=false @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Git command failed: git $($Arguments -join ' ')`n$($output -join "`n")" }
    return [string]::Join("`n", [string[]]$output)
}

function Get-Sha256Text([string]$Text) {
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
}

function Get-Sha256File([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    try { return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)).ToLowerInvariant() }
    finally { $stream.Dispose() }
}

function Get-ReviewPacket([string]$Text) {
    $match = [regex]::Match($Text, '(?ms)^## Review packet\r?\n.*?```text\s*\r?\n(?<packet>DEVELOPER_HANDOFF\r?\n.*?)\r?\n```')
    if (-not $match.Success) { throw 'The active workflow checkpoint has no complete fenced DEVELOPER_HANDOFF Review packet.' }
    return $match.Groups['packet'].Value.Replace("`r`n", "`n")
}

function New-IdleState([string]$CompletedWorkflowId, [string]$OutputPath) {
    $active = Get-Content -Raw -LiteralPath $statePath
    $reviewed = [regex]::Match($active, '(?m)^last_reviewed:\s*(\d{4}-\d{2}-\d{2})\s*$').Groups[1].Value
    $updated = [regex]::Match($active, '(?m)^updated:\s*(\d{4}-\d{2}-\d{2})\s*$').Groups[1].Value
    if (-not $reviewed) { $reviewed = (Get-Date).ToString('yyyy-MM-dd') }
    if (-not $updated) { $updated = (Get-Date).ToString('yyyy-MM-dd') }
    $text = @"
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
last_completed_workflow_id: $CompletedWorkflowId
updated: $updated
last_reviewed: $reviewed
---

# Knowledge Workflow State

No material knowledge workflow is active.

Last completed workflow: $CompletedWorkflowId.
"@
    [IO.File]::WriteAllText($OutputPath, $text.Replace("`r`n", "`n"), [Text.UTF8Encoding]::new($false))
}

function Get-ChangedRows([string]$Target, [string]$Baseline, [string]$TargetCommit) {
    $lines = switch ($Target) {
        'Review' { @((Invoke-Git @('diff','--name-status','--no-renames',$Baseline,'--')) -split "`n") }
        'Worktree' { @((Invoke-Git @('diff','--name-status','--no-renames',$Baseline,'--')) -split "`n") }
        'Index' { @((Invoke-Git @('diff','--cached','--name-status','--no-renames',$Baseline,'--')) -split "`n") }
        'Commit' { @((Invoke-Git @('diff-tree','--no-commit-id','--name-status','-r','--no-renames',$Baseline,$TargetCommit,'--')) -split "`n") }
    }
    $rows = @{}
    foreach ($line in $lines) {
        if ($line -match '^(?<status>[AMDTC])\s+(?<path>.+)$') { $rows[$matches.path.Replace('\','/')] = $matches.status }
    }
    if ($Target -in @('Review','Worktree')) {
        foreach ($path in ((Invoke-Git @('ls-files','--others','--exclude-standard')) -split "`n")) {
            if ($path) { $rows[$path.Replace('\','/')] = 'A' }
        }
    }
    return $rows
}

function Get-BlobIdentity([string]$Target, [string]$Path, [string]$TargetCommit, [string]$OverridePath) {
    if ($OverridePath) {
        return @{ mode='100644'; oid=(Invoke-Git @('hash-object',"--path=$Path",'--',$OverridePath)).Trim(); raw=(Get-Sha256File $OverridePath) }
    }
    if ($Target -in @('Review','Worktree')) {
        $full = Join-Path $root $Path
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Changed path '$Path' is not a regular file." }
        $tracked = (Invoke-Git @('ls-files','-s','--',$Path)).Trim()
        $mode = if ($tracked -match '^(\d+)\s+') { $matches[1] } else { '100644' }
        return @{ mode=$mode; oid=(Invoke-Git @('hash-object',"--path=$Path",'--',$full)).Trim(); raw=(Get-Sha256File $full) }
    }
    if ($Target -eq 'Index') {
        $entry = (Invoke-Git @('ls-files','-s','--',$Path)).Trim()
        if ($entry -notmatch '^(?<mode>\d+)\s+(?<oid>[0-9a-f]+)\s+0\s+') { throw "Index has no stage-zero entry for '$Path'." }
        return @{ mode=$matches.mode; oid=$matches.oid; raw='not-applicable' }
    }
    $entry = (Invoke-Git @('ls-tree',$TargetCommit,'--',$Path)).Trim()
    if ($entry -notmatch '^(?<mode>\d+)\s+\w+\s+(?<oid>[0-9a-f]+)\s+') { throw "Commit has no entry for '$Path'." }
    return @{ mode=$matches.mode; oid=$matches.oid; raw='not-applicable' }
}

function New-Snapshot([string]$Target, [string]$Baseline, [string]$TargetCommit, [string]$CompletedWorkflowId) {
    $idlePath = $null
    try {
        $rows = Get-ChangedRows $Target $Baseline $TargetCommit
        $overrides = @{}
        $idleBase64 = 'not-applicable'
        if ($Target -eq 'Review') {
            $idlePath = Join-Path ([IO.Path]::GetTempPath()) ('workflow-idle-' + [guid]::NewGuid().ToString('N') + '.md')
            New-IdleState $CompletedWorkflowId $idlePath
            $overrides[$stateRelativePath] = $idlePath
            $rows[$stateRelativePath] = 'M'
            $idleBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($idlePath))
        }
        $entries = [Collections.Generic.List[object]]::new()
        foreach ($path in @($rows.Keys | Sort-Object)) {
            $status = $rows[$path]
            if ($status -eq 'D') {
                $entries.Add([ordered]@{ status='D'; path=$path; mode='-'; blob_oid='-'; raw_sha256='-' })
            } else {
                $identity = Get-BlobIdentity $Target $path $TargetCommit $overrides[$path]
                $entries.Add([ordered]@{ status=$status; path=$path; mode=$identity.mode; blob_oid=$identity.oid; raw_sha256=$identity.raw })
            }
        }
        $treeLines = @($entries | ForEach-Object { "$($_.status)`t$($_.path)`t$($_.mode)`t$($_.blob_oid)" })
        $rawLines = @($entries | ForEach-Object { "$($_.status)`t$($_.path)`t$($_.raw_sha256)" })
        return [ordered]@{
            tree_fingerprint = Get-Sha256Text ([string]::Join("`n", $treeLines))
            worktree_fingerprint = if ($Target -in @('Review','Worktree')) { Get-Sha256Text ([string]::Join("`n", $rawLines)) } else { 'not-applicable' }
            final_workflow_state_base64 = $idleBase64
            entries = @($entries)
        }
    } finally {
        if ($idlePath) { Remove-Item -LiteralPath $idlePath -Force -ErrorAction SilentlyContinue }
    }
}

function Read-Manifest([string]$Path) {
    $document = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    if ($document.schema_version -ne 1 -or -not $document.manifest_id -or $null -eq $document.payload) { throw 'Manifest schema is unsupported or incomplete.' }
    $json = $document.payload | ConvertTo-Json -Depth 8 -Compress
    if ((Get-Sha256Text $json) -ne $document.manifest_id) { throw 'Manifest fingerprint does not match its payload.' }
    return $document
}

$baseline = (Invoke-Git @('rev-parse','HEAD')).Trim()

if ($Action -eq 'Create') {
    if ($WorkflowId -notmatch '^KW-\d{8}-\d{3}$') { throw 'Create requires WorkflowId KW-YYYYMMDD-NNN.' }
    if (-not $ManifestPath) {
        $gitPath = (Invoke-Git @('rev-parse','--git-path',"codex/accepted-change-manifests/$WorkflowId.json")).Trim()
        $ManifestPath = if ([IO.Path]::IsPathRooted($gitPath)) { $gitPath } else { Join-Path $root $gitPath }
    }
    $snapshot = New-Snapshot 'Review' $baseline $null $WorkflowId
    $reviewPacketSha256 = Get-Sha256Text (Get-ReviewPacket (Get-Content -Raw -LiteralPath $statePath))
    $payload = [ordered]@{
        workflow_id = $WorkflowId
        baseline_commit = $baseline
        review_packet_sha256 = $reviewPacketSha256
        final_workflow_state_path = $stateRelativePath
        final_workflow_state_base64 = $snapshot.final_workflow_state_base64
        tree_fingerprint = $snapshot.tree_fingerprint
        worktree_fingerprint = $snapshot.worktree_fingerprint
        entries = $snapshot.entries
    }
    $payloadJson = $payload | ConvertTo-Json -Depth 8 -Compress
    $document = [ordered]@{ schema_version=1; manifest_id=(Get-Sha256Text $payloadJson); payload=$payload }
    $ManifestPath = [IO.Path]::GetFullPath($ManifestPath)
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $ManifestPath) -Force
    [IO.File]::WriteAllText($ManifestPath, ($document | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    Write-Output 'CHANGE_MANIFEST_RESULT'
    Write-Output 'action: create'
    Write-Output "workflow_id: $WorkflowId"
    Write-Output "manifest_path: $ManifestPath"
    Write-Output "manifest_id: $($document.manifest_id)"
    Write-Output "baseline_commit: $baseline"
    Write-Output "changed_entries: $($snapshot.entries.Count)"
    exit 0
}

if (-not $ManifestPath) { throw "$Action requires ManifestPath." }
$manifest = Read-Manifest ([IO.Path]::GetFullPath($ManifestPath))
$payload = $manifest.payload
if ($payload.review_packet_sha256 -notmatch '^[0-9a-f]{64}$') { throw 'Manifest has no valid Review packet fingerprint.' }
if ($Action -eq 'VerifyReview') {
    $currentReviewPacketSha256 = Get-Sha256Text (Get-ReviewPacket (Get-Content -Raw -LiteralPath $statePath))
    if ($currentReviewPacketSha256 -ne $payload.review_packet_sha256) { throw 'Workflow Review packet differs from the manifested review packet.' }
}
$snapshot = switch ($Action) {
    'VerifyReview' { New-Snapshot 'Review' $payload.baseline_commit $null $payload.workflow_id }
    'VerifyWorktree' { New-Snapshot 'Worktree' $payload.baseline_commit $null $null }
    'VerifyIndex' { New-Snapshot 'Index' $payload.baseline_commit $null $null }
    'VerifyCommit' {
        if (-not $CommitId) { throw 'VerifyCommit requires CommitId.' }
        New-Snapshot 'Commit' $payload.baseline_commit $CommitId $null
    }
}
if ($snapshot.tree_fingerprint -ne $payload.tree_fingerprint) { throw "Candidate tree fingerprint mismatch for $Action." }
if ($Action -in @('VerifyReview','VerifyWorktree') -and $snapshot.worktree_fingerprint -ne $payload.worktree_fingerprint) { throw "Candidate byte fingerprint mismatch for $Action." }

Write-Output 'CHANGE_MANIFEST_RESULT'
Write-Output "action: $($Action.ToLowerInvariant())"
Write-Output "workflow_id: $($payload.workflow_id)"
Write-Output "manifest_id: $($manifest.manifest_id)"
Write-Output "baseline_commit: $($payload.baseline_commit)"
Write-Output "changed_entries: $($snapshot.entries.Count)"
Write-Output 'verified: yes'
