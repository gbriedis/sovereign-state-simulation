param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Create', 'VerifyReview', 'VerifyWorktree', 'VerifyIndex', 'VerifyCommit')]
    [string]$Action,

    [string]$WorkflowId,
    [string]$ManifestPath,
    [string]$CommitId,
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

$repositoryRootPath = if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    Split-Path -Parent $PSScriptRoot
} else {
    [System.IO.Path]::GetFullPath($RepositoryRoot)
}
$workflowStateRelativePath = 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md'
$workflowStatePath = Join-Path $repositoryRootPath $workflowStateRelativePath

function Invoke-GitText {
    param(
        [string[]]$Arguments,
        [string]$IndexFile,
        [string]$HooksPath
    )

    $previousIndex = $env:GIT_INDEX_FILE
    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-git-stderr-' + [guid]::NewGuid().ToString('N'))
    try {
        if ([string]::IsNullOrWhiteSpace($IndexFile)) {
            Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue
        } else {
            $env:GIT_INDEX_FILE = $IndexFile
        }
        $gitArguments = [System.Collections.Generic.List[string]]::new()
        $gitArguments.Add('-C')
        $gitArguments.Add($repositoryRootPath)
        if (-not [string]::IsNullOrWhiteSpace($HooksPath)) {
            $gitArguments.Add('-c')
            $gitArguments.Add("core.hooksPath=$HooksPath")
        }
        foreach ($argument in $Arguments) {
            $gitArguments.Add($argument)
        }
        $commandOutput = @(& git @gitArguments 2> $stderrPath)
        if ($LASTEXITCODE -ne 0) {
            $standardError = if (Test-Path -LiteralPath $stderrPath) { Get-Content -Raw -LiteralPath $stderrPath } else { '' }
            throw "Git command failed: git $($Arguments -join ' ')`n$standardError$($commandOutput -join "`n")"
        }
        return [string]::Join("`n", [string[]]$commandOutput)
    } finally {
        if ($null -eq $previousIndex) {
            Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue
        } else {
            $env:GIT_INDEX_FILE = $previousIndex
        }
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-Sha256Text {
    param([string]$Text)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return [Convert]::ToHexString($hash).ToLowerInvariant()
}

function Get-Sha256File {
    param([string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $hash = [System.Security.Cryptography.SHA256]::HashData($stream)
        return [Convert]::ToHexString($hash).ToLowerInvariant()
    } finally {
        $stream.Dispose()
    }
}

function New-ExpectedIdleWorkflowState {
    param(
        [string]$ActiveStatePath,
        [string]$CompletedWorkflowId,
        [string]$OutputPath
    )

    $text = (Get-Content -Raw -LiteralPath $ActiveStatePath).Replace("`r`n", "`n")
    $match = [regex]::Match($text, '(?s)\A---\n(?<front>.*?)\n---\n')
    if (-not $match.Success) {
        throw 'Cannot derive the expected idle checkpoint because workflow-state front matter is malformed.'
    }

    $replacements = [ordered]@{
        workflow_state = 'idle'
        workflow_id = 'none'
        round = '0'
        objective = 'none'
        developer_worker = 'none'
        reviewer_worker = 'none'
        review_outcome = 'none'
        change_manifest_path = 'none'
        change_manifest_id = 'none'
        change_manifest_baseline = 'none'
        last_completed_workflow_id = $CompletedWorkflowId
    }
    $front = $match.Groups['front'].Value
    foreach ($field in $replacements.Keys) {
        $pattern = '(?m)^' + [regex]::Escape($field) + ':.*$'
        if (-not [regex]::IsMatch($front, $pattern)) {
            throw "Cannot derive the expected idle checkpoint because field '$field' is missing."
        }
        $front = [regex]::Replace($front, $pattern, "$field`: $($replacements[$field])")
    }

    $idleText = "---`n$front`n---`n`n# Knowledge Workflow State`n`nNo material knowledge workflow is active.`n`nLast completed workflow: ``$CompletedWorkflowId``.`n"
    [System.IO.File]::WriteAllText($OutputPath, $idleText, [System.Text.UTF8Encoding]::new($false))
}

function Get-IndexEntry {
    param(
        [string]$Path,
        [string]$IndexFile,
        [string]$HooksPath
    )

    $entryText = Invoke-GitText -Arguments @('ls-files', '-s', '-z', '--', $Path) -IndexFile $IndexFile -HooksPath $HooksPath
    $entryMatch = [regex]::Match($entryText, '^(?<mode>\d+) (?<oid>[0-9a-f]+) 0\t')
    if (-not $entryMatch.Success) {
        throw "Target Git tree has no stage-zero entry for '$Path'."
    }
    return @{
        Mode = $entryMatch.Groups['mode'].Value
        Oid = $entryMatch.Groups['oid'].Value
    }
}

function New-Snapshot {
    param(
        [ValidateSet('Review', 'Worktree', 'Index', 'Commit')]
        [string]$Target,
        [string]$BaselineCommit,
        [string]$TargetCommit,
        [string]$CompletedWorkflowId
    )

    $temporaryIndex = $null
    $temporaryIdleState = $null
    $indexFile = $null
    $rawSourceOverrides = @{}
    $idleStateBase64 = 'not-applicable'
    $temporaryObjectDirectory = $null
    $previousObjectDirectory = $env:GIT_OBJECT_DIRECTORY
    $previousAlternateObjectDirectories = $env:GIT_ALTERNATE_OBJECT_DIRECTORIES
    $temporaryHooksDirectory = $null
    try {
        if ($Target -in @('Review', 'Worktree', 'Commit')) {
            $temporaryHooksDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-manifest-hooks-' + [guid]::NewGuid().ToString('N'))
            $null = New-Item -ItemType Directory -Path $temporaryHooksDirectory -Force
        }
        if ($Target -in @('Review', 'Worktree')) {
            $realObjectDirectory = (Invoke-GitText -Arguments @('rev-parse', '--path-format=absolute', '--git-path', 'objects') -IndexFile $null -HooksPath $temporaryHooksDirectory).Trim()
            $temporaryObjectDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-manifest-objects-' + [guid]::NewGuid().ToString('N'))
            $null = New-Item -ItemType Directory -Path $temporaryObjectDirectory -Force
            $env:GIT_OBJECT_DIRECTORY = $temporaryObjectDirectory
            $alternateDirectories = [System.Collections.Generic.List[string]]::new()
            $alternateDirectories.Add($realObjectDirectory)
            if (-not [string]::IsNullOrWhiteSpace($previousAlternateObjectDirectories)) {
                $alternateDirectories.Add($previousAlternateObjectDirectories)
            }
            $env:GIT_ALTERNATE_OBJECT_DIRECTORIES = [string]::Join([System.IO.Path]::PathSeparator, $alternateDirectories)
        }

        if ($Target -in @('Review', 'Worktree', 'Commit')) {
            $temporaryIndex = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-manifest-index-' + [guid]::NewGuid().ToString('N'))
            $indexFile = $temporaryIndex
            if ($Target -eq 'Commit') {
                $null = Invoke-GitText -Arguments @('read-tree', $TargetCommit) -IndexFile $indexFile -HooksPath $temporaryHooksDirectory
            } else {
                $null = Invoke-GitText -Arguments @('read-tree', $BaselineCommit) -IndexFile $indexFile -HooksPath $temporaryHooksDirectory
                $null = Invoke-GitText -Arguments @('add', '-A', '--', '.') -IndexFile $indexFile -HooksPath $temporaryHooksDirectory
                if ($Target -eq 'Review') {
                    if ([string]::IsNullOrWhiteSpace($CompletedWorkflowId)) {
                        throw 'Review snapshots require a workflow ID for the deterministic idle checkpoint overlay.'
                    }
                    $temporaryIdleState = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-idle-state-' + [guid]::NewGuid().ToString('N') + '.md')
                    New-ExpectedIdleWorkflowState -ActiveStatePath $workflowStatePath -CompletedWorkflowId $CompletedWorkflowId -OutputPath $temporaryIdleState
                    $idleStateBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($temporaryIdleState))
                    $blobOid = (Invoke-GitText -Arguments @('hash-object', '-w', "--path=$workflowStateRelativePath", '--', $temporaryIdleState) -IndexFile $null -HooksPath $temporaryHooksDirectory).Trim()
                    $null = Invoke-GitText -Arguments @('update-index', '--add', '--cacheinfo', "100644,$blobOid,$workflowStateRelativePath") -IndexFile $indexFile -HooksPath $temporaryHooksDirectory
                    $rawSourceOverrides[$workflowStateRelativePath] = $temporaryIdleState
                }
            }
        }

        $diffText = Invoke-GitText -Arguments @('diff', '--cached', '--name-status', '-z', '--no-renames', $BaselineCommit, '--') -IndexFile $indexFile -HooksPath $temporaryHooksDirectory
        $tokens = @($diffText.Split([char]0, [System.StringSplitOptions]::RemoveEmptyEntries))
        if ($tokens.Count % 2 -ne 0) {
            throw 'Git returned an invalid NUL-delimited name-status stream.'
        }

        $entries = [System.Collections.Generic.List[object]]::new()
        for ($index = 0; $index -lt $tokens.Count; $index += 2) {
            $status = $tokens[$index]
            $path = $tokens[$index + 1]
            if ($status -match '^[RC]') {
                throw "Manifest snapshots require --no-renames path state, but Git returned '$status'."
            }

            $mode = '-'
            $oid = '-'
            $rawSha256 = '-'
            if ($status -ne 'D') {
                $indexEntry = Get-IndexEntry -Path $path -IndexFile $indexFile -HooksPath $temporaryHooksDirectory
                $mode = $indexEntry.Mode
                $oid = $indexEntry.Oid
                if ($Target -in @('Review', 'Worktree')) {
                    $rawPath = if ($rawSourceOverrides.ContainsKey($path)) {
                        $rawSourceOverrides[$path]
                    } else {
                        Join-Path $repositoryRootPath $path
                    }
                    if (-not (Test-Path -LiteralPath $rawPath -PathType Leaf)) {
                        throw "Working-tree path '$path' is not a regular file that can be fingerprinted."
                    }
                    $rawSha256 = Get-Sha256File -Path $rawPath
                }
            }

            $entries.Add([ordered]@{
                status = $status
                path = $path.Replace('\', '/')
                mode = $mode
                blob_oid = $oid
                worktree_sha256 = $rawSha256
            })
        }

        $sortedEntries = @($entries | Sort-Object -Property path)
        $treeLines = @($sortedEntries | ForEach-Object { "$($_.status)`t$($_.path)`t$($_.mode)`t$($_.blob_oid)" })
        $rawLines = @($sortedEntries | ForEach-Object { "$($_.status)`t$($_.path)`t$($_.mode)`t$($_.blob_oid)`t$($_.worktree_sha256)" })
        return [ordered]@{
            tree_fingerprint = Get-Sha256Text -Text ([string]::Join("`n", $treeLines))
            worktree_fingerprint = if ($Target -in @('Review', 'Worktree')) { Get-Sha256Text -Text ([string]::Join("`n", $rawLines)) } else { 'not-applicable' }
            final_workflow_state_base64 = $idleStateBase64
            entries = $sortedEntries
        }
    } finally {
        if ($null -ne $temporaryIndex) {
            Remove-Item -LiteralPath $temporaryIndex -Force -ErrorAction SilentlyContinue
        }
        if ($null -ne $temporaryIdleState) {
            Remove-Item -LiteralPath $temporaryIdleState -Force -ErrorAction SilentlyContinue
        }
        if ($null -eq $previousObjectDirectory) {
            Remove-Item Env:GIT_OBJECT_DIRECTORY -ErrorAction SilentlyContinue
        } else {
            $env:GIT_OBJECT_DIRECTORY = $previousObjectDirectory
        }
        if ($null -eq $previousAlternateObjectDirectories) {
            Remove-Item Env:GIT_ALTERNATE_OBJECT_DIRECTORIES -ErrorAction SilentlyContinue
        } else {
            $env:GIT_ALTERNATE_OBJECT_DIRECTORIES = $previousAlternateObjectDirectories
        }
        if ($null -ne $temporaryObjectDirectory) {
            Remove-Item -LiteralPath $temporaryObjectDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
        if ($null -ne $temporaryHooksDirectory) {
            Remove-Item -LiteralPath $temporaryHooksDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-DefaultManifestPath {
    param([string]$Id)

    $gitDirectoryText = (Invoke-GitText -Arguments @('rev-parse', '--git-dir') -IndexFile $null).Trim()
    $gitDirectory = if ([System.IO.Path]::IsPathRooted($gitDirectoryText)) {
        $gitDirectoryText
    } else {
        Join-Path $repositoryRootPath $gitDirectoryText
    }
    return Join-Path $gitDirectory ("codex/accepted-change-manifests/$Id.json")
}

function Read-VerifiedManifest {
    param([string]$Path)

    $document = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    if ($document.schema_version -ne 1 -or [string]::IsNullOrWhiteSpace($document.manifest_id) -or $null -eq $document.payload) {
        throw 'Accepted-change manifest has an unsupported or incomplete schema.'
    }
    $payloadJson = $document.payload | ConvertTo-Json -Depth 8 -Compress
    $computedId = Get-Sha256Text -Text $payloadJson
    if ($computedId -ne $document.manifest_id) {
        throw "Accepted-change manifest file fingerprint mismatch: recorded $($document.manifest_id), computed $computedId."
    }
    return $document
}

$headCommit = (Invoke-GitText -Arguments @('rev-parse', 'HEAD') -IndexFile $null).Trim()

if ($Action -eq 'Create') {
    if ($WorkflowId -notmatch '^KW-\d{8}-\d{3}$') {
        throw 'Create requires a workflow ID in the form KW-YYYYMMDD-NNN.'
    }
    $usedDefaultManifestPath = [string]::IsNullOrWhiteSpace($ManifestPath)
    if ($usedDefaultManifestPath) {
        $ManifestPath = Get-DefaultManifestPath -Id $WorkflowId
    }
    $ManifestPath = [System.IO.Path]::GetFullPath($ManifestPath)
    $manifestDisplayPath = if ($usedDefaultManifestPath) {
        ".git/codex/accepted-change-manifests/$WorkflowId.json"
    } else {
        $ManifestPath
    }
    $snapshot = New-Snapshot -Target Review -BaselineCommit $headCommit -CompletedWorkflowId $WorkflowId
    $payload = [ordered]@{
        workflow_id = $WorkflowId
        baseline_commit = $headCommit
        final_workflow_state_path = $workflowStateRelativePath
        final_workflow_state_base64 = $snapshot.final_workflow_state_base64
        tree_fingerprint = $snapshot.tree_fingerprint
        worktree_fingerprint = $snapshot.worktree_fingerprint
        entries = $snapshot.entries
    }
    $payloadJson = $payload | ConvertTo-Json -Depth 8 -Compress
    $manifestId = Get-Sha256Text -Text $payloadJson
    $document = [ordered]@{
        schema_version = 1
        manifest_id = $manifestId
        payload = $payload
    }
    $manifestDirectory = Split-Path -Parent $ManifestPath
    $null = New-Item -ItemType Directory -Path $manifestDirectory -Force
    [System.IO.File]::WriteAllText($ManifestPath, ($document | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
    Write-Output "CHANGE_MANIFEST_RESULT"
    Write-Output "action: create"
    Write-Output "workflow_id: $WorkflowId"
    Write-Output "manifest_path: $manifestDisplayPath"
    Write-Output "manifest_id: $manifestId"
    Write-Output "baseline_commit: $headCommit"
    Write-Output "changed_entries: $($snapshot.entries.Count)"
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    throw "$Action requires -ManifestPath."
}
$ManifestPath = [System.IO.Path]::GetFullPath($ManifestPath)
$manifest = Read-VerifiedManifest -Path $ManifestPath
$payload = $manifest.payload

$snapshot = switch ($Action) {
    'VerifyReview' {
        New-Snapshot -Target Review -BaselineCommit $payload.baseline_commit -CompletedWorkflowId $payload.workflow_id
    }
    'VerifyWorktree' {
        New-Snapshot -Target Worktree -BaselineCommit $payload.baseline_commit
    }
    'VerifyIndex' {
        New-Snapshot -Target Index -BaselineCommit $payload.baseline_commit
    }
    'VerifyCommit' {
        if ([string]::IsNullOrWhiteSpace($CommitId)) {
            throw 'VerifyCommit requires -CommitId.'
        }
        New-Snapshot -Target Commit -BaselineCommit $payload.baseline_commit -TargetCommit $CommitId
    }
}

if ($snapshot.tree_fingerprint -ne $payload.tree_fingerprint) {
    throw "Accepted-change tree fingerprint mismatch for $Action. Expected $($payload.tree_fingerprint), got $($snapshot.tree_fingerprint)."
}
if ($Action -in @('VerifyReview', 'VerifyWorktree') -and $snapshot.worktree_fingerprint -ne $payload.worktree_fingerprint) {
    throw "Accepted-change raw-byte fingerprint mismatch for $Action. Expected $($payload.worktree_fingerprint), got $($snapshot.worktree_fingerprint)."
}

Write-Output 'CHANGE_MANIFEST_RESULT'
Write-Output "action: $($Action.ToLowerInvariant())"
Write-Output "workflow_id: $($payload.workflow_id)"
Write-Output "manifest_path: $ManifestPath"
Write-Output "manifest_id: $($manifest.manifest_id)"
Write-Output "baseline_commit: $($payload.baseline_commit)"
Write-Output "changed_entries: $($snapshot.entries.Count)"
Write-Output 'verified: yes'
