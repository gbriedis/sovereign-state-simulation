$ErrorActionPreference = 'Stop'

$guardScript = Join-Path $PSScriptRoot 'check-git-executable-policy.ps1'
$manifestScript = Join-Path $PSScriptRoot 'change-manifest.ps1'
$publishScript = Join-Path $PSScriptRoot 'check-git-publish.ps1'
$recordScript = Join-Path $PSScriptRoot 'record-reviewed-merge.ps1'
$temporaryRepository = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-executable-policy-test-' + [guid]::NewGuid().ToString('N'))
$emptyTemplate = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-git-template-' + [guid]::NewGuid().ToString('N'))
$manifestPath = Join-Path $temporaryRepository '.git/codex/policy-manifest.json'
$workflowId = 'KW-20990101-003'
$remoteUrl = 'https://example.invalid/policy.git'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$checksPassed = 0
$expectedChecks = 37

function Invoke-TestGit {
    param([string[]]$Arguments, [int[]]$AllowedExitCodes = @(0))
    $output = @(& git -C $temporaryRepository -c core.fsmonitor=false @Arguments 2>&1)
    if ($LASTEXITCODE -notin $AllowedExitCodes) {
        throw "Test Git command failed: git $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return [string]::Join("`n", [string[]]$output)
}

function Invoke-TestGitWithInput {
    param([string[]]$Arguments, [string]$InputText)
    $start = [System.Diagnostics.ProcessStartInfo]::new('git')
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.ArgumentList.Add('-C')
    $start.ArgumentList.Add($temporaryRepository)
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    $process = [System.Diagnostics.Process]::Start($start)
    $process.StandardInput.Write($InputText)
    $process.StandardInput.Close()
    $output = $process.StandardOutput.ReadToEnd()
    $errorText = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "Test Git input command failed: git $($Arguments -join ' ')`n$errorText" }
    return $output.Trim()
}

function Write-TestFile {
    param([string]$RelativePath, [string]$Content)
    $path = Join-Path $temporaryRepository $RelativePath
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
    [System.IO.File]::WriteAllText($path, $Content, $utf8)
}

function Get-RepositoryMutationSnapshot {
    $gitDirectory = Join-Path $temporaryRepository '.git'
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add('refs=' + (Invoke-TestGit -Arguments @('for-each-ref', '--format=%(refname) %(objectname)')))
    $indexPath = Join-Path $gitDirectory 'index'
    $parts.Add('index=' + $(if (Test-Path -LiteralPath $indexPath) { (Get-FileHash -Algorithm SHA256 -LiteralPath $indexPath).Hash } else { 'None' }))
    $objectRoot = Join-Path $gitDirectory 'objects'
    foreach ($path in @([System.IO.Directory]::EnumerateFiles($objectRoot, '*', [System.IO.SearchOption]::AllDirectories) | Sort-Object)) {
        $parts.Add(([System.IO.Path]::GetRelativePath($objectRoot, $path).Replace('\', '/')) + '=' + (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash)
    }
    $text = [string]::Join("`n", $parts)
    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($text)))
}

function Invoke-RejectedWithoutMutation {
    param([string]$Name, [scriptblock]$Operation, [string]$MarkerPath, [string]$MustNotContain)
    $before = Get-RepositoryMutationSnapshot
    $output = & $Operation 2>&1 | Out-String
    $didPass = $LASTEXITCODE -eq 0
    if ($didPass) { throw "Executable-policy fixture '$Name' unexpectedly succeeded.`n$output" }
    if (Test-Path -LiteralPath $MarkerPath) { throw "Executable-policy fixture '$Name' executed its marker command." }
    if (-not [string]::IsNullOrEmpty($MustNotContain) -and $output.Contains($MustNotContain)) { throw "Executable-policy fixture '$Name' disclosed prohibited routing or command text." }
    $after = Get-RepositoryMutationSnapshot
    if ($after -ne $before) { throw "Executable-policy fixture '$Name' changed the real object database, index, or refs." }
    $script:checksPassed++
}

function Invoke-RoutingVariableRejection {
    param(
        [string]$Name,
        [string]$Value,
        [scriptblock]$Operation
    )
    $traceMarker = Join-Path $temporaryRepository ('.git/no-git-execution-' + $Name + '.json')
    $before = Get-RepositoryMutationSnapshot
    $previousValue = [System.Environment]::GetEnvironmentVariable($Name)
    $previousTrace = $env:GIT_TRACE2_EVENT
    try {
        [System.Environment]::SetEnvironmentVariable($Name, $Value)
        $env:GIT_TRACE2_EVENT = $traceMarker
        $output = & $Operation 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) { throw "Routing-variable fixture '$Name' unexpectedly succeeded.`n$output" }
        if ($output.Contains('secret-route')) { throw "Routing-variable fixture '$Name' disclosed its routed value." }
    } finally {
        if ([string]::IsNullOrEmpty($previousValue)) {
            Remove-Item -LiteralPath ("Env:" + $Name) -ErrorAction SilentlyContinue
        } else {
            [System.Environment]::SetEnvironmentVariable($Name, $previousValue, [System.EnvironmentVariableTarget]::Process)
        }
        if ([string]::IsNullOrEmpty($previousTrace)) { Remove-Item Env:GIT_TRACE2_EVENT -ErrorAction SilentlyContinue } else { $env:GIT_TRACE2_EVENT = $previousTrace }
    }
    if (Test-Path -LiteralPath $traceMarker) { throw "Routing-variable fixture '$Name' started Git before rejection." }
    $after = Get-RepositoryMutationSnapshot
    if ($after -ne $before) { throw "Routing-variable fixture '$Name' changed the real object database, index, or refs." }
    $script:checksPassed++
}

$idleState = @'
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Executable-policy test
authority: Test
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
scope: Executable-policy test
authority: Test
workflow_state: reviewing
workflow_id: KW-20990101-003
round: 1
objective: Test executable Git policy
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
    $null = New-Item -ItemType Directory -Path $temporaryRepository, $emptyTemplate -Force
    if (@([System.IO.Directory]::EnumerateFileSystemEntries($emptyTemplate)).Count -ne 0) { throw 'Test Git template is not empty.' }
    $previousTemplate = $env:GIT_TEMPLATE_DIR
    try {
        Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue
        $initOutput = @(& git -c init.templateDir= init -q -b main "--template=$emptyTemplate" $temporaryRepository 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Could not initialize isolated test repository.`n$($initOutput -join "`n")" }
    } finally {
        if ($null -eq $previousTemplate) { Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue } else { $env:GIT_TEMPLATE_DIR = $previousTemplate }
    }
    if ((Test-Path -LiteralPath (Join-Path $temporaryRepository '.git/info/attributes')) -or
        ((Test-Path -LiteralPath (Join-Path $temporaryRepository '.git/hooks')) -and @([System.IO.Directory]::EnumerateFileSystemEntries((Join-Path $temporaryRepository '.git/hooks'))).Count -ne 0)) {
        throw 'Isolated test initialization inherited attributes or hooks.'
    }

    $null = Invoke-TestGit -Arguments @('config', 'user.name', 'Executable Policy Test')
    $null = Invoke-TestGit -Arguments @('config', 'user.email', 'policy@example.invalid')
    $null = Invoke-TestGit -Arguments @('config', 'core.autocrlf', 'false')
    Write-TestFile -RelativePath 'tracked.txt' -Content "base`n"
    Write-TestFile -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' -Content $idleState
    $null = Invoke-TestGit -Arguments @('add', '-A', '--', '.')
    $null = Invoke-TestGit -Arguments @('commit', '-q', '-m', 'base')
    $baseCommit = (Invoke-TestGit -Arguments @('rev-parse', 'HEAD')).Trim()
    $null = Invoke-TestGit -Arguments @('remote', 'add', 'origin', $remoteUrl)
    Write-TestFile -RelativePath 'tracked.txt' -Content "candidate`n"
    Write-TestFile -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' -Content $activeState

    $guardOutput = & pwsh -NoProfile -File $guardScript -RepositoryRoot $temporaryRepository 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $guardOutput -notmatch '(?m)^authorization_safe: yes\r?$') { throw "Safe baseline was rejected.`n$guardOutput" }
    $checksPassed++

    $manifestOutput = & pwsh -NoProfile -File $manifestScript -Action Create -WorkflowId $workflowId -ManifestPath $manifestPath -RepositoryRoot $temporaryRepository 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Could not create safe baseline manifest.`n$manifestOutput" }
    $checksPassed++

    $alternateIndex = (Join-Path ([System.IO.Path]::GetTempPath()) ('codex-alternate-index-secret-route-' + [guid]::NewGuid().ToString('N'))).Replace('\', '/')
    $previousIndex = $env:GIT_INDEX_FILE
    Copy-Item -LiteralPath (Join-Path $temporaryRepository '.git/index') -Destination $alternateIndex
    $null = Invoke-TestGit -Arguments @('add', '-A', '--', '.')
    Write-TestFile -RelativePath 'tracked.txt' -Content "base`n"
    Write-TestFile -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' -Content $idleState
    if ([string]::IsNullOrWhiteSpace((Invoke-TestGit -Arguments @('status', '--porcelain=v1', '--untracked-files=all')))) { throw 'False-clean fixture did not make the real index dirty.' }
    try {
        $env:GIT_INDEX_FILE = $alternateIndex
        if (-not [string]::IsNullOrWhiteSpace((Invoke-TestGit -Arguments @('status', '--porcelain=v1', '--untracked-files=all')))) { throw 'False-clean fixture alternate index is not clean.' }
    } finally {
        if ([string]::IsNullOrEmpty($previousIndex)) { Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue } else { $env:GIT_INDEX_FILE = $previousIndex }
    }
    Invoke-RoutingVariableRejection -Name 'GIT_INDEX_FILE' -Value $alternateIndex -Operation {
        & pwsh -NoProfile -File $publishScript -Action PreTransport -RemoteName origin -ExpectedRemoteUrl $remoteUrl -LocalBranch main -RemoteBranch main -ExpectedLocalCommit $baseCommit -ExpectedRemoteCommit ('0' * 40) -PushRefspec 'refs/heads/main:refs/heads/main' -RepositoryRoot $temporaryRepository
    }
    Copy-Item -LiteralPath $alternateIndex -Destination (Join-Path $temporaryRepository '.git/index') -Force
    Write-TestFile -RelativePath 'tracked.txt' -Content "candidate`n"
    Write-TestFile -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' -Content $activeState
    Remove-Item -LiteralPath $alternateIndex -Force

    $routingVariables = [ordered]@{
        GIT_DIR = (Join-Path $temporaryRepository '.git-secret-route')
        GIT_WORK_TREE = (Join-Path $temporaryRepository 'worktree-secret-route')
        GIT_COMMON_DIR = (Join-Path $temporaryRepository '.git/common-secret-route')
        GIT_OBJECT_DIRECTORY = (Join-Path $temporaryRepository '.git/objects-secret-route')
        GIT_ALTERNATE_OBJECT_DIRECTORIES = (Join-Path $temporaryRepository '.git/alternate-objects-secret-route')
        GIT_NAMESPACE = 'secret-route-namespace'
        GIT_SHALLOW_FILE = (Join-Path $temporaryRepository '.git/shallow-secret-route')
        GIT_CEILING_DIRECTORIES = (Join-Path $temporaryRepository 'ceiling-secret-route')
        GIT_DISCOVERY_ACROSS_FILESYSTEM = '1'
        GIT_QUARANTINE_PATH = (Join-Path $temporaryRepository '.git/quarantine-secret-route')
        GIT_REPLACE_REF_BASE = 'refs/secret-route-replace'
        GIT_NO_REPLACE_OBJECTS = '1'
        GIT_GRAFT_FILE = (Join-Path $temporaryRepository '.git/grafts-secret-route')
        GIT_CONFIG_COUNT = '1'
        GIT_CONFIG_PARAMETERS = 'secret-route-config-parameters'
        GIT_CONFIG_SYSTEM = (Join-Path $temporaryRepository 'system-config-secret-route')
        GIT_CONFIG_GLOBAL = (Join-Path $temporaryRepository 'global-config-secret-route')
        GIT_CONFIG_NOSYSTEM = '1'
        GIT_ATTR_NOSYSTEM = '1'
    }
    foreach ($routingVariable in $routingVariables.GetEnumerator()) {
        Invoke-RoutingVariableRejection -Name $routingVariable.Key -Value ([string]$routingVariable.Value) -Operation {
            & pwsh -NoProfile -File $guardScript -RepositoryRoot $temporaryRepository
        }
    }

    $repositoryRoutingMarker = Join-Path $temporaryRepository '.git/repository-routing-marker.txt'
    $routedWorktree = Join-Path $temporaryRepository 'secret-route-worktree'
    $null = New-Item -ItemType Directory -Path $routedWorktree -Force
    $null = Invoke-TestGit -Arguments @('config', 'core.worktree', $routedWorktree)
    try {
        Invoke-RejectedWithoutMutation -Name 'configured core.worktree routing' -MarkerPath $repositoryRoutingMarker -Operation {
            & pwsh -NoProfile -File $guardScript -RepositoryRoot $temporaryRepository
        }
    } finally {
        $null = Invoke-TestGit -Arguments @('config', '--unset-all', 'core.worktree')
        Remove-Item -LiteralPath $routedWorktree -Recurse -Force
    }

    $alternatesPath = Join-Path $temporaryRepository '.git/objects/info/alternates'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $alternatesPath) -Force
    [System.IO.File]::WriteAllText($alternatesPath, "secret-route-object-database`n", $utf8)
    Invoke-RejectedWithoutMutation -Name 'repository object alternates' -MarkerPath $repositoryRoutingMarker -Operation {
        & pwsh -NoProfile -File $guardScript -RepositoryRoot $temporaryRepository
    }
    Remove-Item -LiteralPath $alternatesPath -Force

    $replacementRef = "refs/replace/$baseCommit"
    $null = Invoke-TestGit -Arguments @('update-ref', $replacementRef, $baseCommit)
    Invoke-RejectedWithoutMutation -Name 'repository replacement ref' -MarkerPath $repositoryRoutingMarker -Operation {
        & pwsh -NoProfile -File $guardScript -RepositoryRoot $temporaryRepository
    }
    $null = Invoke-TestGit -Arguments @('update-ref', '-d', $replacementRef)

    $graftsPath = Join-Path $temporaryRepository '.git/info/grafts'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $graftsPath) -Force
    [System.IO.File]::WriteAllText($graftsPath, "$baseCommit $baseCommit`n", $utf8)
    Invoke-RejectedWithoutMutation -Name 'repository graft routing' -MarkerPath $repositoryRoutingMarker -Operation {
        & pwsh -NoProfile -File $guardScript -RepositoryRoot $temporaryRepository
    }
    Remove-Item -LiteralPath $graftsPath -Force

    $shallowPath = Join-Path $temporaryRepository '.git/shallow'
    [System.IO.File]::WriteAllText($shallowPath, "$baseCommit`n", $utf8)
    Invoke-RejectedWithoutMutation -Name 'repository shallow topology routing' -MarkerPath $repositoryRoutingMarker -Operation {
        & pwsh -NoProfile -File $guardScript -RepositoryRoot $temporaryRepository
    }
    Remove-Item -LiteralPath $shallowPath -Force

    $attributeSourceRef = 'refs/heads/attr-source-secret-route'
    $attributeSourceContent = Join-Path $temporaryRepository '.git/attr-source-only.gitattributes'
    [System.IO.File]::WriteAllText($attributeSourceContent, "* filter=attr-route-marker`n", $utf8)
    $attributeBlob = (Invoke-TestGit -Arguments @('hash-object', '--no-filters', '-w', '--', $attributeSourceContent)).Trim()
    $attributeTree = Invoke-TestGitWithInput -Arguments @('mktree') -InputText "100644 blob $attributeBlob`t.gitattributes`n"
    if ($attributeTree -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') { throw 'Could not create the tree-only attribute source fixture.' }
    $attributeCommit = Invoke-TestGitWithInput -Arguments @('commit-tree', $attributeTree) -InputText "tree-only attribute source`n"
    if ($attributeCommit -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') { throw 'Could not create the attribute source fixture commit.' }
    $null = Invoke-TestGit -Arguments @('update-ref', $attributeSourceRef, $attributeCommit)
    Remove-Item -LiteralPath $attributeSourceContent -Force
    $attributeMarker = Join-Path $temporaryRepository '.git/attr-source-filter-marker.txt'
    $attributeSecret = 'secret-route-attribute-command'
    $attributeFilterCommand = "pwsh -NoProfile -Command `"[IO.File]::WriteAllText('$($attributeMarker.Replace("'", "''"))','$attributeSecret')`""
    $null = Invoke-TestGit -Arguments @('config', 'filter.attr-route-marker.clean', $attributeFilterCommand)

    Invoke-RoutingVariableRejection -Name 'GIT_ATTR_SOURCE' -Value $attributeSourceRef -Operation {
        & pwsh -NoProfile -File $manifestScript -Action Create -WorkflowId $workflowId -ManifestPath (Join-Path $temporaryRepository '.git/codex/rejected-attr-source.json') -RepositoryRoot $temporaryRepository
    }
    if (Test-Path -LiteralPath $attributeMarker) { throw 'Rejected GIT_ATTR_SOURCE executed its tree-only filter marker.' }

    $null = Invoke-TestGit -Arguments @('config', 'attr.tree', $attributeSourceRef)
    try {
        Invoke-RejectedWithoutMutation -Name 'configured attr.tree routing' -MarkerPath $attributeMarker -MustNotContain 'secret-route' -Operation {
            & pwsh -NoProfile -File $manifestScript -Action Create -WorkflowId $workflowId -ManifestPath (Join-Path $temporaryRepository '.git/codex/rejected-attr-tree.json') -RepositoryRoot $temporaryRepository
        }
    } finally {
        $null = Invoke-TestGit -Arguments @('config', '--unset-all', 'attr.tree')
        $null = Invoke-TestGit -Arguments @('config', '--unset-all', 'filter.attr-route-marker.clean')
        $null = Invoke-TestGit -Arguments @('update-ref', '-d', $attributeSourceRef)
    }

    $privateFilterMarker = Join-Path $temporaryRepository '.git/private-filter-marker.txt'
    $privateFilterCommand = "pwsh -NoProfile -Command `"[IO.File]::WriteAllText('$($privateFilterMarker.Replace("'", "''"))','executed')`""
    $null = Invoke-TestGit -Arguments @('config', 'filter.private.clean', $privateFilterCommand)
    $privateAttribute = Join-Path $temporaryRepository '.git/private/.gitattributes'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $privateAttribute) -Force
    [System.IO.File]::WriteAllText($privateAttribute, "* filter=private`n", $utf8)
    $privateOutput = & pwsh -NoProfile -File $guardScript -RepositoryRoot $temporaryRepository 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $privateOutput -notmatch '(?m)^configured_clean_or_process_filter_drivers: .*private.*\r?$' -or
        $privateOutput -notmatch '(?m)^selected_executable_filter_drivers: None\r?$' -or $privateOutput.Contains($privateFilterCommand) -or
        (Test-Path -LiteralPath $privateFilterMarker)) {
        throw "Git-directory exclusion or filter diagnostics are not truthful and isolated.`n$privateOutput"
    }
    $checksPassed++
    $null = Invoke-TestGit -Arguments @('config', '--unset-all', 'filter.private.clean')
    Remove-Item -LiteralPath (Split-Path -Parent $privateAttribute) -Recurse -Force

    $filterMarker = Join-Path $temporaryRepository '.git/filter-marker.txt'
    $filterCommand = "pwsh -NoProfile -Command `"[IO.File]::WriteAllText('$($filterMarker.Replace("'", "''"))','executed')`""
    $null = Invoke-TestGit -Arguments @('config', 'filter.marker.clean', $filterCommand)
    $null = Invoke-TestGit -Arguments @('config', 'filter.marker.process', $filterCommand)
    $null = New-Item -ItemType Directory -Path (Join-Path $temporaryRepository '.git/info') -Force
    [System.IO.File]::WriteAllText((Join-Path $temporaryRepository '.git/info/attributes'), "* filter=marker`n", $utf8)

    foreach ($action in @('Create', 'VerifyReview', 'VerifyWorktree', 'VerifyIndex')) {
        $operation = if ($action -eq 'Create') {
            { & pwsh -NoProfile -File $manifestScript -Action Create -WorkflowId $workflowId -ManifestPath (Join-Path $temporaryRepository '.git/codex/rejected.json') -RepositoryRoot $temporaryRepository }
        } else {
            { & pwsh -NoProfile -File $manifestScript -Action $action -ManifestPath $manifestPath -RepositoryRoot $temporaryRepository }
        }
        Invoke-RejectedWithoutMutation -Name "manifest $action" -Operation $operation -MarkerPath $filterMarker
    }

    $fingerprint = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($remoteUrl))).ToLowerInvariant()
    Invoke-RejectedWithoutMutation -Name 'reviewed merge recorder filter preflight' -MarkerPath $filterMarker -Operation {
        & pwsh -NoProfile -File $recordScript -WorkflowId $workflowId -PacketPath (Join-Path $temporaryRepository '.git/codex/missing-packet.json') -PacketId ('0' * 64) -ManifestPath $manifestPath -ManifestId ('0' * 64) -CandidateTreeOid ('0' * 40) -LocalBranch main -RemoteName origin -ExpectedRemoteUrl $remoteUrl -ExpectedRemoteUrlFingerprint $fingerprint -RemoteBranch main -PushRefspec 'refs/heads/main:refs/heads/main' -LocalParent $baseCommit -RemoteParent ('0' * 40) -CommitMessage 'Reviewed merge' -AuthorizedPaths @('tracked.txt') -RepositoryRoot $temporaryRepository
    }

    $null = Invoke-TestGit -Arguments @('config', '--unset-all', 'filter.marker.clean')
    $null = Invoke-TestGit -Arguments @('config', '--unset-all', 'filter.marker.process')
    Remove-Item -LiteralPath (Join-Path $temporaryRepository '.git/info/attributes') -Force

    $fsmonitorMarker = Join-Path $temporaryRepository '.git/fsmonitor-marker.txt'
    $fsmonitorCommand = "pwsh -NoProfile -Command `"[IO.File]::WriteAllText('$($fsmonitorMarker.Replace("'", "''"))','executed')`""
    $null = Invoke-TestGit -Arguments @('config', 'core.fsmonitor', $fsmonitorCommand)
    Invoke-RejectedWithoutMutation -Name 'publication status fsmonitor preflight' -MarkerPath $fsmonitorMarker -Operation {
        & pwsh -NoProfile -File $publishScript -Action PreTransport -RemoteName origin -ExpectedRemoteUrl $remoteUrl -LocalBranch main -RemoteBranch main -ExpectedLocalCommit $baseCommit -ExpectedRemoteCommit ('0' * 40) -PushRefspec 'refs/heads/main:refs/heads/main' -RepositoryRoot $temporaryRepository
    }
    $null = Invoke-TestGit -Arguments @('config', '--unset-all', 'core.fsmonitor')

    $queryMarker = Join-Path $temporaryRepository '.git/query-fsmonitor-marker.txt'
    $null = Invoke-TestGit -Arguments @('config', 'core.hooksPath', '.custom-hooks')
    $queryHook = Join-Path $temporaryRepository '.custom-hooks/query-fsmonitor'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $queryHook) -Force
    [System.IO.File]::WriteAllText($queryHook, "#!/bin/sh`nprintf executed > .git/query-fsmonitor-marker.txt`n", $utf8)
    if (-not $IsWindows) {
        [System.IO.File]::SetUnixFileMode($queryHook, [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::UserExecute)
    }
    Invoke-RejectedWithoutMutation -Name 'query-fsmonitor hook preflight' -MarkerPath $queryMarker -Operation {
        & pwsh -NoProfile -File $guardScript -RepositoryRoot $temporaryRepository
    }
} finally {
    Remove-Item -LiteralPath $temporaryRepository, $emptyTemplate -Recurse -Force -ErrorAction SilentlyContinue
}

if ($checksPassed -ne $expectedChecks) { throw "Executable Git policy test count changed: expected $expectedChecks, got $checksPassed." }
Write-Host "Executable Git policy tests passed: $checksPassed/$expectedChecks." -ForegroundColor Green
