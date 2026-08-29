param(
    [switch]$Check,
    [string]$RootPath,
    [string]$RegistryPath
)

$ErrorActionPreference = 'Stop'
$root = if ($RootPath) { [IO.Path]::GetFullPath($RootPath) } else { Split-Path -Parent $PSScriptRoot }
$registryFile = if ($RegistryPath) { [IO.Path]::GetFullPath($RegistryPath) } else { Join-Path $root 'docs/project-journal/SYSTEMS.json' }
$errors = [Collections.Generic.List[string]]::new()

function Add-JournalError([string]$Message) { $errors.Add($Message) }

function Get-Relative([string]$Path) {
    return [IO.Path]::GetRelativePath($root, [IO.Path]::GetFullPath($Path)).Replace('\', '/')
}

function Get-FrontMatter([string]$Text, [string]$Path) {
    $match = [regex]::Match($Text, '(?s)\A---\r?\n(?<body>.*?)\r?\n---\r?\n')
    if (-not $match.Success) {
        Add-JournalError "$Path does not begin with valid front matter."
        return @{}
    }
    $fields = @{}
    foreach ($line in ($match.Groups['body'].Value -split '\r?\n')) {
        if ($line -match '^([a-z_]+):\s*(.*?)\s*$') { $fields[$matches[1]] = $matches[2] }
    }
    return $fields
}

function Get-MarkdownLink([string]$FromDirectory, [string]$TargetPath, [string]$Label) {
    $target = Join-Path $root $TargetPath
    $relative = [IO.Path]::GetRelativePath($FromDirectory, $target).Replace('\', '/')
    return "[$Label]($relative)"
}

function Escape-Table([string]$Text) {
    if ($null -eq $Text) { return '' }
    return $Text.Replace('|', '\|').Replace("`r", '').Replace("`n", ' ')
}

function Test-SystemWithin([string]$SystemId, [string]$AncestorId, $SystemLookup) {
    $cursor = $SystemId
    $visited = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    while ($cursor -and $SystemLookup.ContainsKey($cursor)) {
        if ($cursor -eq $AncestorId) { return $true }
        if (-not $visited.Add($cursor)) { return $false }
        $cursor = [string]$SystemLookup[$cursor].parent
    }
    return $false
}

function ConvertTo-CanonicalValue($Value) {
    if ($null -eq $Value) { return $null }
    if ($Value -is [string] -or $Value -is [ValueType]) { return $Value }
    if ($Value -is [Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($key in @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)) {
            $ordered[$key] = ConvertTo-CanonicalValue $Value[$key]
        }
        return $ordered
    }
    if ($Value -is [Collections.IEnumerable]) {
        return @($Value | ForEach-Object { ConvertTo-CanonicalValue $_ })
    }
    $ordered = [ordered]@{}
    foreach ($property in @($Value.PSObject.Properties | Sort-Object Name)) {
        $ordered[$property.Name] = ConvertTo-CanonicalValue $property.Value
    }
    return $ordered
}

function Get-SemanticFingerprint($Registry, $Concepts, $Decisions, $HistoricalAccounts, $RuntimeArtifacts) {
    $conceptProjection = @($Concepts.Values | Sort-Object Id | ForEach-Object {
        [ordered]@{
            id = $_.Id; state = $_.State; truth = $_.Truth; ownerId = $_.OwnerId
            ownerPath = $_.OwnerPath; ownerLabel = $_.OwnerLabel
            coverage = $_.Coverage; implementation = $_.Implementation
        }
    })
    $decisionProjection = @($Decisions | Sort-Object Id | ForEach-Object { [ordered]@{ id = $_.Id; title = $_.Title } })
    $projection = [ordered]@{
        contractVersion = 2
        registry = ConvertTo-CanonicalValue $Registry
        concepts = $conceptProjection
        decisions = $decisionProjection
        historicalAccounts = @($HistoricalAccounts | Sort-Object path)
        runtimeArtifacts = @($RuntimeArtifacts | Sort-Object)
    }
    $json = (ConvertTo-CanonicalValue $projection) | ConvertTo-Json -Depth 100 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([Convert]::ToHexString($sha.ComputeHash($bytes))).ToLowerInvariant() }
    finally { $sha.Dispose() }
}

try {
    $registryText = Get-Content -Raw -LiteralPath $registryFile
    $registry = $registryText | ConvertFrom-Json -Depth 100
} catch {
    Write-Host "Project Journal validation failed:`n- Registry is malformed JSON: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($registry.schemaVersion -ne 1) { Add-JournalError "Registry schemaVersion must be 1." }
if ($null -eq $registry.currentView) { Add-JournalError 'Registry currentView is required.' }
elseif ([string]$registry.currentView.reviewedOn -notmatch '^\d{4}-\d{2}-\d{2}$') { Add-JournalError 'Registry currentView.reviewedOn must be an ISO date.' }
if ([string]::IsNullOrWhiteSpace([string]$registry.currentView.focus.label)) { Add-JournalError 'Registry currentView.focus.label must not be blank.' }
if ([string]::IsNullOrWhiteSpace([string]$registry.currentView.milestone.id) -or [string]::IsNullOrWhiteSpace([string]$registry.currentView.milestone.name)) { Add-JournalError 'Registry currentView milestone requires an id and name.' }
if ([string]::IsNullOrWhiteSpace([string]$registry.builder) -or -not (Test-Path -LiteralPath (Join-Path $root ([string]$registry.builder)) -PathType Leaf)) { Add-JournalError 'Registry builder must identify an existing repository file.' }
if ($null -eq $registry.sourceDocuments -or $null -eq $registry.systems) { Add-JournalError 'Registry requires sourceDocuments and systems arrays.' }
if ($null -eq $registry.website) { Add-JournalError 'Registry website metadata is required.' }
else {
    if ($registry.website.authority -ne 'derivative-only') { Add-JournalError 'Registry website must declare authority: derivative-only.' }
    foreach ($field in @('directory','dataFile','syncScript')) {
        $relative = [string]$registry.website.$field
        if ([string]::IsNullOrWhiteSpace($relative)) { Add-JournalError "Registry website.$field must not be blank."; continue }
        $absolute = Join-Path $root $relative
        if ($field -eq 'directory') {
            if (-not (Test-Path -LiteralPath $absolute -PathType Container)) { Add-JournalError "Registry website directory '$relative' is missing." }
        } elseif (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) { Add-JournalError "Registry website $field '$relative' is missing." }
    }
}

$allMarkdown = @(Get-ChildItem -LiteralPath (Join-Path $root 'docs') -Recurse -File -Filter '*.md')
$documentsById = @{}
$documentsByPath = @{}
foreach ($file in $allMarkdown) {
    $relative = Get-Relative $file.FullName
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $front = Get-FrontMatter $text $relative
    if ($front.id) {
        $record = [pscustomobject]@{ Id = $front.id; Path = $relative; Status = $front.status; Type = $front.type; Text = $text; Front = $front }
        $documentsById[$front.id] = $record
        $documentsByPath[$relative] = $record
    }
}

$sourceById = @{}
$sourcePaths = [Collections.Generic.List[string]]::new()
foreach ($source in @($registry.sourceDocuments)) {
    $id = [string]$source.id
    $path = ([string]$source.path).Replace('\', '/')
    if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($path)) {
        Add-JournalError 'Every source document requires a nonblank id and path.'
        continue
    }
    if ($sourceById.ContainsKey($id)) { Add-JournalError "Source document ID '$id' is duplicated." }
    else { $sourceById[$id] = $source }
    if ($sourcePaths -contains $path) { Add-JournalError "Source document path '$path' is duplicated." }
    else { $sourcePaths.Add($path) }
    if (-not $documentsByPath.ContainsKey($path)) {
        Add-JournalError "Source document '$id' points to missing or unrecognized path '$path'."
    } else {
        $actual = $documentsByPath[$path]
        if ($actual.Id -ne $id) { Add-JournalError "Source document path '$path' contains ID '$($actual.Id)', not '$id'." }
        if ($actual.Status -eq 'superseded') { Add-JournalError "Source document '$id' is superseded and cannot support the current journal." }
        if ($path.StartsWith('docs/project-journal/', [StringComparison]::OrdinalIgnoreCase)) {
            Add-JournalError "Journal document '$id' is prohibited as a source authority."
        }
    }
}

$activeNonJournal = @($allMarkdown | ForEach-Object {
    $relative = Get-Relative $_.FullName
    if (-not $relative.StartsWith('docs/project-journal/', [StringComparison]::OrdinalIgnoreCase)) {
        $front = Get-FrontMatter (Get-Content -Raw -LiteralPath $_.FullName) $relative
        if ($front.status -ne 'superseded') { [pscustomobject]@{ Id = $front.id; Path = $relative } }
    }
})
foreach ($doc in $activeNonJournal) {
    if (-not $sourceById.ContainsKey($doc.Id)) { Add-JournalError "Active non-journal document '$($doc.Id)' is missing from sourceDocuments." }
}
foreach ($source in @($registry.sourceDocuments)) {
    if (-not ($activeNonJournal.Id -contains [string]$source.id)) { Add-JournalError "sourceDocuments contains non-active entry '$($source.id)'." }
}

$allowedKinds = @('product', 'support')
$allowedKnowledge = @('accepted', 'partially-accepted', 'recognized', 'exploring', 'proposed', 'operational')
$allowedCoverage = @('exploratory', 'partial', 'complete-at-scope')
$allowedImplementation = @('not-investigated', 'unresolved', 'exploration', 'not-started', 'partial', 'implemented', 'verified', 'operational')
$allowedAttention = @('now', 'next', 'later', 'blocked', 'supporting', 'unassigned')
$allowedRelationships = @('depends-on', 'constrained-by', 'feeds', 'supports', 'uses', 'governs')
$vagueNameSegments = @('misc', 'stuff', 'updates', 'changes', 'temp', 'old', 'new')
$systemsById = @{}
$names = @{}

foreach ($system in @($registry.systems)) {
    $id = [string]$system.id
    $name = [string]$system.name
    foreach ($field in @('id','name','purpose','kind','parent','knowledgeState','coverage','implementationState','attention','authorities','documents','worldGenerationConcepts','openDecisions','relationships')) {
        if ($system.PSObject.Properties.Name -notcontains $field) { Add-JournalError "System '$id' is missing required field '$field'." }
    }
    if ([string]::IsNullOrWhiteSpace($id)) { Add-JournalError 'A system has a blank ID.'; continue }
    if ($systemsById.ContainsKey($id)) { Add-JournalError "System ID '$id' is duplicated." } else { $systemsById[$id] = $system }
    if ([string]::IsNullOrWhiteSpace($name)) { Add-JournalError "System '$id' has a blank name." }
    else {
        $key = $name.Trim().ToLowerInvariant()
        if ($names.ContainsKey($key)) { Add-JournalError "System name '$name' is duplicated." } else { $names[$key] = $id }
        $segments = @($key -split '[^a-z0-9]+' | Where-Object { $_ })
        foreach ($segment in $segments) {
            if ($segment -in $vagueNameSegments) { Add-JournalError "System '$id' uses vague name segment '$segment'." }
        }
    }
    if ([string]::IsNullOrWhiteSpace([string]$system.purpose)) { Add-JournalError "System '$id' has a blank purpose." }
    if ($system.kind -notin $allowedKinds) { Add-JournalError "System '$id' has invalid kind '$($system.kind)'." }
    if ($system.knowledgeState -notin $allowedKnowledge) { Add-JournalError "System '$id' has invalid knowledgeState '$($system.knowledgeState)'." }
    if ($system.coverage -notin $allowedCoverage) { Add-JournalError "System '$id' has invalid coverage '$($system.coverage)'." }
    if ($system.implementationState -notin $allowedImplementation) { Add-JournalError "System '$id' has invalid implementationState '$($system.implementationState)'." }
    if ($system.attention -notin $allowedAttention) { Add-JournalError "System '$id' has invalid attention '$($system.attention)'." }
}

foreach ($system in @($registry.systems)) {
    $id = [string]$system.id
    $parent = [string]$system.parent
    if ($parent) {
        if ($parent -eq $id) { Add-JournalError "System '$id' cannot be its own parent." }
        elseif (-not $systemsById.ContainsKey($parent)) { Add-JournalError "System '$id' has unknown parent '$parent'." }
    }
    $seenAncestors = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $cursor = $id
    while ($cursor -and $systemsById.ContainsKey($cursor)) {
        if (-not $seenAncestors.Add($cursor)) { Add-JournalError "Parent cycle detected at system '$id'."; break }
        $cursor = [string]$systemsById[$cursor].parent
    }
    $seenRelationships = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($relationship in @($system.relationships)) {
        $type = [string]$relationship.type
        $target = [string]$relationship.target
        if ($type -notin $allowedRelationships) { Add-JournalError "System '$id' has unknown relationship type '$type'." }
        if (-not $systemsById.ContainsKey($target)) { Add-JournalError "System '$id' has relationship to unknown system '$target'." }
        if ($target -eq $id) { Add-JournalError "System '$id' has a self relationship." }
        if (-not $seenRelationships.Add("$type|$target")) { Add-JournalError "System '$id' duplicates relationship '$type' to '$target'." }
        if ($type -eq 'constrained-by') {
            if (@($relationship.evidence).Count -eq 0) { Add-JournalError "System '$id' constrained-by relationship to '$target' requires authority evidence." }
            foreach ($evidenceId in @($relationship.evidence)) {
                if (-not $documentsById.ContainsKey([string]$evidenceId)) { Add-JournalError "System '$id' constrained-by relationship uses unknown evidence '$evidenceId'." }
            }
        }
    }
    foreach ($authority in @($system.authorities)) {
        $authorityId = [string]$authority
        if (-not $documentsById.ContainsKey($authorityId)) { Add-JournalError "System '$id' references unknown authority '$authorityId'." }
        else {
            $record = $documentsById[$authorityId]
            if ($record.Status -eq 'superseded') { Add-JournalError "System '$id' references superseded authority '$authorityId'." }
            if ($record.Path.StartsWith('docs/project-journal/', [StringComparison]::OrdinalIgnoreCase)) { Add-JournalError "System '$id' uses journal entry '$authorityId' as authority, which is prohibited." }
        }
    }
}

$documentCoverage = @{}
foreach ($system in @($registry.systems)) {
    foreach ($documentId in @($system.documents)) {
        $id = [string]$documentId
        if (-not $sourceById.ContainsKey($id)) { Add-JournalError "System '$($system.id)' covers unknown document '$id'." }
        if (-not $documentCoverage.ContainsKey($id)) { $documentCoverage[$id] = [Collections.Generic.List[string]]::new() }
        $documentCoverage[$id].Add([string]$system.id)
    }
}
foreach ($source in @($registry.sourceDocuments)) {
    $id = [string]$source.id
    $count = if ($documentCoverage.ContainsKey($id)) { $documentCoverage[$id].Count } else { 0 }
    if ($count -eq 0) { Add-JournalError "Document '$id' has no primary system coverage." }
    elseif ($count -gt 1) { Add-JournalError "Document '$id' has duplicate primary system coverage: $($documentCoverage[$id] -join ', ')." }
}

$worldIndexPath = Join-Path $root 'docs/world-generation/README.md'
$worldIndexText = Get-Content -Raw -LiteralPath $worldIndexPath
$acceptedSection = [regex]::Match($worldIndexText, '(?ms)^## Accepted concepts\s+(?<body>.*?)(?=^## Recognized exploration topics)').Groups['body'].Value
$recognizedSection = [regex]::Match($worldIndexText, '(?ms)^## Recognized exploration topics\s+(?<body>.*?)(?=^## Dependency order)').Groups['body'].Value
$worldConcepts = @{}
$allowedConceptStates = @('recognized', 'exploring', 'proposed', 'accepted', 'superseded')
foreach ($match in [regex]::Matches($acceptedSection, '(?m)^\| `(?<id>WG-\d{3})` \| (?<truth>.*?) \| \[(?<ownerLabel>.*?)\]\((?<ownerPath>.*?)\) \| (?<implementation>.*?) \|$')) {
    $ownerPath = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $worldIndexPath) $match.Groups['ownerPath'].Value))
    $ownerRelative = Get-Relative $ownerPath
    if (-not $documentsByPath.ContainsKey($ownerRelative)) { Add-JournalError "Accepted concept '$($match.Groups['id'].Value)' has missing owner '$ownerRelative'."; $ownerId = 'missing' }
    else { $ownerId = $documentsByPath[$ownerRelative].Id }
    $conceptId = $match.Groups['id'].Value
    if ($worldConcepts.ContainsKey($conceptId)) { Add-JournalError "World-generation concept '$conceptId' is duplicated."; continue }
    $coverage = if ($ownerId -ne 'missing' -and $documentsById[$ownerId].Front.coverage) { [string]$documentsById[$ownerId].Front.coverage } else { 'partial' }
    if ($ownerId -ne 'missing' -and $documentsById[$ownerId].Front.concept_state -and $documentsById[$ownerId].Front.concept_state -ne 'accepted') {
        Add-JournalError "Accepted concept '$conceptId' owner '$ownerId' does not declare concept_state: accepted."
    }
    $worldConcepts[$conceptId] = [pscustomobject]@{
        Id = $match.Groups['id'].Value; State = 'accepted'; Truth = $match.Groups['truth'].Value
        OwnerId = $ownerId; OwnerPath = $ownerRelative; OwnerLabel = $match.Groups['ownerLabel'].Value
        Coverage = $coverage; Implementation = $match.Groups['implementation'].Value.Trim().ToLowerInvariant().Replace(' ', '-')
    }
}
foreach ($match in [regex]::Matches($recognizedSection, '(?m)^\| `(?<id>WG-\d{3})` \| `(?<state>[^`]+)` \| (?<question>.*?) \| (?<owner>.*?) \|$')) {
    $conceptId = $match.Groups['id'].Value
    $state = $match.Groups['state'].Value.Trim().ToLowerInvariant()
    $ownerCell = $match.Groups['owner'].Value.Trim()
    if ($state -notin $allowedConceptStates) { Add-JournalError "World-generation concept '$conceptId' has unsupported lifecycle state '$state'."; continue }
    if ($state -eq 'accepted') { Add-JournalError "Concept '$conceptId' is accepted but remains in the exploration table."; continue }
    if ($worldConcepts.ContainsKey($conceptId)) { Add-JournalError "World-generation concept '$conceptId' is duplicated."; continue }
    $ownerId = $null; $ownerRelative = $null; $ownerLabel = $ownerCell
    if ($state -in @('exploring', 'proposed')) {
        $ownerMatch = [regex]::Match($ownerCell, '^\[(?<label>.*?)\]\((?<path>.*?)\)$')
        if (-not $ownerMatch.Success) { Add-JournalError "Concept '$conceptId' in state '$state' requires a linked detailed owner." }
        else {
            $ownerRelative = Get-Relative ([IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $worldIndexPath) $ownerMatch.Groups['path'].Value)))
            $ownerLabel = $ownerMatch.Groups['label'].Value
            if (-not $documentsByPath.ContainsKey($ownerRelative)) { Add-JournalError "Concept '$conceptId' has missing owner '$ownerRelative'." }
            else {
                $ownerId = $documentsByPath[$ownerRelative].Id
                $ownerFront = $documentsByPath[$ownerRelative].Front
                if ($ownerFront.concept_state -ne $state) { Add-JournalError "Concept '$conceptId' state '$state' disagrees with owner '$ownerId' concept_state '$($ownerFront.concept_state)'." }
                $requiredStatus = if ($state -eq 'exploring') { 'draft' } else { 'proposed' }
                if ($ownerFront.status -ne $requiredStatus) { Add-JournalError "Concept '$conceptId' state '$state' requires owner status '$requiredStatus'." }
            }
        }
    } elseif ($state -eq 'recognized' -and $ownerCell -ne 'Not created') {
        Add-JournalError "Recognized concept '$conceptId' must say 'Not created' until exploration has an owner."
    } elseif ($state -eq 'superseded' -and $ownerCell -notmatch 'WG-\d{3}') {
        Add-JournalError "Superseded concept '$conceptId' must identify its replacement."
    }
    $coverage = if ($state -eq 'superseded') { 'superseded' } elseif ($ownerId -and $documentsById[$ownerId].Front.coverage) { [string]$documentsById[$ownerId].Front.coverage } else { 'exploratory' }
    $implementation = if ($state -eq 'superseded') { 'not-applicable' } elseif ($ownerId -and $documentsById[$ownerId].Front.implementation) { [string]$documentsById[$ownerId].Front.implementation } else { 'not-investigated' }
    $worldConcepts[$conceptId] = [pscustomobject]@{
        Id = $conceptId; State = $state; Truth = $match.Groups['question'].Value
        OwnerId = $ownerId; OwnerPath = $ownerRelative; OwnerLabel = $ownerLabel
        Coverage = $coverage; Implementation = $implementation
    }
}
if ($worldConcepts.Count -eq 0) { Add-JournalError 'No world-generation concepts could be parsed from WG-INDEX.' }
foreach ($concept in @($worldConcepts.Values | Where-Object { $_.State -eq 'superseded' })) {
    $replacementId = [regex]::Match([string]$concept.OwnerLabel, 'WG-\d{3}').Value
    if (-not $worldConcepts.ContainsKey($replacementId) -or $worldConcepts[$replacementId].State -ne 'accepted') {
        Add-JournalError "Superseded concept '$($concept.Id)' replacement '$replacementId' is not an accepted concept."
    }
}

$conceptCoverage = @{}
foreach ($system in @($registry.systems)) {
    foreach ($conceptId in @($system.worldGenerationConcepts)) {
        $id = [string]$conceptId
        if (-not $worldConcepts.ContainsKey($id)) { Add-JournalError "System '$($system.id)' covers unknown world-generation concept '$id'." }
        elseif ($worldConcepts[$id].State -eq 'superseded') { Add-JournalError "System '$($system.id)' covers superseded world-generation concept '$id'." }
        if (-not $conceptCoverage.ContainsKey($id)) { $conceptCoverage[$id] = [Collections.Generic.List[string]]::new() }
        $conceptCoverage[$id].Add([string]$system.id)
    }
}
foreach ($id in @($worldConcepts.Keys | Where-Object { $worldConcepts[$_].State -ne 'superseded' })) {
    $count = if ($conceptCoverage.ContainsKey($id)) { $conceptCoverage[$id].Count } else { 0 }
    if ($count -eq 0) { Add-JournalError "World-generation concept '$id' has no primary system coverage." }
    elseif ($count -gt 1) { Add-JournalError "World-generation concept '$id' has duplicate primary system coverage: $($conceptCoverage[$id] -join ', ')." }
}

$openDecisionText = Get-Content -Raw -LiteralPath (Join-Path $root 'docs/architecture/OPEN_DECISIONS.md')
$openDecisions = @([regex]::Matches($openDecisionText, '(?m)^#{2,3} (?<id>ARCH-OPEN-\d{3}) — (?<title>.+)$') | ForEach-Object {
    [pscustomobject]@{ Id = $_.Groups['id'].Value; Title = $_.Groups['title'].Value.Trim() }
})
$openDecisionById = @{}
foreach ($decision in $openDecisions) {
    if ($openDecisionById.ContainsKey($decision.Id)) { Add-JournalError "Open-decision register duplicates '$($decision.Id)'." }
    else { $openDecisionById[$decision.Id] = $decision }
}
$decisionCoverage = @{}
foreach ($system in @($registry.systems)) {
    foreach ($decisionId in @($system.openDecisions)) {
        $id = [string]$decisionId
        if (-not $openDecisionById.ContainsKey($id)) { Add-JournalError "System '$($system.id)' covers unknown open decision '$id'." }
        if (-not $decisionCoverage.ContainsKey($id)) { $decisionCoverage[$id] = [Collections.Generic.List[string]]::new() }
        $decisionCoverage[$id].Add([string]$system.id)
    }
}
foreach ($decision in $openDecisions) {
    $count = if ($decisionCoverage.ContainsKey($decision.Id)) { $decisionCoverage[$decision.Id].Count } else { 0 }
    if ($count -eq 0) { Add-JournalError "Open decision '$($decision.Id)' has no primary system coverage." }
    elseif ($count -gt 1) { Add-JournalError "Open decision '$($decision.Id)' has duplicate primary system coverage: $($decisionCoverage[$decision.Id] -join ', ')." }
}

# Semantic associations prevent exact-once counting from hiding a wrong system assignment.
$associationNames = @($registry.decisionAssociations.PSObject.Properties.Name)
foreach ($decision in $openDecisions) {
    if ($associationNames -notcontains $decision.Id) { Add-JournalError "Open decision '$($decision.Id)' has no semantic association."; continue }
    $association = $registry.decisionAssociations.$($decision.Id)
    $actualSystem = if ($decisionCoverage.ContainsKey($decision.Id) -and $decisionCoverage[$decision.Id].Count -eq 1) { [string]$decisionCoverage[$decision.Id].Item(0) } else { '' }
    if ($actualSystem -and $actualSystem -ne [string]$association.system) { Add-JournalError "Open decision '$($decision.Id)' is covered by '$actualSystem' but its semantic association requires '$($association.system)'." }
    if (@($association.evidence).Count -eq 0) { Add-JournalError "Open decision '$($decision.Id)' semantic association has no evidence." }
    foreach ($evidenceId in @($association.evidence)) {
        if (-not $documentsById.ContainsKey([string]$evidenceId) -and -not $worldConcepts.ContainsKey([string]$evidenceId)) { Add-JournalError "Open decision '$($decision.Id)' uses unknown association evidence '$evidenceId'." }
    }
}
foreach ($associationName in $associationNames) {
    if (-not $openDecisionById.ContainsKey($associationName)) { Add-JournalError "Decision association '$associationName' does not name an open decision." }
}

foreach ($requiredRelationship in @($registry.relationshipAssociations)) {
    $sourceId = [string]$requiredRelationship.source
    if (-not $systemsById.ContainsKey($sourceId)) { Add-JournalError "Required relationship has unknown source '$sourceId'."; continue }
    $matches = @($systemsById[$sourceId].relationships | Where-Object { $_.type -eq $requiredRelationship.type -and $_.target -eq $requiredRelationship.target })
    if ($matches.Count -ne 1) { Add-JournalError "System '$sourceId' must have exactly one '$($requiredRelationship.type)' relationship to '$($requiredRelationship.target)'." }
    foreach ($evidenceId in @($requiredRelationship.evidence)) {
        if (-not $documentsById.ContainsKey([string]$evidenceId)) { Add-JournalError "Required relationship '$sourceId' uses unknown evidence '$evidenceId'." }
    }
}

function Get-ConceptAggregate([string]$SystemId, [string]$Dimension, [string]$Scope) {
    $conceptIds = [Collections.Generic.List[string]]::new()
    foreach ($candidate in @($registry.systems)) {
        $include = if ($Scope -eq 'descendants') { Test-SystemWithin ([string]$candidate.id) $SystemId $systemsById } else { [string]$candidate.id -eq $SystemId }
        if ($include) { foreach ($conceptId in @($candidate.worldGenerationConcepts)) { $conceptIds.Add([string]$conceptId) } }
    }
    $concepts = @($conceptIds | Sort-Object -Unique | Where-Object { $worldConcepts.ContainsKey($_) -and $worldConcepts[$_].State -ne 'superseded' } | ForEach-Object { $worldConcepts[$_] })
    if ($concepts.Count -eq 0) { return '' }
    if ($Dimension -eq 'knowledge') {
        $states = @($concepts.State | Sort-Object -Unique)
        if ($states -contains 'accepted' -and $states.Count -gt 1) { return 'partially-accepted' }
        if ($states.Count -eq 1) { return [string]$states[0] }
        if ($states -contains 'proposed') { return 'proposed' }
        if ($states -contains 'exploring') { return 'exploring' }
        return 'recognized'
    }
    if ($Dimension -eq 'coverage') {
        if (@($concepts | Where-Object { $_.Coverage -eq 'partial' }).Count -gt 0) { return 'partial' }
        if (@($concepts | Where-Object { $_.Coverage -ne 'complete-at-scope' }).Count -eq 0) { return 'complete-at-scope' }
        return 'exploratory'
    }
    if ($Dimension -eq 'implementation') {
        $states = @($concepts.Implementation | ForEach-Object { ([string]$_).Trim().ToLowerInvariant().Replace(' ', '-') } | Sort-Object -Unique)
        foreach ($candidate in @('unresolved','partial','implemented','verified','not-started','not-investigated')) { if ($states -contains $candidate) { return $candidate } }
        return [string]$states[0]
    }
    return ''
}

function Test-EvidenceAssertion($Assertion, $System, $Profile, [string]$Context) {
    $source = [string]$Assertion.source
    $field = [string]$Assertion.field
    $expected = [string]$Assertion.equals
    $actual = $null
    if ($field -eq 'path.exists') {
        $actual = if (Test-Path -LiteralPath (Join-Path $root $source) -PathType Leaf) { 'true' } else { 'false' }
    } elseif ($field -eq 'profile.coverage') { $actual = [string]$Profile.coverage
    } elseif ($field -eq 'profile.attention') { $actual = [string]$Profile.attention
    } elseif ($field -match '^concepts\.(knowledge|coverage|implementation)$') {
        if ($source -ne 'WG-INDEX') { Add-JournalError "$Context concept evidence must use WG-INDEX."; return }
        $actual = Get-ConceptAggregate ([string]$System.id) $matches[1] ([string]$Assertion.scope)
    } elseif (-not $documentsById.ContainsKey($source)) {
        Add-JournalError "$Context uses unknown evidence source '$source'."; return
    } elseif ($field -match '^front\.(.+)$') {
        $actual = [string]$documentsById[$source].Front[$matches[1]]
    } elseif ($field -eq 'body.contains') {
        $actual = if ($documentsById[$source].Text.Contains($expected)) { $expected } else { '<missing>' }
    } else { Add-JournalError "$Context uses unsupported evidence field '$field'."; return }
    if ([string]$actual -ne $expected) { Add-JournalError "$Context evidence '$source/$field' expected '$expected' but found '$actual'." }
}

$profileNames = @($registry.statusProfiles.PSObject.Properties.Name)
$evidenceNames = @($registry.systemEvidence.PSObject.Properties.Name)
foreach ($system in @($registry.systems)) {
    $systemId = [string]$system.id
    if ($evidenceNames -notcontains $systemId) { Add-JournalError "System '$systemId' has no four-dimensional evidence declaration."; continue }
    $declaration = $registry.systemEvidence.$systemId
    if ($profileNames -notcontains [string]$declaration.profile) { Add-JournalError "System '$systemId' uses unknown status profile '$($declaration.profile)'."; continue }
    $profile = $registry.statusProfiles.$($declaration.profile)
    $dimensionMap = @{ knowledge = 'knowledgeState'; coverage = 'coverage'; implementation = 'implementationState'; attention = 'attention' }
    foreach ($dimension in @('knowledge','coverage','implementation','attention')) {
        $systemField = $dimensionMap[$dimension]
        if ([string]$system.$systemField -ne [string]$profile.$dimension) { Add-JournalError "System '$systemId' $systemField '$($system.$systemField)' disagrees with profile '$($declaration.profile)' value '$($profile.$dimension)'." }
        $assertions = @($declaration.$dimension)
        if ($assertions.Count -eq 0) { Add-JournalError "System '$systemId' has no $dimension evidence." }
        foreach ($assertion in $assertions) { Test-EvidenceAssertion $assertion $system $profile "System '$systemId' $dimension" }
    }
}
foreach ($evidenceName in $evidenceNames) { if (-not $systemsById.ContainsKey($evidenceName)) { Add-JournalError "systemEvidence contains unknown system '$evidenceName'." } }

# Current-view claims are checked against governed authority and the human-facing root summary.
$reviewedOn = [string]$registry.currentView.reviewedOn
$rootSummaryPath = Join-Path $root ([string]$registry.currentView.rootSummary)
if (-not (Test-Path -LiteralPath $rootSummaryPath -PathType Leaf)) { Add-JournalError "Current-view root summary '$($registry.currentView.rootSummary)' is missing." }
else {
    $rootSummaryText = Get-Content -Raw -LiteralPath $rootSummaryPath
    if (-not $rootSummaryText.Contains("**Status reviewed:** $reviewedOn")) { Add-JournalError 'Root summary review date disagrees with currentView.reviewedOn.' }
}
if (-not $documentsById.ContainsKey('HANDOFF-CURRENT')) { Add-JournalError 'HANDOFF-CURRENT is required for current-view evidence.' }
else {
    $currentState = $documentsById['HANDOFF-CURRENT']
    if ($currentState.Front.last_reviewed -ne $reviewedOn -or -not $currentState.Text.Contains("**Snapshot date:** $reviewedOn")) { Add-JournalError 'HANDOFF-CURRENT review metadata disagrees with currentView.reviewedOn.' }
    $milestoneMatch = [regex]::Match($currentState.Text, '(?m)^-?\s*\*\*Immediate milestone:\*\* `(?<id>[^`]+)` — (?<name>.+)$')
    $phaseMatch = [regex]::Match($currentState.Text, '(?m)^-?\s*\*\*Active phase:\*\* (?<phase>.+?)(?:\s+\(`[^`]+`–`[^`]+`\))?$')
    if (-not $milestoneMatch.Success) { Add-JournalError 'HANDOFF-CURRENT does not expose a parseable immediate milestone.' }
    elseif ($milestoneMatch.Groups['id'].Value -ne [string]$registry.currentView.milestone.id -or $milestoneMatch.Groups['name'].Value.Trim() -ne [string]$registry.currentView.milestone.name) { Add-JournalError 'Registry current milestone disagrees with HANDOFF-CURRENT.' }
    if (-not $phaseMatch.Success) { Add-JournalError 'HANDOFF-CURRENT does not expose a parseable active phase.' }
    else {
        $derivedFocus = "$($phaseMatch.Groups['phase'].Value.Trim()) and the $($registry.currentView.milestone.name)"
        if ([string]$registry.currentView.focus.label -ne $derivedFocus) { Add-JournalError "Registry current focus label disagrees with HANDOFF-CURRENT; expected '$derivedFocus'." }
    }
}
foreach ($assertion in @($registry.currentView.focus.evidence)) { Test-EvidenceAssertion $assertion $null $null 'Current focus' }
foreach ($assertion in @($registry.currentView.milestone.evidence)) { Test-EvidenceAssertion $assertion $null $null 'Current milestone' }

$runtimeFiles = @(
    Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '[\\/]\.git[\\/]' -and
            ($_.Name -eq 'Cargo.toml' -or $_.Extension -eq '.rs')
        }
)
$runtimePresent = $runtimeFiles.Count -gt 0
if (-not $runtimePresent) {
    foreach ($system in @($registry.systems | Where-Object { $_.kind -eq 'product' })) {
        if ($system.implementationState -in @('partial', 'implemented', 'verified')) {
            Add-JournalError "Product system '$($system.id)' claims '$($system.implementationState)' but no Rust source or Cargo workspace exists."
        }
    }
}

$seenPostPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$historicalAccounts = [Collections.Generic.List[object]]::new()
$gitAvailable = $false
try { $gitAvailable = ((& git -C $root rev-parse --is-inside-work-tree 2>$null) -eq 'true') } catch { $gitAvailable = $false }
foreach ($postPath in @($registry.historicalPosts)) {
    if (-not $seenPostPaths.Add([string]$postPath)) { Add-JournalError "Historical post '$postPath' is duplicated."; continue }
    $absolute = Join-Path $root ([string]$postPath)
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) { Add-JournalError "Historical post '$postPath' is missing."; continue }
    $text = Get-Content -Raw -LiteralPath $absolute
    $front = Get-FrontMatter $text ([string]$postPath)
    foreach ($field in @('snapshot_date', 'baseline_commit', 'current_truth')) {
        if (-not $front.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($front[$field])) { Add-JournalError "Historical post '$postPath' is missing '$field'." }
    }
    if ($front.snapshot_date -notmatch '^\d{4}-\d{2}-\d{2}$') { Add-JournalError "Historical post '$postPath' has invalid snapshot_date." }
    if ($front.baseline_commit -notmatch '^[0-9a-f]{40}$') { Add-JournalError "Historical post '$postPath' has invalid baseline_commit." }
    elseif ($gitAvailable) {
        & git -C $root cat-file -e "$($front.baseline_commit)^{commit}" 2>$null
        if ($LASTEXITCODE -ne 0) { Add-JournalError "Historical post '$postPath' baseline commit '$($front.baseline_commit)' does not resolve in this repository." }
    }
    if ($front.current_truth -ne 'historical-only') { Add-JournalError "Historical post '$postPath' must declare current_truth: historical-only." }
    $fileDate = [regex]::Match([IO.Path]::GetFileName([string]$postPath), '^(?<date>\d{4}-\d{2}-\d{2})-').Groups['date'].Value
    if ($fileDate -ne $front.snapshot_date) { Add-JournalError "Historical post '$postPath' filename date disagrees with snapshot_date." }
    if (-not $text.Contains("> **Historical snapshot — $($front.snapshot_date).**")) { Add-JournalError "Historical post '$postPath' is missing its dated visible historical-snapshot banner." }
    if (-not $text.Contains([string]$front.baseline_commit)) { Add-JournalError "Historical post '$postPath' does not show its own baseline commit." }
    if ($text -notmatch '\.\./WORLD_GENERATION_STATUS\.md') { Add-JournalError "Historical post '$postPath' does not link to the current world-generation status." }
    $historicalAccounts.Add([ordered]@{
        path = ([string]$postPath).Replace('\', '/')
        id = [string]$front.id
        snapshotDate = [string]$front.snapshot_date
        baselineCommit = [string]$front.baseline_commit
        currentTruth = [string]$front.current_truth
        content = $text.Replace("`r`n", "`n")
    })
}

if ($errors.Count) {
    Write-Host 'Project Journal validation failed:' -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}

$runtimeArtifactPaths = @($runtimeFiles | ForEach-Object { Get-Relative $_.FullName } | Sort-Object -Unique)
$fingerprint = Get-SemanticFingerprint $registry $worldConcepts $openDecisions $historicalAccounts $runtimeArtifactPaths
if ($errors.Count) {
    Write-Host 'Project Journal validation failed:' -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}

$homePath = Join-Path $root ([string]$registry.generatedFiles.home)
$homeDirectory = Split-Path -Parent $homePath
$statusPath = Join-Path $root ([string]$registry.generatedFiles.worldGenerationStatus)
$statusDirectory = Split-Path -Parent $statusPath

$journalBuilder = [Text.StringBuilder]::new()
$null = $journalBuilder.AppendLine('---')
$null = $journalBuilder.AppendLine('id: JOURNAL-HOME')
$null = $journalBuilder.AppendLine('type: project-journal')
$null = $journalBuilder.AppendLine('status: accepted')
$null = $journalBuilder.AppendLine('scope: Human-readable current project navigation and system overview')
$null = $journalBuilder.AppendLine('authority: Derivative current view generated from SYSTEMS.json and linked authorities; owns no technical project truth')
$null = $journalBuilder.AppendLine("dependency_fingerprint: $fingerprint")
$null = $journalBuilder.AppendLine("last_reviewed: $reviewedOn")
$null = $journalBuilder.AppendLine('---')
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('# Project Journal')
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('> **Generated current view.** Do not edit this file by hand. It summarizes and links to current authority; it does not replace that authority.')
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine("**Current focus:** $($registry.currentView.focus.label)")
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine("**Semantic fingerprint:** ``$fingerprint``")
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('## What needs attention now')
$null = $journalBuilder.AppendLine()
foreach ($system in @($registry.systems | Where-Object { $_.attention -eq 'now' })) {
    $authority = [string]@($system.authorities)[0]
    $link = Get-MarkdownLink $homeDirectory $documentsById[$authority].Path $system.name
    $null = $journalBuilder.AppendLine("- **${link}:** $($system.purpose)")
}
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('## Project System Map')
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('The four state columns answer different questions: what is known, how complete that knowledge is, what exists in code, and where attention is assigned. `Unassigned` means no topic-level priority has been accepted.')
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('| System | Kind | Knowledge | Coverage | Implementation | Attention | Evidence | Purpose |')
$null = $journalBuilder.AppendLine('| --- | --- | --- | --- | --- | --- | --- | --- |')
foreach ($system in @($registry.systems)) {
    $authorityId = [string]@($system.authorities)[0]
    $label = Get-MarkdownLink $homeDirectory $documentsById[$authorityId].Path $system.name
    $declaration = $registry.systemEvidence.$($system.id)
    $evidenceSources = @('knowledge','coverage','implementation','attention' | ForEach-Object { @($declaration.$_) } | ForEach-Object { [string]$_.source } | Sort-Object -Unique) -join ', '
    $null = $journalBuilder.AppendLine("| $label | $($system.kind) | $($system.knowledgeState) | $($system.coverage) | $($system.implementationState) | $($system.attention) | $(Escape-Table $evidenceSources) | $(Escape-Table $system.purpose) |")
}
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('```mermaid')
$null = $journalBuilder.AppendLine('flowchart TD')
foreach ($system in @($registry.systems)) {
    $safeName = ([string]$system.name).Replace('"', "'")
    $null = $journalBuilder.AppendLine(('    {0}["{1}"]' -f $system.id.Replace('-', '_'), $safeName))
}
foreach ($system in @($registry.systems)) {
    if ($system.parent) { $null = $journalBuilder.AppendLine("    $(([string]$system.parent).Replace('-', '_')) --> $(([string]$system.id).Replace('-', '_'))") }
    foreach ($relationship in @($system.relationships)) {
        $label = ([string]$relationship.type).Replace('-', ' ')
        $null = $journalBuilder.AppendLine("    $(([string]$system.id).Replace('-', '_')) -. $label .-> $(([string]$relationship.target).Replace('-', '_'))")
    }
}
$null = $journalBuilder.AppendLine('```')
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('## Current world-generation picture')
$null = $journalBuilder.AppendLine()
$statusLink = Get-MarkdownLink $homeDirectory ([string]$registry.generatedFiles.worldGenerationStatus) 'World-generation status'
$null = $journalBuilder.AppendLine("The $statusLink explains every accepted and recognized concept, its owner, unresolved choices, and the current absence or presence of runtime evidence.")
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('## Browser view')
$null = $journalBuilder.AppendLine()
$websiteLink = Get-MarkdownLink $homeDirectory ([string]$registry.website.directory) 'Browser Project Journal'
$null = $journalBuilder.AppendLine("The $websiteLink presents this same generated information as a browser website. It is derivative, owns no technical truth, and must be synced whenever a Journal-impacting change alters its source data.")
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('## Historical posts')
$null = $journalBuilder.AppendLine()
$null = $journalBuilder.AppendLine('Posts explain what was understood at a named date and commit. They are historical records, never current authority.')
$null = $journalBuilder.AppendLine()
foreach ($post in @($registry.historicalPosts)) {
    $postRecord = $documentsByPath[[string]$post]
    $titleMatch = [regex]::Match($postRecord.Text, '(?m)^# (?<title>.+)$')
    $title = if ($titleMatch.Success) { $titleMatch.Groups['title'].Value } else { [IO.Path]::GetFileNameWithoutExtension([string]$post) }
    $link = Get-MarkdownLink $homeDirectory ([string]$post) $title
    $null = $journalBuilder.AppendLine("- $link — snapshot $($postRecord.Front.snapshot_date)")
}
$homeContent = $journalBuilder.ToString().Replace("`r`n", "`n")

$acceptedConcepts = @($worldConcepts.Values | Where-Object { $_.State -eq 'accepted' } | Sort-Object Id)
$recognizedConcepts = @($worldConcepts.Values | Where-Object { $_.State -eq 'recognized' } | Sort-Object Id)
$exploringConcepts = @($worldConcepts.Values | Where-Object { $_.State -eq 'exploring' } | Sort-Object Id)
$proposedConcepts = @($worldConcepts.Values | Where-Object { $_.State -eq 'proposed' } | Sort-Object Id)
$supersededConcepts = @($worldConcepts.Values | Where-Object { $_.State -eq 'superseded' } | Sort-Object Id)
$worldDecisionSystems = @($registry.systems | Where-Object {
    @($_.openDecisions).Count -gt 0 -and
    ((Test-SystemWithin ([string]$_.id) 'world-generation' $systemsById) -or $_.id -eq 'map-and-spatial-model-prototype')
})
$otherDecisionSystems = @($registry.systems | Where-Object {
    @($_.openDecisions).Count -gt 0 -and $worldDecisionSystems.id -notcontains $_.id
})
$worldDecisionCount = @($worldDecisionSystems | ForEach-Object { @($_.openDecisions) }).Count
$otherDecisionCount = @($otherDecisionSystems | ForEach-Object { @($_.openDecisions) }).Count
$status = [Text.StringBuilder]::new()
$null = $status.AppendLine('---')
$null = $status.AppendLine('id: JOURNAL-WORLD-GENERATION')
$null = $status.AppendLine('type: project-status-view')
$null = $status.AppendLine('status: accepted')
$null = $status.AppendLine('scope: Human-readable current status of world-generation knowledge, implementation, attention, and open decisions')
$null = $status.AppendLine('authority: Derivative current view generated from WG-INDEX, project authorities, and SYSTEMS.json; owns no technical project truth')
$null = $status.AppendLine("dependency_fingerprint: $fingerprint")
$null = $status.AppendLine("last_reviewed: $reviewedOn")
$null = $status.AppendLine('---')
$null = $status.AppendLine()
$null = $status.AppendLine('# Current World-Generation Status')
$null = $status.AppendLine()
$null = $status.AppendLine('> **Generated current view.** Do not edit this file by hand. Follow its links to the documents that own current truth.')
$null = $status.AppendLine()
$null = $status.AppendLine("**Semantic fingerprint:** ``$fingerprint``")
$null = $status.AppendLine()
$null = $status.AppendLine('## Plain-language summary')
$null = $status.AppendLine()
$null = $status.AppendLine("World generation is at the beginning of the natural-world foundation. The active lifecycle contains **$($acceptedConcepts.Count) accepted**, **$($proposedConcepts.Count) proposed**, **$($exploringConcepts.Count) exploring**, and **$($recognizedConcepts.Count) recognized** concepts. **$($supersededConcepts.Count) superseded** concepts are retained as history but excluded from current coverage. Accepted concepts define causal boundaries and relationships; they do not select the algorithms, storage layouts, or numerical methods in the **$worldDecisionCount world-generation and prototype open-decision groups**. Another **$otherDecisionCount groups** concern later product systems or cross-cutting runtime architecture, for **$($openDecisions.Count) repository-wide**.")
$null = $status.AppendLine()
if ($runtimePresent) {
    $null = $status.AppendLine("Runtime evidence was detected in **$($runtimeFiles.Count) Rust or Cargo artifact(s)**. This view does not infer completeness from file presence; implementation claims require their owning authority to be updated.")
} else {
    $null = $status.AppendLine('No Rust source file or Cargo workspace is present. The map and spatial model prototype and runtime architecture therefore remain **not started** in this workspace.')
}
$null = $status.AppendLine()
$null = $status.AppendLine('No priority is assigned to an individual recognized world-generation topic. The accepted immediate milestone is the map and spatial model prototype; detailed world-generation sequencing remains open.')
$null = $status.AppendLine()
$null = $status.AppendLine('## Four separate status dimensions')
$null = $status.AppendLine()
$null = $status.AppendLine('| Dimension | Current reading |')
$null = $status.AppendLine('| --- | --- |')
$null = $status.AppendLine("| Knowledge | $($acceptedConcepts.Count) accepted, $($proposedConcepts.Count) proposed, $($exploringConcepts.Count) exploring, and $($recognizedConcepts.Count) recognized active concepts. |")
$null = $status.AppendLine('| Coverage | Coverage is read from each concept owner or the governed lifecycle row; the whole natural world remains intentionally incomplete. |')
$null = $status.AppendLine("| Implementation | Concept implementation states come from WG-INDEX; runtime-file presence is only a conservative consistency check. |")
$null = $status.AppendLine("| Attention | $($registry.currentView.focus.label) are current; topic-level priority remains unassigned unless authority says otherwise. |")
$null = $status.AppendLine()
$null = $status.AppendLine('## Accepted concepts')
$null = $status.AppendLine()
$null = $status.AppendLine('| ID | Accepted truth | Detailed owner | Coverage | Implementation |')
$null = $status.AppendLine('| --- | --- | --- | --- | --- |')
foreach ($concept in $acceptedConcepts) {
    $ownerLink = Get-MarkdownLink $statusDirectory $concept.OwnerPath $concept.OwnerLabel
    $null = $status.AppendLine("| ``$($concept.Id)`` | $(Escape-Table $concept.Truth) | $ownerLink | $($concept.Coverage) | $($concept.Implementation) |")
}
$null = $status.AppendLine()
$null = $status.AppendLine('## Active exploration and proposals')
$null = $status.AppendLine()
$null = $status.AppendLine('| ID | State | Exploration question or proposal | Detailed owner | Coverage | Implementation |')
$null = $status.AppendLine('| --- | --- | --- | --- | --- | --- |')
foreach ($concept in @($proposedConcepts + $exploringConcepts + $recognizedConcepts | Sort-Object Id)) {
    $owner = if ($concept.OwnerPath) { Get-MarkdownLink $statusDirectory $concept.OwnerPath $concept.OwnerLabel } else { 'Not created' }
    $null = $status.AppendLine("| ``$($concept.Id)`` | $($concept.State) | $(Escape-Table $concept.Truth) | $owner | $($concept.Coverage) | $($concept.Implementation) |")
}
$null = $status.AppendLine()
$null = $status.AppendLine('## World-generation and prototype open decisions')
$null = $status.AppendLine()
$openDecisionLink = Get-MarkdownLink $statusDirectory 'docs/architecture/OPEN_DECISIONS.md' 'Open Architecture Decisions'
$null = $status.AppendLine("The $openDecisionLink register owns the unresolved choices below. Listing an option here does not accept it.")
$null = $status.AppendLine()
foreach ($system in $worldDecisionSystems) {
    $null = $status.AppendLine("### $($system.name)")
    $null = $status.AppendLine()
    foreach ($id in @($system.openDecisions)) {
        $decision = $openDecisionById[[string]$id]
        $null = $status.AppendLine("- ``$($decision.Id)`` — $($decision.Title)")
    }
    $null = $status.AppendLine()
}
$null = $status.AppendLine('## Other project open decisions')
$null = $status.AppendLine()
$null = $status.AppendLine('These decisions are included to keep repository-wide coverage visible, but they do not belong to the current world-generation concept set.')
$null = $status.AppendLine()
foreach ($system in $otherDecisionSystems) {
    $null = $status.AppendLine("### $($system.name)")
    $null = $status.AppendLine()
    foreach ($id in @($system.openDecisions)) {
        $decision = $openDecisionById[[string]$id]
        $null = $status.AppendLine("- ``$($decision.Id)`` — $($decision.Title)")
    }
    $null = $status.AppendLine()
}
$null = $status.AppendLine('## Authority boundary')
$null = $status.AppendLine()
$wgIndexLink = Get-MarkdownLink $statusDirectory 'docs/world-generation/README.md' 'World-Generation Source of Truth'
$journalLink = Get-MarkdownLink $statusDirectory 'docs/project-journal/README.md' 'Project Journal'
$null = $status.AppendLine("The $wgIndexLink and its linked specifications own world-generation truth. This page and the $journalLink are generated navigation views. The fingerprint covers every represented semantic value and generated output must match it; it does not replace independent semantic review.")
$statusContent = $status.ToString().Replace("`r`n", "`n")

$outputs = @{
    ([string]$registry.generatedFiles.home) = $homeContent
    ([string]$registry.generatedFiles.worldGenerationStatus) = $statusContent
}
$utf8 = [Text.UTF8Encoding]::new($false)
if ($Check) {
    foreach ($entry in $outputs.GetEnumerator()) {
        $absolute = Join-Path $root $entry.Key
        if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) { Add-JournalError "Generated file '$($entry.Key)' is missing."; continue }
        $actual = [IO.File]::ReadAllText($absolute)
        if ($actual -ne $entry.Value) { Add-JournalError "Generated file '$($entry.Key)' is stale or hand-edited; rebuild it." }
    }
    if ($errors.Count) {
        Write-Host 'Project Journal validation failed:' -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "Project Journal validation passed: $(@($registry.systems).Count) systems, $($sourceById.Count) source documents, $($worldConcepts.Count) world-generation concepts, $($openDecisions.Count) open decisions; fingerprint $fingerprint." -ForegroundColor Green
} else {
    foreach ($entry in $outputs.GetEnumerator()) {
        $absolute = Join-Path $root $entry.Key
        $directory = Split-Path -Parent $absolute
        if (-not (Test-Path -LiteralPath $directory)) { $null = New-Item -ItemType Directory -Path $directory }
        [IO.File]::WriteAllText($absolute, $entry.Value, $utf8)
    }
    Write-Host "Project Journal generated: $(@($registry.systems).Count) systems, $($sourceById.Count) source documents, $($worldConcepts.Count) world-generation concepts, $($openDecisions.Count) open decisions; fingerprint $fingerprint." -ForegroundColor Green
}
