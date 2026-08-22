$ErrorActionPreference = 'Stop'

$packetScript = Join-Path $PSScriptRoot 'reconciliation-packet.ps1'
$manifestScript = Join-Path $PSScriptRoot 'change-manifest.ps1'
$publishScript = Join-Path $PSScriptRoot 'check-git-publish.ps1'
$recordScript = Join-Path $PSScriptRoot 'record-reviewed-merge.ps1'
$temporaryRepository = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-reconciliation-test-' + [guid]::NewGuid().ToString('N'))
$workflowId = 'KW-20990101-002'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$rootedLocalUrl = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') { 'C:\repository.git' } else { '/tmp/repository.git' }
$checksPassed = 0

function Invoke-TestGit {
    param([string[]]$Arguments)
    $output = @(& git -C $temporaryRepository @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Test Git command failed: git $($Arguments -join ' ')`n$($output -join "`n")" }
    return [string]::Join("`n", [string[]]$output)
}

function Initialize-IsolatedTestRepository {
    param([string]$Path)
    $template = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-template-' + [guid]::NewGuid().ToString('N'))
    $previousTemplate = $env:GIT_TEMPLATE_DIR
    try {
        $null = New-Item -ItemType Directory -Path $template -Force
        if (@([System.IO.Directory]::EnumerateFileSystemEntries($template)).Count -ne 0) { throw 'Reconciliation test template is not empty.' }
        Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue
        $output = @(& git -c init.templateDir= init -q -b main "--template=$template" $Path 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Could not initialize isolated reconciliation test repository.`n$($output -join "`n")" }
        if ((Test-Path -LiteralPath (Join-Path $Path '.git/info/attributes')) -or
            ((Test-Path -LiteralPath (Join-Path $Path '.git/hooks')) -and @([System.IO.Directory]::EnumerateFileSystemEntries((Join-Path $Path '.git/hooks'))).Count -ne 0)) {
            throw 'Reconciliation test initialization inherited attributes or hooks.'
        }
    } finally {
        if ($null -eq $previousTemplate) { Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue } else { $env:GIT_TEMPLATE_DIR = $previousTemplate }
        Remove-Item -LiteralPath $template -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Write-TestFile {
    param([string]$RelativePath, [string]$Content)
    $path = Join-Path $temporaryRepository $RelativePath
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
    [System.IO.File]::WriteAllText($path, $Content, $utf8)
}

function Get-ResultField {
    param([string]$Output, [string]$Name)
    $match = [regex]::Match($Output, '(?m)^' + [regex]::Escape($Name) + ': (?<value>.+)\r?$')
    if (-not $match.Success) { throw "Result field '$Name' is missing.`n$Output" }
    return $match.Groups['value'].Value.Trim()
}

function Invoke-Packet {
    param([string[]]$Arguments, [bool]$ShouldPass = $true, [string]$MustNotContain)
    $output = & pwsh -NoProfile -File $packetScript @Arguments -RepositoryRoot $temporaryRepository 2>&1 | Out-String
    $didPass = $LASTEXITCODE -eq 0
    if ($didPass -ne $ShouldPass) { throw "Reconciliation packet fixture produced the wrong result.`n$output" }
    if (-not [string]::IsNullOrEmpty($MustNotContain) -and $output.Contains($MustNotContain)) { throw 'Reconciliation packet fixture disclosed prohibited remote or command text.' }
    $script:checksPassed++
    return $output
}

function New-StateText {
    param([string]$Stage, [string]$ReviewOutcome, [string]$ManifestPathValue, [string]$ManifestIdValue, [string]$BaselineValue, [string]$AcceptedId)
    return @"
---
id: HANDOFF-KNOWLEDGE-WORKFLOW
type: workflow-state
status: accepted
scope: Reconciliation packet test
authority: Test
workflow_state: $Stage
workflow_id: $workflowId
round: 1
objective: Reconcile test histories
developer_worker: systems-knowledge-developer
reviewer_worker: systems-coherence-reviewer
review_outcome: $ReviewOutcome
change_manifest_path: $ManifestPathValue
change_manifest_id: $ManifestIdValue
change_manifest_baseline: $BaselineValue
last_completed_workflow_id: none
updated: 2099-01-01
last_reviewed: 2099-01-01
---

# Knowledge Workflow State

accepted_manifest_id: $AcceptedId
"@
}

function Invoke-NegativeRecorder {
    param([string]$Name, [hashtable]$Parameters)
    $mainBefore = (Invoke-TestGit -Arguments @('rev-parse', 'refs/heads/main')).Trim()
    $otherBeforeResult = @(& git -C $temporaryRepository rev-parse --verify refs/heads/other 2>$null)
    $otherBefore = if ($LASTEXITCODE -eq 0) { $otherBeforeResult -join '' } else { 'None' }
    $failed = $false
    try { $null = & $recordScript @Parameters 2>&1 | Out-String } catch { $failed = $true }
    if (-not $failed) { throw "Negative recorder fixture '$Name' unexpectedly succeeded." }
    $mainAfter = (Invoke-TestGit -Arguments @('rev-parse', 'refs/heads/main')).Trim()
    $otherAfterResult = @(& git -C $temporaryRepository rev-parse --verify refs/heads/other 2>$null)
    $otherAfter = if ($LASTEXITCODE -eq 0) { $otherAfterResult -join '' } else { 'None' }
    $staged = Invoke-TestGit -Arguments @('diff', '--cached', '--name-only', '--')
    if ($mainAfter -ne $mainBefore -or $otherAfter -ne $otherBefore -or -not [string]::IsNullOrWhiteSpace($staged)) {
        throw "Negative recorder fixture '$Name' changed a ref or the index."
    }
    $script:checksPassed++
}

function Invoke-ConflictClassFixture {
    param([ValidateSet('add-add', 'binary', 'rename-rename', 'directory-file')][string]$Kind)
    $fixture = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-conflict-class-' + [guid]::NewGuid().ToString('N'))
    function Git-Fixture([string[]]$Arguments) {
        $result = @(& git -C $fixture @Arguments 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Conflict fixture Git failure for $Kind.`n$($result -join "`n")" }
        return (@($result) -join "`n")
    }
    function Write-Fixture([string]$Path, [string]$Text) {
        $full = Join-Path $fixture $Path; $null = New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force
        [System.IO.File]::WriteAllText($full, $Text, $utf8)
    }
    try {
        $null = New-Item -ItemType Directory -Path $fixture -Force
        Initialize-IsolatedTestRepository -Path $fixture; $null = Git-Fixture @('config', 'user.name', 'Conflict Test'); $null = Git-Fixture @('config', 'user.email', 'conflict@example.invalid')
        Write-Fixture '.keep' "base`n"
        if ($Kind -eq 'binary') { $path = Join-Path $fixture 'docs/data.bin'; $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force; [System.IO.File]::WriteAllBytes($path, [byte[]](0,1,2,0)) }
        if ($Kind -eq 'rename-rename') { Write-Fixture 'docs/original.md' "rename source`n" }
        $null = Git-Fixture @('add', '-A', '--', '.'); $null = Git-Fixture @('commit', '-q', '-m', 'base'); $baseId = (Git-Fixture @('rev-parse', 'HEAD')).Trim()
        switch ($Kind) {
            'add-add' { Write-Fixture 'docs/collision.md' "local`n" }
            'binary' { [System.IO.File]::WriteAllBytes((Join-Path $fixture 'docs/data.bin'), [byte[]](0,3,2,0)) }
            'rename-rename' { Move-Item -LiteralPath (Join-Path $fixture 'docs/original.md') -Destination (Join-Path $fixture 'docs/local-name.md') }
            'directory-file' { Write-Fixture 'docs/node' "local file`n" }
        }
        $null = Git-Fixture @('add', '-A', '--', '.'); $null = Git-Fixture @('commit', '-q', '-m', 'local'); $localId = (Git-Fixture @('rev-parse', 'HEAD')).Trim()
        $null = Git-Fixture @('switch', '-q', '-c', 'remote-fixture', $baseId)
        switch ($Kind) {
            'add-add' { Write-Fixture 'docs/collision.md' "remote`n" }
            'binary' { [System.IO.File]::WriteAllBytes((Join-Path $fixture 'docs/data.bin'), [byte[]](0,4,2,0)) }
            'rename-rename' { Move-Item -LiteralPath (Join-Path $fixture 'docs/original.md') -Destination (Join-Path $fixture 'docs/remote-name.md') }
            'directory-file' { Write-Fixture 'docs/node/child.md' "remote directory child`n" }
        }
        $null = Git-Fixture @('add', '-A', '--', '.'); $null = Git-Fixture @('commit', '-q', '-m', 'remote'); $remoteId = (Git-Fixture @('rev-parse', 'HEAD')).Trim()
        $url = 'git@example.invalid:conflict-fixture.git'; $fingerprint = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($url))).ToLowerInvariant()
        $output = & pwsh -NoProfile -File $packetScript -Action CreateAssessment -RepositoryRoot $fixture -RemoteName origin -RemoteUrlSafe $url -RemoteUrlFingerprint $fingerprint -LocalBranch main -RemoteBranch main -LocalParent $localId -RemoteParent $remoteId 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw "Conflict fixture packet failed for $Kind.`n$output" }
        $path = Get-ResultField -Output $output -Name 'packet_path'; $document = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
        $expectedPaths = switch ($Kind) {
            'add-add' { @('docs/collision.md') }
            'binary' { @('docs/data.bin') }
            'rename-rename' { @('docs/local-name.md', 'docs/original.md', 'docs/remote-name.md') }
            'directory-file' { @("docs/node~$localId") }
        }
        if ((@($document.payload.conflict_paths) -join "`n") -ne (@($expectedPaths) -join "`n")) {
            throw "Structured conflict evidence for $Kind was not exact. Actual: $(@($document.payload.conflict_paths) -join ', ')"
        }
        $script:checksPassed++
    } finally { Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue }
}

function Invoke-CustomMergeDriverFixture {
    $fixture = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-custom-merge-driver-' + [guid]::NewGuid().ToString('N'))
    $marker = Join-Path $fixture 'driver-marker.txt'
    $secret = 'secret-custom-merge-driver'
    function Git-DriverFixture([string[]]$Arguments) {
        $result = @(& git -C $fixture @Arguments 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Custom driver fixture Git failure.`n$($result -join "`n")" }
        return (@($result) -join "`n")
    }
    function Write-DriverFixture([string]$Path, [string]$Text) {
        $full = Join-Path $fixture $Path
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force
        [System.IO.File]::WriteAllText($full, $Text, $utf8)
    }
    try {
        $null = New-Item -ItemType Directory -Path $fixture -Force
        Initialize-IsolatedTestRepository -Path $fixture
        $null = Git-DriverFixture @('config', 'user.name', 'Driver Test')
        $null = Git-DriverFixture @('config', 'user.email', 'driver@example.invalid')
        Write-DriverFixture '.gitattributes' "*.md merge=marker`n"
        Write-DriverFixture 'docs/shared.md' "base`n"
        $null = Git-DriverFixture @('add', '-A', '--', '.')
        $null = Git-DriverFixture @('commit', '-q', '-m', 'base')
        $baseId = (Git-DriverFixture @('rev-parse', 'HEAD')).Trim()
        Write-DriverFixture 'docs/shared.md' "local`n"
        $null = Git-DriverFixture @('commit', '-qam', 'local')
        $localId = (Git-DriverFixture @('rev-parse', 'HEAD')).Trim()
        $null = Git-DriverFixture @('switch', '-q', '-c', 'remote-fixture', $baseId)
        Write-DriverFixture 'docs/shared.md' "remote`n"
        $null = Git-DriverFixture @('commit', '-qam', 'remote')
        $remoteId = (Git-DriverFixture @('rev-parse', 'HEAD')).Trim()
        $driver = "pwsh -NoProfile -Command `"[IO.File]::WriteAllText('$($marker.Replace("'", "''"))','$secret')`""
        $null = Git-DriverFixture @('config', 'merge.marker.driver', $driver)
        $url = 'git@example.invalid:driver-fixture.git'
        $fingerprint = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($url))).ToLowerInvariant()
        $output = & pwsh -NoProfile -File $packetScript -Action CreateAssessment -RepositoryRoot $fixture -RemoteName origin -RemoteUrlSafe $url -RemoteUrlFingerprint $fingerprint -LocalBranch main -RemoteBranch main -LocalParent $localId -RemoteParent $remoteId 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) { throw 'Active custom merge driver was not rejected.' }
        if (Test-Path -LiteralPath $marker) { throw 'Rejected custom merge driver executed its marker command.' }
        if ($output.Contains($secret)) { throw 'Custom merge driver rejection disclosed command text.' }
        $script:checksPassed++
        $null = Git-DriverFixture @('config', '--unset-all', 'merge.marker.driver')
        $output = & pwsh -NoProfile -File $packetScript -Action CreateAssessment -RepositoryRoot $fixture -RemoteName origin -RemoteUrlSafe $url -RemoteUrlFingerprint $fingerprint -LocalBranch main -RemoteBranch main -LocalParent $localId -RemoteParent $remoteId 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) { throw 'Custom .gitattributes merge selection was not rejected without a configured driver.' }
        if (Test-Path -LiteralPath $marker) { throw 'Custom attribute-only rejection unexpectedly executed a marker.' }
        $script:checksPassed++
    } finally {
        Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-TemplateIsolationFixture {
    param([ValidateSet('union', 'custom')][string]$Kind)
    $fixture = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-template-isolation-' + [guid]::NewGuid().ToString('N'))
    $initializerTemplate = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-template-' + [guid]::NewGuid().ToString('N'))
    $maliciousTemplate = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-malicious-template-' + [guid]::NewGuid().ToString('N'))
    $marker = Join-Path $fixture 'template-driver-marker.txt'
    function Git-TemplateFixture([string[]]$Arguments) {
        $result = @(& git -C $fixture @Arguments 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Template fixture Git failure for $Kind.`n$($result -join "`n")" }
        return (@($result) -join "`n")
    }
    function Write-TemplateFixture([string]$Path, [string]$Text) {
        $full = Join-Path $fixture $Path
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $full) -Force
        [System.IO.File]::WriteAllText($full, $Text, $utf8)
    }
    $previousTemplate = $env:GIT_TEMPLATE_DIR
    try {
        $null = New-Item -ItemType Directory -Path $fixture, $initializerTemplate, (Join-Path $maliciousTemplate 'info'), (Join-Path $maliciousTemplate 'hooks') -Force
        if (@([System.IO.Directory]::EnumerateFileSystemEntries($initializerTemplate)).Count -ne 0) { throw 'Template fixture initializer is not empty.' }
        Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue
        $initOutput = @(& git -c init.templateDir= init -q -b main "--template=$initializerTemplate" $fixture 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Could not initialize template-isolation fixture.`n$($initOutput -join "`n")" }
        $null = Git-TemplateFixture @('config', 'user.name', 'Template Isolation Test')
        $null = Git-TemplateFixture @('config', 'user.email', 'template@example.invalid')
        Write-TemplateFixture 'docs/shared.md' "base`n"
        $null = Git-TemplateFixture @('add', '-A', '--', '.')
        $null = Git-TemplateFixture @('commit', '-q', '-m', 'base')
        $baseId = (Git-TemplateFixture @('rev-parse', 'HEAD')).Trim()
        Write-TemplateFixture 'docs/shared.md' "local`n"
        $null = Git-TemplateFixture @('commit', '-qam', 'local')
        $localId = (Git-TemplateFixture @('rev-parse', 'HEAD')).Trim()
        $null = Git-TemplateFixture @('switch', '-q', '-c', 'remote-fixture', $baseId)
        Write-TemplateFixture 'docs/shared.md' "remote`n"
        $null = Git-TemplateFixture @('commit', '-qam', 'remote')
        $remoteId = (Git-TemplateFixture @('rev-parse', 'HEAD')).Trim()

        $attributeValue = if ($Kind -eq 'union') { '*.md merge=union' } else { '*.md merge=marker' }
        [System.IO.File]::WriteAllText((Join-Path $maliciousTemplate 'info/attributes'), "$attributeValue`n", $utf8)
        $hookPath = Join-Path $maliciousTemplate 'hooks/query-fsmonitor'
        [System.IO.File]::WriteAllText($hookPath, "#!/bin/sh`nprintf executed > template-driver-marker.txt`n", $utf8)
        if (-not $IsWindows) {
            [System.IO.File]::SetUnixFileMode($hookPath, [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::UserExecute)
        }
        if ($Kind -eq 'custom') {
            $driverCommand = "pwsh -NoProfile -Command `"[IO.File]::WriteAllText('$($marker.Replace("'", "''"))','executed')`""
            [System.IO.File]::WriteAllText((Join-Path $maliciousTemplate 'config'), "[merge `"marker`"]`n`tdriver = $driverCommand`n", $utf8)
        }

        $null = Git-TemplateFixture @('config', 'init.templateDir', $maliciousTemplate)
        $env:GIT_TEMPLATE_DIR = $maliciousTemplate
        $url = 'git@example.invalid:template-fixture.git'
        $fingerprint = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($url))).ToLowerInvariant()
        $output = & pwsh -NoProfile -File $packetScript -Action CreateAssessment -RepositoryRoot $fixture -RemoteName origin -RemoteUrlSafe $url -RemoteUrlFingerprint $fingerprint -LocalBranch main -RemoteBranch main -LocalParent $localId -RemoteParent $remoteId 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { throw "Template-isolation packet failed for $Kind.`n$output" }
        $packetPath = Get-ResultField -Output $output -Name 'packet_path'
        $document = Get-Content -Raw -LiteralPath $packetPath | ConvertFrom-Json
        if ((@($document.payload.conflict_paths) -join "`n") -ne 'docs/shared.md') {
            throw "Inherited $Kind template policy changed the exact conflict set."
        }
        if (Test-Path -LiteralPath $marker) { throw "Inherited $Kind template policy executed a marker command." }
        $script:checksPassed++
    } finally {
        if ($null -eq $previousTemplate) { Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue } else { $env:GIT_TEMPLATE_DIR = $previousTemplate }
        Remove-Item -LiteralPath $fixture, $initializerTemplate, $maliciousTemplate -Recurse -Force -ErrorAction SilentlyContinue
    }
}

try {
    $null = New-Item -ItemType Directory -Path $temporaryRepository -Force
    Initialize-IsolatedTestRepository -Path $temporaryRepository
    $null = Invoke-TestGit -Arguments @('config', 'user.name', 'Reconciliation Test')
    $null = Invoke-TestGit -Arguments @('config', 'user.email', 'reconciliation@example.invalid')
    $null = Invoke-TestGit -Arguments @('config', 'core.autocrlf', 'false')
    Write-TestFile -RelativePath 'docs/shared.md' -Content "base`n"
    Write-TestFile -RelativePath 'docs/old-name.md' -Content "renamed upstream authority`n"
    Write-TestFile -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' -Content (New-StateText -Stage idle -ReviewOutcome none -ManifestPathValue none -ManifestIdValue none -BaselineValue none -AcceptedId None)
    $null = Invoke-TestGit -Arguments @('add', '-A', '--', '.')
    $null = Invoke-TestGit -Arguments @('commit', '-q', '-m', 'base')
    $base = (Invoke-TestGit -Arguments @('rev-parse', 'HEAD')).Trim()

    Write-TestFile -RelativePath 'docs/local.md' -Content "local accepted knowledge`n"
    Write-TestFile -RelativePath 'docs/shared.md' -Content "local version`n"
    $null = Invoke-TestGit -Arguments @('add', '--', 'docs/local.md', 'docs/shared.md')
    $null = Invoke-TestGit -Arguments @('commit', '-q', '-m', 'local')
    $localParent = (Invoke-TestGit -Arguments @('rev-parse', 'HEAD')).Trim()

    $null = Invoke-TestGit -Arguments @('switch', '-q', '-c', 'remote-fixture', $base)
    Write-TestFile -RelativePath 'docs/upstream.md' -Content "# ADR-0002: Upstream authority`n`n- **Status:** Accepted`n- **Related work:** WG-002`n"
    Write-TestFile -RelativePath 'docs/shared.md' -Content "remote version`n"
    Move-Item -LiteralPath (Join-Path $temporaryRepository 'docs/old-name.md') -Destination (Join-Path $temporaryRepository 'docs/new-name.md')
    Write-TestFile -RelativePath 'docs/fenced-example.md' -Content "# Draft`n`n```yaml`nstatus: accepted`n``` `n"
    Write-TestFile -RelativePath 'docs/draft-example.md' -Content "---`nid: DRAFT-001`ntype: test`nstatus: draft`nscope: Test`nauthority: Test`nlast_reviewed: 2099-01-01`n---`n`nExample:`nstatus: accepted`n"
    Write-TestFile -RelativePath 'docs/yaml-accepted.md' -Content "---`nid: YAML-001`ntype: test`nstatus: accepted`nscope: Test`nauthority: Test`nlast_reviewed: 2099-01-01`n---`n"
    $null = Invoke-TestGit -Arguments @('add', '-A', '--', 'docs')
    $null = Invoke-TestGit -Arguments @('commit', '-q', '-m', 'remote')
    $remoteParent = (Invoke-TestGit -Arguments @('rev-parse', 'HEAD')).Trim()
    $null = Invoke-TestGit -Arguments @('switch', '-q', 'main')
    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/remotes/origin/main', $remoteParent)
    $remoteUrl = 'git@example.invalid:state-of-consequence.git'
    $null = Invoke-TestGit -Arguments @('remote', 'add', 'origin', $remoteUrl)
    $remoteFingerprint = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($remoteUrl))).ToLowerInvariant()

    $assessmentArguments = @(
        '-Action', 'CreateAssessment', '-RemoteName', 'origin', '-RemoteUrlSafe', $remoteUrl,
        '-RemoteUrlFingerprint', $remoteFingerprint, '-LocalBranch', 'main', '-RemoteBranch', 'main',
        '-LocalParent', $localParent, '-RemoteParent', $remoteParent
    )
    $assessmentOutput = Invoke-Packet -Arguments $assessmentArguments
    $assessmentPath = Get-ResultField -Output $assessmentOutput -Name 'packet_path'
    $assessmentId = Get-ResultField -Output $assessmentOutput -Name 'packet_id'
    $repeatOutput = Invoke-Packet -Arguments $assessmentArguments
    if ((Get-ResultField -Output $repeatOutput -Name 'packet_id') -ne $assessmentId) { throw 'Assessment packet identity is not deterministic.' }
    $checksPassed++
    $null = Invoke-Packet -Arguments @('-Action', 'VerifyAssessment', '-PacketPath', $assessmentPath)
    $assessmentDocument = Get-Content -Raw -LiteralPath $assessmentPath | ConvertFrom-Json
    $upstreamCandidate = @($assessmentDocument.payload.upstream_accepted_knowledge_candidates | Where-Object path -eq 'docs/upstream.md')[0]
    $manualCandidate = @($assessmentDocument.payload.upstream_accepted_knowledge_candidates | Where-Object path -eq 'docs/shared.md')[0]
    $expectedChangedPaths = @('docs/draft-example.md', 'docs/fenced-example.md', 'docs/local.md', 'docs/new-name.md', 'docs/old-name.md', 'docs/shared.md', 'docs/upstream.md', 'docs/yaml-accepted.md')
    $expectedConflicts = @('docs/shared.md')
    $renameSource = @($assessmentDocument.payload.upstream_accepted_knowledge_candidates | Where-Object path -eq 'docs/old-name.md')[0]
    $renameDestination = @($assessmentDocument.payload.upstream_accepted_knowledge_candidates | Where-Object path -eq 'docs/new-name.md')[0]
    $fencedCandidate = @($assessmentDocument.payload.upstream_accepted_knowledge_candidates | Where-Object path -eq 'docs/fenced-example.md')[0]
    $draftCandidate = @($assessmentDocument.payload.upstream_accepted_knowledge_candidates | Where-Object path -eq 'docs/draft-example.md')[0]
    $yamlCandidate = @($assessmentDocument.payload.upstream_accepted_knowledge_candidates | Where-Object path -eq 'docs/yaml-accepted.md')[0]
    $candidatePaths = @($assessmentDocument.payload.upstream_accepted_knowledge_candidates | ForEach-Object { [string]$_.path })
    $expectedCandidatePaths = @('docs/draft-example.md', 'docs/fenced-example.md', 'docs/new-name.md', 'docs/old-name.md', 'docs/shared.md', 'docs/upstream.md', 'docs/yaml-accepted.md')
    $remoteStateEvidence = @($assessmentDocument.payload.remote_changed_path_states | ForEach-Object { "$($_.side)|$($_.status)|$($_.path)" })
    $expectedRemoteStateEvidence = @('remote|A|docs/draft-example.md', 'remote|A|docs/fenced-example.md', 'remote|A|docs/new-name.md', 'remote|D|docs/old-name.md', 'remote|M|docs/shared.md', 'remote|A|docs/upstream.md', 'remote|A|docs/yaml-accepted.md')
    if ((@($assessmentDocument.payload.changed_paths) -join "`n") -ne ($expectedChangedPaths -join "`n") -or
        (@($assessmentDocument.payload.conflict_paths) -join "`n") -ne ($expectedConflicts -join "`n") -or
        (@($assessmentDocument.payload.governed_knowledge_paths) -join "`n") -ne ($expectedChangedPaths -join "`n") -or
        ($candidatePaths -join "`n") -ne ($expectedCandidatePaths -join "`n") -or
        ($remoteStateEvidence -join "`n") -ne ($expectedRemoteStateEvidence -join "`n") -or
        @($assessmentDocument.payload.upstream_accepted_knowledge_candidates).Count -ne 7 -or
        $upstreamCandidate.classification -ne 'accepted-metadata-detected' -or 'ADR-0002' -notin @($upstreamCandidate.authority_ids) -or 'WG-002' -notin @($upstreamCandidate.authority_ids) -or
        $manualCandidate.manual_classification_required -ne 'yes' -or $renameSource.classification -ne 'remote-deleted-governed-path' -or $renameSource.change_status -ne 'D' -or
        $renameDestination.change_status -ne 'A' -or $fencedCandidate.manual_classification_required -ne 'yes' -or $draftCandidate.manual_classification_required -ne 'yes' -or
        $yamlCandidate.classification -ne 'accepted-metadata-detected' -or 'YAML-001' -notin @($yamlCandidate.authority_ids)) {
        throw 'Assessment did not preserve exact conflicts or mechanically classify real upstream-style accepted and manual knowledge candidates.'
    }
    $checksPassed++

    $tamperedPath = Join-Path (Split-Path -Parent $assessmentPath) ('0' * 64 + '.json')
    $tampered = Get-Content -Raw -LiteralPath $assessmentPath | ConvertFrom-Json
    $tampered.payload.changed_paths = @('docs/omitted.md')
    [System.IO.File]::WriteAllText($tamperedPath, ($tampered | ConvertTo-Json -Depth 12), $utf8)
    $null = Invoke-Packet -Arguments @('-Action', 'VerifyAssessment', '-PacketPath', $tamperedPath) -ShouldPass $false

    foreach ($mutation in @('omit-candidate', 'alter-classification', 'omit-conflict', 'omit-changed-path', 'alter-path-state')) {
        $mutated = Get-Content -Raw -LiteralPath $assessmentPath | ConvertFrom-Json
        if ($mutation -eq 'omit-candidate') {
            $mutated.payload.upstream_accepted_knowledge_candidates = @($mutated.payload.upstream_accepted_knowledge_candidates | Select-Object -Skip 1)
        } elseif ($mutation -eq 'alter-classification') {
            $mutated.payload.upstream_accepted_knowledge_candidates[0].classification = 'accepted-metadata-detected'
            $mutated.payload.upstream_accepted_knowledge_candidates[0].manual_classification_required = 'no'
        } elseif ($mutation -eq 'omit-conflict') {
            $mutated.payload.conflict_paths = @()
        } elseif ($mutation -eq 'omit-changed-path') {
            $mutated.payload.changed_paths = @($mutated.payload.changed_paths | Where-Object { $_ -ne 'docs/old-name.md' })
        } else {
            @($mutated.payload.remote_changed_path_states | Where-Object path -eq 'docs/old-name.md')[0].status = 'M'
        }
        $payloadJson = $mutated.payload | ConvertTo-Json -Depth 12 -Compress
        $newId = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($payloadJson))).ToLowerInvariant()
        $mutated.packet_id = $newId
        $mutatedPath = Join-Path (Split-Path -Parent $assessmentPath) "$newId.json"
        [System.IO.File]::WriteAllText($mutatedPath, ($mutated | ConvertTo-Json -Depth 12), $utf8)
        $null = Invoke-Packet -Arguments @('-Action', 'VerifyAssessment', '-PacketPath', $mutatedPath) -ShouldPass $false
    }
    foreach ($conflictKind in @('add-add', 'binary', 'rename-rename', 'directory-file')) { Invoke-ConflictClassFixture -Kind $conflictKind }
    Invoke-CustomMergeDriverFixture
    Invoke-TemplateIsolationFixture -Kind union
    Invoke-TemplateIsolationFixture -Kind custom

    foreach ($safeUrl in @('https://example.invalid/repository.git', 'ssh://git@example.invalid/repository.git', 'git://example.invalid/repository.git', 'file:///C:/repository.git', 'git@example.invalid:repository.git', '../repository.git', $rootedLocalUrl)) {
        $fingerprint = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($safeUrl))).ToLowerInvariant()
        $null = Invoke-Packet -Arguments @('-Action', 'CreateAssessment', '-RemoteName', 'origin', '-RemoteUrlSafe', $safeUrl, '-RemoteUrlFingerprint', $fingerprint, '-LocalBranch', 'main', '-RemoteBranch', 'main', '-LocalParent', $localParent, '-RemoteParent', $remoteParent)
    }
    foreach ($unsafeUrl in @('https://example.invalid/repository.git;secret-token=value', 'https://example.invalid/repository.git%3Bsecret-token=value', 'https://example.invalid/repository.git?secret-token=value', 'https://example.invalid/repository.git#secret-token=value', 'ssh:///secret-token/repository.git', 'https://user:secret-token@example.invalid/repository.git')) {
        $fingerprint = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($unsafeUrl))).ToLowerInvariant()
        $null = Invoke-Packet -Arguments @('-Action', 'CreateAssessment', '-RemoteName', 'origin', '-RemoteUrlSafe', $unsafeUrl, '-RemoteUrlFingerprint', $fingerprint, '-LocalBranch', 'main', '-RemoteBranch', 'main', '-LocalParent', $localParent, '-RemoteParent', $remoteParent) -ShouldPass $false -MustNotContain 'secret-token'
    }

    Write-TestFile -RelativePath 'docs/upstream.md' -Content "# ADR-0002: Upstream authority`n`n- **Status:** Accepted`n- **Related work:** WG-002`n"
    Write-TestFile -RelativePath 'docs/shared.md' -Content "reviewed integrated version`n"
    Write-TestFile -RelativePath 'docs/integration.md' -Content "reviewed integration`n"
    Remove-Item -LiteralPath (Join-Path $temporaryRepository 'docs/old-name.md') -Force
    Write-TestFile -RelativePath 'docs/new-name.md' -Content "renamed upstream authority`n"
    Write-TestFile -RelativePath 'docs/fenced-example.md' -Content "# Draft`n`nExample contains accepted-looking text only.`n"
    Write-TestFile -RelativePath 'docs/draft-example.md' -Content "---`nid: DRAFT-001`ntype: test`nstatus: draft`nscope: Test`nauthority: Test`nlast_reviewed: 2099-01-01`n---`n"
    Write-TestFile -RelativePath 'docs/yaml-accepted.md' -Content "---`nid: YAML-001`ntype: test`nstatus: accepted`nscope: Test`nauthority: Test`nlast_reviewed: 2099-01-01`n---`n"
    Write-TestFile -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' -Content (New-StateText -Stage reviewing -ReviewOutcome none -ManifestPathValue none -ManifestIdValue none -BaselineValue none -AcceptedId None)
    $manifestPath = Join-Path $temporaryRepository '.git/codex/accepted-change-manifests/reconciliation.json'
    $manifestOutput = & pwsh -NoProfile -File $manifestScript -Action Create -WorkflowId $workflowId -ManifestPath $manifestPath -RepositoryRoot $temporaryRepository 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Could not create reconciliation manifest.`n$manifestOutput" }
    $manifestId = Get-ResultField -Output $manifestOutput -Name 'manifest_id'
    $candidateTree = Get-ResultField -Output $manifestOutput -Name 'candidate_tree_oid'
    Write-TestFile -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md' -Content (New-StateText -Stage finalizing -ReviewOutcome accept -ManifestPathValue $manifestPath -ManifestIdValue $manifestId -BaselineValue $localParent -AcceptedId $manifestId)
    $bindOutput = Invoke-Packet -Arguments @('-Action', 'BindCandidate', '-PacketPath', $assessmentPath, '-WorkflowId', $workflowId, '-ManifestPath', $manifestPath, '-ManifestId', $manifestId, '-CommitMessage', 'Merge reviewed upstream knowledge')
    $candidatePacketPath = Get-ResultField -Output $bindOutput -Name 'packet_path'
    if ((Get-ResultField -Output $bindOutput -Name 'candidate_tree_oid') -ne $candidateTree) { throw 'Bound packet lost the reviewed candidate tree.' }

    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    [System.IO.File]::WriteAllBytes((Join-Path $temporaryRepository $manifest.payload.final_workflow_state_path), [Convert]::FromBase64String($manifest.payload.final_workflow_state_base64))
    $null = Invoke-Packet -Arguments @('-Action', 'VerifyCandidate', '-PacketPath', $candidatePacketPath, '-ManifestPath', $manifestPath)

    $manifestPaths = @($manifest.payload.entries | ForEach-Object { [string]$_.path })
    $recordParameters = @{
        WorkflowId = $workflowId
        RepositoryRoot = $temporaryRepository
        PacketPath = $candidatePacketPath
        PacketId = Get-ResultField -Output $bindOutput -Name 'packet_id'
        ManifestPath = $manifestPath
        ManifestId = $manifestId
        CandidateTreeOid = $candidateTree
        LocalBranch = 'main'
        RemoteName = 'origin'
        ExpectedRemoteUrl = $remoteUrl
        ExpectedRemoteUrlFingerprint = $remoteFingerprint
        RemoteBranch = 'main'
        PushRefspec = 'refs/heads/main:refs/heads/main'
        LocalParent = $localParent
        RemoteParent = $remoteParent
        CommitMessage = 'Merge reviewed upstream knowledge'
        AuthorizedPaths = $manifestPaths
    }
    $null = Invoke-TestGit -Arguments @('branch', 'other', $localParent)
    $wrong = $recordParameters.Clone(); $wrong.LocalBranch = 'other'; $wrong.PushRefspec = 'refs/heads/other:refs/heads/main'; Invoke-NegativeRecorder -Name 'wrong local branch' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.WorkflowId = 'KW-20990101-999'; Invoke-NegativeRecorder -Name 'wrong workflow ID' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.ExpectedRemoteUrl = 'https://example.invalid/wrong.git'; $wrong.ExpectedRemoteUrlFingerprint = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($wrong.ExpectedRemoteUrl))).ToLowerInvariant(); Invoke-NegativeRecorder -Name 'wrong remote URL' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.ExpectedRemoteUrlFingerprint = ('0' * 64); Invoke-NegativeRecorder -Name 'wrong remote URL fingerprint' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.RemoteName = 'upstream'; Invoke-NegativeRecorder -Name 'wrong remote name' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.RemoteBranch = 'other'; $wrong.PushRefspec = 'refs/heads/main:refs/heads/other'; Invoke-NegativeRecorder -Name 'wrong remote branch' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.PushRefspec = 'refs/heads/main:refs/heads/other'; Invoke-NegativeRecorder -Name 'wrong refspec' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.LocalParent = $base; Invoke-NegativeRecorder -Name 'wrong local parent' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.RemoteParent = $base; Invoke-NegativeRecorder -Name 'wrong remote parent' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.CandidateTreeOid = (Invoke-TestGit -Arguments @('rev-parse', "$localParent^{tree}")).Trim(); Invoke-NegativeRecorder -Name 'wrong candidate tree' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.ManifestId = '0000000000000000000000000000000000000000000000000000000000000000'; Invoke-NegativeRecorder -Name 'wrong manifest ID' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.PacketId = '0000000000000000000000000000000000000000000000000000000000000000'; Invoke-NegativeRecorder -Name 'wrong packet ID' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.CommitMessage = 'Unreviewed message'; Invoke-NegativeRecorder -Name 'wrong merge message' -Parameters $wrong
    $wrong = $recordParameters.Clone(); $wrong.AuthorizedPaths = @($manifestPaths | Select-Object -Skip 1); Invoke-NegativeRecorder -Name 'wrong authorized path set' -Parameters $wrong
    $recordOutput = & $recordScript @recordParameters 2>&1 | Out-String
    if ($recordOutput -notmatch '(?m)^verified: yes\r?$') { throw "Reviewed merge recorder failed.`n$recordOutput" }
    $mergeCommit = Get-ResultField -Output $recordOutput -Name 'commit_id'
    $checksPassed++
    $parents = (Invoke-TestGit -Arguments @('show', '-s', '--format=%P', $mergeCommit)).Trim()
    if ($parents -ne "$localParent $remoteParent") { throw 'Recorded merge parent order is wrong.' }
    $checksPassed++

    $publishOutput = & pwsh -NoProfile -File $publishScript -RepositoryRoot $temporaryRepository -RemoteName origin -ExpectedRemoteUrl $remoteUrl -LocalBranch main -RemoteBranch main -ExpectedLocalCommit $mergeCommit -ExpectedRemoteCommit $remoteParent -PushRefspec 'refs/heads/main:refs/heads/main' 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $publishOutput -notmatch '(?m)^topology: fast-forward-push\r?$') { throw "Reviewed merge did not produce publishable ancestry.`n$publishOutput" }
    $checksPassed++
} finally {
    Remove-Item -LiteralPath $temporaryRepository -Recurse -Force -ErrorAction SilentlyContinue
}

$expectedChecks = 51
if ($checksPassed -ne $expectedChecks) { throw "Reconciliation packet test count changed: expected $expectedChecks, got $checksPassed." }
Write-Host "Reconciliation packet tests passed: $checksPassed/$expectedChecks." -ForegroundColor Green
