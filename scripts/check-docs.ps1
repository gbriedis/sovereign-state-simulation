param(
    [string]$WorkflowStatePath,
    [string]$TaxonomyProbeType,
    [string]$TaxonomyProbePath
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$documentationRoot = Join-Path $repositoryRoot 'docs'
$canonicalWorkflowStatePath = Join-Path $documentationRoot 'operations/KNOWLEDGE_WORKFLOW_STATE.md'
$workflowStatePath = if ([string]::IsNullOrWhiteSpace($WorkflowStatePath)) {
    $canonicalWorkflowStatePath
} else {
    [System.IO.Path]::GetFullPath($WorkflowStatePath)
}
$documentationFiles = @(Get-ChildItem -LiteralPath $documentationRoot -Recurse -File -Filter '*.md')
$allMarkdownFiles = @(
    Get-ChildItem -LiteralPath $repositoryRoot -File -Filter '*.md'
    Get-ChildItem -LiteralPath $documentationRoot -Recurse -File -Filter '*.md'
)

$errors = [System.Collections.Generic.List[string]]::new()
$allowedStatuses = @('draft', 'proposed', 'accepted', 'superseded')
$requiredFields = @('id', 'type', 'status', 'scope', 'authority', 'last_reviewed')
$ids = @{}
$documentTypeLocations = @{
    'documentation-standard' = '^docs/README\.md$'
    'document-index' = '^docs/INDEX\.md$'
    'architecture-overview' = '^docs/architecture/[^/]+\.md$'
    'implementation-specification' = '^docs/architecture/[^/]+\.md$'
    'open-decision-register' = '^docs/architecture/[^/]+\.md$'
    'brand-standard' = '^docs/brand/[^/]+\.md$'
    'decision-record-index' = '^docs/decisions/[^/]+\.md$'
    'decision-record' = '^docs/decisions/[^/]+\.md$'
    'product-vision' = '^docs/foundations/[^/]+\.md$'
    'design-principles' = '^docs/foundations/[^/]+\.md$'
    'glossary' = '^docs/foundations/[^/]+\.md$'
    'agent-role' = '^docs/governance/roles/[^/]+\.md$'
    'collaboration-protocol' = '^docs/governance/workflows/[^/]+\.md$'
    'operational-handoff' = '^docs/operations/[^/]+\.md$'
    'workflow-state' = '^docs/operations/[^/]+\.md$'
    'phase-roadmap' = '^docs/planning/[^/]+\.md$'
    'authoring-protocol' = '^docs/world-generation/[^/]+\.md$'
    'source-of-truth-index' = '^docs/world-generation/[^/]+\.md$'
    'world-generation-specification' = '^docs/world-generation/[^/]+\.md$'
    'world-generation-exploration' = '^docs/world-generation/[^/]+\.md$'
}

function Add-DocumentationError {
    param([string]$Message)
    $errors.Add($Message)
}

function Test-DocumentTypeLocation {
    param(
        [string]$DocumentType,
        [string]$RelativePath
    )

    if (-not $documentTypeLocations.ContainsKey($DocumentType)) {
        Add-DocumentationError "$RelativePath uses ungoverned document type '$DocumentType'; add its subject-folder mapping to docs/README.md and scripts/check-docs.ps1 before using it."
    } elseif ($RelativePath -notmatch $documentTypeLocations[$DocumentType]) {
        Add-DocumentationError "$RelativePath is misfiled for document type '$DocumentType'; its governed subject-folder mapping is defined in docs/README.md."
    }
}

function ConvertFrom-CommandResultFields {
    param([string]$Text)

    $fields = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::Ordinal)
    foreach ($line in ($Text -split '\r?\n')) {
        $fieldMatch = [regex]::Match($line, '^(?<name>[a-z_]+):[ \t]*(?<value>.*?)[ \t]*$')
        if ($fieldMatch.Success) {
            $fields[$fieldMatch.Groups['name'].Value] = $fieldMatch.Groups['value'].Value
        }
    }
    return $fields
}

function Get-FrontMatter {
    param(
        [string]$Text,
        [string]$RelativePath
    )

    if (-not $Text.StartsWith("---`n") -and -not $Text.StartsWith("---`r`n")) {
        Add-DocumentationError "$RelativePath does not begin with YAML front matter."
        return $null
    }

    $match = [regex]::Match($Text, '(?s)\A---\r?\n(.*?)\r?\n---\r?\n')
    if (-not $match.Success) {
        Add-DocumentationError "$RelativePath has malformed YAML front matter."
        return $null
    }

    $fields = @{}
    foreach ($line in ($match.Groups[1].Value -split '\r?\n')) {
        if ($line -match '^([a-z_]+):\s*(.+?)\s*$') {
            $fields[$matches[1]] = $matches[2]
        }
    }
    return $fields
}

foreach ($file in $documentationFiles) {
    $relativePath = [System.IO.Path]::GetRelativePath($repositoryRoot, $file.FullName).Replace('\', '/')
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $frontMatter = Get-FrontMatter -Text $text -RelativePath $relativePath

    if ($null -ne $frontMatter) {
        foreach ($field in $requiredFields) {
            if (-not $frontMatter.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($frontMatter[$field])) {
                Add-DocumentationError "$relativePath is missing required metadata field '$field'."
            }
        }

        if ($frontMatter.ContainsKey('status') -and $frontMatter['status'] -notin $allowedStatuses) {
            Add-DocumentationError "$relativePath uses invalid status '$($frontMatter['status'])'."
        }

        if ($frontMatter.ContainsKey('last_reviewed') -and $frontMatter['last_reviewed'] -notmatch '^\d{4}-\d{2}-\d{2}$') {
            Add-DocumentationError "$relativePath has invalid last_reviewed date '$($frontMatter['last_reviewed'])'."
        }

        if ($frontMatter.ContainsKey('id')) {
            $id = $frontMatter['id']
            if ($ids.ContainsKey($id)) {
                Add-DocumentationError "Duplicate document ID '$id' in $relativePath and $($ids[$id])."
            } else {
                $ids[$id] = $relativePath
            }
        }

        if ($frontMatter.ContainsKey('type')) {
            Test-DocumentTypeLocation -DocumentType $frontMatter['type'] -RelativePath $relativePath
        }

        if ($frontMatter.ContainsKey('type') -and $frontMatter['type'] -in @('world-generation-specification', 'world-generation-exploration')) {
            foreach ($worldField in @('concept_state', 'coverage', 'implementation')) {
                if (-not $frontMatter.ContainsKey($worldField) -or [string]::IsNullOrWhiteSpace($frontMatter[$worldField])) {
                    Add-DocumentationError "$relativePath is a world-generation topic document and is missing '$worldField'."
                }
            }

            $allowedConceptStates = @('recognized', 'exploring', 'proposed', 'accepted', 'superseded')
            if ($frontMatter.ContainsKey('concept_state') -and $frontMatter['concept_state'] -notin $allowedConceptStates) {
                Add-DocumentationError "$relativePath uses invalid concept_state '$($frontMatter['concept_state'])'."
            }

            $allowedCoverage = @('exploratory', 'partial', 'complete-at-scope')
            if ($frontMatter.ContainsKey('coverage') -and $frontMatter['coverage'] -notin $allowedCoverage) {
                Add-DocumentationError "$relativePath uses invalid coverage '$($frontMatter['coverage'])'."
            }

            if ($frontMatter['status'] -eq 'accepted' -and $frontMatter['concept_state'] -ne 'accepted') {
                Add-DocumentationError "$relativePath is accepted but its concept_state is not accepted."
            }
        }
    }

    $headingText = [regex]::Replace($text, '(?s)```.*?```', '')
    $h1Count = ([regex]::Matches($headingText, '(?m)^# [^#]')).Count
    if ($h1Count -ne 1) {
        Add-DocumentationError "$relativePath must contain exactly one level-one heading; found $h1Count."
    }
}

if (-not [string]::IsNullOrWhiteSpace($TaxonomyProbeType) -or -not [string]::IsNullOrWhiteSpace($TaxonomyProbePath)) {
    if ([string]::IsNullOrWhiteSpace($TaxonomyProbeType) -or [string]::IsNullOrWhiteSpace($TaxonomyProbePath)) {
        Add-DocumentationError 'Taxonomy probes require both -TaxonomyProbeType and -TaxonomyProbePath.'
    } else {
        Test-DocumentTypeLocation -DocumentType $TaxonomyProbeType -RelativePath $TaxonomyProbePath.Replace('\', '/')
    }
}

$allowedDocumentationRootFiles = @('README.md', 'INDEX.md')
$allowedDocumentationFolders = @('architecture', 'brand', 'decisions', 'foundations', 'governance', 'operations', 'planning', 'world-generation')
foreach ($file in (Get-ChildItem -LiteralPath $documentationRoot -File -Filter '*.md')) {
    if ($file.Name -notin $allowedDocumentationRootFiles) {
        Add-DocumentationError "docs/$($file.Name) is outside the governed subject-folder taxonomy; only README.md and INDEX.md remain at the documentation root."
    }
}
foreach ($directory in (Get-ChildItem -LiteralPath $documentationRoot -Directory)) {
    if ($directory.Name -notin $allowedDocumentationFolders) {
        Add-DocumentationError "docs/$($directory.Name)/ is outside the governed subject-folder taxonomy."
    }
}

$governanceRoot = Join-Path $documentationRoot 'governance'
$allowedGovernanceFolders = @('roles', 'workflows')
foreach ($file in (Get-ChildItem -LiteralPath $governanceRoot -File -Filter '*.md' -ErrorAction SilentlyContinue)) {
    Add-DocumentationError "docs/governance/$($file.Name) must be classified under governance/roles or governance/workflows."
}
foreach ($directory in (Get-ChildItem -LiteralPath $governanceRoot -Directory -ErrorAction SilentlyContinue)) {
    if ($directory.Name -notin $allowedGovernanceFolders) {
        Add-DocumentationError "docs/governance/$($directory.Name)/ is outside the governed governance taxonomy."
    }
}

foreach ($file in $allMarkdownFiles) {
    $relativePath = [System.IO.Path]::GetRelativePath($repositoryRoot, $file.FullName)
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $links = [regex]::Matches($text, '\[[^\]]+\]\(([^)]+)\)')

    foreach ($link in $links) {
        $target = $link.Groups[1].Value.Split('#')[0]
        if ([string]::IsNullOrWhiteSpace($target) -or $target -match '^(https?|mailto):') {
            continue
        }

        $resolvedTarget = Join-Path $file.DirectoryName $target
        if (-not (Test-Path -LiteralPath $resolvedTarget)) {
            Add-DocumentationError "$relativePath contains broken relative link '$target'."
        }
    }
}

$routeAuditFiles = @(
    $allMarkdownFiles
    Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'scripts') -File -Filter '*.ps1' -ErrorAction SilentlyContinue
    Get-ChildItem -LiteralPath (Join-Path $repositoryRoot '.github') -Recurse -File -Include '*.yml', '*.yaml' -ErrorAction SilentlyContinue
)
$obsoleteDocumentationPaths = @(
    'docs/agents/',
    'docs/handoff/',
    'docs/PROJECT_VISION.md',
    'docs/DESIGN_PRINCIPLES.md',
    'docs/GLOSSARY.md',
    'docs/NATURAL_WORLD_FOUNDATION_ROADMAP.md',
    'docs/KNOWLEDGE_DEVELOPMENT_WORKFLOW.md'
)

function Remove-FencedWorkflowContractEvidence {
    param([string]$Text)

    $contractsBySection = @{
        'Developer handoff' = 'DEVELOPER_HANDOFF'
        'Reviewer findings and outcome' = 'REVIEW_OUTCOME'
    }
    foreach ($sectionName in $contractsBySection.Keys) {
        $contractName = $contractsBySection[$sectionName]
        $sectionPattern = '(?ms)^## ' + [regex]::Escape($sectionName) + '\r?\n.*?(?=^## |\z)'
        $Text = [regex]::Replace($Text, $sectionPattern, {
            param($sectionMatch)
            $contractPattern = '(?ms)```text\s*\r?\n' + [regex]::Escape($contractName) + '\r?\n.*?\r?\n```'
            $replacement = '```text' + "`n" + $contractName + "`n<historical worker contract omitted from route audit>`n" + '```'
            return [regex]::Replace($sectionMatch.Value, $contractPattern, $replacement)
        })
    }
    return $Text
}

foreach ($file in $routeAuditFiles) {
    if ([System.IO.Path]::GetFullPath($file.FullName) -eq [System.IO.Path]::GetFullPath($PSCommandPath)) {
        continue
    }
    $auditPath = if (
        [System.IO.Path]::GetFullPath($file.FullName) -eq [System.IO.Path]::GetFullPath($canonicalWorkflowStatePath)
    ) { $workflowStatePath } else { $file.FullName }
    $text = Get-Content -Raw -LiteralPath $auditPath
    $relativePath = [System.IO.Path]::GetRelativePath($repositoryRoot, $file.FullName).Replace('\', '/')
    if ([System.IO.Path]::GetFullPath($file.FullName) -eq [System.IO.Path]::GetFullPath($canonicalWorkflowStatePath)) {
        $text = Remove-FencedWorkflowContractEvidence -Text $text
    }
    foreach ($obsoletePath in $obsoleteDocumentationPaths) {
        if ($text.Contains($obsoletePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            Add-DocumentationError "$relativePath references obsolete documentation path '$obsoletePath'."
        }
    }

    foreach ($pathMatch in [regex]::Matches($text, '`(?<path>(?:\./)?(?:docs|scripts|\.github)/[A-Za-z0-9_./*?-]+)`')) {
        $declaredPath = $pathMatch.Groups['path'].Value -replace '^\./', ''
        $resolvedPath = Join-Path $repositoryRoot $declaredPath
        $pathExists = if ($declaredPath -match '[*?]') {
            @(Get-ChildItem -Path $resolvedPath -ErrorAction SilentlyContinue).Count -gt 0
        } else {
            Test-Path -LiteralPath $resolvedPath
        }
        if (-not $pathExists) {
            Add-DocumentationError "$relativePath references missing repository path '$declaredPath'."
        }
    }
}

$routingFiles = @(
    (Join-Path $documentationRoot 'INDEX.md'),
    (Join-Path $documentationRoot 'world-generation/README.md'),
    (Join-Path $documentationRoot 'decisions/README.md')
)
$routedTargets = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($routingFile in $routingFiles) {
    $routingText = Get-Content -Raw -LiteralPath $routingFile
    foreach ($link in [regex]::Matches($routingText, '\[[^\]]+\]\(([^)]+)\)')) {
        $target = $link.Groups[1].Value.Split('#')[0]
        if ([string]::IsNullOrWhiteSpace($target) -or $target -match '^(https?|mailto):') {
            continue
        }
        $resolved = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $routingFile) $target))
        $null = $routedTargets.Add($resolved)
    }
}

$routingFileSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($routingFile in $routingFiles) {
    $null = $routingFileSet.Add([System.IO.Path]::GetFullPath($routingFile))
}

foreach ($file in $documentationFiles) {
    $fullPath = [System.IO.Path]::GetFullPath($file.FullName)
    if (-not $routingFileSet.Contains($fullPath) -and -not $routedTargets.Contains($fullPath)) {
        $relativePath = [System.IO.Path]::GetRelativePath($repositoryRoot, $fullPath)
        Add-DocumentationError "$relativePath is active but is not routed by a source-of-truth index."
    }
}

$technicalRoots = @(
    (Join-Path $documentationRoot 'architecture'),
    (Join-Path $documentationRoot 'world-generation')
)
foreach ($technicalRoot in $technicalRoots) {
    foreach ($file in (Get-ChildItem -LiteralPath $technicalRoot -Recurse -File -Filter '*.md')) {
        $text = Get-Content -Raw -LiteralPath $file.FullName
        $relativePath = [System.IO.Path]::GetRelativePath($repositoryRoot, $file.FullName)
        if ($text -match '(?i)\b(neighbour|neighbouring|modelling)\b') {
            Add-DocumentationError "$relativePath uses non-standard technical spelling; use American English."
        }
        if ($text -match 'PROTOTYPE_V0\.1|TECH_ARCHITECTURE_v0\.1|simulation/world core') {
            Add-DocumentationError "$relativePath references obsolete documentation terminology."
        }
        if ($file.Name -ne 'OPEN_DECISIONS.md' -and $text -match '(?i)\b(likely|probably|possibly|candidate|candidates)\b') {
            Add-DocumentationError "$relativePath uses tentative wording outside the open-decision register. State the decision or label the question explicitly."
        }
    }
}

$worldIndexPath = Join-Path $documentationRoot 'world-generation/README.md'
$worldIndexText = Get-Content -Raw -LiteralPath $worldIndexPath
$conceptRows = @([regex]::Matches($worldIndexText, '(?m)^\| `(?<id>WG-\d{3})` \|'))
$conceptIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($conceptRow in $conceptRows) {
    $conceptId = $conceptRow.Groups['id'].Value
    if (-not $conceptIds.Add($conceptId)) {
        Add-DocumentationError "docs/world-generation/README.md contains duplicate registered concept '$conceptId'."
    }
}

foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $documentationRoot 'world-generation') -File -Filter '*.md')) {
    if ($file.Name -eq 'README.md') {
        continue
    }
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $frontMatter = Get-FrontMatter -Text $text -RelativePath ([System.IO.Path]::GetRelativePath($repositoryRoot, $file.FullName))
    if ($null -ne $frontMatter -and $frontMatter['id'] -match '^WG-\d{3}$' -and -not $conceptIds.Contains($frontMatter['id'])) {
        Add-DocumentationError "World-generation document ID '$($frontMatter['id'])' has no concept row in docs/world-generation/README.md."
    }
}

$handoffPath = Join-Path $documentationRoot 'operations/CURRENT_STATE.md'
$handoffLineCount = (Get-Content -LiteralPath $handoffPath).Count
if ($handoffLineCount -gt 100) {
    Add-DocumentationError "docs/operations/CURRENT_STATE.md has $handoffLineCount lines; the operational handoff limit is 100."
}

$workflowStateText = Get-Content -Raw -LiteralPath $workflowStatePath
$workflowFrontMatter = Get-FrontMatter -Text $workflowStateText -RelativePath 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md'

function Get-WorkflowSection {
    param(
        [string]$Text,
        [string]$Heading
    )

    $pattern = '(?ms)^## ' + [regex]::Escape($Heading) + '\r?\n(?<body>.*?)(?=^## |\z)'
    $match = [regex]::Match($Text, $pattern)
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups['body'].Value.Trim()
}

function Get-WorkflowContract {
    param(
        [string]$Section,
        [string]$ContractName
    )

    if ([string]::IsNullOrWhiteSpace($Section)) {
        return $null
    }
    $pattern = '(?ms)```text\s*\r?\n(?<contract>' + [regex]::Escape($ContractName) + '\r?\n.*?)\r?\n```'
    $match = [regex]::Match($Section, $pattern)
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups['contract'].Value
}

function Get-WorkflowContractField {
    param(
        [string]$Contract,
        [string]$Field
    )

    if ([string]::IsNullOrWhiteSpace($Contract)) {
        return $null
    }
    $match = [regex]::Match($Contract, '(?m)^' + [regex]::Escape($Field) + ':[ \t]*([^\r\n]*?)[ \t]*$')
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups[1].Value
}

function Test-WorkflowContractFields {
    param(
        [string]$Contract,
        [string]$ContractName,
        [string[]]$Fields
    )

    foreach ($field in $Fields) {
        $fieldMatch = [regex]::Match($Contract, '(?m)^' + [regex]::Escape($field) + ':[ \t]*([^\r\n]*?)[ \t]*$')
        if (-not $fieldMatch.Success) {
            Add-DocumentationError "Knowledge workflow $ContractName is missing field '$field'."
        } elseif ($field -ne 'findings' -and [string]::IsNullOrWhiteSpace($fieldMatch.Groups[1].Value)) {
            Add-DocumentationError "Knowledge workflow $ContractName field '$field' must not be empty; use 'None' when no item applies."
        }
    }
}

if ($null -ne $workflowFrontMatter) {
    $allowedWorkflowStates = @('idle', 'developing', 'reviewing', 'revising', 'recording-open-decision', 'finalizing')
    $allowedReviewOutcomes = @('none', 'revise', 'accept', 'open-decision-required')
    foreach ($workflowField in @('workflow_state', 'workflow_id', 'round', 'objective', 'developer_worker', 'reviewer_worker', 'review_outcome', 'change_manifest_path', 'change_manifest_id', 'change_manifest_baseline', 'last_completed_workflow_id', 'updated')) {
        if (-not $workflowFrontMatter.ContainsKey($workflowField)) {
            Add-DocumentationError "docs/operations/KNOWLEDGE_WORKFLOW_STATE.md is missing workflow field '$workflowField'."
        }
    }

    if ($workflowFrontMatter['workflow_state'] -notin $allowedWorkflowStates) {
        Add-DocumentationError "Knowledge workflow uses invalid state '$($workflowFrontMatter['workflow_state'])'."
    } elseif ($workflowFrontMatter['review_outcome'] -notin $allowedReviewOutcomes) {
        Add-DocumentationError "Knowledge workflow uses invalid review outcome '$($workflowFrontMatter['review_outcome'])'."
    } elseif ($workflowFrontMatter['developer_worker'] -notin @('none', 'systems-knowledge-developer')) {
        Add-DocumentationError "Knowledge workflow uses invalid developer role token '$($workflowFrontMatter['developer_worker'])'."
    } elseif ($workflowFrontMatter['reviewer_worker'] -notin @('none', 'systems-coherence-reviewer')) {
        Add-DocumentationError "Knowledge workflow uses invalid reviewer role token '$($workflowFrontMatter['reviewer_worker'])'."
    } elseif ($workflowFrontMatter['workflow_state'] -eq 'idle') {
        if ($workflowFrontMatter['workflow_id'] -ne 'none' -or $workflowFrontMatter['round'] -ne '0' -or $workflowFrontMatter['objective'] -ne 'none') {
            Add-DocumentationError 'Idle knowledge workflow must use workflow_id none, round 0, and objective none.'
        }
        if ($workflowFrontMatter['developer_worker'] -ne 'none' -or $workflowFrontMatter['reviewer_worker'] -ne 'none' -or $workflowFrontMatter['review_outcome'] -ne 'none') {
            Add-DocumentationError 'Idle knowledge workflow must not retain worker assignments or a review outcome.'
        }
        if ($workflowFrontMatter['change_manifest_path'] -ne 'none' -or $workflowFrontMatter['change_manifest_id'] -ne 'none' -or $workflowFrontMatter['change_manifest_baseline'] -ne 'none') {
            Add-DocumentationError 'Idle knowledge workflow must not retain accepted-change manifest fields.'
        }

        $frontMatterMatch = [regex]::Match($workflowStateText, '(?s)\A---\r?\n.*?\r?\n---\r?\n')
        $idleBody = $workflowStateText.Substring($frontMatterMatch.Length).Replace("`r`n", "`n").Trim()
        $expectedIdleBody = "# Knowledge Workflow State`n`nNo material knowledge workflow is active.`n`nLast completed workflow: ``$($workflowFrontMatter['last_completed_workflow_id'])``."
        if ($idleBody -ne $expectedIdleBody) {
            Add-DocumentationError 'Idle knowledge workflow body must contain only the explicit idle statement and matching last-completed workflow ID.'
        }
    } else {
        if ($workflowFrontMatter['workflow_id'] -notmatch '^KW-\d{8}-\d{3}$') {
            Add-DocumentationError "Active knowledge workflow has invalid ID '$($workflowFrontMatter['workflow_id'])'."
        }
        $workflowRound = 0
        $workflowRoundValid = [int]::TryParse($workflowFrontMatter['round'], [ref]$workflowRound)
        if (-not $workflowRoundValid -or $workflowRound -lt 1 -or $workflowFrontMatter['objective'] -eq 'none') {
            Add-DocumentationError 'Active knowledge workflow requires a positive round and a real objective.'
        }
        $stageRequirements = @{
            'developing' = @{ Outcome = 'none'; Developer = 'systems-knowledge-developer'; Reviewer = 'none' }
            'reviewing' = @{ Outcome = 'none'; Developer = 'systems-knowledge-developer'; Reviewer = 'systems-coherence-reviewer' }
            'revising' = @{ Outcome = 'revise'; Developer = 'systems-knowledge-developer'; Reviewer = 'systems-coherence-reviewer' }
            'recording-open-decision' = @{ Outcome = 'open-decision-required'; Developer = 'systems-knowledge-developer'; Reviewer = 'systems-coherence-reviewer' }
            'finalizing' = @{ Outcome = 'accept'; Developer = 'systems-knowledge-developer'; Reviewer = 'systems-coherence-reviewer' }
        }
        $stageRequirement = $stageRequirements[$workflowFrontMatter['workflow_state']]
        if ($null -ne $stageRequirement) {
            if ($workflowFrontMatter['review_outcome'] -ne $stageRequirement.Outcome) {
                Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires review_outcome '$($stageRequirement.Outcome)'."
            }
            if ($workflowFrontMatter['developer_worker'] -ne $stageRequirement.Developer) {
                Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires developer_worker '$($stageRequirement.Developer)'."
            }
            if ($workflowFrontMatter['reviewer_worker'] -ne $stageRequirement.Reviewer) {
                Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires reviewer_worker '$($stageRequirement.Reviewer)'."
            }
        }

        $requiredSections = @(
            'Active objective',
            'Affected entries',
            'Input artifacts',
            'Worker references',
            'Accepted-change manifest',
            'Developer handoff',
            'Reviewer findings and outcome',
            'Next required action'
        )
        $workflowSections = @{}
        foreach ($sectionName in $requiredSections) {
            $sectionBody = Get-WorkflowSection -Text $workflowStateText -Heading $sectionName
            $workflowSections[$sectionName] = $sectionBody
            if ($null -eq $sectionBody) {
                Add-DocumentationError "Active knowledge workflow is missing section '## $sectionName'."
            }
        }

        foreach ($listSectionName in @('Affected entries', 'Input artifacts')) {
            $listSection = $workflowSections[$listSectionName]
            if ($null -ne $listSection -and $listSection -notmatch '(?m)^-[ \t]+\S') {
                Add-DocumentationError "Active knowledge workflow section '## $listSectionName' must contain at least one list item."
            }
        }

        $affectedEntrySection = $workflowSections['Affected entries']
        foreach ($affectedEntryLine in @([regex]::Matches($affectedEntrySection, '(?m)^-[ \t]+(.+?)[ \t]*$'))) {
            $affectedEntry = $affectedEntryLine.Groups[1].Value.Trim().Trim('`')
            $isStableId = $ids.ContainsKey($affectedEntry)
            $isRepositoryPath = -not [System.IO.Path]::IsPathRooted($affectedEntry) -and
                $affectedEntry -notmatch '(^|/)\.\.(/|$)' -and
                $affectedEntry -match '^(?=.+(?:/|\.[A-Za-z0-9]+$))[A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)*$'
            if (-not $isStableId -and -not $isRepositoryPath) {
                Add-DocumentationError "Affected entry '$affectedEntry' must be a registered documentation ID or an explicit repository-relative path."
            }
        }

        foreach ($textSectionName in @('Active objective', 'Next required action')) {
            if ([string]::IsNullOrWhiteSpace($workflowSections[$textSectionName])) {
                Add-DocumentationError "Active knowledge workflow section '## $textSectionName' must not be empty."
            }
        }

        $expectedNextActions = @{
            'developing' = "Await the Systems Knowledge Developer DEVELOPER_HANDOFF for round $workflowRound; if the recorded task-scoped reference is unavailable, reconstruct the same development assignment."
            'reviewing' = "Await the Systems Coherence Reviewer REVIEW_OUTCOME for round $workflowRound; if the recorded task-scoped reference is unavailable, reconstruct the same review assignment."
            'revising' = "Await the Systems Knowledge Developer revised DEVELOPER_HANDOFF for round $workflowRound; if the recorded task-scoped reference is unavailable, reconstruct the same revision assignment with the preceding REVIEW_OUTCOME."
            'recording-open-decision' = "Await the Systems Knowledge Developer open-decision DEVELOPER_HANDOFF for round $workflowRound; if the recorded task-scoped reference is unavailable, reconstruct the same assignment with the preceding REVIEW_OUTCOME."
            'finalizing' = 'Materialize the accepted manifest idle checkpoint, verify the final worktree, run ./scripts/check-docs.ps1 against the materialized state, and only then complete any separately authorized Git handoff.'
        }
        $expectedNextAction = $expectedNextActions[$workflowFrontMatter['workflow_state']]
        $actualNextAction = [regex]::Replace($workflowSections['Next required action'], '\s+', ' ').Trim()
        if ($null -ne $expectedNextAction -and $actualNextAction -ne $expectedNextAction) {
            Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' has a stale or invalid next required action."
        }

        $workerSection = $workflowSections['Worker references']
        $workerRoleFields = @{
            'Developer role token' = 'developer_worker'
            'Reviewer role token' = 'reviewer_worker'
        }
        foreach ($workerLabel in $workerRoleFields.Keys) {
            $workerMatch = [regex]::Match($workerSection, '(?m)^-[ \t]+' + [regex]::Escape($workerLabel) + ':[ \t]*(.+?)[ \t]*$')
            $workerValue = if ($workerMatch.Success) { $workerMatch.Groups[1].Value.Trim().Trim('`') } else { $null }
            $expectedWorkerValue = $workflowFrontMatter[$workerRoleFields[$workerLabel]]
            if ([string]::IsNullOrWhiteSpace($workerValue) -or $workerValue -ne $expectedWorkerValue) {
                Add-DocumentationError "Active knowledge workflow '$workerLabel' must match front-matter $($workerRoleFields[$workerLabel]) '$expectedWorkerValue'."
            }
            if ($workerValue -eq 'unavailable') {
                Add-DocumentationError "Active knowledge workflow must not use 'unavailable' as a role token."
            }
        }
        foreach ($workerLabel in @('Developer task-scoped reference', 'Reviewer task-scoped reference')) {
            $workerMatch = [regex]::Match($workerSection, '(?m)^-[ \t]+' + [regex]::Escape($workerLabel) + ':[ \t]*(.+?)[ \t]*$')
            $workerValue = if ($workerMatch.Success) { $workerMatch.Groups[1].Value.Trim().Trim('`') } else { $null }
            if ([string]::IsNullOrWhiteSpace($workerValue) -or $workerValue -eq 'none') {
                Add-DocumentationError "Active knowledge workflow must record '$workerLabel' or use 'unavailable'."
            }
        }

        $manifestSection = $workflowSections['Accepted-change manifest']
        $manifestLabels = [ordered]@{
            'Path' = 'change_manifest_path'
            'ID' = 'change_manifest_id'
            'Baseline commit' = 'change_manifest_baseline'
        }
        foreach ($manifestLabel in $manifestLabels.Keys) {
            $manifestMatch = [regex]::Match($manifestSection, '(?m)^-[ \t]+' + [regex]::Escape($manifestLabel) + ':[ \t]*(.+?)[ \t]*$')
            $manifestValue = if ($manifestMatch.Success) { $manifestMatch.Groups[1].Value.Trim().Trim('`') } else { $null }
            $expectedManifestValue = $workflowFrontMatter[$manifestLabels[$manifestLabel]]
            if ([string]::IsNullOrWhiteSpace($manifestValue) -or $manifestValue -ne $expectedManifestValue) {
                Add-DocumentationError "Active knowledge workflow manifest '$manifestLabel' must match front-matter $($manifestLabels[$manifestLabel]) '$expectedManifestValue'."
            }
        }
        $finalStateMatch = [regex]::Match($manifestSection, '(?m)^-[ \t]+Final workflow-state path:[ \t]*(.+?)[ \t]*$')
        $finalStateValue = if ($finalStateMatch.Success) { $finalStateMatch.Groups[1].Value.Trim().Trim('`') } else { $null }
        $manifestRequired = $workflowFrontMatter['workflow_state'] -in @('reviewing', 'finalizing')
        if ($manifestRequired) {
            if ($workflowFrontMatter['change_manifest_path'] -notmatch '^\.git/codex/accepted-change-manifests/KW-\d{8}-\d{3}\.json$') {
                Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires a canonical transient manifest path."
            }
            if ($workflowFrontMatter['change_manifest_id'] -notmatch '^[0-9a-f]{64}$') {
                Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires a SHA-256 manifest ID."
            }
            if ($workflowFrontMatter['change_manifest_baseline'] -notmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$') {
                Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires a full baseline commit ID."
            }
            if ($finalStateValue -ne 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md') {
                Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires the canonical final workflow-state path."
            }

            $manifestAbsolutePath = Join-Path $repositoryRoot $workflowFrontMatter['change_manifest_path']
            if (-not (Test-Path -LiteralPath $manifestAbsolutePath -PathType Leaf)) {
                Add-DocumentationError "Knowledge workflow accepted-change manifest '$($workflowFrontMatter['change_manifest_path'])' is missing."
            } else {
                $manifestOutput = & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'change-manifest.ps1') -Action VerifyReview -ManifestPath $manifestAbsolutePath 2>&1 | Out-String
                $manifestExitCode = $LASTEXITCODE
                $manifestResult = ConvertFrom-CommandResultFields -Text $manifestOutput
                $manifestResultIsExact =
                    $manifestResult.ContainsKey('action') -and $manifestResult['action'] -eq 'verifyreview' -and
                    $manifestResult.ContainsKey('workflow_id') -and $manifestResult['workflow_id'] -eq $workflowFrontMatter['workflow_id'] -and
                    $manifestResult.ContainsKey('manifest_id') -and [string]::Equals($manifestResult['manifest_id'], $workflowFrontMatter['change_manifest_id'], [System.StringComparison]::Ordinal) -and
                    $manifestResult.ContainsKey('verified') -and $manifestResult['verified'] -eq 'yes'
                if ($manifestExitCode -ne 0 -or -not $manifestResultIsExact) {
                    Add-DocumentationError 'Knowledge workflow accepted-change manifest does not verify the current review snapshot and recorded ID.'
                }
            }
        } else {
            if ($workflowFrontMatter['change_manifest_path'] -ne 'none' -or $workflowFrontMatter['change_manifest_id'] -ne 'none' -or $workflowFrontMatter['change_manifest_baseline'] -ne 'none' -or $finalStateValue -ne 'none') {
                Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires all accepted-change manifest values to be 'none'."
            }
        }

        $developerContract = Get-WorkflowContract -Section $workflowSections['Developer handoff'] -ContractName 'DEVELOPER_HANDOFF'
        $reviewContract = Get-WorkflowContract -Section $workflowSections['Reviewer findings and outcome'] -ContractName 'REVIEW_OUTCOME'
        $developerFields = @('workflow_id', 'round', 'objective', 'affected_entries', 'current_concept_state', 'proposed_concept_state', 'accepted_truths_preserved', 'truths_added_changed_or_removed', 'assumptions', 'alternatives_considered', 'known_downstream_consumers', 'open_questions', 'review_finding_dispositions', 'files_added_changed_renamed_or_removed', 'validation_command', 'validation_result', 'ready_for_review')
        $reviewFields = @('workflow_id', 'round', 'outcome', 'summary', 'findings', 'validation_checked', 'remaining_open_decisions', 'accepted_manifest_id')
        if ($null -ne $developerContract) {
            Test-WorkflowContractFields -Contract $developerContract -ContractName 'DEVELOPER_HANDOFF' -Fields $developerFields
        }
        if ($null -ne $reviewContract) {
            Test-WorkflowContractFields -Contract $reviewContract -ContractName 'REVIEW_OUTCOME' -Fields $reviewFields
        }

        $expectedContractRound = $workflowRound
        $developerRequired = $workflowFrontMatter['workflow_state'] -in @('reviewing', 'revising', 'recording-open-decision', 'finalizing')
        $reviewRequired = $workflowFrontMatter['workflow_state'] -in @('revising', 'recording-open-decision', 'finalizing')
        if ($workflowFrontMatter['workflow_state'] -in @('revising', 'recording-open-decision')) {
            $expectedContractRound = $workflowRound - 1
        }

        if ($developerRequired -and $null -eq $developerContract) {
            Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires a complete DEVELOPER_HANDOFF contract."
        } elseif ($null -ne $developerContract) {
            if ((Get-WorkflowContractField -Contract $developerContract -Field 'workflow_id') -ne $workflowFrontMatter['workflow_id']) {
                Add-DocumentationError 'Knowledge workflow DEVELOPER_HANDOFF workflow_id does not match active workflow_id.'
            }
            if ($developerRequired -and (Get-WorkflowContractField -Contract $developerContract -Field 'round') -ne [string]$expectedContractRound) {
                Add-DocumentationError "Knowledge workflow DEVELOPER_HANDOFF round must be $expectedContractRound for state '$($workflowFrontMatter['workflow_state'])'."
            }
            $readyForReview = Get-WorkflowContractField -Contract $developerContract -Field 'ready_for_review'
            if ($readyForReview -notin @('yes', 'no')) {
                Add-DocumentationError "Knowledge workflow DEVELOPER_HANDOFF ready_for_review must be 'yes' or 'no'."
            }
            if ($workflowFrontMatter['workflow_state'] -in @('reviewing', 'finalizing') -and $readyForReview -ne 'yes') {
                Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires ready_for_review yes."
            }
        }

        if ($reviewRequired -and $null -eq $reviewContract) {
            Add-DocumentationError "Knowledge workflow state '$($workflowFrontMatter['workflow_state'])' requires a complete REVIEW_OUTCOME contract."
        } elseif ($null -ne $reviewContract) {
            if ((Get-WorkflowContractField -Contract $reviewContract -Field 'workflow_id') -ne $workflowFrontMatter['workflow_id']) {
                Add-DocumentationError 'Knowledge workflow REVIEW_OUTCOME workflow_id does not match active workflow_id.'
            }
            if ($reviewRequired -and (Get-WorkflowContractField -Contract $reviewContract -Field 'round') -ne [string]$expectedContractRound) {
                Add-DocumentationError "Knowledge workflow REVIEW_OUTCOME round must be $expectedContractRound for state '$($workflowFrontMatter['workflow_state'])'."
            }
            if ($reviewRequired -and (Get-WorkflowContractField -Contract $reviewContract -Field 'outcome') -ne $workflowFrontMatter['review_outcome']) {
                Add-DocumentationError 'Knowledge workflow REVIEW_OUTCOME does not match front-matter review_outcome.'
            }
            $reviewManifestId = Get-WorkflowContractField -Contract $reviewContract -Field 'accepted_manifest_id'
            if ($workflowFrontMatter['workflow_state'] -eq 'finalizing' -and $reviewManifestId -ne $workflowFrontMatter['change_manifest_id']) {
                Add-DocumentationError 'Knowledge workflow finalizing REVIEW_OUTCOME accepted_manifest_id must match the recorded manifest ID.'
            }
            if ($workflowFrontMatter['workflow_state'] -ne 'finalizing' -and $reviewManifestId -ne 'None') {
                Add-DocumentationError 'Non-accept REVIEW_OUTCOME accepted_manifest_id must be None.'
            }

            $contractOutcome = Get-WorkflowContractField -Contract $reviewContract -Field 'outcome'
            $findingMatches = @([regex]::Matches($reviewContract, '(?ms)^[ \t]{2}- severity:[ \t]*(?<severity>blocking|major|minor|polish)[ \t]*\r?\n(?<body>.*?)(?=^[ \t]{2}- severity:|^validation_checked:)'))
            $findingsInline = Get-WorkflowContractField -Contract $reviewContract -Field 'findings'
            if ($findingMatches.Count -eq 0 -and $findingsInline -ne '[]') {
                Add-DocumentationError "Knowledge workflow REVIEW_OUTCOME findings must be '[]' or contain structured finding entries."
            }
            if ($contractOutcome -in @('revise', 'open-decision-required') -and $findingMatches.Count -eq 0) {
                Add-DocumentationError "Knowledge workflow REVIEW_OUTCOME '$contractOutcome' requires at least one structured finding."
            }
            foreach ($findingMatch in $findingMatches) {
                foreach ($findingField in @('location', 'affected_concept_or_authority', 'problem', 'long_term_consequence', 'required_resolution_or_question')) {
                    if ($findingMatch.Groups['body'].Value -notmatch ('(?m)^[ \t]{4}' + [regex]::Escape($findingField) + ':[ \t]*\S')) {
                        Add-DocumentationError "Knowledge workflow REVIEW_OUTCOME finding is missing non-empty field '$findingField'."
                    }
                }
                if ($contractOutcome -eq 'accept' -and $findingMatch.Groups['severity'].Value -in @('blocking', 'major')) {
                    Add-DocumentationError "Knowledge workflow REVIEW_OUTCOME accept cannot contain a '$($findingMatch.Groups['severity'].Value)' finding."
                }
            }
        }

        if ($workflowFrontMatter['workflow_state'] -eq 'developing') {
            if ($workflowSections['Developer handoff'] -ne 'Pending.' -or $workflowSections['Reviewer findings and outcome'] -ne 'Pending.') {
                Add-DocumentationError "Knowledge workflow state 'developing' requires both contract sections to contain exactly 'Pending.'."
            }
        }
        if ($workflowFrontMatter['workflow_state'] -eq 'reviewing' -and $workflowSections['Reviewer findings and outcome'] -ne 'Pending.') {
            Add-DocumentationError "Knowledge workflow state 'reviewing' requires reviewer findings and outcome to contain exactly 'Pending.'."
        }
    }

    if ($workflowFrontMatter['updated'] -notmatch '^\d{4}-\d{2}-\d{2}$') {
        Add-DocumentationError "Knowledge workflow has invalid updated date '$($workflowFrontMatter['updated'])'."
    }
    if ($workflowFrontMatter['last_completed_workflow_id'] -ne 'none' -and $workflowFrontMatter['last_completed_workflow_id'] -notmatch '^KW-\d{8}-\d{3}$') {
        Add-DocumentationError "Knowledge workflow has invalid last_completed_workflow_id '$($workflowFrontMatter['last_completed_workflow_id'])'."
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Documentation validation failed with $($errors.Count) error(s):" -ForegroundColor Red
    foreach ($documentationError in $errors) {
        Write-Host "- $documentationError" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Documentation validation passed: $($documentationFiles.Count) active docs, $($ids.Count) unique IDs, no broken links." -ForegroundColor Green
