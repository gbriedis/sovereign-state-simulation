param(
    [string]$WorkflowStatePath,
    [string]$TaxonomyProbeType,
    [string]$TaxonomyProbePath
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$docsRoot = Join-Path $root 'docs'
$canonicalState = Join-Path $docsRoot 'operations/KNOWLEDGE_WORKFLOW_STATE.md'
$statePath = if ($WorkflowStatePath) { [IO.Path]::GetFullPath($WorkflowStatePath) } else { $canonicalState }
$errors = [Collections.Generic.List[string]]::new()
$ids = @{}

$locations = @{
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

function Add-Error([string]$Message) { $errors.Add($Message) }

function Get-FrontMatter([string]$Text, [string]$RelativePath) {
    $match = [regex]::Match($Text, '(?s)\A---\r?\n(?<body>.*?)\r?\n---\r?\n')
    if (-not $match.Success) {
        Add-Error "$RelativePath does not begin with valid YAML front matter."
        return $null
    }
    $fields = @{}
    foreach ($line in ($match.Groups['body'].Value -split '\r?\n')) {
        if ($line -match '^([a-z_]+):\s*(.*?)\s*$') { $fields[$matches[1]] = $matches[2] }
    }
    return $fields
}

function Test-Location([string]$Type, [string]$Path) {
    if (-not $locations.ContainsKey($Type)) {
        Add-Error "$Path uses ungoverned document type '$Type'."
    } elseif ($Path -notmatch $locations[$Type]) {
        Add-Error "$Path is misfiled for document type '$Type'."
    }
}

function Get-Section([string]$Text, [string]$Heading) {
    $match = [regex]::Match($Text, '(?ms)^## ' + [regex]::Escape($Heading) + '\r?\n(?<body>.*?)(?=^## |\z)')
    if ($match.Success) { return $match.Groups['body'].Value.Trim() }
    return $null
}

function Get-FencedContract([string]$Section, [string]$ContractName) {
    if ([string]::IsNullOrWhiteSpace($Section)) { return $null }
    $match = [regex]::Match($Section, '(?ms)```text\s*\r?\n(?<body>' + [regex]::Escape($ContractName) + '\r?\n.*?)\r?\n```')
    if ($match.Success) { return $match.Groups['body'].Value }
    return $null
}

$documents = @(Get-ChildItem -LiteralPath $docsRoot -Recurse -File -Filter '*.md')
foreach ($file in $documents) {
    $path = [IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $front = Get-FrontMatter $text $path
    if ($null -ne $front) {
        foreach ($field in @('id', 'type', 'status', 'scope', 'authority', 'last_reviewed')) {
            if (-not $front.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($front[$field])) {
                Add-Error "$path is missing required metadata field '$field'."
            }
        }
        if ($front.status -notin @('draft', 'proposed', 'accepted', 'superseded')) {
            Add-Error "$path uses invalid status '$($front.status)'."
        }
        if ($front.last_reviewed -notmatch '^\d{4}-\d{2}-\d{2}$') {
            Add-Error "$path has invalid last_reviewed date '$($front.last_reviewed)'."
        }
        if ($front.id) {
            if ($ids.ContainsKey($front.id)) { Add-Error "Duplicate document ID '$($front.id)' in $path and $($ids[$front.id])." }
            else { $ids[$front.id] = $path }
        }
        if ($front.type) { Test-Location $front.type $path }

        if ($front.type -in @('world-generation-specification', 'world-generation-exploration')) {
            foreach ($field in @('concept_state', 'coverage', 'implementation')) {
                if (-not $front.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($front[$field])) {
                    Add-Error "$path is a world-generation topic and is missing '$field'."
                }
            }
            if ($front.concept_state -notin @('recognized', 'exploring', 'proposed', 'accepted', 'superseded')) { Add-Error "$path has invalid concept_state '$($front.concept_state)'." }
            if ($front.coverage -notin @('exploratory', 'partial', 'complete-at-scope')) { Add-Error "$path has invalid coverage '$($front.coverage)'." }
            if ($front.status -eq 'accepted' -and $front.concept_state -ne 'accepted') { Add-Error "$path is accepted but its concept_state is not accepted." }
        }
    }
    $withoutFences = [regex]::Replace($text, '(?s)```.*?```', '')
    $h1Count = [regex]::Matches($withoutFences, '(?m)^# [^#]').Count
    if ($h1Count -ne 1) { Add-Error "$path must contain exactly one level-one heading; found $h1Count." }
}

if ($TaxonomyProbeType -or $TaxonomyProbePath) {
    if (-not $TaxonomyProbeType -or -not $TaxonomyProbePath) { Add-Error 'Taxonomy probes require both parameters.' }
    else { Test-Location $TaxonomyProbeType $TaxonomyProbePath.Replace('\', '/') }
}

$allowedRootFiles = @('README.md', 'INDEX.md')
foreach ($file in (Get-ChildItem -LiteralPath $docsRoot -File -Filter '*.md')) {
    if ($file.Name -notin $allowedRootFiles) { Add-Error "docs/$($file.Name) is outside the subject-folder taxonomy." }
}
$allowedFolders = @('architecture', 'brand', 'decisions', 'foundations', 'governance', 'operations', 'planning', 'world-generation')
foreach ($folder in (Get-ChildItem -LiteralPath $docsRoot -Directory)) {
    if ($folder.Name -notin $allowedFolders) { Add-Error "docs/$($folder.Name)/ is outside the subject-folder taxonomy." }
}

$markdown = @((Get-ChildItem -LiteralPath $root -File -Filter '*.md'); $documents)
foreach ($file in $markdown) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $path = [IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')
    foreach ($link in [regex]::Matches($text, '\[[^\]]+\]\(([^)]+)\)')) {
        $target = $link.Groups[1].Value.Split('#')[0]
        if (-not $target -or $target -match '^(https?|mailto):') { continue }
        if (-not (Test-Path -LiteralPath (Join-Path $file.DirectoryName $target))) { Add-Error "$path contains broken relative link '$target'." }
    }
}

$obsolete = @(
    'KNOWLEDGE_WORKFLOW_COORDINATOR.md',
    'REPOSITORY_GIT_STEWARD.md', 'AGENT-GIT-STEWARD', 'repository-git-steward',
    'check-git-executable-policy.ps1', 'check-git-hooks.ps1', 'check-git-publish.ps1',
    'reconciliation-packet.ps1', 'record-reviewed-merge.ps1',
    'test-git-executable-policy.ps1', 'test-git-hooks.ps1', 'test-git-publish.ps1',
    'test-reconciliation-packet.ps1', 'bounded-correction', 'Route convergence record'
)
$activeStateText = Get-Content -Raw -LiteralPath $statePath
$activeStateFront = Get-FrontMatter $activeStateText 'docs/operations/KNOWLEDGE_WORKFLOW_STATE.md'
foreach ($file in @($markdown; Get-ChildItem -LiteralPath (Join-Path $root 'scripts') -File -Filter '*.ps1'; Get-ChildItem -LiteralPath (Join-Path $root '.github') -Recurse -File -Include '*.yml','*.yaml' -ErrorAction SilentlyContinue)) {
    if ([IO.Path]::GetFullPath($file.FullName) -eq [IO.Path]::GetFullPath($PSCommandPath)) { continue }
    if ($file.FullName -eq $canonicalState -and ($statePath -ne $canonicalState -or $activeStateFront.workflow_state -ne 'idle')) { continue }
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $path = [IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')
    foreach ($term in $obsolete) {
        if ($text.Contains($term, [StringComparison]::OrdinalIgnoreCase)) { Add-Error "$path references obsolete governance '$term'." }
    }
}

$routing = @('docs/INDEX.md', 'docs/world-generation/README.md', 'docs/decisions/README.md')
$routed = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relative in $routing) {
    $file = Join-Path $root $relative
    $text = Get-Content -Raw -LiteralPath $file
    $null = $routed.Add([IO.Path]::GetFullPath($file))
    foreach ($link in [regex]::Matches($text, '\[[^\]]+\]\(([^)]+)\)')) {
        $target = $link.Groups[1].Value.Split('#')[0]
        if ($target -and $target -notmatch '^(https?|mailto):') { $null = $routed.Add([IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $file) $target))) }
    }
}
foreach ($file in $documents) {
    if (-not $routed.Contains([IO.Path]::GetFullPath($file.FullName))) { Add-Error "$([IO.Path]::GetRelativePath($root, $file.FullName)) is active but is not routed by an index." }
}

foreach ($folder in @('docs/architecture', 'docs/world-generation')) {
    foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $root $folder) -File -Filter '*.md')) {
        $text = Get-Content -Raw -LiteralPath $file.FullName
        $path = [IO.Path]::GetRelativePath($root, $file.FullName)
        if ($text -match '(?i)\b(neighbour|neighbouring|modelling)\b') { Add-Error "$path uses non-standard technical spelling." }
        if ($file.Name -ne 'OPEN_DECISIONS.md' -and $text -match '(?i)\b(likely|probably|possibly|candidate|candidates)\b') { Add-Error "$path uses tentative wording outside the open-decision register." }
    }
}

$worldIndex = Get-Content -Raw -LiteralPath (Join-Path $docsRoot 'world-generation/README.md')
$registered = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($match in [regex]::Matches($worldIndex, '(?m)^\| `(?<id>WG-\d{3})` \|')) {
    if (-not $registered.Add($match.Groups['id'].Value)) { Add-Error "World-generation index duplicates '$($match.Groups['id'].Value)'." }
}
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $docsRoot 'world-generation') -File -Filter '*.md')) {
    if ($file.Name -eq 'README.md') { continue }
    $front = Get-FrontMatter (Get-Content -Raw -LiteralPath $file.FullName) ([IO.Path]::GetRelativePath($root, $file.FullName))
    if ($front.id -match '^WG-\d{3}$' -and -not $registered.Contains($front.id)) { Add-Error "World-generation document '$($front.id)' has no source-of-truth row." }
}

if ((Get-Content -LiteralPath (Join-Path $docsRoot 'operations/CURRENT_STATE.md')).Count -gt 100) { Add-Error 'CURRENT_STATE.md exceeds 100 lines.' }

if ($null -ne $activeStateFront) {
    $state = $activeStateFront.workflow_state
    if ($state -notin @('idle', 'developing', 'reviewing', 'correcting', 'final-review', 'finalizing')) { Add-Error "Workflow state '$state' is invalid." }
    foreach ($field in @('workflow_state','workflow_id','mode','objective','current_owner','correction_used','manifest_id','last_completed_workflow_id','updated')) {
        if (-not $activeStateFront.ContainsKey($field)) { Add-Error "Workflow checkpoint is missing '$field'." }
    }
    if ($state -eq 'idle') {
        foreach ($field in @('workflow_id','mode','objective','current_owner','manifest_id')) {
            if ($activeStateFront[$field] -ne 'none') { Add-Error "Idle workflow requires $field none." }
        }
        if ($activeStateFront.correction_used -ne 'no') { Add-Error 'Idle workflow requires correction_used no.' }
        if ($null -ne (Get-Section $activeStateText 'Review packet')) { Add-Error 'Idle workflow must not retain a Review packet.' }
    } else {
        if ($activeStateFront.workflow_id -notmatch '^KW-\d{8}-\d{3}$') { Add-Error 'Active workflow ID must match KW-YYYYMMDD-NNN.' }
        if ($activeStateFront.mode -notin @('explore','fast','governed')) { Add-Error 'Active workflow mode is invalid.' }
        if ($activeStateFront.objective -eq 'none' -or $activeStateFront.current_owner -eq 'none') { Add-Error 'Active workflow requires an objective and current owner.' }
        if ($activeStateFront.correction_used -notin @('yes','no')) { Add-Error 'correction_used must be yes or no.' }
        $expectedOwner = @{ developing='systems-knowledge-developer'; reviewing='systems-coherence-reviewer'; correcting='systems-knowledge-developer'; 'final-review'='systems-coherence-reviewer'; finalizing='outcome-lead' }[$state]
        if ($activeStateFront.current_owner -ne $expectedOwner) { Add-Error "Workflow state '$state' requires current_owner '$expectedOwner'." }
        if ($state -in @('reviewing','final-review','finalizing') -and $activeStateFront.manifest_id -notmatch '^[0-9a-f]{64}$') { Add-Error "Workflow state '$state' requires a manifest ID." }
        if ($state -in @('developing','correcting') -and $activeStateFront.manifest_id -ne 'none') { Add-Error "Workflow state '$state' requires manifest_id none until the candidate is snapshotted." }
        if ($state -in @('developing','reviewing') -and $activeStateFront.correction_used -ne 'no') { Add-Error "Workflow state '$state' requires correction_used no." }
        if ($state -in @('correcting','final-review') -and $activeStateFront.correction_used -ne 'yes') { Add-Error "Workflow state '$state' requires correction_used yes." }
        foreach ($section in @('Outcome','Authorized changes','Risks and stop conditions','Progress','Affected entries')) {
            if ([string]::IsNullOrWhiteSpace((Get-Section $activeStateText $section))) { Add-Error "Active workflow is missing section '$section'." }
        }
        $progress = Get-Section $activeStateText 'Progress'
        foreach ($label in @('Completed evidence','Remaining blocker','Next action')) {
            if ($progress -notmatch '(?m)^- ' + [regex]::Escape($label) + ':\s*\S') { Add-Error "Workflow Progress is missing '$label'." }
        }

        if ($state -in @('reviewing','final-review','finalizing')) {
            $reviewPacketSection = Get-Section $activeStateText 'Review packet'
            $developerHandoff = Get-FencedContract $reviewPacketSection 'DEVELOPER_HANDOFF'
            if ([string]::IsNullOrWhiteSpace($developerHandoff)) {
                Add-Error "Workflow state '$state' requires a fenced DEVELOPER_HANDOFF in Review packet."
            } else {
                $requiredHandoffFields = @(
                    'workflow_id','objective','affected_entries','accepted_truth_preserved',
                    'truth_added_changed_or_removed','assumptions','downstream_consumers',
                    'open_questions','review_finding_dispositions',
                    'files_added_changed_renamed_or_removed','validation','ready_for_review'
                )
                foreach ($field in $requiredHandoffFields) {
                    $fieldMatches = [regex]::Matches($developerHandoff, '(?m)^' + [regex]::Escape($field) + ':[ \t]*(?<value>.*?)[ \t]*$')
                    if ($fieldMatches.Count -ne 1) {
                        Add-Error "Workflow Review packet requires exactly one '$field' field."
                    } elseif ([string]::IsNullOrWhiteSpace($fieldMatches[0].Groups['value'].Value)) {
                        Add-Error "Workflow Review packet field '$field' must not be empty; use None when no item applies."
                    }
                }
                $packetWorkflowId = [regex]::Match($developerHandoff, '(?m)^workflow_id:[ \t]*(.*?)[ \t]*$').Groups[1].Value
                if ($packetWorkflowId -ne $activeStateFront.workflow_id) { Add-Error 'Workflow Review packet workflow_id must match the active workflow.' }
                $packetReady = [regex]::Match($developerHandoff, '(?m)^ready_for_review:[ \t]*(.*?)[ \t]*$').Groups[1].Value
                if ($packetReady -ne 'yes') { Add-Error 'Workflow Review packet requires ready_for_review yes.' }
            }
        }
    }
}

if ($errors.Count) {
    Write-Host 'Documentation validation failed:' -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Documentation validation passed: $($documents.Count) documents checked." -ForegroundColor Green
