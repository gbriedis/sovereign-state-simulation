$ErrorActionPreference = 'Stop'

$checkerPath = Join-Path $PSScriptRoot 'check-docs.ps1'
$checksPassed = 0
$expectedChecks = 9

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

$routingAuthorities = @(
    @{ Path = 'docs/governance/workflows/KNOWLEDGE_WORKFLOW.md'; Required = @(
        'gpt-5.6-luna', 'gpt-5.6-terra', 'gpt-5.6-sol', 'Model selection and reasoning effort are separate decisions',
        'SELECTED_MODEL:', 'REASONING_EFFORT:', 'MODEL_JUSTIFICATION:', 'ESCALATION_CONDITIONS:',
        'least costly available model', 'independent of the developer''s selected model'
    ) },
    @{ Path = 'docs/governance/roles/OUTCOME_LEAD.md'; Required = @(
        'SELECTED_MODEL', 'REASONING_EFFORT', 'MODEL_JUSTIFICATION', 'ESCALATION_CONDITIONS',
        'least costly available model', 'independently of the developer''s model'
    ) },
    @{ Path = 'docs/governance/roles/SYSTEMS_KNOWLEDGE_DEVELOPER.md'; Required = @(
        'selected_model:', 'reasoning_effort:', 'request escalation', 'Do not silently change the selected model'
    ) },
    @{ Path = 'docs/governance/roles/SYSTEMS_COHERENCE_REVIEWER.md'; Required = @(
        'independently of the', 'developer''s model and reasoning effort', 'missed-defect', 'detection difficulty'
    ) }
)
foreach ($authority in $routingAuthorities) {
    $content = Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) $authority.Path)
    foreach ($requiredText in $authority.Required) {
        if (-not $content.Contains($requiredText)) {
            throw "Model-routing contract is missing '$requiredText' from $($authority.Path)."
        }
    }
}
$checksPassed++

$newTypes = @(
    @{ Type = 'clear-language-standard'; Path = 'docs/governance/standards/TAXONOMY_PROBE.md' },
    @{ Type = 'project-journal'; Path = 'docs/project-journal/README.md' },
    @{ Type = 'project-status-view'; Path = 'docs/project-journal/TAXONOMY_PROBE.md' },
    @{ Type = 'historical-project-post'; Path = 'docs/project-journal/posts/TAXONOMY_PROBE.md' }
)
foreach ($probe in $newTypes) {
    $result = Invoke-DocumentationCheck -Arguments @('-TaxonomyProbeType', $probe.Type, '-TaxonomyProbePath', $probe.Path)
    if ($result.ExitCode -ne 0) { throw "The taxonomy rejected governed type '$($probe.Type)' in '$($probe.Path)'.`n$($result.Output)" }
}
$journalMisfiled = Invoke-DocumentationCheck -Arguments @(
    '-TaxonomyProbeType', 'historical-project-post',
    '-TaxonomyProbePath', 'docs/project-journal/HISTORY.md'
)
if ($journalMisfiled.ExitCode -eq 0 -or $journalMisfiled.Output -notmatch "misfiled for document type 'historical-project-post'") {
    throw 'The taxonomy validator did not confine historical posts to the posts folder.'
}
$checksPassed++

$validBranch = Invoke-DocumentationCheck -Arguments @('-BranchNameProbe', 'docs/project-journal-and-system-map')
if ($validBranch.ExitCode -ne 0) { throw "The branch validator rejected a clear outcome branch.`n$($validBranch.Output)" }
$checksPassed++

$toolBranch = Invoke-DocumentationCheck -Arguments @('-BranchNameProbe', 'docs/codex-journal')
if ($toolBranch.ExitCode -eq 0 -or $toolBranch.Output -notmatch "prohibited vague or performer segment 'codex'") {
    throw 'The branch validator did not reject a tool-named outcome.'
}
$checksPassed++

$vagueBranch = Invoke-DocumentationCheck -Arguments @('-BranchNameProbe', 'maintenance/misc-changes')
if ($vagueBranch.ExitCode -eq 0 -or $vagueBranch.Output -notmatch "prohibited vague or performer segment") {
    throw 'The branch validator did not reject vague outcome segments.'
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
exit 0
