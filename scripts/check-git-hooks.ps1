param(
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

$repositoryRootPath = if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    Split-Path -Parent $PSScriptRoot
} else {
    [System.IO.Path]::GetFullPath($RepositoryRoot)
}

function Invoke-GitText {
    param(
        [string[]]$Arguments,
        [bool]$AllowMissingValue = $false
    )

    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-hook-check-' + [guid]::NewGuid().ToString('N'))
    try {
        $output = @(& git -C $repositoryRootPath @Arguments 2> $stderrPath)
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0 -and -not ($AllowMissingValue -and $exitCode -eq 1)) {
            $standardError = if (Test-Path -LiteralPath $stderrPath) { Get-Content -Raw -LiteralPath $stderrPath } else { '' }
            throw "Git command failed: git $($Arguments -join ' ')`n$standardError$($output -join "`n")"
        }
        return @{
            ExitCode = $exitCode
            Text = [string]::Join("`n", [string[]]$output)
        }
    } finally {
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Test-HookExecutable {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }
    if ($IsWindows) {
        # Git for Windows executable behavior depends on its POSIX compatibility
        # layer. Treat every exact hook file as active rather than under-block.
        return $true
    }
    try {
        $mode = [System.IO.File]::GetUnixFileMode($Path)
        $executeBits = [System.IO.UnixFileMode]::UserExecute -bor [System.IO.UnixFileMode]::GroupExecute -bor [System.IO.UnixFileMode]::OtherExecute
        return ($mode -band $executeBits) -ne 0
    } catch {
        # When executable state cannot be established, block conservatively.
        return $true
    }
}

$null = Invoke-GitText -Arguments @('rev-parse', '--is-inside-work-tree')
$hooksSettingResult = Invoke-GitText -Arguments @('config', '--path', '--get', 'core.hooksPath') -AllowMissingValue $true
$hooksSetting = if ($hooksSettingResult.ExitCode -eq 0) { $hooksSettingResult.Text.Trim() } else { 'unset' }
$effectiveHooksPath = (Invoke-GitText -Arguments @('rev-parse', '--path-format=absolute', '--git-path', 'hooks')).Text.Trim()

$commitLifecycleHooks = @(
    'post-index-change',
    'pre-commit',
    'prepare-commit-msg',
    'commit-msg',
    'reference-transaction',
    'post-commit'
)
$activeHooks = [System.Collections.Generic.List[string]]::new()
foreach ($hookName in $commitLifecycleHooks) {
    $hookPath = Join-Path $effectiveHooksPath $hookName
    if (Test-HookExecutable -Path $hookPath) {
        $activeHooks.Add([System.IO.Path]::GetFullPath($hookPath))
    }
}

Write-Output 'GIT_HOOK_PREFLIGHT'
Write-Output "repository_root: $repositoryRootPath"
Write-Output "core_hooks_path: $hooksSetting"
Write-Output "effective_hooks_path: $effectiveHooksPath"
Write-Output "active_commit_lifecycle_hooks: $(if ($activeHooks.Count -eq 0) { 'None' } else { [string]::Join('; ', $activeHooks) })"
if ($activeHooks.Count -gt 0) {
    Write-Output 'authorization_safe: no'
    Write-Output 'blocked_reason: Active commit-lifecycle hooks can execute effects outside the authorized path-specific staging and commit contract.'
    exit 1
}

Write-Output 'authorization_safe: yes'
Write-Output 'blocked_reason: None'
