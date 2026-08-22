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
    Invoke-TestGit -Arguments @('init', '-q')
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
} finally {
    Remove-Item -LiteralPath $temporaryRepository -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Git hook preflight tests passed: $checksPassed/3." -ForegroundColor Green
