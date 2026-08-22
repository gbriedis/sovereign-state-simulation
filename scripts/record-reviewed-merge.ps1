param(
    [Parameter(Mandatory = $true)][string]$WorkflowId,
    [Parameter(Mandatory = $true)][string]$PacketPath,
    [Parameter(Mandatory = $true)][string]$PacketId,
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [Parameter(Mandatory = $true)][string]$ManifestId,
    [Parameter(Mandatory = $true)][string]$CandidateTreeOid,
    [Parameter(Mandatory = $true)][string]$LocalBranch,
    [Parameter(Mandatory = $true)][string]$RemoteName,
    [Parameter(Mandatory = $true)][string]$ExpectedRemoteUrl,
    [Parameter(Mandatory = $true)][string]$ExpectedRemoteUrlFingerprint,
    [Parameter(Mandatory = $true)][string]$RemoteBranch,
    [Parameter(Mandatory = $true)][string]$PushRefspec,
    [Parameter(Mandatory = $true)][string]$LocalParent,
    [Parameter(Mandatory = $true)][string]$RemoteParent,
    [Parameter(Mandatory = $true)][string]$CommitMessage,
    [Parameter(Mandatory = $true)][string[]]$AuthorizedPaths,
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
$repositoryRootPath = if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { Split-Path -Parent $PSScriptRoot } else { [System.IO.Path]::GetFullPath($RepositoryRoot) }
$packetScript = Join-Path $PSScriptRoot 'reconciliation-packet.ps1'
$manifestScript = Join-Path $PSScriptRoot 'change-manifest.ps1'
$hookScript = Join-Path $PSScriptRoot 'check-git-hooks.ps1'
$policyGuardScript = Join-Path $PSScriptRoot 'check-git-executable-policy.ps1'
$workflowStatePath = Join-Path $repositoryRootPath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md'
$emptyHooksPath = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-record-merge-hooks-' + [guid]::NewGuid().ToString('N'))
$messagePath = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-record-merge-message-' + [guid]::NewGuid().ToString('N'))
$emptyAttributesPath = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-record-empty-attributes-' + [guid]::NewGuid().ToString('N'))
$commitCreated = $null
[System.IO.File]::WriteAllText($emptyAttributesPath, '', [System.Text.UTF8Encoding]::new($false))

function Invoke-Git {
    param([string[]]$Arguments, [string]$HooksPath)
    $previousAttrNoSystem = $env:GIT_ATTR_NOSYSTEM
    $allArguments = [System.Collections.Generic.List[string]]::new()
    $allArguments.Add('-C'); $allArguments.Add($repositoryRootPath)
    $allArguments.Add('-c'); $allArguments.Add('core.fsmonitor=false')
    $allArguments.Add('-c'); $allArguments.Add("core.attributesFile=$emptyAttributesPath")
    if (-not [string]::IsNullOrWhiteSpace($HooksPath)) { $allArguments.Add('-c'); $allArguments.Add("core.hooksPath=$HooksPath") }
    foreach ($argument in $Arguments) { $allArguments.Add($argument) }
    try {
        $env:GIT_ATTR_NOSYSTEM = '1'
        $output = @(& git @allArguments 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Reviewed merge Git operation failed.`n$($output -join "`n")" }
        return (@($output) -join "`n")
    } finally {
        if ($null -eq $previousAttrNoSystem) { Remove-Item Env:GIT_ATTR_NOSYSTEM -ErrorAction SilentlyContinue } else { $env:GIT_ATTR_NOSYSTEM = $previousAttrNoSystem }
    }
}

function Invoke-RequiredScript {
    param([string]$Script, [string[]]$Arguments, [string]$ExpectedPattern)
    $output = & pwsh -NoProfile -File $Script @Arguments -RepositoryRoot $repositoryRootPath 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $output -notmatch $ExpectedPattern) { throw "Required reviewed-merge verification failed.`n$output" }
    return $output
}

function Normalize-Text {
    param([string]$Text)
    return $Text.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n") + "`n"
}

function Get-Sha256Text {
    param([string]$Text)
    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
}

function Assert-ExecutableGitPolicy {
    $output = & pwsh -NoProfile -File $policyGuardScript -RepositoryRoot $repositoryRootPath 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $output -notmatch '(?m)^authorization_safe: yes\r?$') {
        throw 'Executable Git policy is outside the reviewed-merge authorization.'
    }
}

function Assert-SafeRemoteUrl {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match '[\r\n]' -or $Value.Contains('::')) { throw 'Assigned remote URL form is prohibited.' }
    if ($Value -match '^(?i:[a-z][a-z0-9+.-]*)://') {
        $uri = $null
        if (-not [uri]::TryCreate($Value, [System.UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -notin @('https', 'ssh', 'git', 'file') -or
            ($uri.Scheme -ne 'file' -and [string]::IsNullOrEmpty($uri.Host)) -or
            (($uri.Scheme -ne 'ssh') -and -not [string]::IsNullOrEmpty($uri.UserInfo)) -or $uri.UserInfo.Contains(':') -or
            -not [string]::IsNullOrEmpty($uri.Query) -or -not [string]::IsNullOrEmpty($uri.Fragment) -or $Value.Contains('\\') -or
            $uri.AbsolutePath.Contains(';') -or $uri.AbsolutePath -match '(?i)%3b') { throw 'Assigned remote URL form is prohibited.' }
    } elseif ($Value -match '^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+:[A-Za-z0-9._~/-]+$') {
        return
    } elseif (-not [System.IO.Path]::IsPathRooted($Value) -and $Value -notmatch '^(?:\.{0,2}/)?[A-Za-z0-9._/-]+$') {
        throw 'Assigned remote URL form is prohibited.'
    }
}

try {
    if ($WorkflowId -notmatch '^KW-\d{8}-\d{3}$') { throw 'Workflow ID must be exact.' }
    Assert-SafeRemoteUrl -Value $ExpectedRemoteUrl
    if ($ExpectedRemoteUrlFingerprint -notmatch '^[0-9a-f]{64}$' -or (Get-Sha256Text -Text $ExpectedRemoteUrl) -ne $ExpectedRemoteUrlFingerprint) {
        throw 'Assigned remote URL fingerprint is invalid.'
    }
    Assert-ExecutableGitPolicy
    foreach ($oid in @($CandidateTreeOid, $LocalParent, $RemoteParent)) {
        if ($oid -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') { throw 'Tree and parent IDs must be full lowercase object IDs.' }
    }
    if ($PacketId -notmatch '^[0-9a-f]{64}$' -or $ManifestId -notmatch '^[0-9a-f]{64}$') { throw 'Packet and manifest IDs must be full SHA-256 values.' }
    foreach ($branch in @($LocalBranch, $RemoteBranch)) {
        if ($branch.StartsWith('refs/')) { throw 'Branch values must be names below refs/heads.' }
        $null = Invoke-Git -Arguments @('check-ref-format', "refs/heads/$branch")
    }
    if ($RemoteName -notmatch '^[A-Za-z0-9._/-]+$' -or $RemoteName.Contains('..')) { throw 'Remote name is unsafe.' }
    $expectedRefspec = "refs/heads/$LocalBranch`:refs/heads/$RemoteBranch"
    if ($PushRefspec -ne $expectedRefspec) { throw 'Push refspec differs from the exact local and remote branch refs.' }
    if ([string]::IsNullOrWhiteSpace($CommitMessage)) { throw 'An exact non-empty merge message is required.' }

    $state = (Get-Content -Raw -LiteralPath $workflowStatePath).Replace("`r`n", "`n")
    foreach ($idleField in @('workflow_state: idle', 'workflow_id: none', 'round: 0', 'objective: none', 'developer_worker: none', 'reviewer_worker: none', 'review_outcome: none', 'change_manifest_path: none', 'change_manifest_id: none', 'change_manifest_baseline: none')) {
        if ($state -notmatch ('(?m)^' + [regex]::Escape($idleField) + '$')) { throw 'Reviewed merge recording requires the exact idle workflow checkpoint.' }
    }
    if ($state -match '(?m)^## (?:Active objective|Affected entries|Input artifacts|Worker references|Accepted-change manifest|Developer handoff|Reviewer findings and outcome|Next required action)$' -or
        $state -notmatch '(?s)\n# Knowledge Workflow State\n\nNo material knowledge workflow is active\.\n\nLast completed workflow: `(?:none|KW-\d{8}-\d{3})`\.\n?\z') {
        throw 'Reviewed merge recording rejects stale active workflow payload.'
    }
    $currentBranch = (Invoke-Git -Arguments @('symbolic-ref', '--quiet', '--short', 'HEAD')).Trim()
    $currentHead = (Invoke-Git -Arguments @('rev-parse', 'HEAD')).Trim()
    if ($currentBranch -ne $LocalBranch -or $currentHead -ne $LocalParent) { throw 'Current branch or HEAD differs from the reviewed reconciliation parent.' }
    if (-not [string]::IsNullOrWhiteSpace((Invoke-Git -Arguments @('diff', '--cached', '--name-only', '--')))) { throw 'Reviewed merge recording requires an initially empty index diff.' }

    $packetOutput = Invoke-RequiredScript -Script $packetScript -Arguments @('-Action', 'VerifyCandidate', '-PacketPath', $PacketPath, '-ManifestPath', $ManifestPath) -ExpectedPattern '(?m)^verified: yes\r?$'
    if ($packetOutput -notmatch ('(?m)^packet_id: ' + [regex]::Escape($PacketId) + '\r?$') -or $packetOutput -notmatch ('(?m)^candidate_tree_oid: ' + [regex]::Escape($CandidateTreeOid) + '\r?$')) { throw 'Verified packet identity or candidate tree differs from the assignment.' }
    $packet = Get-Content -Raw -LiteralPath $PacketPath | ConvertFrom-Json
    if ($packet.payload.review_workflow_id -ne $WorkflowId -or $packet.payload.remote_url_safe -ne $ExpectedRemoteUrl -or
        $packet.payload.remote_url_fingerprint -ne $ExpectedRemoteUrlFingerprint -or $packet.payload.local_branch -ne $LocalBranch -or
        $packet.payload.remote_name -ne $RemoteName -or $packet.payload.remote_branch -ne $RemoteBranch -or
        $packet.payload.local_parent -ne $LocalParent -or $packet.payload.remote_parent -ne $RemoteParent -or
        $packet.payload.candidate_tree_oid -ne $CandidateTreeOid -or $packet.payload.accepted_manifest_id -ne $ManifestId) {
        throw 'Recorder branch, remote, parents, tree, or manifest differ from the verified packet.'
    }
    $packetMessage = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($packet.payload.merge_commit_message_base64))
    if ((Normalize-Text -Text $CommitMessage) -ne $packetMessage) { throw 'Commit message differs from the reviewed-candidate packet.' }

    $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    if ($manifest.payload.workflow_id -ne $WorkflowId) { throw 'Accepted manifest workflow differs from the recorder assignment.' }
    $manifestPaths = @($manifest.payload.entries | ForEach-Object { [string]$_.path } | Sort-Object -Unique -CaseSensitive)
    $assignedPaths = @($AuthorizedPaths | ForEach-Object { ([string]$_).Replace('\', '/') } | Sort-Object -Unique -CaseSensitive)
    if ((@($manifestPaths) -join "`n") -ne (@($assignedPaths) -join "`n")) { throw 'Authorized paths do not equal the accepted manifest entries.' }
    $null = Invoke-RequiredScript -Script $manifestScript -Arguments @('-Action', 'VerifyWorktree', '-ManifestPath', $ManifestPath) -ExpectedPattern '(?m)^verified: yes\r?$'
    $null = Invoke-RequiredScript -Script $hookScript -Arguments @() -ExpectedPattern '(?m)^authorization_safe: yes\r?$'
    Assert-ExecutableGitPolicy

    $null = New-Item -ItemType Directory -Path $emptyHooksPath -Force
    if (@(Get-ChildItem -LiteralPath $emptyHooksPath -Force).Count -ne 0) { throw 'Command-scoped hooks directory is not empty.' }
    foreach ($path in $assignedPaths) {
        if ([System.IO.Path]::IsPathRooted($path) -or $path.Contains('..') -or $path.IndexOfAny([char[]]'*?[') -ge 0) { throw 'Accepted manifest contains an unsafe staging path.' }
        $null = Invoke-Git -HooksPath $emptyHooksPath -Arguments @('add', '-A', '--', $path)
    }
    $stagedPaths = @((Invoke-Git -Arguments @('-c', 'diff.renames=false', 'diff', '--cached', '--no-ext-diff', '--no-renames', '--name-only', '--')).Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries) | Sort-Object -Unique -CaseSensitive)
    if ((@($stagedPaths) -join "`n") -ne (@($assignedPaths) -join "`n")) { throw 'Staged paths differ from the exact accepted manifest.' }
    $null = Invoke-Git -Arguments @('diff', '--cached', '--check')
    $null = Invoke-RequiredScript -Script $manifestScript -Arguments @('-Action', 'VerifyIndex', '-ManifestPath', $ManifestPath) -ExpectedPattern '(?m)^verified: yes\r?$'
    $writtenTree = (Invoke-Git -HooksPath $emptyHooksPath -Arguments @('write-tree')).Trim()
    if ($writtenTree -ne $CandidateTreeOid) { throw 'Staged tree differs from the reviewed candidate tree.' }

    [System.IO.File]::WriteAllText($messagePath, (Normalize-Text -Text $CommitMessage), [System.Text.UTF8Encoding]::new($false))
    $commitCreated = (Invoke-Git -HooksPath $emptyHooksPath -Arguments @('-c', 'commit.gpgSign=false', 'commit-tree', $CandidateTreeOid, '-p', $LocalParent, '-p', $RemoteParent, '-F', $messagePath)).Trim()
    $null = Invoke-RequiredScript -Script $packetScript -Arguments @('-Action', 'VerifyRecordedCommit', '-PacketPath', $PacketPath, '-ManifestPath', $ManifestPath, '-CommitId', $commitCreated) -ExpectedPattern '(?m)^verified: yes\r?$'
    $null = Invoke-RequiredScript -Script $hookScript -Arguments @() -ExpectedPattern '(?m)^authorization_safe: yes\r?$'
    if (@(Get-ChildItem -LiteralPath $emptyHooksPath -Force).Count -ne 0) { throw 'Command-scoped hooks directory changed before ref update.' }
    $null = Invoke-Git -HooksPath $emptyHooksPath -Arguments @('update-ref', "refs/heads/$LocalBranch", $commitCreated, $LocalParent)

    $null = Invoke-RequiredScript -Script $packetScript -Arguments @('-Action', 'VerifyRecordedCommit', '-PacketPath', $PacketPath, '-ManifestPath', $ManifestPath, '-CommitId', $commitCreated) -ExpectedPattern '(?m)^verified: yes\r?$'
    $null = Invoke-RequiredScript -Script $manifestScript -Arguments @('-Action', 'VerifyWorktree', '-ManifestPath', $ManifestPath) -ExpectedPattern '(?m)^verified: yes\r?$'
    if (-not [string]::IsNullOrWhiteSpace((Invoke-Git -Arguments @('status', '--porcelain=v1', '--untracked-files=all')))) { throw 'Recorded merge did not leave a clean worktree and index.' }

    Write-Output 'REVIEWED_MERGE_RESULT'
    Write-Output "packet_id: $PacketId"
    Write-Output "manifest_id: $ManifestId"
    Write-Output "candidate_tree_oid: $CandidateTreeOid"
    Write-Output "commit_id: $commitCreated"
    Write-Output "ordered_parents: $LocalParent $RemoteParent"
    Write-Output "committed_paths: $($assignedPaths -join '; ')"
    Write-Output 'verified: yes'
} catch {
    if (-not [string]::IsNullOrWhiteSpace($commitCreated)) { Write-Error "A reviewed merge commit object may exist without an updated branch ref: $commitCreated" }
    throw
} finally {
    Remove-Item -LiteralPath $messagePath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $emptyHooksPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $emptyAttributesPath -Force -ErrorAction SilentlyContinue
}
