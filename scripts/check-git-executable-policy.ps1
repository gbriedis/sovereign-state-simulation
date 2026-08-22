param(
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
$repositoryRootPath = if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    Split-Path -Parent $PSScriptRoot
} else {
    [System.IO.Path]::GetFullPath($RepositoryRoot)
}

function Invoke-SafeGitText {
    param([string[]]$Arguments, [int[]]$AllowedExitCodes = @(0))
    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ('codex-policy-guard-' + [guid]::NewGuid().ToString('N'))
    try {
        $output = @(& git -C $repositoryRootPath -c core.fsmonitor=false @Arguments 2> $stderrPath)
        $exitCode = $LASTEXITCODE
        if ($exitCode -notin $AllowedExitCodes) { throw 'Git policy inspection could not read repository metadata safely.' }
        return @{ ExitCode = $exitCode; Lines = @($output); Text = [string]::Join("`n", [string[]]$output) }
    } finally {
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

$selectedFilterDrivers = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

function Register-FilterAttributes {
    param([string]$Content)
    foreach ($line in $Content.Replace("`r`n", "`n").Replace("`r", "`n").Split("`n")) {
        if ($line.TrimStart().StartsWith('#')) { continue }
        foreach ($match in [regex]::Matches($line, '(?<!\S)(?<token>[!-]?filter(?:=[^\s]+)?)(?=\s|$)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $token = $match.Groups['token'].Value
            if ($token -match '^(?i:filter)=(?<driver>.+)$') {
                $null = $selectedFilterDrivers.Add($Matches['driver'])
            }
        }
    }
}

function Read-AttributeFileIfPresent {
    param([string]$Path)
    if (-not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Register-FilterAttributes -Content (Get-Content -Raw -LiteralPath $Path)
    }
}

function ConvertTo-CanonicalPath {
    param([string]$Path)
    return [System.IO.Path]::TrimEndingDirectorySeparator([System.IO.Path]::GetFullPath($Path))
}

foreach ($environmentName in @(
    'GIT_DIR',
    'GIT_WORK_TREE',
    'GIT_COMMON_DIR',
    'GIT_INDEX_FILE',
    'GIT_OBJECT_DIRECTORY',
    'GIT_ALTERNATE_OBJECT_DIRECTORIES',
    'GIT_NAMESPACE',
    'GIT_SHALLOW_FILE',
    'GIT_CEILING_DIRECTORIES',
    'GIT_DISCOVERY_ACROSS_FILESYSTEM',
    'GIT_QUARANTINE_PATH',
    'GIT_REPLACE_REF_BASE',
    'GIT_NO_REPLACE_OBJECTS',
    'GIT_GRAFT_FILE',
    'GIT_CONFIG_COUNT',
    'GIT_CONFIG_PARAMETERS',
    'GIT_CONFIG_SYSTEM',
    'GIT_CONFIG_GLOBAL',
    'GIT_CONFIG_NOSYSTEM',
    'GIT_ATTR_NOSYSTEM',
    'GIT_ATTR_SOURCE'
)) {
    if (-not [string]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($environmentName))) {
        throw 'Inherited Git repository, object, index, attribute, or configuration routing is prohibited by the executable-policy guard.'
    }
}

$pathComparison = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
$canonicalRepositoryRoot = ConvertTo-CanonicalPath -Path $repositoryRootPath
$insideWorkTree = (Invoke-SafeGitText -Arguments @('rev-parse', '--is-inside-work-tree')).Text.Trim()
$resolvedWorkTree = ConvertTo-CanonicalPath -Path (Invoke-SafeGitText -Arguments @('rev-parse', '--path-format=absolute', '--show-toplevel')).Text.Trim()
if ($insideWorkTree -ne 'true' -or -not [string]::Equals($resolvedWorkTree, $canonicalRepositoryRoot, $pathComparison)) {
    throw 'Git resolved a worktree other than the explicitly assigned repository root.'
}
$gitDirectory = (Invoke-SafeGitText -Arguments @('rev-parse', '--path-format=absolute', '--absolute-git-dir')).Text.Trim()
$canonicalGitDirectory = ConvertTo-CanonicalPath -Path $gitDirectory
$gitCommonDirectory = ConvertTo-CanonicalPath -Path (Invoke-SafeGitText -Arguments @('rev-parse', '--path-format=absolute', '--git-common-dir')).Text.Trim()
$resolvedIndexPath = ConvertTo-CanonicalPath -Path (Invoke-SafeGitText -Arguments @('rev-parse', '--path-format=absolute', '--git-path', 'index')).Text.Trim()
$resolvedObjectDirectory = ConvertTo-CanonicalPath -Path (Invoke-SafeGitText -Arguments @('rev-parse', '--path-format=absolute', '--git-path', 'objects')).Text.Trim()

foreach ($routingFile in @(
    (Join-Path $resolvedObjectDirectory 'info/alternates'),
    (Join-Path $resolvedObjectDirectory 'info/http-alternates'),
    (Join-Path $gitCommonDirectory 'info/grafts')
)) {
    if ((Test-Path -LiteralPath $routingFile -PathType Leaf) -and (Get-Item -LiteralPath $routingFile).Length -ne 0) {
        throw 'Repository-private object routing is outside the current authorization.'
    }
}
$replacementRefs = Invoke-SafeGitText -Arguments @('for-each-ref', '--format=%(refname)', 'refs/replace')
if (-not [string]::IsNullOrWhiteSpace($replacementRefs.Text)) { throw 'Git replacement refs are outside the current authorization.' }
if ((Invoke-SafeGitText -Arguments @('rev-parse', '--is-shallow-repository')).Text.Trim() -eq 'true') {
    throw 'A shallow object graph is outside the exact topology authorization.'
}
$attributeTreeRouting = Invoke-SafeGitText -Arguments @('config', '--get-all', 'attr.tree') -AllowedExitCodes @(0, 1)
if ($attributeTreeRouting.ExitCode -eq 0) {
    throw 'Configured Git attribute-tree routing is outside the current authorization.'
}

$configuredExecutableFilterDrivers = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$configKeys = @((Invoke-SafeGitText -Arguments @('config', '--name-only', '--list')).Lines | ForEach-Object { [string]$_ })
foreach ($configKey in $configKeys) {
    if ($configKey -match '^(?i:filter\.(?<driver>.+)\.(?:clean|process))$') {
        $null = $configuredExecutableFilterDrivers.Add($Matches['driver'])
    }
}
$fsmonitorValues = Invoke-SafeGitText -Arguments @('config', '--get-all', 'core.fsmonitor') -AllowedExitCodes @(0, 1)
if ($fsmonitorValues.ExitCode -eq 0 -and @($fsmonitorValues.Lines | Where-Object { ([string]$_).Trim().ToLowerInvariant() -notin @('', 'false', 'no', 'off', '0') }).Count -ne 0) {
    throw 'Executable Git filesystem monitoring is prohibited by the current authorization.'
}

$effectiveHooksDirectory = (Invoke-SafeGitText -Arguments @('rev-parse', '--path-format=absolute', '--git-path', 'hooks')).Text.Trim()
$queryFsmonitor = Join-Path $effectiveHooksDirectory 'query-fsmonitor'
if (Test-Path -LiteralPath $queryFsmonitor -PathType Leaf) {
    throw 'A query-fsmonitor hook is outside the current authorization.'
}

$infoAttributes = Join-Path $gitDirectory 'info/attributes'
Read-AttributeFileIfPresent -Path $infoAttributes

$configuredAttributeFiles = Invoke-SafeGitText -Arguments @('config', '--path', '--get-all', 'core.attributesFile') -AllowedExitCodes @(0, 1)
if ($configuredAttributeFiles.ExitCode -eq 0) {
    foreach ($attributePath in $configuredAttributeFiles.Lines) { Read-AttributeFileIfPresent -Path ([string]$attributePath) }
}

$implicitGlobalAttributes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$gitVariables = (Invoke-SafeGitText -Arguments @('var', '-l')).Lines
foreach ($gitVariable in $gitVariables) {
    if ([string]$gitVariable -match '^GIT_ATTR_(?:SYSTEM|GLOBAL)=(?<path>.+)$') {
        $null = $implicitGlobalAttributes.Add($Matches['path'])
    }
}
$xdgRoot = [System.Environment]::GetEnvironmentVariable('XDG_CONFIG_HOME')
if (-not [string]::IsNullOrWhiteSpace($xdgRoot)) { $null = $implicitGlobalAttributes.Add((Join-Path $xdgRoot 'git/attributes')) }
$userProfileRoot = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
if (-not [string]::IsNullOrWhiteSpace($userProfileRoot)) { $null = $implicitGlobalAttributes.Add((Join-Path $userProfileRoot '.config/git/attributes')) }
foreach ($attributePath in $implicitGlobalAttributes) { Read-AttributeFileIfPresent -Path $attributePath }

$indexEntries = Invoke-SafeGitText -Arguments @('ls-files', '--stage', '-z')
foreach ($token in $indexEntries.Text.Split([char]0, [System.StringSplitOptions]::RemoveEmptyEntries)) {
    $match = [regex]::Match($token, '^(?<mode>\d+) (?<oid>[0-9a-f]+) \d+\t(?<path>.+)$')
    if ($match.Success -and ($match.Groups['path'].Value -eq '.gitattributes' -or $match.Groups['path'].Value.EndsWith('/.gitattributes'))) {
        $content = (Invoke-SafeGitText -Arguments @('cat-file', 'blob', $match.Groups['oid'].Value)).Text
        Register-FilterAttributes -Content $content
    }
}

$pending = [System.Collections.Generic.Stack[string]]::new()
$pending.Push($repositoryRootPath)
while ($pending.Count -ne 0) {
    $directory = $pending.Pop()
    foreach ($childDirectory in [System.IO.Directory]::EnumerateDirectories($directory)) {
        $fullChild = [System.IO.Path]::TrimEndingDirectorySeparator([System.IO.Path]::GetFullPath($childDirectory))
        if ([string]::Equals($fullChild, $canonicalGitDirectory, $pathComparison)) { continue }
        $attributes = [System.IO.File]::GetAttributes($fullChild)
        if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) { $pending.Push($fullChild) }
    }
    $attributePath = Join-Path $directory '.gitattributes'
    Read-AttributeFileIfPresent -Path $attributePath
}

foreach ($filterDriver in $selectedFilterDrivers) {
    if ($configuredExecutableFilterDrivers.Contains($filterDriver)) {
        throw 'An executable Git clean or process filter is selected by active attributes and is outside the current authorization.'
    }
}

Write-Output 'GIT_EXECUTABLE_POLICY_GUARD'
Write-Output "repository_root: $repositoryRootPath"
Write-Output "resolved_worktree: $resolvedWorkTree"
Write-Output "resolved_git_directory: $canonicalGitDirectory"
Write-Output "resolved_common_directory: $gitCommonDirectory"
Write-Output "resolved_index: $resolvedIndexPath"
Write-Output "resolved_object_directory: $resolvedObjectDirectory"
Write-Output "configured_clean_or_process_filter_drivers: $(if ($configuredExecutableFilterDrivers.Count -eq 0) { 'None' } else { [string]::Join('; ', @($configuredExecutableFilterDrivers | Sort-Object -CaseSensitive)) })"
Write-Output 'executable_fsmonitor: None'
Write-Output 'selected_executable_filter_drivers: None'
Write-Output 'authorization_safe: yes'
