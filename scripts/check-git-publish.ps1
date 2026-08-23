param(
    [ValidateSet('PreTransport', 'VerifyFetched')]
    [string]$Action = 'VerifyFetched',
    [Parameter(Mandatory = $true)]
    [string]$RemoteName,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedRemoteUrl,
    [Parameter(Mandatory = $true)]
    [string]$LocalBranch,
    [Parameter(Mandatory = $true)]
    [string]$RemoteBranch,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedLocalCommit,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedRemoteCommit,
    [Parameter(Mandatory = $true)]
    [string]$PushRefspec,
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

$repositoryRootPath = if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    Split-Path -Parent $PSScriptRoot
} else {
    [System.IO.Path]::GetFullPath($RepositoryRoot)
}
$policyGuardScript = Join-Path $PSScriptRoot 'check-git-executable-policy.ps1'

function Invoke-GitResult {
    param(
        [string[]]$Arguments,
        [int[]]$AllowedExitCodes = @(0)
    )

    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-publish-check-' + [guid]::NewGuid().ToString('N'))
    try {
        $output = @(& git -C $repositoryRootPath -c core.fsmonitor=false @Arguments 2> $stderrPath)
        $exitCode = $LASTEXITCODE
        if ($exitCode -notin $AllowedExitCodes) {
            $standardError = if (Test-Path -LiteralPath $stderrPath) { Get-Content -Raw -LiteralPath $stderrPath } else { '' }
            throw "Git command failed: git $($Arguments -join ' ')`n$standardError$($output -join "`n")"
        }
        return @{
            ExitCode = $exitCode
            Lines = @($output)
            Text = [string]::Join("`n", [string[]]$output)
        }
    } finally {
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Assert-ExecutableGitPolicy {
    $output = & pwsh -NoProfile -File $policyGuardScript -RepositoryRoot $repositoryRootPath 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $output -notmatch '(?m)^authorization_safe: yes\r?$') {
        throw 'Executable Git policy is outside the exact publication authorization.'
    }
}

function Assert-SafeName {
    param(
        [string]$Value,
        [string]$Label
    )

    if ($Value -notmatch '^[A-Za-z0-9._/-]+$' -or $Value.Contains('..') -or $Value.StartsWith('/') -or $Value.EndsWith('/')) {
        throw "$Label '$Value' is not a safe explicit Git name."
    }
}

function Assert-SecretSafeRemoteUrl {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match '[\r\n]') {
        throw 'Remote URL is missing or cannot be handled safely.'
    }
    if ($Value.Contains('::')) { throw 'Remote URL form is prohibited.' }
    if ($Value -match '^(?i:[a-z][a-z0-9+.-]*)://') {
        $uri = $null
        if (-not [uri]::TryCreate($Value, [System.UriKind]::Absolute, [ref]$uri) -or
            $uri.Scheme -notin @('https', 'ssh', 'git', 'file') -or
            ($uri.Scheme -ne 'file' -and [string]::IsNullOrEmpty($uri.Host)) -or
            (($uri.Scheme -ne 'ssh') -and -not [string]::IsNullOrEmpty($uri.UserInfo)) -or
            $uri.UserInfo.Contains(':') -or
            -not [string]::IsNullOrEmpty($uri.Query) -or
            -not [string]::IsNullOrEmpty($uri.Fragment) -or
            $Value.Contains('\\') -or
            $uri.AbsolutePath.Contains(';') -or
            $uri.AbsolutePath -match '(?i)%3b') {
            throw 'Remote URL form is prohibited.'
        }
    } elseif ($Value -match '^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+:[A-Za-z0-9._~/-]+$') {
        return
    } elseif (-not [System.IO.Path]::IsPathRooted($Value) -and $Value -notmatch '^(?:\.{0,2}/)?[A-Za-z0-9._/-]+$') {
        throw 'Remote URL form is prohibited.'
    }
}

function Assert-NoExecutableTransportOverrides {
    param([string]$TargetRemote)

    foreach ($environmentName in @(
        'GIT_SSH_COMMAND', 'GIT_SSH', 'GIT_PROXY_COMMAND', 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY',
        'http_proxy', 'https_proxy', 'all_proxy',
        'GIT_CONFIG_COUNT', 'GIT_CONFIG_PARAMETERS', 'GIT_CONFIG_SYSTEM', 'GIT_CONFIG_GLOBAL'
    )) {
        if (-not [string]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($environmentName))) {
            throw 'Executable or inherited transport environment configuration is prohibited.'
        }
    }

    $keyPattern = '^(?i:core\.(?:sshcommand|gitproxy)|http\.proxy|url\..*\.(?:insteadof|pushinsteadof)|remote\.' +
        [regex]::Escape($TargetRemote) + '\.(?:proxy|receivepack|uploadpack|vcs))$'
    $configuredKeys = @((Invoke-GitResult -Arguments @('config', '--name-only', '--list')).Lines | Where-Object { [string]$_ -match $keyPattern })
    if ($configuredKeys.Count -ne 0) {
        throw 'Executable or rewriting Git transport configuration is prohibited.'
    }
}

function Get-Sha256Text {
    param([string]$Text)
    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
}

Assert-SafeName -Value $RemoteName -Label 'Remote name'
Assert-SafeName -Value $LocalBranch -Label 'Local branch'
Assert-SafeName -Value $RemoteBranch -Label 'Remote branch'
if ($LocalBranch.StartsWith('refs/') -or $RemoteBranch.StartsWith('refs/')) { throw 'Branch values must be names below refs/heads, not full ref strings.' }
Assert-SecretSafeRemoteUrl -Value $ExpectedRemoteUrl
Assert-ExecutableGitPolicy
Assert-NoExecutableTransportOverrides -TargetRemote $RemoteName
$null = Invoke-GitResult -Arguments @('check-ref-format', "refs/heads/$LocalBranch")
$null = Invoke-GitResult -Arguments @('check-ref-format', "refs/heads/$RemoteBranch")

if ($ExpectedLocalCommit -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$' -or $ExpectedRemoteCommit -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') {
    throw 'Expected local and remote commits must be full lowercase object IDs.'
}
$expectedRefspec = "refs/heads/$LocalBranch`:refs/heads/$RemoteBranch"
if ($PushRefspec -ne $expectedRefspec -or $PushRefspec.StartsWith('+') -or $PushRefspec.Contains('*') -or $PushRefspec -match '^:') {
    throw "Push refspec must be the exact normal non-force branch refspec '$expectedRefspec'."
}

$insideWorkTree = (Invoke-GitResult -Arguments @('rev-parse', '--is-inside-work-tree')).Text.Trim()
if ($insideWorkTree -ne 'true') {
    throw 'Publish preflight requires a non-bare Git worktree.'
}
$status = (Invoke-GitResult -Arguments @('status', '--porcelain=v1', '--untracked-files=all')).Text
if (-not [string]::IsNullOrWhiteSpace($status)) {
    throw 'Publish preflight requires an exactly clean worktree and index.'
}

$currentBranch = (Invoke-GitResult -Arguments @('symbolic-ref', '--quiet', '--short', 'HEAD')).Text.Trim()
if ($currentBranch -ne $LocalBranch) {
    throw "Current branch '$currentBranch' does not match assigned local branch '$LocalBranch'."
}
$localCommit = (Invoke-GitResult -Arguments @('rev-parse', '--verify', "refs/heads/$LocalBranch^{commit}")).Text.Trim()
if ($localCommit -ne $ExpectedLocalCommit) {
    throw "Local branch resolves to '$localCommit', not expected commit '$ExpectedLocalCommit'."
}

$configuredFetchUrls = @((Invoke-GitResult -Arguments @('config', '--get-all', "remote.$RemoteName.url") -AllowedExitCodes @(0, 1)).Lines | ForEach-Object { [string]$_ })
$configuredPushUrls = @((Invoke-GitResult -Arguments @('config', '--get-all', "remote.$RemoteName.pushurl") -AllowedExitCodes @(0, 1)).Lines | ForEach-Object { [string]$_ })
foreach ($url in @($configuredFetchUrls) + @($configuredPushUrls)) { Assert-SecretSafeRemoteUrl -Value $url }
$fetchUrls = @((Invoke-GitResult -Arguments @('remote', 'get-url', '--all', $RemoteName)).Lines | ForEach-Object { [string]$_ })
$pushUrls = @((Invoke-GitResult -Arguments @('remote', 'get-url', '--push', '--all', $RemoteName)).Lines | ForEach-Object { [string]$_ })
foreach ($url in @($fetchUrls) + @($pushUrls)) { Assert-SecretSafeRemoteUrl -Value $url }
if ($fetchUrls.Count -ne 1 -or $pushUrls.Count -ne 1 -or $fetchUrls[0] -ne $ExpectedRemoteUrl -or $pushUrls[0] -ne $ExpectedRemoteUrl) {
    throw 'The assigned remote must have exactly one fetch URL and one push URL, both exactly matching EXPECTED_REMOTE_URL.'
}

$remoteUrlFingerprint = Get-Sha256Text -Text $ExpectedRemoteUrl
$fetchCommand = "git -c core.hooksPath=<verified-empty-hooks-path> -c fetch.writeCommitGraph=false fetch --no-tags --no-recurse-submodules --no-prune --refmap= -- $RemoteName refs/heads/$RemoteBranch`:refs/remotes/$RemoteName/$RemoteBranch"
if ($Action -eq 'PreTransport') {
    Write-Output 'GIT_PUBLISH_PRETRANSPORT'
    Write-Output "remote_name: $RemoteName"
    Write-Output "remote_url_safe: $ExpectedRemoteUrl"
    Write-Output "remote_url_fingerprint: $remoteUrlFingerprint"
    Write-Output "local_branch: $LocalBranch"
    Write-Output "remote_branch: $RemoteBranch"
    Write-Output "push_refspec: $PushRefspec"
    Write-Output "local_commit: $localCommit"
    Write-Output "fetch_command_proposal: $fetchCommand"
    Write-Output 'transport_authorization_safe: yes'
    exit 0
}

$remoteTrackingRef = "refs/remotes/$RemoteName/$RemoteBranch"
$remoteCommit = (Invoke-GitResult -Arguments @('rev-parse', '--verify', "$remoteTrackingRef^{commit}")).Text.Trim()
if ($remoteCommit -ne $ExpectedRemoteCommit) {
    throw "Fetched remote-tracking ref resolves to '$remoteCommit', not expected commit '$ExpectedRemoteCommit'."
}

$mergeBaseResult = Invoke-GitResult -Arguments @('merge-base', $localCommit, $remoteCommit) -AllowedExitCodes @(0, 1)
$mergeBase = if ($mergeBaseResult.ExitCode -eq 0) { $mergeBaseResult.Text.Trim() } else { 'None' }
$remoteIsAncestor = (Invoke-GitResult -Arguments @('merge-base', '--is-ancestor', $remoteCommit, $localCommit) -AllowedExitCodes @(0, 1)).ExitCode -eq 0
$localIsAncestor = (Invoke-GitResult -Arguments @('merge-base', '--is-ancestor', $localCommit, $remoteCommit) -AllowedExitCodes @(0, 1)).ExitCode -eq 0
$topology = if ($localCommit -eq $remoteCommit) {
    'already-published'
} elseif ($remoteIsAncestor) {
    'fast-forward-push'
} elseif ($localIsAncestor) {
    'behind'
} elseif ($mergeBase -eq 'None') {
    'unrelated'
} else {
    'diverged'
}
$publishReady = $topology -in @('already-published', 'fast-forward-push')
$pushCommand = "git -c core.hooksPath=<verified-empty-hooks-path> -c push.followTags=false -c remote.$RemoteName.mirror=false -c push.default=nothing -c remote.pushDefault= -c branch.$LocalBranch.pushRemote= -c push.autoSetupRemote=false -c push.recurseSubmodules=no -c push.pushOption= -c push.gpgSign=false push --porcelain --no-verify --no-follow-tags --no-signed --recurse-submodules=no -- $RemoteName $PushRefspec"

Write-Output 'GIT_PUBLISH_PREFLIGHT'
Write-Output "remote_name: $RemoteName"
Write-Output "remote_url_safe: $ExpectedRemoteUrl"
Write-Output "remote_url_fingerprint: $remoteUrlFingerprint"
Write-Output "local_branch: $LocalBranch"
Write-Output "remote_branch: $RemoteBranch"
Write-Output "push_refspec: $PushRefspec"
Write-Output "local_commit: $localCommit"
Write-Output "remote_commit: $remoteCommit"
Write-Output "merge_base: $mergeBase"
Write-Output "topology: $topology"
Write-Output "fetch_command_proposal: $fetchCommand"
Write-Output "push_command_proposal: $pushCommand"
Write-Output "publish_ready: $(if ($publishReady) { 'yes' } else { 'no' })"
Write-Output "reconciliation_required: $(if ($publishReady) { 'no' } else { 'yes' })"
