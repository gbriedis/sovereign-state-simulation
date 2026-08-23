$ErrorActionPreference = 'Stop'

$checkerPath = Join-Path $PSScriptRoot 'check-docs.ps1'
$checksPassed = 0
$expectedChecks = 4

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

$decisionIndexPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'docs/decisions/README.md'
$decisionIndex = Get-Content -Raw -LiteralPath $decisionIndexPath
$requiredShape = [regex]::Match(
    $decisionIndex,
    '(?ms)^## Required record shape\s+```markdown\s+(.*?)^```'
)
if (-not $requiredShape.Success) {
    throw 'The decision-record index does not contain its required fenced record shape.'
}
$exampleType = [regex]::Match($requiredShape.Groups[1].Value, '(?m)^type:\s*(\S+)\s*$').Groups[1].Value
if ($exampleType -ne 'decision-record') {
    throw "The decision-record index example uses '$exampleType' instead of canonical type 'decision-record'."
}
$decisionTypeInCanonicalFolder = Invoke-DocumentationCheck -Arguments @(
    '-TaxonomyProbeType', $exampleType,
    '-TaxonomyProbePath', 'docs/decisions/TAXONOMY_PROBE.md'
)
if ($decisionTypeInCanonicalFolder.ExitCode -ne 0) {
    throw "The decision-record index example is not accepted by the enforced decisions-folder taxonomy.`n$($decisionTypeInCanonicalFolder.Output)"
}
$decisionTypeOutsideCanonicalFolder = Invoke-DocumentationCheck -Arguments @(
    '-TaxonomyProbeType', $exampleType,
    '-TaxonomyProbePath', 'docs/architecture/TAXONOMY_PROBE.md'
)
if ($decisionTypeOutsideCanonicalFolder.ExitCode -eq 0 -or
    $decisionTypeOutsideCanonicalFolder.Output -notmatch "misfiled for document type 'decision-record'") {
    throw 'The taxonomy validator did not keep the decision-index example confined to the decisions folder.'
}
$checksPassed++

if ($checksPassed -ne $expectedChecks) {
    throw "Documentation taxonomy tests executed $checksPassed checks; expected $expectedChecks."
}
Write-Host "Documentation taxonomy tests passed: $checksPassed/$expectedChecks." -ForegroundColor Green
