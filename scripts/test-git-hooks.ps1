$ErrorActionPreference = 'Stop'

$hookChecker = Join-Path $PSScriptRoot 'check-git-hooks.ps1'
$temporaryRepository = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-hook-test-' + [guid]::NewGuid().ToString('N'))
$checksPassed = 0

function Invoke-TestGit {
    param([string[]]$Arguments)

    $output = & git -C $temporaryRepository @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Test Git command failed: git $($Arguments -join ' ')`n$($output -join "`n")"
    }
}

function Initialize-IsolatedTestRepository {
    $template = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-empty-template-' + [guid]::NewGuid().ToString('N'))
    $previousTemplate = $env:GIT_TEMPLATE_DIR
    try {
        $null = New-Item -ItemType Directory -Path $template -Force
        if (@([System.IO.Directory]::EnumerateFileSystemEntries($template)).Count -ne 0) { throw 'Hook test template is not empty.' }
        Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue
        $output = @(& git -c init.templateDir= init -q "--template=$template" $temporaryRepository 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Could not initialize isolated hook test repository.`n$($output -join "`n")" }
        if ((Test-Path -LiteralPath (Join-Path $temporaryRepository '.git/info/attributes')) -or
            ((Test-Path -LiteralPath (Join-Path $temporaryRepository '.git/hooks')) -and @([System.IO.Directory]::EnumerateFileSystemEntries((Join-Path $temporaryRepository '.git/hooks'))).Count -ne 0)) {
            throw 'Hook test initialization inherited attributes or hooks.'
        }
    } finally {
        if ($null -eq $previousTemplate) { Remove-Item Env:GIT_TEMPLATE_DIR -ErrorAction SilentlyContinue } else { $env:GIT_TEMPLATE_DIR = $previousTemplate }
        Remove-Item -LiteralPath $template -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-HookFixture {
    param(
        [string]$Name,
        [bool]$ShouldPass
    )

    $output = & pwsh -NoProfile -File $hookChecker -RepositoryRoot $temporaryRepository 2>&1 | Out-String
    $didPass = $LASTEXITCODE -eq 0
    if ($didPass -ne $ShouldPass) {
        throw "Git hook preflight fixture '$Name' produced the wrong result.`n$output"
    }
    if ($ShouldPass -and $output -notmatch '(?m)^authorization_safe: yes\r?$') {
        throw "Git hook preflight fixture '$Name' omitted its safe result."
    }
    if (-not $ShouldPass -and $output -notmatch '(?m)^authorization_safe: no\r?$') {
        throw "Git hook preflight fixture '$Name' omitted its blocking result."
    }
    $script:checksPassed++
}

try {
    $null = New-Item -ItemType Directory -Path $temporaryRepository -Force
    Initialize-IsolatedTestRepository
    Invoke-HookFixture -Name 'default sample hooks only' -ShouldPass $true

    Invoke-TestGit -Arguments @('config', 'core.hooksPath', '.custom-hooks')
    $customHooks = Join-Path $temporaryRepository '.custom-hooks'
    $null = New-Item -ItemType Directory -Path $customHooks -Force
    [System.IO.File]::WriteAllText((Join-Path $customHooks 'pre-commit.sample'), "#!/bin/sh`nexit 1`n", [System.Text.UTF8Encoding]::new($false))
    Invoke-HookFixture -Name 'inactive sample in effective custom path' -ShouldPass $true

    $activeHook = Join-Path $customHooks 'pre-commit'
    [System.IO.File]::WriteAllText($activeHook, "#!/bin/sh`nexit 0`n", [System.Text.UTF8Encoding]::new($false))
    if (-not $IsWindows) {
        [System.IO.File]::SetUnixFileMode(
            $activeHook,
            [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::UserExecute
        )
    }
    Invoke-HookFixture -Name 'active pre-commit hook blocks authorization' -ShouldPass $false

    Remove-Item -LiteralPath $activeHook -Force
    $prePushHook = Join-Path $customHooks 'pre-push'
    [System.IO.File]::WriteAllText($prePushHook, "#!/bin/sh`nexit 0`n", [System.Text.UTF8Encoding]::new($false))
    if (-not $IsWindows) {
        [System.IO.File]::SetUnixFileMode($prePushHook, [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::UserExecute)
    }
    Invoke-HookFixture -Name 'active pre-push hook blocks authorization' -ShouldPass $false

    Remove-Item -LiteralPath $prePushHook -Force
    $postMergeHook = Join-Path $customHooks 'post-merge'
    [System.IO.File]::WriteAllText($postMergeHook, "#!/bin/sh`nexit 0`n", [System.Text.UTF8Encoding]::new($false))
    if (-not $IsWindows) {
        [System.IO.File]::SetUnixFileMode($postMergeHook, [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::UserExecute)
    }
    Invoke-HookFixture -Name 'active post-merge hook blocks authorization' -ShouldPass $false

    Remove-Item -LiteralPath $postMergeHook -Force
    $queryFsmonitorHook = Join-Path $customHooks 'query-fsmonitor'
    [System.IO.File]::WriteAllText($queryFsmonitorHook, "#!/bin/sh`nexit 0`n", [System.Text.UTF8Encoding]::new($false))
    if (-not $IsWindows) {
        [System.IO.File]::SetUnixFileMode($queryFsmonitorHook, [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::UserExecute)
    }
    Invoke-HookFixture -Name 'active query-fsmonitor hook blocks authorization' -ShouldPass $false
} finally {
    Remove-Item -LiteralPath $temporaryRepository -Recurse -Force -ErrorAction SilentlyContinue
}

$expectedChecks = 6
if ($checksPassed -ne $expectedChecks) { throw "Git hook preflight test count changed: expected $expectedChecks, got $checksPassed." }
Write-Host "Git hook preflight tests passed: $checksPassed/$expectedChecks." -ForegroundColor Green
