$ErrorActionPreference = 'Stop'

$checkerPath = Join-Path $PSScriptRoot 'check-docs.ps1'
$checksPassed = 0

function Invoke-DocumentationCheck {
    param([string[]]$Arguments)

    $output = & pwsh -NoProfile -File $checkerPath @Arguments 2>&1 | Out-String
    return @{
        ExitCode = $LASTEXITCODE
        Output = $output
    }
}

$baseline = Invoke-DocumentationCheck -Arguments @()
if ($baseline.ExitCode -ne 0) {
    throw "The live documentation taxonomy did not pass before mutation probes.`n$($baseline.Output)"
}
$checksPassed++

$misfiled = Invoke-DocumentationCheck -Arguments @(
    '-TaxonomyProbeType', 'glossary',
    '-TaxonomyProbePath', 'docs/planning/TAXONOMY_PROBE.md'
)
if ($misfiled.ExitCode -eq 0 -or $misfiled.Output -notmatch "misfiled for document type 'glossary'") {
    throw 'The taxonomy validator did not reject a known document type in the wrong folder.'
}
$checksPassed++

$unregistered = Invoke-DocumentationCheck -Arguments @(
    '-TaxonomyProbeType', 'unregistered-probe-type',
    '-TaxonomyProbePath', 'docs/foundations/TAXONOMY_PROBE.md'
)
if ($unregistered.ExitCode -eq 0 -or $unregistered.Output -notmatch "uses ungoverned document type 'unregistered-probe-type'") {
    throw 'The taxonomy validator did not reject an unregistered document type.'
}
$checksPassed++

Write-Host "Documentation taxonomy tests passed: $checksPassed/3." -ForegroundColor Green
