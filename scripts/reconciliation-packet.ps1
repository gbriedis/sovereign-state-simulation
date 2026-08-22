param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('CreateAssessment', 'VerifyAssessment', 'BindCandidate', 'VerifyCandidate', 'VerifyRecordedCommit')]
    [string]$Action,
    [string]$PacketPath,
    [string]$RepositoryRoot,
    [string]$RemoteName,
    [string]$RemoteUrlSafe,
    [string]$RemoteUrlFingerprint,
    [string]$LocalBranch,
    [string]$RemoteBranch,
    [string]$LocalParent,
    [string]$RemoteParent,
    [string]$WorkflowId,
    [string]$ManifestPath,
    [string]$ManifestId,
    [string]$CommitMessage,
    [string]$CommitId
)

$ErrorActionPreference = 'Stop'
$repositoryRootPath = if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    Split-Path -Parent $PSScriptRoot
} else {
    [System.IO.Path]::GetFullPath($RepositoryRoot)
}
$workflowStatePath = Join-Path $repositoryRootPath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md'
$policyGuardScript = Join-Path $PSScriptRoot 'check-git-executable-policy.ps1'

function Get-Sha256Text {
    param([string]$Text)
    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
}

function Normalize-Text {
    param([string]$Text)
    return $Text.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n") + "`n"
}

function Invoke-GitResult {
    param([string[]]$Arguments, [int[]]$AllowedExitCodes = @(0))
    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-reconciliation-git-' + [guid]::NewGuid().ToString('N'))
    try {
        $output = @(& git -C $repositoryRootPath -c core.fsmonitor=false @Arguments 2> $stderrPath)
        $exitCode = $LASTEXITCODE
        if ($exitCode -notin $AllowedExitCodes) {
            $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -Raw -LiteralPath $stderrPath } else { '' }
            throw "Git reconciliation inspection failed.`n$stderr"
        }
        return @{ ExitCode = $exitCode; Lines = @($output); Text = (@($output) -join "`n") }
    } finally {
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Assert-ObjectId {
    param([string]$Value, [string]$Label)
    if ($Value -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') { throw "$Label must be a full lowercase object ID." }
}

function Assert-ExecutableGitPolicy {
    $output = & pwsh -NoProfile -File $policyGuardScript -RepositoryRoot $repositoryRootPath 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $output -notmatch '(?m)^authorization_safe: yes\r?$') {
        throw 'Executable Git policy is outside the reconciliation-assessment authorization.'
    }
}

function Assert-SafeRemoteDisplay {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match '[\r\n]') { throw 'Remote URL safe form is missing or unsafe.' }
    if ($Value.Contains('::')) { throw 'Remote URL form cannot be persisted.' }
    if ($Value -match '^(?i:[a-z][a-z0-9+.-]*)://') {
        $uri = $null
        if (-not [uri]::TryCreate($Value, [System.UriKind]::Absolute, [ref]$uri) -or
            $uri.Scheme -notin @('https', 'ssh', 'git', 'file') -or
            ($uri.Scheme -ne 'file' -and [string]::IsNullOrEmpty($uri.Host)) -or
            (($uri.Scheme -ne 'ssh') -and -not [string]::IsNullOrEmpty($uri.UserInfo)) -or
            $uri.UserInfo.Contains(':') -or -not [string]::IsNullOrEmpty($uri.Query) -or -not [string]::IsNullOrEmpty($uri.Fragment) -or
            $Value.Contains('\\') -or $uri.AbsolutePath.Contains(';') -or $uri.AbsolutePath -match '(?i)%3b') {
            throw 'Remote URL form cannot be persisted.'
        }
    } elseif ($Value -match '^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+:[A-Za-z0-9._~/-]+$') {
        return
    } elseif (-not [System.IO.Path]::IsPathRooted($Value) -and $Value -notmatch '^(?:\.{0,2}/)?[A-Za-z0-9._/-]+$') {
        throw 'Remote URL form cannot be persisted.'
    }
}

function Get-SortedUnique {
    param([object[]]$Values)
    $set = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($value in $Values) {
        $normalized = ([string]$value).Replace('\', '/')
        if (-not [string]::IsNullOrWhiteSpace($normalized)) { $null = $set.Add($normalized) }
    }
    return @($set)
}

function Test-GovernedPath {
    param([string]$Path)
    return $Path -eq 'AGENTS.md' -or $Path -eq 'README.md' -or $Path -eq '.gitattributes' -or $Path.EndsWith('/.gitattributes') -or $Path.StartsWith('docs/') -or
        $Path -eq '.github/workflows/documentation.yml' -or
        $Path -match '^scripts/(?:check-docs|test-docs-|change-manifest|reconciliation-packet|record-reviewed-merge|check-git-|test-git-).*\.ps1$'
}

function Invoke-GitNulText {
    param([string[]]$Arguments)
    $start = [System.Diagnostics.ProcessStartInfo]::new('git')
    $start.WorkingDirectory = $repositoryRootPath
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in @('-C', $repositoryRootPath) + $Arguments) { $start.ArgumentList.Add($argument) }
    $process = [System.Diagnostics.Process]::Start($start)
    $stdout = $process.StandardOutput.ReadToEnd()
    $null = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw 'Configuration-neutralized Git path inspection failed.' }
    return $stdout
}

function Get-ChangedPathStates {
    param([string]$From, [string]$To, [string]$Side)
    $stdout = Invoke-GitNulText -Arguments @(
        '-c', 'core.quotepath=false', '-c', 'diff.renames=false', '-c', 'diff.external=',
        'diff', '--no-ext-diff', '--no-textconv', '--no-renames', '--name-status', '-z', $From, $To, '--'
    )
    $tokens = @($stdout.Split([char]0, [System.StringSplitOptions]::None))
    $states = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index + 1 -lt $tokens.Count -and $tokens[$index] -ne ''; $index += 2) {
        $status = $tokens[$index]
        if ($status -notmatch '^[AMDTCUXB]$' -or [string]::IsNullOrWhiteSpace($tokens[$index + 1])) {
            throw 'NUL-delimited name-status output is incomplete or unsupported.'
        }
        $states.Add([ordered]@{ side = $Side; status = $status; path = $tokens[$index + 1].Replace('\', '/') })
    }
    $sorted = [System.Collections.Generic.SortedDictionary[string, object]]::new([System.StringComparer]::Ordinal)
    foreach ($state in $states) { $sorted["$($state.side)`0$($state.path)`0$($state.status)"] = $state }
    return @($sorted.Values)
}

function Get-TreePathStates {
    param([string]$Tree, [string]$Side)
    $stdout = Invoke-GitNulText -Arguments @('-c', 'core.quotepath=false', 'ls-tree', '-r', '--name-only', '-z', $Tree)
    $sorted = [System.Collections.Generic.SortedDictionary[string, object]]::new([System.StringComparer]::Ordinal)
    foreach ($path in $stdout.Split([char]0, [System.StringSplitOptions]::RemoveEmptyEntries)) {
        $normalized = $path.Replace('\', '/')
        $sorted[$normalized] = [ordered]@{ side = $Side; status = 'A'; path = $normalized }
    }
    return @($sorted.Values)
}

function Assert-BuiltinMergeAttributes {
    param([string]$Content)
    foreach ($line in $Content.Replace("`r`n", "`n").Replace("`r", "`n").Split("`n")) {
        $trimmed = $line.TrimStart()
        if ($trimmed.StartsWith('#')) { continue }
        foreach ($match in [regex]::Matches($line, '(?<!\S)(?<token>[!-]?merge(?:=[^\s]+)?)(?=\s|$)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            if ($match.Groups['token'].Value.ToLowerInvariant() -notin @('merge', '-merge', '!merge', 'merge=text', 'merge=binary')) {
                throw 'Custom merge attributes are prohibited during reconciliation assessment.'
            }
        }
    }
}

function Get-MergePolicyEvidence {
    param([string]$Local, [string]$Remote)
    foreach ($environmentName in @('GIT_CONFIG_COUNT', 'GIT_CONFIG_PARAMETERS', 'GIT_CONFIG_SYSTEM', 'GIT_CONFIG_GLOBAL')) {
        if (-not [string]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($environmentName))) {
            throw 'Inherited Git configuration overrides are prohibited during reconciliation assessment.'
        }
    }
    $unsafeConfig = @((Invoke-GitResult -Arguments @('config', '--name-only', '--list')).Lines | Where-Object { [string]$_ -match '^(?i:merge\.default|merge\..*\.driver|core\.attributesfile)$' })
    if ($unsafeConfig.Count -ne 0) {
        throw 'Custom or inherited merge configuration is prohibited during reconciliation assessment.'
    }

    $attributeEvidence = [System.Collections.Generic.List[object]]::new()
    foreach ($commit in @($Local, $Remote)) {
        $attributePaths = @(Get-SortedUnique -Values @((Invoke-GitNulText -Arguments @('ls-tree', '-r', '--name-only', '-z', $commit)).Split([char]0, [System.StringSplitOptions]::RemoveEmptyEntries) |
            Where-Object { $_ -eq '.gitattributes' -or $_.EndsWith('/.gitattributes') }))
        foreach ($path in $attributePaths) {
            $content = (Invoke-GitResult -Arguments @('show', "$commit`:$path")).Text
            Assert-BuiltinMergeAttributes -Content $content
            $attributeEvidence.Add([ordered]@{ commit = $commit; path = $path; sha256 = Get-Sha256Text -Text (Normalize-Text -Text $content) })
        }
    }
    $infoAttributes = (Invoke-GitResult -Arguments @('rev-parse', '--path-format=absolute', '--git-path', 'info/attributes')).Text.Trim()
    if (Test-Path -LiteralPath $infoAttributes) {
        $content = Get-Content -Raw -LiteralPath $infoAttributes
        Assert-BuiltinMergeAttributes -Content $content
        $attributeEvidence.Add([ordered]@{ commit = 'repository-private'; path = 'info/attributes'; sha256 = Get-Sha256Text -Text (Normalize-Text -Text $content) })
    }
    return ([ordered]@{ config_policy = 'no-merge-default-driver-or-attributes-file'; attribute_policy = 'built-in-only'; attributes = @($attributeEvidence) } | ConvertTo-Json -Depth 8 -Compress)
}

function Get-StructuredMergeTree {
    param([string]$Local, [string]$Remote)
    $realObjects = (Invoke-GitResult -Arguments @('rev-parse', '--path-format=absolute', '--git-path', 'objects')).Text.Trim()
    $mergePolicyEvidence = Get-MergePolicyEvidence -Local $Local -Remote $Remote
    $temporaryRepository = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-merge-tree-repository-' + [guid]::NewGuid().ToString('N'))
    $temporaryTemplate = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-git-template-' + [guid]::NewGuid().ToString('N'))
    $temporaryObjects = Join-Path $temporaryRepository 'objects'
    $temporaryHooks = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-merge-tree-hooks-' + [guid]::NewGuid().ToString('N'))
    $emptyConfig = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-git-config-' + [guid]::NewGuid().ToString('N'))
    $emptyAttributes = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-git-attributes-' + [guid]::NewGuid().ToString('N'))
    $previousTemplateDirectory = $env:GIT_TEMPLATE_DIR
    try {
        $objectFormat = (Invoke-GitResult -Arguments @('rev-parse', '--show-object-format')).Text.Trim()
        $null = New-Item -ItemType Directory -Path $temporaryTemplate -Force
        if (@(Get-ChildItem -LiteralPath $temporaryTemplate -Force).Count -ne 0) { throw 'The isolated Git template directory is not empty.' }
        Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue
        $null = & git -c init.templateDir= init -q --bare "--template=$temporaryTemplate" "--object-format=$objectFormat" $temporaryRepository 2>&1
        if ($LASTEXITCODE -ne 0) { throw 'Could not initialize isolated merge assessment repository.' }
        if ($null -eq $previousTemplateDirectory) { Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue } else { $env:GIT_TEMPLATE_DIR = $previousTemplateDirectory }
        $temporaryInfoAttributes = Join-Path $temporaryRepository 'info/attributes'
        if ((Test-Path -LiteralPath $temporaryInfoAttributes -PathType Leaf) -and (Get-Item -LiteralPath $temporaryInfoAttributes).Length -ne 0) {
            throw 'The isolated merge repository inherited info/attributes.'
        }
        $temporaryRepositoryHooks = Join-Path $temporaryRepository 'hooks'
        if ((Test-Path -LiteralPath $temporaryRepositoryHooks -PathType Container) -and @(Get-ChildItem -LiteralPath $temporaryRepositoryHooks -Force).Count -ne 0) {
            throw 'The isolated merge repository inherited hooks.'
        }
        $null = New-Item -ItemType Directory -Path $temporaryHooks -Force
        [System.IO.File]::WriteAllText($emptyConfig, '', [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText($emptyAttributes, '', [System.Text.UTF8Encoding]::new($false))
        $start = [System.Diagnostics.ProcessStartInfo]::new('git')
        $start.WorkingDirectory = $repositoryRootPath
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
        foreach ($argument in @("--git-dir=$temporaryRepository", '-c', "core.hooksPath=$temporaryHooks", '-c', "core.attributesFile=$emptyAttributes", '-c', 'merge.default=text', '-c', 'core.quotepath=false', 'merge-tree', '--write-tree', '--name-only', '-z', $Local, $Remote)) { $start.ArgumentList.Add($argument) }
        $start.Environment['GIT_OBJECT_DIRECTORY'] = $temporaryObjects
        $start.Environment['GIT_CONFIG_NOSYSTEM'] = '1'
        $start.Environment['GIT_CONFIG_GLOBAL'] = $emptyConfig
        $start.Environment['GIT_ATTR_NOSYSTEM'] = '1'
        $null = $start.Environment.Remove('GIT_CONFIG_COUNT')
        $null = $start.Environment.Remove('GIT_CONFIG_PARAMETERS')
        $alternates = @($realObjects)
        if (-not [string]::IsNullOrWhiteSpace($env:GIT_ALTERNATE_OBJECT_DIRECTORIES)) { $alternates += $env:GIT_ALTERNATE_OBJECT_DIRECTORIES }
        $start.Environment['GIT_ALTERNATE_OBJECT_DIRECTORIES'] = $alternates -join [System.IO.Path]::PathSeparator
        $process = [System.Diagnostics.Process]::Start($start)
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -notin @(0, 1)) { throw "Structured merge-tree inspection failed.`n$stderr" }
        $tokens = @($stdout.Split([char]0, [System.StringSplitOptions]::None))
        if ($tokens.Count -lt 2 -or $tokens[0] -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') { throw 'Structured merge-tree output is incomplete.' }
        $conflicts = [System.Collections.Generic.List[string]]::new()
        for ($index = 1; $index -lt $tokens.Count -and $tokens[$index] -ne ''; $index++) { $conflicts.Add($tokens[$index]) }
        $conflictPaths = @(Get-SortedUnique -Values $conflicts)
        $evidence = [ordered]@{
            format = 'git-merge-tree-write-tree-name-only-z-v1'
            exit_code = $process.ExitCode
            merge_tree_oid = $tokens[0]
            conflict_paths = $conflictPaths
            merge_policy_sha256 = Get-Sha256Text -Text $mergePolicyEvidence
            raw_stdout_base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($stdout))
        } | ConvertTo-Json -Depth 6 -Compress
        return @{ ConflictPaths = $conflictPaths; Evidence = $evidence }
    } finally {
        if ($null -eq $previousTemplateDirectory) { Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue } else { $env:GIT_TEMPLATE_DIR = $previousTemplateDirectory }
        Remove-Item -LiteralPath $temporaryRepository -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $temporaryTemplate -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $temporaryHooks -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $emptyConfig -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $emptyAttributes -Force -ErrorAction SilentlyContinue
    }
}

function Get-UpstreamKnowledgeCandidates {
    param([string]$Remote, [object[]]$RemoteChangedStates)
    $candidates = [System.Collections.Generic.List[object]]::new()
    foreach ($state in @($RemoteChangedStates | Where-Object { Test-GovernedPath -Path $_.path })) {
        $path = [string]$state.path
        $objectResult = Invoke-GitResult -Arguments @('rev-parse', '--verify', "$Remote`:$path") -AllowedExitCodes @(0, 128)
        if ($objectResult.ExitCode -ne 0) {
            $candidates.Add([ordered]@{ path = $path; change_status = [string]$state.status; blob_oid = 'None'; classification = 'remote-deleted-governed-path'; manual_classification_required = 'yes'; authority_ids = @(); evidence_sha256 = Get-Sha256Text -Text 'remote-deleted-governed-path' })
            continue
        }
        $blobOid = $objectResult.Text.Trim()
        $content = Normalize-Text -Text (Invoke-GitResult -Arguments @('show', "$Remote`:$path")).Text
        $metadata = ''
        $accepted = $false
        if ($content.StartsWith("---`n")) {
            $closing = $content.IndexOf("`n---`n", 4, [System.StringComparison]::Ordinal)
            if ($closing -gt 4) {
                $metadata = $content.Substring(4, $closing - 4)
                $accepted = $metadata -match '(?m)^status:[ \t]*accepted[ \t]*$'
            }
        } else {
            $lines = $content.Split("`n")
            if ($lines.Count -gt 0 -and $lines[0] -match '^#\s+(?<id>ADR-\d{4})(?::|\s+-)') {
                $metadataLines = [System.Collections.Generic.List[string]]::new()
                for ($index = 1; $index -lt $lines.Count; $index++) {
                    if ([string]::IsNullOrWhiteSpace($lines[$index]) -and $metadataLines.Count -eq 0) { continue }
                    if ($lines[$index] -match '^-\s+\*\*[^*]+:\*\*\s+.+$') { $metadataLines.Add($lines[$index]); continue }
                    break
                }
                $metadata = @($metadataLines) -join "`n"
                $accepted = $metadata -match '(?m)^-\s+\*\*Status:\*\*[ \t]+Accepted[ \t]*$'
            }
        }
        $ids = @(Get-SortedUnique -Values @([regex]::Matches($metadata, '(?i)\b(?:ADR-\d{4}|WG-\d{3}|[A-Z][A-Z0-9]+-\d{3})\b') | ForEach-Object { $_.Value.ToUpperInvariant() }))
        if ($content -match '^#\s+(?<id>ADR-\d{4})(?::|\s+-)') { $ids = @(Get-SortedUnique -Values (@($Matches.id.ToUpperInvariant()) + $ids)) }
        $candidates.Add([ordered]@{
            path = $path
            change_status = [string]$state.status
            blob_oid = $blobOid
            classification = if ($accepted) { 'accepted-metadata-detected' } else { 'manual-classification-required' }
            manual_classification_required = if ($accepted) { 'no' } else { 'yes' }
            authority_ids = $ids
            evidence_sha256 = Get-Sha256Text -Text $content
        })
    }
    return @($candidates)
}

function Get-RepositoryAssessment {
    param([string]$Local, [string]$Remote)
    $mergeBaseResult = Invoke-GitResult -Arguments @('merge-base', $Local, $Remote) -AllowedExitCodes @(0, 1)
    $mergeBase = if ($mergeBaseResult.ExitCode -eq 0) { $mergeBaseResult.Text.Trim() } else { 'None' }
    $remoteAncestor = (Invoke-GitResult -Arguments @('merge-base', '--is-ancestor', $Remote, $Local) -AllowedExitCodes @(0, 1)).ExitCode -eq 0
    $localAncestor = (Invoke-GitResult -Arguments @('merge-base', '--is-ancestor', $Local, $Remote) -AllowedExitCodes @(0, 1)).ExitCode -eq 0
    $topology = if ($Local -eq $Remote) { 'already-published' } elseif ($remoteAncestor) { 'fast-forward-push' } elseif ($localAncestor) { 'behind' } elseif ($mergeBase -eq 'None') { 'unrelated' } else { 'diverged' }
    $remotePathStates = if ($mergeBase -eq 'None') {
        @(Get-TreePathStates -Tree $Remote -Side 'remote')
    } else {
        @(Get-ChangedPathStates -From $mergeBase -To $Remote -Side 'remote')
    }
    $pathStates = if ($mergeBase -eq 'None') {
        @(Get-ChangedPathStates -From $Local -To $Remote -Side 'comparison')
    } else {
        @((Get-ChangedPathStates -From $mergeBase -To $Local -Side 'local')) +
            @((Get-ChangedPathStates -From $mergeBase -To $Remote -Side 'remote'))
    }
    $structuredMerge = if ($mergeBase -eq 'None') { $null } else { Get-StructuredMergeTree -Local $Local -Remote $Remote }
    $evidence = if ($mergeBase -eq 'None') {
        Normalize-Text -Text (Invoke-GitResult -Arguments @('diff', '--no-ext-diff', '--binary', $Local, $Remote, '--')).Text
    } else {
        $structuredMerge.Evidence
    }
    return @{
        MergeBase = $mergeBase
        Topology = $topology
        ChangedPathStates = @($pathStates)
        ChangedPaths = Get-SortedUnique -Values @($pathStates | ForEach-Object { $_.path })
        Evidence = $evidence
        ConflictPaths = if ($mergeBase -eq 'None') { @() } else { @($structuredMerge.ConflictPaths) }
        RemoteChangedPathStates = @($remotePathStates)
        UpstreamKnowledgeCandidates = @(Get-UpstreamKnowledgeCandidates -Remote $Remote -RemoteChangedStates $remotePathStates)
    }
}

function Get-DefaultPacketPath {
    param([string]$Id)
    $gitPath = (Invoke-GitResult -Arguments @('rev-parse', '--path-format=absolute', '--git-path', "codex/reconciliation-packets/$Id.json")).Text.Trim()
    return [System.IO.Path]::GetFullPath($gitPath)
}

function Write-Packet {
    param([System.Collections.IDictionary]$Payload)
    $payloadJson = $Payload | ConvertTo-Json -Depth 12 -Compress
    $packetId = Get-Sha256Text -Text $payloadJson
    $path = Get-DefaultPacketPath -Id $packetId
    $document = [ordered]@{ schema_version = 2; packet_id = $packetId; payload = $Payload }
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
    [System.IO.File]::WriteAllText($path, ($document | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return @{ Id = $packetId; Path = $path; Document = $document }
}

function Read-VerifiedPacket {
    param([string]$Path, [string]$ExpectedPhase)
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'A packet path is required.' }
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $document = Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json
    if ($document.schema_version -ne 2 -or $document.packet_id -notmatch '^[0-9a-f]{64}$' -or $null -eq $document.payload) {
        throw 'Reconciliation packet has an unsupported or incomplete schema.'
    }
    $computed = Get-Sha256Text -Text ($document.payload | ConvertTo-Json -Depth 12 -Compress)
    if ($computed -ne $document.packet_id) { throw 'Reconciliation packet fingerprint mismatch.' }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedPhase) -and $document.payload.phase -ne $ExpectedPhase) {
        throw "Reconciliation packet phase must be '$ExpectedPhase'."
    }
    Assert-SafeRemoteDisplay -Value $document.payload.remote_url_safe
    if ($document.payload.remote_url_fingerprint -notmatch '^[0-9a-f]{64}$') { throw 'Packet remote URL fingerprint is invalid.' }
    if ((Get-Sha256Text -Text $document.payload.remote_url_safe) -ne $document.payload.remote_url_fingerprint) { throw 'Packet safe remote URL and fingerprint disagree.' }
    foreach ($field in @('local_parent', 'remote_parent')) { Assert-ObjectId -Value $document.payload.$field -Label $field }
    foreach ($arrayField in @('changed_paths', 'conflict_paths', 'governed_knowledge_paths')) {
        $values = @($document.payload.$arrayField)
        if ((@($values) -join "`n") -ne (@(Get-SortedUnique -Values $values) -join "`n")) {
            throw "Packet array '$arrayField' is not sorted and unique."
        }
    }
    foreach ($stateField in @('changed_path_states', 'remote_changed_path_states')) {
        if ($stateField -notin @($document.payload.PSObject.Properties.Name)) { throw "Packet path-state field '$stateField' is missing." }
    }
    $evidenceText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($document.payload.merge_tree_evidence_base64))
    if ((Get-Sha256Text -Text $evidenceText) -ne $document.payload.merge_tree_evidence_sha256) { throw 'Merge-tree evidence fingerprint mismatch.' }
    if ($document.payload.phase -eq 'assessment' -and $document.payload.topology -notin @('behind', 'diverged', 'unrelated')) { throw 'Assessment packet topology is invalid.' }
    if ($document.payload.phase -eq 'reviewed-candidate') {
        if ($document.payload.topology -ne 'diverged' -or $document.payload.assessment_packet_id -notmatch '^[0-9a-f]{64}$' -or
            $document.payload.accepted_manifest_id -notmatch '^[0-9a-f]{64}$' -or
            $document.payload.candidate_tree_oid -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$' -or
            $document.payload.merge_commit_message_sha256 -notmatch '^[0-9a-f]{64}$') {
            throw 'Reviewed-candidate packet contract is incomplete.'
        }
        $message = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($document.payload.merge_commit_message_base64))
        if ((Get-Sha256Text -Text $message) -ne $document.payload.merge_commit_message_sha256) { throw 'Reviewed merge message fingerprint mismatch.' }
        $assessmentPayload = [ordered]@{
            phase = 'assessment'
            writer_role = 'repository-git-steward'
            remote_name = $document.payload.remote_name
            remote_url_safe = $document.payload.remote_url_safe
            remote_url_fingerprint = $document.payload.remote_url_fingerprint
            local_branch = $document.payload.local_branch
            remote_branch = $document.payload.remote_branch
            local_parent = $document.payload.local_parent
            remote_parent = $document.payload.remote_parent
            merge_base = $document.payload.merge_base
            topology = $document.payload.topology
            changed_paths = @($document.payload.changed_paths)
            changed_path_states = @($document.payload.changed_path_states)
            remote_changed_path_states = @($document.payload.remote_changed_path_states)
            conflict_paths = @($document.payload.conflict_paths)
            governed_knowledge_paths = @($document.payload.governed_knowledge_paths)
            upstream_accepted_knowledge_candidates = @($document.payload.upstream_accepted_knowledge_candidates)
            merge_tree_evidence_sha256 = $document.payload.merge_tree_evidence_sha256
            merge_tree_evidence_base64 = $document.payload.merge_tree_evidence_base64
        }
        if ((Get-Sha256Text -Text ($assessmentPayload | ConvertTo-Json -Depth 12 -Compress)) -ne $document.payload.assessment_packet_id) {
            throw 'Reviewed-candidate packet does not reproduce its assessment packet identity.'
        }
    }
    $facts = Get-RepositoryAssessment -Local $document.payload.local_parent -Remote $document.payload.remote_parent
    if ($facts.MergeBase -ne $document.payload.merge_base -or $facts.Topology -ne $document.payload.topology -or
        (@($facts.ChangedPaths) -join "`n") -ne (@($document.payload.changed_paths) -join "`n") -or
        (@($facts.ChangedPathStates) | ConvertTo-Json -Depth 5 -Compress) -ne (@($document.payload.changed_path_states) | ConvertTo-Json -Depth 5 -Compress) -or
        (@($facts.RemoteChangedPathStates) | ConvertTo-Json -Depth 5 -Compress) -ne (@($document.payload.remote_changed_path_states) | ConvertTo-Json -Depth 5 -Compress) -or
        (@($facts.ConflictPaths) -join "`n") -ne (@($document.payload.conflict_paths) -join "`n") -or
        $facts.Evidence -ne $evidenceText) {
        throw 'Reconciliation packet ancestry, paths, conflicts, or merge-tree evidence do not match the exact parents.'
    }
    $computedGoverned = @($facts.ChangedPaths | Where-Object { Test-GovernedPath -Path $_ })
    if ((@($computedGoverned) -join "`n") -ne (@($document.payload.governed_knowledge_paths) -join "`n")) { throw 'Packet governed paths do not match the exact path policy.' }
    if ((@($facts.UpstreamKnowledgeCandidates) | ConvertTo-Json -Depth 8 -Compress) -ne (@($document.payload.upstream_accepted_knowledge_candidates) | ConvertTo-Json -Depth 8 -Compress)) {
        throw 'Packet upstream accepted-knowledge candidates are incomplete or altered.'
    }
    $expectedPath = Get-DefaultPacketPath -Id $document.packet_id
    if ($resolvedPath -ne $expectedPath) { throw 'Reconciliation packet path does not match its deterministic packet ID.' }
    return @{ Path = $resolvedPath; Document = $document }
}

function Read-VerifiedManifest {
    param([string]$Path, [string]$ExpectedId)
    $resolved = [System.IO.Path]::GetFullPath($Path)
    $manifest = Get-Content -Raw -LiteralPath $resolved | ConvertFrom-Json
    if ($manifest.schema_version -ne 2 -or $manifest.manifest_id -notmatch '^[0-9a-f]{64}$' -or $manifest.manifest_id -ne $ExpectedId) {
        throw 'Reviewed reconciliation requires the exact accepted manifest schema 2 and ID.'
    }
    $computed = Get-Sha256Text -Text ($manifest.payload | ConvertTo-Json -Depth 12 -Compress)
    if ($computed -ne $manifest.manifest_id -or $manifest.payload.candidate_tree_oid -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') {
        throw 'Accepted manifest fingerprint or candidate tree identity is invalid.'
    }
    return @{ Path = $resolved; Document = $manifest }
}

function Write-Result {
    param($Packet, [string]$ResultAction)
    Write-Output 'RECONCILIATION_PACKET_RESULT'
    Write-Output "action: $ResultAction"
    Write-Output "packet_path: $($Packet.Path)"
    Write-Output "packet_id: $($Packet.Document.packet_id)"
    Write-Output "phase: $($Packet.Document.payload.phase)"
    Write-Output "local_parent: $($Packet.Document.payload.local_parent)"
    Write-Output "remote_parent: $($Packet.Document.payload.remote_parent)"
    Write-Output "remote_name: $($Packet.Document.payload.remote_name)"
    Write-Output "local_branch: $($Packet.Document.payload.local_branch)"
    Write-Output "remote_branch: $($Packet.Document.payload.remote_branch)"
    Write-Output "topology: $($Packet.Document.payload.topology)"
    Write-Output "changed_paths: $(@($Packet.Document.payload.changed_paths).Count)"
    Write-Output "conflict_paths: $(@($Packet.Document.payload.conflict_paths).Count)"
    Write-Output "candidate_tree_oid: $(if ($Packet.Document.payload.phase -eq 'reviewed-candidate') { $Packet.Document.payload.candidate_tree_oid } else { 'none' })"
    Write-Output "accepted_manifest_id: $(if ($Packet.Document.payload.phase -eq 'reviewed-candidate') { $Packet.Document.payload.accepted_manifest_id } else { 'none' })"
    Write-Output "merge_commit_message_sha256: $(if ($Packet.Document.payload.phase -eq 'reviewed-candidate') { $Packet.Document.payload.merge_commit_message_sha256 } else { 'none' })"
    Write-Output 'verified: yes'
}

Assert-ExecutableGitPolicy

if ($Action -eq 'CreateAssessment') {
    foreach ($value in @($RemoteName, $LocalBranch, $RemoteBranch)) {
        if ($value -notmatch '^[A-Za-z0-9._/-]+$' -or $value.Contains('..')) { throw 'Remote and branch names must be exact safe Git names.' }
    }
    if ($LocalBranch.StartsWith('refs/') -or $RemoteBranch.StartsWith('refs/')) { throw 'Branch values must be names below refs/heads.' }
    $null = Invoke-GitResult -Arguments @('check-ref-format', "refs/heads/$LocalBranch")
    $null = Invoke-GitResult -Arguments @('check-ref-format', "refs/heads/$RemoteBranch")
    Assert-SafeRemoteDisplay -Value $RemoteUrlSafe
    if ($RemoteUrlFingerprint -notmatch '^[0-9a-f]{64}$') { throw 'Remote URL fingerprint must be SHA-256.' }
    if ((Get-Sha256Text -Text $RemoteUrlSafe) -ne $RemoteUrlFingerprint) { throw 'Remote URL safe form and fingerprint must represent the same exact safe URL.' }
    Assert-ObjectId -Value $LocalParent -Label 'Local parent'
    Assert-ObjectId -Value $RemoteParent -Label 'Remote parent'
    foreach ($commit in @($LocalParent, $RemoteParent)) {
        if ((Invoke-GitResult -Arguments @('rev-parse', '--verify', "$commit^{commit}")).Text.Trim() -ne $commit) { throw 'A reconciliation parent does not resolve exactly.' }
    }
    $facts = Get-RepositoryAssessment -Local $LocalParent -Remote $RemoteParent
    $mergeBase = $facts.MergeBase
    $topology = $facts.Topology
    if ($topology -notin @('diverged', 'unrelated', 'behind')) { throw "Topology '$topology' does not require a reconciliation packet." }

    $changedPaths = @($facts.ChangedPaths)
    $conflicts = @($facts.ConflictPaths)
    $governedPaths = @($changedPaths | Where-Object { Test-GovernedPath -Path $_ })
    $evidence = $facts.Evidence
    $payload = [ordered]@{
        phase = 'assessment'
        writer_role = 'repository-git-steward'
        remote_name = $RemoteName
        remote_url_safe = $RemoteUrlSafe
        remote_url_fingerprint = $RemoteUrlFingerprint
        local_branch = $LocalBranch
        remote_branch = $RemoteBranch
        local_parent = $LocalParent
        remote_parent = $RemoteParent
        merge_base = $mergeBase
        topology = $topology
        changed_paths = @($changedPaths)
        changed_path_states = @($facts.ChangedPathStates)
        remote_changed_path_states = @($facts.RemoteChangedPathStates)
        conflict_paths = @($conflicts)
        governed_knowledge_paths = @($governedPaths)
        upstream_accepted_knowledge_candidates = @($facts.UpstreamKnowledgeCandidates)
        merge_tree_evidence_sha256 = Get-Sha256Text -Text $evidence
        merge_tree_evidence_base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($evidence))
    }
    $written = Write-Packet -Payload $payload
    Write-Result -Packet @{ Path = $written.Path; Document = $written.Document } -ResultAction 'create-assessment'
    exit 0
}

if ($Action -eq 'VerifyAssessment') {
    $packet = Read-VerifiedPacket -Path $PacketPath -ExpectedPhase 'assessment'
    Write-Result -Packet $packet -ResultAction 'verify-assessment'
    exit 0
}

if ($Action -eq 'BindCandidate') {
    if ($WorkflowId -notmatch '^KW-\d{8}-\d{3}$' -or $ManifestId -notmatch '^[0-9a-f]{64}$') { throw 'Binding requires exact workflow and manifest IDs.' }
    $assessment = Read-VerifiedPacket -Path $PacketPath -ExpectedPhase 'assessment'
    if ($assessment.Document.payload.topology -ne 'diverged') { throw 'Only related divergent histories can bind a reviewed two-parent candidate.' }
    $manifest = Read-VerifiedManifest -Path $ManifestPath -ExpectedId $ManifestId
    if ($manifest.Document.payload.workflow_id -ne $WorkflowId -or $manifest.Document.payload.baseline_commit -ne $assessment.Document.payload.local_parent) {
        throw 'Accepted manifest workflow or baseline does not match the reconciliation assessment.'
    }
    if ((Invoke-GitResult -Arguments @('rev-parse', 'HEAD')).Text.Trim() -ne $assessment.Document.payload.local_parent) { throw 'Current HEAD moved away from the assessed local parent.' }
    $state = (Get-Content -Raw -LiteralPath $workflowStatePath).Replace("`r`n", "`n")
    foreach ($required in @("workflow_state: finalizing", "workflow_id: $WorkflowId", 'review_outcome: accept', "change_manifest_id: $ManifestId", "change_manifest_baseline: $($assessment.Document.payload.local_parent)", "accepted_manifest_id: $ManifestId")) {
        if ($state -notmatch ('(?m)^' + [regex]::Escape($required) + '$')) { throw 'Workflow state does not prove final reviewer acceptance of this manifest.' }
    }
    $stateManifestMatch = [regex]::Match($state, '(?m)^change_manifest_path: (?<path>.+)$')
    if (-not $stateManifestMatch.Success) { throw 'Workflow state does not record the accepted manifest path.' }
    $stateManifestPath = $stateManifestMatch.Groups['path'].Value.Trim()
    $stateManifestFullPath = if ([System.IO.Path]::IsPathRooted($stateManifestPath)) { [System.IO.Path]::GetFullPath($stateManifestPath) } else { [System.IO.Path]::GetFullPath((Join-Path $repositoryRootPath $stateManifestPath)) }
    if ($stateManifestFullPath -ne $manifest.Path) { throw 'Workflow state manifest path does not match the binding input.' }
    if ([string]::IsNullOrWhiteSpace($CommitMessage)) { throw 'Binding requires an exact non-empty merge commit message.' }
    $message = Normalize-Text -Text $CommitMessage
    $payload = [ordered]@{
        phase = 'reviewed-candidate'
        writer_role = 'knowledge-workflow-coordinator'
        assessment_packet_id = $assessment.Document.packet_id
        remote_name = $assessment.Document.payload.remote_name
        remote_url_safe = $assessment.Document.payload.remote_url_safe
        remote_url_fingerprint = $assessment.Document.payload.remote_url_fingerprint
        local_branch = $assessment.Document.payload.local_branch
        remote_branch = $assessment.Document.payload.remote_branch
        local_parent = $assessment.Document.payload.local_parent
        remote_parent = $assessment.Document.payload.remote_parent
        merge_base = $assessment.Document.payload.merge_base
        topology = $assessment.Document.payload.topology
        changed_paths = @($assessment.Document.payload.changed_paths)
        changed_path_states = @($assessment.Document.payload.changed_path_states)
        remote_changed_path_states = @($assessment.Document.payload.remote_changed_path_states)
        conflict_paths = @($assessment.Document.payload.conflict_paths)
        governed_knowledge_paths = @($assessment.Document.payload.governed_knowledge_paths)
        upstream_accepted_knowledge_candidates = @($assessment.Document.payload.upstream_accepted_knowledge_candidates)
        merge_tree_evidence_sha256 = $assessment.Document.payload.merge_tree_evidence_sha256
        merge_tree_evidence_base64 = $assessment.Document.payload.merge_tree_evidence_base64
        review_workflow_id = $WorkflowId
        accepted_manifest_id = $ManifestId
        candidate_tree_oid = $manifest.Document.payload.candidate_tree_oid
        merge_commit_message_sha256 = Get-Sha256Text -Text $message
        merge_commit_message_base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($message))
    }
    $written = Write-Packet -Payload $payload
    Write-Result -Packet @{ Path = $written.Path; Document = $written.Document } -ResultAction 'bind-candidate'
    exit 0
}

if ($Action -in @('VerifyCandidate', 'VerifyRecordedCommit')) {
    $packet = Read-VerifiedPacket -Path $PacketPath -ExpectedPhase 'reviewed-candidate'
    Assert-ObjectId -Value $packet.Document.payload.candidate_tree_oid -Label 'Candidate tree'
    $manifest = Read-VerifiedManifest -Path $ManifestPath -ExpectedId $packet.Document.payload.accepted_manifest_id
    if ($manifest.Document.payload.candidate_tree_oid -ne $packet.Document.payload.candidate_tree_oid -or $manifest.Document.payload.baseline_commit -ne $packet.Document.payload.local_parent) {
        throw 'Candidate packet does not match the accepted manifest tree or baseline.'
    }
    if ($Action -eq 'VerifyRecordedCommit') {
        Assert-ObjectId -Value $CommitId -Label 'Recorded commit'
        $tree = (Invoke-GitResult -Arguments @('rev-parse', "$CommitId^{tree}")).Text.Trim()
        $parents = @(((Invoke-GitResult -Arguments @('show', '-s', '--format=%P', $CommitId)).Text.Trim()) -split ' ')
        if ($tree -ne $packet.Document.payload.candidate_tree_oid -or $parents.Count -ne 2 -or $parents[0] -ne $packet.Document.payload.local_parent -or $parents[1] -ne $packet.Document.payload.remote_parent) {
            throw 'Recorded reconciliation commit tree or ordered parents do not match the reviewed packet.'
        }
        $commitObject = (Invoke-GitResult -Arguments @('cat-file', 'commit', $CommitId)).Text.Replace("`r`n", "`n")
        $message = Normalize-Text -Text ($commitObject.Substring($commitObject.IndexOf("`n`n") + 2))
        if ((Get-Sha256Text -Text $message) -ne $packet.Document.payload.merge_commit_message_sha256) { throw 'Recorded reconciliation commit message does not match the authorized packet.' }
        foreach ($parent in @($packet.Document.payload.local_parent, $packet.Document.payload.remote_parent)) {
            if ((Invoke-GitResult -Arguments @('merge-base', '--is-ancestor', $parent, $CommitId) -AllowedExitCodes @(0, 1)).ExitCode -ne 0) { throw 'Recorded reconciliation commit does not preserve both histories.' }
        }
        $manifestScript = Join-Path $PSScriptRoot 'change-manifest.ps1'
        $manifestOutput = & pwsh -NoProfile -File $manifestScript -Action VerifyCommit -ManifestPath $ManifestPath -CommitId $CommitId -RepositoryRoot $repositoryRootPath 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or $manifestOutput -notmatch '(?m)^verified: yes\r?$') { throw 'Recorded reconciliation commit does not verify against the accepted manifest.' }
    }
    Write-Result -Packet $packet -ResultAction $(if ($Action -eq 'VerifyCandidate') { 'verify-candidate' } else { 'verify-recorded-commit' })
    exit 0
}
