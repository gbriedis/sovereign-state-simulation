$ErrorActionPreference = 'Stop'

$publishChecker = Join-Path $PSScriptRoot 'check-git-publish.ps1'
$temporaryRepository = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-publish-test-' + [guid]::NewGuid().ToString('N'))
$temporaryBareRemote = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-publish-bare-' + [guid]::NewGuid().ToString('N'))
$remoteUrl = 'https://example.invalid/state-of-consequence.git'
$checksPassed = 0
$utf8 = [System.Text.UTF8Encoding]::new($false)
$rootedLocalUrl = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') { 'C:\repository.git' } else { '/tmp/repository.git' }

function Invoke-TestGit {
    param(
        [string[]]$Arguments,
        [int[]]$AllowedExitCodes = @(0)
    )

    $output = @(& git -C $temporaryRepository @Arguments 2>&1)
    if ($LASTEXITCODE -notin $AllowedExitCodes) {
        throw "Test Git command failed: git $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return [string]::Join("`n", [string[]]$output)
}

function Initialize-IsolatedTestRepository {
    $template = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-template-' + [guid]::NewGuid().ToString('N'))
    $previousTemplate = $env:GIT_TEMPLATE_DIR
    try {
        $null = New-Item -ItemType Directory -Path $template -Force
        if (@([System.IO.Directory]::EnumerateFileSystemEntries($template)).Count -ne 0) { throw 'Publication test template is not empty.' }
        Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue
        $output = @(& git -c init.templateDir= init -q -b main "--template=$template" $temporaryRepository 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Could not initialize isolated publication test repository.`n$($output -join "`n")" }
        if ((Test-Path -LiteralPath (Join-Path $temporaryRepository '.git/info/attributes')) -or
            ((Test-Path -LiteralPath (Join-Path $temporaryRepository '.git/hooks')) -and @([System.IO.Directory]::EnumerateFileSystemEntries((Join-Path $temporaryRepository '.git/hooks'))).Count -ne 0)) {
            throw 'Publication test initialization inherited attributes or hooks.'
        }
    } finally {
        if ($null -eq $previousTemplate) { Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue } else { $env:GIT_TEMPLATE_DIR = $previousTemplate }
        Remove-Item -LiteralPath $template -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Initialize-IsolatedBareRepository {
    param([string]$Path)

    $template = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-bare-template-' + [guid]::NewGuid().ToString('N'))
    $previousTemplate = $env:GIT_TEMPLATE_DIR
    try {
        $null = New-Item -ItemType Directory -Path $template -Force
        if (@([System.IO.Directory]::EnumerateFileSystemEntries($template)).Count -ne 0) { throw 'Bare publication test template is not empty.' }
        Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue
        $output = @(& git -c init.templateDir= init -q --bare "--template=$template" $Path 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Could not initialize isolated bare publication remote.`n$($output -join "`n")" }
        if ((Test-Path -LiteralPath (Join-Path $Path 'info/attributes')) -or
            ((Test-Path -LiteralPath (Join-Path $Path 'hooks')) -and @([System.IO.Directory]::EnumerateFileSystemEntries((Join-Path $Path 'hooks'))).Count -ne 0)) {
            throw 'Bare publication test initialization inherited attributes or hooks.'
        }
    } finally {
        if ($null -eq $previousTemplate) { Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue } else { $env:GIT_TEMPLATE_DIR = $previousTemplate }
        Remove-Item -LiteralPath $template -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-PublishFixture {
    param(
        [string]$Name,
        [string]$ExpectedLocal,
    [string]$ExpectedRemote,
    [string]$ExpectedTopology,
    [string]$ExpectedMergeBase,
    [bool]$ShouldPass = $true,
    [string]$ExpectedUrl = $remoteUrl,
    [string]$Refspec = 'refs/heads/main:refs/heads/main',
    [string]$MustNotContain,
    [ValidateSet('PreTransport', 'VerifyFetched')][string]$Action = 'VerifyFetched'
    )

    $output = & pwsh -NoProfile -File $publishChecker `
        -RepositoryRoot $temporaryRepository `
        -Action $Action `
        -RemoteName origin `
        -ExpectedRemoteUrl $ExpectedUrl `
        -LocalBranch main `
        -RemoteBranch main `
        -ExpectedLocalCommit $ExpectedLocal `
        -ExpectedRemoteCommit $ExpectedRemote `
        -PushRefspec $Refspec 2>&1 | Out-String
    $didPass = $LASTEXITCODE -eq 0
    if ($didPass -ne $ShouldPass) {
        throw "Publish preflight fixture '$Name' produced the wrong result.`n$output"
    }
    if (-not [string]::IsNullOrEmpty($MustNotContain) -and $output.Contains($MustNotContain)) {
        throw "Publish preflight fixture '$Name' disclosed prohibited text.`n$output"
    }
    if ($ShouldPass -and $Action -eq 'VerifyFetched' -and $output -notmatch ("(?m)^topology: " + [regex]::Escape($ExpectedTopology) + "\r?$")) {
        throw "Publish preflight fixture '$Name' did not report topology '$ExpectedTopology'.`n$output"
    }
    if ($ShouldPass -and $Action -eq 'VerifyFetched' -and -not [string]::IsNullOrWhiteSpace($ExpectedMergeBase) -and $output -notmatch ("(?m)^merge_base: " + [regex]::Escape($ExpectedMergeBase) + "\r?$")) {
        throw "Publish preflight fixture '$Name' did not report merge base '$ExpectedMergeBase'.`n$output"
    }
    $script:checksPassed++
}

function Invoke-ConfigMarkerFixture {
    param([string]$Name, [string]$Key, [string]$MarkerPath, [string]$Secret)
    $command = "pwsh -NoProfile -Command `"[IO.File]::WriteAllText('$($MarkerPath.Replace("'", "''"))','$Secret')`""
    $null = Invoke-TestGit -Arguments @('config', $Key, $command)
    try {
        Invoke-PublishFixture -Name $Name -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -Action PreTransport -MustNotContain $Secret
        if (Test-Path -LiteralPath $MarkerPath) { throw "Rejected override '$Name' executed its marker command." }
    } finally {
        $null = Invoke-TestGit -Arguments @('config', '--unset-all', $Key) -AllowedExitCodes @(0, 5)
        Remove-Item -LiteralPath $MarkerPath -Force -ErrorAction SilentlyContinue
    }
}

try {
    $null = New-Item -ItemType Directory -Path $temporaryRepository -Force
    Initialize-IsolatedTestRepository
    $null = Invoke-TestGit -Arguments @('config', 'user.name', 'Publish Test')
    $null = Invoke-TestGit -Arguments @('config', 'user.email', 'publish-test@example.invalid')
    [System.IO.File]::WriteAllText((Join-Path $temporaryRepository 'tracked.txt'), "base`n", $utf8)
    $null = Invoke-TestGit -Arguments @('add', '--', 'tracked.txt')
    $null = Invoke-TestGit -Arguments @('commit', '-q', '-m', 'base')
    $baseCommit = (Invoke-TestGit -Arguments @('rev-parse', 'HEAD')).Trim()
    $null = Invoke-TestGit -Arguments @('remote', 'add', 'origin', $remoteUrl)

    [System.IO.File]::WriteAllText((Join-Path $temporaryRepository 'tracked.txt'), "local`n", $utf8)
    $null = Invoke-TestGit -Arguments @('add', '--', 'tracked.txt')
    $null = Invoke-TestGit -Arguments @('commit', '-q', '-m', 'local')
    $localCommit = (Invoke-TestGit -Arguments @('rev-parse', 'HEAD')).Trim()
    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/remotes/origin/main', $baseCommit)
    $normalOutput = & pwsh -NoProfile -File $publishChecker -RepositoryRoot $temporaryRepository -RemoteName origin -ExpectedRemoteUrl $remoteUrl -LocalBranch main -RemoteBranch main -ExpectedLocalCommit $localCommit -ExpectedRemoteCommit $baseCommit -PushRefspec 'refs/heads/main:refs/heads/main' 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $normalOutput -notmatch '(?m)^push_command_proposal: git -c core\.hooksPath=<verified-empty-hooks-path> .* -- origin refs/heads/main:refs/heads/main\r?$' -or $normalOutput -notmatch '(?m)^remote_url_fingerprint: [0-9a-f]{64}\r?$') {
        throw "Normal publication command proposal is incomplete.`n$normalOutput"
    }
    $checksPassed++
    Invoke-PublishFixture -Name 'remote ancestor permits normal push' -ExpectedLocal $localCommit -ExpectedRemote $baseCommit -ExpectedTopology 'fast-forward-push' -ExpectedMergeBase $baseCommit

    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/remotes/origin/main', $localCommit)
    Invoke-PublishFixture -Name 'already published is idempotent' -ExpectedLocal $localCommit -ExpectedRemote $localCommit -ExpectedTopology 'already-published' -ExpectedMergeBase $localCommit

    $tree = (Invoke-TestGit -Arguments @('rev-parse', "$localCommit^{tree}")).Trim()
    $remoteDescendant = ("remote descendant`n" | git -C $temporaryRepository commit-tree $tree -p $localCommit).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not create remote-descendant fixture commit.' }
    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/remotes/origin/main', $remoteDescendant)
    Invoke-PublishFixture -Name 'local behind requires reconciliation' -ExpectedLocal $localCommit -ExpectedRemote $remoteDescendant -ExpectedTopology 'behind' -ExpectedMergeBase $localCommit

    $remoteDivergent = ("remote divergent`n" | git -C $temporaryRepository commit-tree $tree -p $baseCommit).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not create divergent fixture commit.' }
    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/remotes/origin/main', $remoteDivergent)
    Invoke-PublishFixture -Name 'divergence requires reconciliation' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ExpectedMergeBase $baseCommit

    $unrelatedCommit = ("unrelated`n" | git -C $temporaryRepository commit-tree $tree).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not create unrelated fixture commit.' }
    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/remotes/origin/main', $unrelatedCommit)
    Invoke-PublishFixture -Name 'unrelated history is distinct' -ExpectedLocal $localCommit -ExpectedRemote $unrelatedCommit -ExpectedTopology 'unrelated' -ExpectedMergeBase 'None'

    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/remotes/origin/main', $remoteDivergent)
    Invoke-PublishFixture -Name 'remote URL mismatch is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -ExpectedUrl 'https://example.invalid/wrong.git'
    Invoke-PublishFixture -Name 'force refspec is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -Refspec '+refs/heads/main:refs/heads/main'
    Invoke-PublishFixture -Name 'deletion refspec is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -Refspec ':refs/heads/main'
    Invoke-PublishFixture -Name 'tag refspec is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -Refspec 'refs/tags/v1:refs/tags/v1'
    Invoke-PublishFixture -Name 'wildcard refspec is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -Refspec 'refs/heads/*:refs/heads/*'
    Invoke-PublishFixture -Name 'matching refspec is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -Refspec ':'
    Invoke-PublishFixture -Name 'other destination is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -Refspec 'refs/heads/main:refs/heads/other'

    $secretUrl = 'https://user:secret-token@example.invalid/repository.git'
    Invoke-PublishFixture -Name 'credential URL is rejected without disclosure' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -ExpectedUrl $secretUrl -MustNotContain 'secret-token'
    Invoke-PublishFixture -Name 'expected ext helper is rejected without execution text' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -ExpectedUrl 'ext::dangerous-command' -MustNotContain 'dangerous-command'
    Invoke-PublishFixture -Name 'unknown helper scheme is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -ExpectedUrl 'unknown-helper://example.invalid/repository'

    $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', 'ext::configured-danger')
    Invoke-PublishFixture -Name 'configured ext helper is rejected without disclosure' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -ExpectedUrl $remoteUrl -MustNotContain 'configured-danger'
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', 'unknown-helper::configured-address')
    Invoke-PublishFixture -Name 'configured unknown helper syntax is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false -ExpectedUrl $remoteUrl -MustNotContain 'configured-address'
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', $remoteUrl)

    $scpUrl = 'git@example.invalid:state-of-consequence.git'
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', $scpUrl)
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', '--push', 'origin', $scpUrl)
    Invoke-PublishFixture -Name 'SSH scp-style URL is preserved' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ExpectedUrl $scpUrl -ExpectedMergeBase $baseCommit
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', $remoteUrl)
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', '--push', 'origin', $remoteUrl)

    $null = Invoke-TestGit -Arguments @('config', 'push.followTags', 'true')
    $null = Invoke-TestGit -Arguments @('config', 'remote.origin.mirror', 'true')
    $null = Invoke-TestGit -Arguments @('config', '--add', 'remote.origin.push', 'refs/heads/main:refs/heads/unrelated-target')
    $null = Invoke-TestGit -Arguments @('config', 'push.recurseSubmodules', 'on-demand')
    $null = Invoke-TestGit -Arguments @('config', '--add', 'push.pushOption', 'server-option')
    $configuredOutput = & pwsh -NoProfile -File $publishChecker -RepositoryRoot $temporaryRepository -RemoteName origin -ExpectedRemoteUrl $remoteUrl -LocalBranch main -RemoteBranch main -ExpectedLocalCommit $localCommit -ExpectedRemoteCommit $remoteDivergent -PushRefspec 'refs/heads/main:refs/heads/main' 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or
        $configuredOutput -notmatch '(?m)^push_command_proposal: .*push\.followTags=false.*remote\.origin\.mirror=false.*push\.default=nothing.*push\.recurseSubmodules=no.*push\.pushOption=.*--no-follow-tags.*--recurse-submodules=no.*refs/heads/main:refs/heads/main\r?$' -or
        $configuredOutput -match '(?m)^push_command_proposal: .*remote\.origin\.push=') {
        throw "Configuration broadening was not command-scoped away.`n$configuredOutput"
    }
    $checksPassed++

    Initialize-IsolatedBareRepository -Path $temporaryBareRemote
    $emptyPushHooks = Join-Path $temporaryRepository '.git/publish-test-empty-hooks'
    $null = New-Item -ItemType Directory -Path $emptyPushHooks -Force
    if (@([System.IO.Directory]::EnumerateFileSystemEntries($emptyPushHooks)).Count -ne 0) { throw 'Execution-fixture hooks path is not empty.' }
    $seedOutput = @(& git -C $temporaryBareRemote -c "core.hooksPath=$emptyPushHooks" -c fetch.writeCommitGraph=false fetch --no-tags --no-recurse-submodules --no-write-fetch-head -- $temporaryRepository $localCommit 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Could not seed isolated bare publication remote.`n$($seedOutput -join "`n")" }
    foreach ($destination in @('refs/heads/main', 'refs/heads/published/exact', 'refs/heads/side', 'refs/heads/unrelated-target')) {
        $null = & git -C $temporaryBareRemote update-ref $destination $baseCommit
        if ($LASTEXITCODE -ne 0) { throw "Could not initialize isolated destination '$destination'." }
    }
    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/heads/side', $localCommit)
    $null = Invoke-TestGit -Arguments @('tag', '-a', 'publish-fixture-tag', '-m', 'publication fixture', $localCommit)
    $null = Invoke-TestGit -Arguments @('branch', '-m', 'release/exact')
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', $temporaryBareRemote)
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', '--push', 'origin', $temporaryBareRemote)
    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/remotes/origin/published/exact', $baseCommit)
    $null = Invoke-TestGit -Arguments @('config', '--add', 'remote.origin.push', 'refs/heads/release/exact:refs/heads/unrelated-target')
    $null = Invoke-TestGit -Arguments @('config', '--add', 'remote.origin.push', 'refs/heads/*:refs/heads/*')
    $null = Invoke-TestGit -Arguments @('config', '--add', 'remote.origin.push', 'refs/tags/*:refs/tags/*')
    $null = Invoke-TestGit -Arguments @('config', 'push.default', 'matching')
    $null = Invoke-TestGit -Arguments @('config', 'remote.pushDefault', 'other')
    $null = Invoke-TestGit -Arguments @('config', 'branch.release/exact.pushRemote', 'other')
    $null = Invoke-TestGit -Arguments @('config', 'push.autoSetupRemote', 'true')
    $null = Invoke-TestGit -Arguments @('config', 'push.gpgSign', 'true')

    $executionOutput = & pwsh -NoProfile -File $publishChecker -RepositoryRoot $temporaryRepository -RemoteName origin -ExpectedRemoteUrl $temporaryBareRemote -LocalBranch 'release/exact' -RemoteBranch 'published/exact' -ExpectedLocalCommit $localCommit -ExpectedRemoteCommit $baseCommit -PushRefspec 'refs/heads/release/exact:refs/heads/published/exact' 2>&1 | Out-String
    $expectedExecutionProposal = 'git -c core.hooksPath=<verified-empty-hooks-path> -c push.followTags=false -c remote.origin.mirror=false -c push.default=nothing -c remote.pushDefault= -c branch.release/exact.pushRemote= -c push.autoSetupRemote=false -c push.recurseSubmodules=no -c push.pushOption= -c push.gpgSign=false push --porcelain --no-verify --no-follow-tags --no-signed --recurse-submodules=no -- origin refs/heads/release/exact:refs/heads/published/exact'
    $proposalMatch = [regex]::Match($executionOutput, '(?m)^push_command_proposal: (.+?)\r?$')
    if ($LASTEXITCODE -ne 0 -or -not $proposalMatch.Success -or $proposalMatch.Groups[1].Value -ne $expectedExecutionProposal -or
        $executionOutput -notmatch '(?m)^publish_ready: yes\r?$') {
        throw "Executable publication proposal is not exact or ready.`n$executionOutput"
    }

    $proposalTokens = @($proposalMatch.Groups[1].Value -split ' ')
    if ($proposalTokens[0] -ne 'git') { throw 'Generated publication proposal does not begin with Git.' }
    $pushArguments = @($proposalTokens[1..($proposalTokens.Count - 1)])
    $hooksArgumentIndex = [Array]::IndexOf($pushArguments, 'core.hooksPath=<verified-empty-hooks-path>')
    if ($hooksArgumentIndex -lt 0) { throw 'Generated publication proposal does not contain its hooks placeholder.' }
    $pushArguments[$hooksArgumentIndex] = "core.hooksPath=$emptyPushHooks"
    $pushExecution = @(& git -C $temporaryRepository @pushArguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Generated exact publication command failed against isolated bare remote.`n$($pushExecution -join "`n")" }

    $observedRemoteRefs = @(& git -C $temporaryBareRemote for-each-ref '--format=%(refname) %(objectname)' refs/heads refs/tags)
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect isolated bare remote after generated push.' }
    $expectedRemoteRefs = @(
        "refs/heads/main $baseCommit",
        "refs/heads/published/exact $localCommit",
        "refs/heads/side $baseCommit",
        "refs/heads/unrelated-target $baseCommit"
    )
    if ([string]::Join("`n", [string[]]$observedRemoteRefs) -ne [string]::Join("`n", [string[]]$expectedRemoteRefs)) {
        throw "Generated push changed a destination outside the exact assigned refspec.`nObserved:`n$($observedRemoteRefs -join "`n")"
    }
    $checksPassed++

    $null = Invoke-TestGit -Arguments @('branch', '-m', 'main')
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', $remoteUrl)
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', '--push', 'origin', $remoteUrl)
    $null = Invoke-TestGit -Arguments @('update-ref', 'refs/remotes/origin/main', $remoteDivergent)

    $null = Invoke-TestGit -Arguments @('config', 'remote.origin.receivepack', 'custom-receive')
    Invoke-PublishFixture -Name 'custom receive command is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false
    $null = Invoke-TestGit -Arguments @('config', '--unset-all', 'remote.origin.receivepack')

    Invoke-PublishFixture -Name 'pre-transport action succeeds before remote inspection' -ExpectedLocal $localCommit -ExpectedRemote ('0' * 40) -ExpectedTopology 'not-applicable' -Action PreTransport

    $safeUrls = @(
        'https://example.invalid/repository.git',
        'ssh://git@example.invalid/repository.git',
        'git://example.invalid/repository.git',
        'file:///C:/repository.git',
        'git@example.invalid:repository.git',
        '../repository.git',
        $rootedLocalUrl
    )
    foreach ($safeUrl in $safeUrls) {
        $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', $safeUrl)
        $null = Invoke-TestGit -Arguments @('remote', 'set-url', '--push', 'origin', $safeUrl)
        Invoke-PublishFixture -Name "safe URL is preserved: $safeUrl" -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'not-applicable' -ExpectedUrl $safeUrl -Action PreTransport
    }
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', $remoteUrl)
    $null = Invoke-TestGit -Arguments @('remote', 'set-url', '--push', 'origin', $remoteUrl)

    foreach ($unsafeUrl in @(
        'https://example.invalid/repository.git;secret-token=value',
        'https://example.invalid/repository.git%3Bsecret-token=value',
        'https://example.invalid/repository.git?secret-token=value',
        'https://example.invalid/repository.git#secret-token=value',
        'ssh:///secret-token/repository.git',
        'https://user:secret-token@example.invalid/repository.git'
    )) {
        Invoke-PublishFixture -Name 'unsafe expected URL is rejected without disclosure' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'not-applicable' -ExpectedUrl $unsafeUrl -ShouldPass $false -Action PreTransport -MustNotContain 'secret-token'
        $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', $unsafeUrl)
        $null = Invoke-TestGit -Arguments @('remote', 'set-url', '--push', 'origin', $unsafeUrl)
        Invoke-PublishFixture -Name 'unsafe configured URL is rejected without disclosure' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'not-applicable' -ExpectedUrl $remoteUrl -ShouldPass $false -Action PreTransport -MustNotContain 'secret-token'
        $null = Invoke-TestGit -Arguments @('remote', 'set-url', 'origin', $remoteUrl)
        $null = Invoke-TestGit -Arguments @('remote', 'set-url', '--push', 'origin', $remoteUrl)
    }

    $markerRoot = Join-Path $temporaryRepository '.git/transport-markers'
    $null = New-Item -ItemType Directory -Path $markerRoot -Force
    foreach ($key in @('core.sshCommand', 'core.gitProxy', 'http.proxy', 'remote.origin.proxy', 'remote.origin.uploadpack')) {
        $safeKey = $key.Replace('.', '-')
        Invoke-ConfigMarkerFixture -Name "executable transport override $key is rejected" -Key $key -MarkerPath (Join-Path $markerRoot "$safeKey.txt") -Secret "secret-$safeKey"
    }

    foreach ($environmentName in @('GIT_SSH_COMMAND', 'GIT_SSH', 'GIT_PROXY_COMMAND', 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'http_proxy', 'https_proxy', 'all_proxy', 'GIT_CONFIG_COUNT', 'GIT_CONFIG_PARAMETERS', 'GIT_CONFIG_SYSTEM', 'GIT_CONFIG_GLOBAL')) {
        $previous = [System.Environment]::GetEnvironmentVariable($environmentName)
        $secret = "secret-$environmentName"
        try {
            [System.Environment]::SetEnvironmentVariable($environmentName, $secret)
            Invoke-PublishFixture -Name "transport environment $environmentName is rejected" -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'not-applicable' -ShouldPass $false -Action PreTransport -MustNotContain $secret
        } finally {
            [System.Environment]::SetEnvironmentVariable($environmentName, $previous)
        }
    }

    [System.IO.File]::WriteAllText((Join-Path $temporaryRepository 'untracked.txt'), "dirty`n", $utf8)
    Invoke-PublishFixture -Name 'dirty worktree is rejected' -ExpectedLocal $localCommit -ExpectedRemote $remoteDivergent -ExpectedTopology 'diverged' -ShouldPass $false
} finally {
    Remove-Item -LiteralPath $temporaryRepository -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $temporaryBareRemote -Recurse -Force -ErrorAction SilentlyContinue
}

$expectedChecks = 61
if ($checksPassed -ne $expectedChecks) { throw "Git publish preflight test count changed: expected $expectedChecks, got $checksPassed." }
Write-Host "Git publish preflight tests passed: $checksPassed/$expectedChecks." -ForegroundColor Green
