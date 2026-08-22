[CmdletBinding()]
param(
    [ValidateSet('Validate', 'AuditGit', 'All')]
    [string] $Mode = 'Validate',

    [switch] $StrictMetadata,

    [string] $RepositoryRoot,

    [string] $ReferenceRef = 'main',

    [ValidateRange(1, 3650)]
    [int] $StaleAfterDays = 14
)

$implementation = Join-Path $PSScriptRoot 'governance/Validate-ProjectGovernance.ps1'
& $implementation @PSBoundParameters
exit $LASTEXITCODE
