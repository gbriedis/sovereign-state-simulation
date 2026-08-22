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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Warnings = [System.Collections.Generic.List[string]]::new()
$script:MarkdownFilesChecked = 0
$script:MarkdownLinksChecked = 0

function Write-Check {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('PASS', 'FAIL', 'WARN', 'INFO')]
        [string] $Kind,

        [Parameter(Mandatory)]
        [string] $Message
    )

    $color = switch ($Kind) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'WARN' { 'Yellow' }
        default { 'Cyan' }
    }

    Write-Host "[$Kind] $Message" -ForegroundColor $color
}

function Add-Failure {
    param([Parameter(Mandatory)][string] $Message)

    $script:Failures.Add($Message)
    Write-Check -Kind FAIL -Message $Message
}

function Add-ValidationWarning {
    param([Parameter(Mandatory)][string] $Message)

    $script:Warnings.Add($Message)
    Write-Check -Kind WARN -Message $Message
}

function Get-RepositoryRoot {
    if (-not [string]::IsNullOrWhiteSpace($RepositoryRoot)) {
        if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {
            throw "RepositoryRoot does not exist or is not a directory: $RepositoryRoot"
        }

        return (Resolve-Path -LiteralPath $RepositoryRoot).Path
    }

    $scriptRoot = Split-Path -Parent $PSScriptRoot
    $scriptRoot = Split-Path -Parent $scriptRoot
    $gitRoot = & git -C $scriptRoot rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($gitRoot -join ''))) {
        return (Resolve-Path -LiteralPath ($gitRoot | Select-Object -First 1)).Path
    }

    return (Resolve-Path -LiteralPath $scriptRoot).Path
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory)][string] $Root,
        [Parameter(Mandatory)][string] $Path
    )

    return [System.IO.Path]::GetRelativePath($Root, $Path).Replace('\', '/')
}

function Test-IsIgnoredPath {
    param(
        [Parameter(Mandatory)][string] $Root,
        [Parameter(Mandatory)][string] $Path
    )

    $relative = '/' + (Get-RelativePath -Root $Root -Path $Path).Trim('/') + '/'
    return $relative -match '/(?:\.git|target|node_modules|vendor|dist|build)/'
}

function Get-MarkdownScanLines {
    param(
        [Parameter(Mandatory)][string] $Path,
        [switch] $PreserveInlineCode
    )

    $lines = @(Get-Content -LiteralPath $Path)
    $insideFence = $false
    $fenceCharacter = $null
    $result = [System.Collections.Generic.List[object]]::new()

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = [string] $lines[$index]
        $fenceMatch = [regex]::Match($line, '^\s{0,3}(?<fence>`{3,}|~{3,})')
        if ($fenceMatch.Success) {
            $character = $fenceMatch.Groups['fence'].Value.Substring(0, 1)
            if (-not $insideFence) {
                $insideFence = $true
                $fenceCharacter = $character
            }
            elseif ($character -eq $fenceCharacter) {
                $insideFence = $false
                $fenceCharacter = $null
            }

            continue
        }

        if ($insideFence) {
            continue
        }

        # Link-like text inside inline code is an example, not a live link. Some
        # structural consumers (headings and ADR metadata) request the raw line.
        $scanText = if ($PreserveInlineCode) {
            $line
        }
        else {
            [regex]::Replace($line, '`+[^`]*`+', '')
        }
        $result.Add([pscustomobject]@{
                Number = $index + 1
                Text   = $scanText
            })
    }

    return $result
}

function Get-InlineMarkdownDestinations {
    param([Parameter(Mandatory)][AllowEmptyString()][string] $Line)

    $destinations = [System.Collections.Generic.List[string]]::new()
    $searchFrom = 0

    while ($searchFrom -lt $Line.Length) {
        $open = $Line.IndexOf('](', $searchFrom, [System.StringComparison]::Ordinal)
        if ($open -lt 0) {
            break
        }

        $contentStart = $open + 2
        $depth = 1
        $escaped = $false
        $close = -1

        for ($position = $contentStart; $position -lt $Line.Length; $position++) {
            $character = $Line[$position]
            if ($escaped) {
                $escaped = $false
                continue
            }

            if ($character -eq '\') {
                $escaped = $true
                continue
            }

            if ($character -eq '(') {
                $depth++
            }
            elseif ($character -eq ')') {
                $depth--
                if ($depth -eq 0) {
                    $close = $position
                    break
                }
            }
        }

        if ($close -lt 0) {
            break
        }

        $inside = $Line.Substring($contentStart, $close - $contentStart).Trim()
        if ($inside.StartsWith('<', [System.StringComparison]::Ordinal)) {
            $angleClose = $inside.IndexOf('>')
            if ($angleClose -gt 0) {
                $destinations.Add($inside.Substring(1, $angleClose - 1))
            }
        }
        elseif ($inside.Length -gt 0) {
            $destination = [System.Text.StringBuilder]::new()
            $escaped = $false
            foreach ($character in $inside.ToCharArray()) {
                if ($escaped) {
                    [void] $destination.Append($character)
                    $escaped = $false
                    continue
                }

                if ($character -eq '\') {
                    $escaped = $true
                    continue
                }

                if ([char]::IsWhiteSpace($character)) {
                    break
                }

                [void] $destination.Append($character)
            }

            if ($destination.Length -gt 0) {
                $destinations.Add($destination.ToString())
            }
        }

        $searchFrom = $close + 1
    }

    return $destinations
}

function ConvertTo-GitHubAnchor {
    param([Parameter(Mandatory)][string] $Heading)

    $slug = $Heading.Trim()
    $slug = [regex]::Replace($slug, '!\[(?<text>[^\]]*)\]\([^)]*\)', '${text}')
    $slug = [regex]::Replace($slug, '\[(?<text>[^\]]+)\]\([^)]*\)', '${text}')
    $slug = [regex]::Replace($slug, '\[(?<text>[^\]]+)\]\[[^\]]*\]', '${text}')
    $slug = [regex]::Replace($slug, '`+(?<text>[^`]*)`+', '${text}')
    $slug = [regex]::Replace($slug, '<[^>]+>', '')
    $slug = $slug.ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^\p{L}\p{Nd}\s_-]', '')
    $slug = [regex]::Replace($slug, '\s+', '-')
    return $slug
}

function Get-MarkdownAnchors {
    param([Parameter(Mandatory)][string] $Path)

    $anchors = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $baseCounts = @{}

    $scanLines = @(Get-MarkdownScanLines -Path $Path -PreserveInlineCode)
    for ($index = 0; $index -lt $scanLines.Count; $index++) {
        $scanLine = $scanLines[$index]
        $heading = $null
        $headingMatch = [regex]::Match($scanLine.Text, '^\s{0,3}#{1,6}\s+(?<heading>.*?)\s*#*\s*$')
        if ($headingMatch.Success) {
            $heading = $headingMatch.Groups['heading'].Value
        }
        elseif ($index + 1 -lt $scanLines.Count -and
            $scanLines[$index + 1].Number -eq $scanLine.Number + 1 -and
            $scanLines[$index + 1].Text -match '^\s{0,3}(?:=+|-+)\s*$' -and
            -not [string]::IsNullOrWhiteSpace($scanLine.Text)) {
            $heading = $scanLine.Text.Trim()
        }

        if (-not [string]::IsNullOrWhiteSpace($heading)) {
            $base = ConvertTo-GitHubAnchor -Heading $heading
            if (-not [string]::IsNullOrWhiteSpace($base)) {
                $count = if ($baseCounts.ContainsKey($base)) { [int] $baseCounts[$base] } else { 0 }
                $anchor = if ($count -eq 0) { $base } else { "$base-$count" }
                $baseCounts[$base] = $count + 1
                [void] $anchors.Add($anchor)
            }
        }

        $withoutInlineCode = [regex]::Replace($scanLine.Text, '`+[^`]*`+', '')
        foreach ($idMatch in [regex]::Matches($withoutInlineCode, '(?i)\bid\s*=\s*["''](?<id>[^"'']+)["'']')) {
            [void] $anchors.Add($idMatch.Groups['id'].Value)
        }
    }

    return ,$anchors
}

function Test-MarkdownDestination {
    param(
        [Parameter(Mandatory)][string] $Root,
        [Parameter(Mandatory)][string] $SourcePath,
        [Parameter(Mandatory)][int] $LineNumber,
        [Parameter(Mandatory)][string] $Destination,
        [Parameter(Mandatory)][hashtable] $AnchorCache
    )

    $target = $Destination.Trim()
    if ([string]::IsNullOrWhiteSpace($target)) {
        return
    }

    if ($target -match '^(?i:file):') {
        Add-Failure "$(Get-RelativePath -Root $Root -Path $SourcePath):$LineNumber uses a machine-local absolute path: $Destination"
        return
    }

    if ($target.StartsWith('//', [System.StringComparison]::Ordinal) -or
        $target -match '^[A-Za-z][A-Za-z0-9+.-]*:') {
        return
    }

    $fragment = $null
    $fragmentIndex = $target.IndexOf('#')
    if ($fragmentIndex -ge 0) {
        $fragment = $target.Substring($fragmentIndex + 1)
        $target = $target.Substring(0, $fragmentIndex)
    }

    $queryIndex = $target.IndexOf('?')
    if ($queryIndex -ge 0) {
        $target = $target.Substring(0, $queryIndex)
    }

    try {
        $target = [System.Uri]::UnescapeDataString($target)
        if ($null -ne $fragment) {
            $fragment = [System.Uri]::UnescapeDataString($fragment)
        }
    }
    catch {
        Add-Failure "$(Get-RelativePath -Root $Root -Path $SourcePath):$LineNumber has an invalid escaped link: $Destination"
        return
    }

    if ($target -match '^[A-Za-z]:[\\/]') {
        Add-Failure "$(Get-RelativePath -Root $Root -Path $SourcePath):$LineNumber uses a machine-local absolute path: $Destination"
        return
    }

    if ([string]::IsNullOrWhiteSpace($target)) {
        $resolvedTarget = $SourcePath
    }
    elseif ($target.StartsWith('/', [System.StringComparison]::Ordinal)) {
        $resolvedTarget = [System.IO.Path]::GetFullPath((Join-Path $Root $target.TrimStart('/')))
    }
    else {
        $resolvedTarget = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $SourcePath) $target.Replace('/', [System.IO.Path]::DirectorySeparatorChar)))
    }

    $relativeTarget = [System.IO.Path]::GetRelativePath($Root, $resolvedTarget)
    if ($relativeTarget -eq '..' -or $relativeTarget.StartsWith('..' + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::Ordinal)) {
        Add-Failure "$(Get-RelativePath -Root $Root -Path $SourcePath):$LineNumber links outside the repository: $Destination"
        return
    }

    if (-not (Test-Path -LiteralPath $resolvedTarget)) {
        Add-Failure "$(Get-RelativePath -Root $Root -Path $SourcePath):$LineNumber links to a missing local target: $Destination"
        return
    }

    $script:MarkdownLinksChecked++

    if (-not [string]::IsNullOrWhiteSpace($fragment) -and
        (Test-Path -LiteralPath $resolvedTarget -PathType Leaf) -and
        [System.IO.Path]::GetExtension($resolvedTarget) -ieq '.md') {
        if (-not $AnchorCache.ContainsKey($resolvedTarget)) {
            $AnchorCache[$resolvedTarget] = Get-MarkdownAnchors -Path $resolvedTarget
        }

        if (-not $AnchorCache[$resolvedTarget].Contains($fragment)) {
            Add-Failure "$(Get-RelativePath -Root $Root -Path $SourcePath):$LineNumber links to a missing Markdown anchor: $Destination"
        }
    }
}

function Test-MarkdownLinks {
    param([Parameter(Mandatory)][string] $Root)

    Write-Check -Kind INFO -Message 'Checking local Markdown links...'
    $failureCountBefore = $script:Failures.Count
    $anchorCache = @{}
    $markdownFiles = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.md' |
            Where-Object { -not (Test-IsIgnoredPath -Root $Root -Path $_.FullName) })

    foreach ($file in $markdownFiles) {
        $script:MarkdownFilesChecked++
        $definitions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $referenceUses = [System.Collections.Generic.List[object]]::new()

        foreach ($scanLine in Get-MarkdownScanLines -Path $file.FullName) {
            $definitionMatch = [regex]::Match($scanLine.Text, '^\s{0,3}\[(?<label>[^\]]+)\]:\s*(?<destination><[^>]+>|\S+)')
            if ($definitionMatch.Success) {
                [void] $definitions.Add($definitionMatch.Groups['label'].Value.Trim())
                $definitionTarget = $definitionMatch.Groups['destination'].Value.Trim().Trim('<', '>')
                Test-MarkdownDestination -Root $Root -SourcePath $file.FullName -LineNumber $scanLine.Number -Destination $definitionTarget -AnchorCache $anchorCache
                continue
            }

            foreach ($destination in Get-InlineMarkdownDestinations -Line $scanLine.Text) {
                Test-MarkdownDestination -Root $Root -SourcePath $file.FullName -LineNumber $scanLine.Number -Destination $destination -AnchorCache $anchorCache
            }

            foreach ($referenceMatch in [regex]::Matches($scanLine.Text, '\[(?<text>[^\]]+)\]\[(?<label>[^\]]*)\]')) {
                $label = $referenceMatch.Groups['label'].Value
                if ([string]::IsNullOrWhiteSpace($label)) {
                    $label = $referenceMatch.Groups['text'].Value
                }
                $referenceUses.Add([pscustomobject]@{ Label = $label.Trim(); Line = $scanLine.Number })
            }
        }

        foreach ($referenceUse in $referenceUses) {
            if (-not $definitions.Contains($referenceUse.Label)) {
                Add-Failure "$(Get-RelativePath -Root $Root -Path $file.FullName):$($referenceUse.Line) uses undefined Markdown reference [$($referenceUse.Label)]"
            }
        }
    }

    if ($script:Failures.Count -eq $failureCountBefore) {
        Write-Check -Kind PASS -Message "Checked $($script:MarkdownLinksChecked) local targets across $($script:MarkdownFilesChecked) Markdown files."
    }
}

function Test-RequiredControlPlaneFiles {
    param([Parameter(Mandatory)][string] $Root)

    Write-Check -Kind INFO -Message 'Checking required project-control files...'
    $requiredFiles = @(
        'AGENTS.md',
        'docs/handoff/CURRENT_STATE.md',
        'docs/operations/OPERATING_MODEL.md',
        'docs/operations/WORKSTREAMS.md',
        'docs/operations/DEPENDENCIES.md',
        'docs/art/README.md',
        'docs/decisions/README.md',
        'docs/decisions/ADR_TEMPLATE.md',
        'docs/decisions/ADR-0001-project-control-plane.md'
    )

    $missingBefore = $script:Failures.Count
    foreach ($relativePath in $requiredFiles) {
        $fullPath = Join-Path $Root $relativePath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            Add-Failure "Missing required project-control file: $relativePath"
        }
    }

    if ($script:Failures.Count -eq $missingBefore) {
        Write-Check -Kind PASS -Message "All $($requiredFiles.Count) required project-control files are present."
    }
}

function Get-DecisionStatus {
    param([Parameter(Mandatory)][AllowEmptyString()][string] $Content)

    $lineMatch = [regex]::Match(
        $Content,
        '(?im)^\s*(?:[-*]\s*)?(?:\*\*Status:\*\*|\*\*Status\*\*\s*:|Status\s*:)\s*(?:\*\*)?(?<status>[A-Za-z]+)(?:\*\*)?\s*$'
    )
    if ($lineMatch.Success) {
        return $lineMatch.Groups['status'].Value.Trim()
    }

    $tableMatch = [regex]::Match(
        $Content,
        '(?im)^\s*\|\s*(?:\*\*)?Status(?:\*\*)?\s*\|\s*(?:\*\*)?(?<status>[^|*]+)'
    )
    if ($tableMatch.Success) {
        return $tableMatch.Groups['status'].Value.Trim()
    }

    return $null
}

function Test-DecisionRecords {
    param([Parameter(Mandatory)][string] $Root)

    Write-Check -Kind INFO -Message 'Checking architecture decision records...'
    $decisionDirectory = Join-Path $Root 'docs/decisions'
    if (-not (Test-Path -LiteralPath $decisionDirectory -PathType Container)) {
        return
    }

    $validStatuses = @('Proposed', 'Accepted', 'Rejected', 'Superseded')
    $ids = @{}
    $records = @(Get-ChildItem -LiteralPath $decisionDirectory -File -Filter '*.md' |
            Where-Object { $_.Name -notin @('README.md', 'ADR_TEMPLATE.md') })
    $failureCountBefore = $script:Failures.Count

    foreach ($record in $records) {
        $filenameMatch = [regex]::Match($record.Name, '^ADR-(?<id>\d{4})-(?<slug>[a-z0-9]+(?:-[a-z0-9]+)*)\.md$')
        if (-not $filenameMatch.Success) {
            Add-Failure "Malformed ADR filename: docs/decisions/$($record.Name). Expected ADR-NNNN-kebab-case.md."
            continue
        }

        $id = $filenameMatch.Groups['id'].Value
        if ($id -eq '0000') {
            Add-Failure "Malformed ADR ID in docs/decisions/$($record.Name): ADR-0000 is reserved and may not be used."
        }
        elseif ($ids.ContainsKey($id)) {
            Add-Failure "Duplicate ADR ID ADR-$id in docs/decisions/$($record.Name) and $($ids[$id])."
        }
        else {
            $ids[$id] = "docs/decisions/$($record.Name)"
        }

        $recordScanLines = @(Get-MarkdownScanLines -Path $record.FullName -PreserveInlineCode)
        $content = (($recordScanLines | ForEach-Object { $_.Text }) -join "`n")
        $headingMatch = [regex]::Match($content, '(?im)^\s*#\s+ADR-(?<id>\d{4})\b')
        if (-not $headingMatch.Success) {
            Add-Failure "docs/decisions/$($record.Name) is missing a level-one ADR-NNNN heading."
        }
        elseif ($headingMatch.Groups['id'].Value -ne $id) {
            Add-Failure "ADR ID mismatch in docs/decisions/$($record.Name): filename ADR-$id, heading ADR-$($headingMatch.Groups['id'].Value)."
        }

        $status = Get-DecisionStatus -Content $content
        if ([string]::IsNullOrWhiteSpace($status)) {
            Add-Failure "docs/decisions/$($record.Name) is missing a Status field."
        }
        elseif (-not ($validStatuses -ccontains $status)) {
            Add-Failure "Invalid ADR status '$status' in docs/decisions/$($record.Name). Allowed: $($validStatuses -join ', ')."
        }

        $artImpactRaw = Get-BoldMetadataValue -Content $content -Label 'Art / Technical Art impact'
        if ([string]::IsNullOrWhiteSpace($artImpactRaw)) {
            Add-Failure "docs/decisions/$($record.Name) is missing non-empty 'Art / Technical Art impact' metadata."
        }
        else {
            $artImpact = $artImpactRaw.Trim(' ', '`', '*')
            $routedArtImpact = $artImpact -cmatch '^(?:Action required|Consulted|Informed)(?=$|[\s—:])'
            $reasonedArtNia = $artImpact -cmatch '^N/A\s+—\s+\S'
            if (-not $routedArtImpact -and -not $reasonedArtNia) {
                Add-Failure "docs/decisions/$($record.Name) has invalid Art / Technical Art impact '$artImpact'. Begin with Action required, Consulted, Informed, or N/A — <nonempty rationale>."
            }
        }
    }

    if ($script:Failures.Count -eq $failureCountBefore) {
        Write-Check -Kind PASS -Message "Validated $($records.Count) decision record(s)."
    }
}

function Get-BoldMetadataValue {
    param(
        [Parameter(Mandatory)][string] $Content,
        [Parameter(Mandatory)][string] $Label
    )

    $escapedLabel = [regex]::Escape($Label)
    $match = [regex]::Match(
        $Content,
        "(?im)^\s*[-*]\s+\*\*${escapedLabel}:\*\*\s*(?<value>.+?)\s*$"
    )
    if ($match.Success) {
        return $match.Groups['value'].Value.Trim()
    }

    return $null
}

function Test-ArtContractMarkers {
    param([Parameter(Mandatory)][string] $Root)

    Write-Check -Kind INFO -Message 'Checking stable Art / Technical Art contract markers...'
    $failureCountBefore = $script:Failures.Count
    $requiredMarkers = @(
        'ART-CONTRACT: IMPACT-DECLARATION',
        'ART-CONTRACT: REVIEW-GATE'
    )
    $contractFiles = @(
        'AGENTS.md',
        'docs/operations/OPERATING_MODEL.md',
        'docs/operations/DEPENDENCIES.md',
        '.github/pull_request_template.md',
        '.github/ISSUE_TEMPLATE/work-packet.yml',
        '.github/ISSUE_TEMPLATE/decision-rfc.yml',
        '.github/ISSUE_TEMPLATE/review-finding.yml'
    )

    foreach ($relativePath in $contractFiles) {
        $fullPath = Join-Path $Root $relativePath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            Add-Failure "Cannot validate the Art contract because its required source is missing: $relativePath"
            continue
        }

        $content = Get-Content -LiteralPath $fullPath -Raw
        foreach ($marker in $requiredMarkers) {
            if (-not $content.Contains($marker, [System.StringComparison]::Ordinal)) {
                Add-Failure "$relativePath is missing stable marker '$marker'. Retain the marker when editing the Art contract."
            }
        }
    }

    if ($script:Failures.Count -eq $failureCountBefore) {
        Write-Check -Kind PASS -Message "Validated both Art contract markers in all $($contractFiles.Count) contract surfaces."
    }
}

function Test-WorkstreamArtImpact {
    param([Parameter(Mandatory)][string] $Root)

    Write-Check -Kind INFO -Message 'Checking Art / Technical Art impact on every workstream...'
    $failureCountBefore = $script:Failures.Count
    $workstreamsPath = Join-Path $Root 'docs/operations/WORKSTREAMS.md'
    if (-not (Test-Path -LiteralPath $workstreamsPath -PathType Leaf)) {
        return
    }

    $workstreams = Get-Content -LiteralPath $workstreamsPath -Raw
    $recordPattern = '(?im)^##\s+(?<id>[A-Z][A-Z0-9]*-[0-9]{3})\s+—\s+(?<title>\S.*?)\s*$' +
        '(?<body>.*?)(?=^##\s+|\z)'
    $recordMatches = [regex]::Matches(
        $workstreams,
        $recordPattern,
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if ($recordMatches.Count -eq 0) {
        Add-Failure 'docs/operations/WORKSTREAMS.md contains no valid records on which to validate Art / Technical Art impact.'
        return
    }

    foreach ($recordMatch in $recordMatches) {
        $id = $recordMatch.Groups['id'].Value.ToUpperInvariant()
        $body = $recordMatch.Groups['body'].Value
        $impactRaw = Get-BoldMetadataValue -Content $body -Label 'Art / Technical Art impact'
        if ([string]::IsNullOrWhiteSpace($impactRaw)) {
            Add-Failure "Workstream $id is missing non-empty 'Art / Technical Art impact' metadata."
            continue
        }

        $impact = $impactRaw.Trim(' ', '`', '*')
        $routedImpact = $impact -cmatch '^(?:Action required|Consulted|Informed)(?=$|[\s—:])'
        $reasonedNotApplicable = $impact -cmatch '^N/A\s+—\s+\S'
        if (-not $routedImpact -and -not $reasonedNotApplicable) {
            Add-Failure "Workstream $id has invalid Art / Technical Art impact '$impact'. Begin with Action required, Consulted, Informed, or N/A — <nonempty rationale>."
        }
    }

    if ($script:Failures.Count -eq $failureCountBefore) {
        Write-Check -Kind PASS -Message "Validated Art / Technical Art impact on all $($recordMatches.Count) workstream record(s)."
    }
}

function Test-StrictMetadata {
    param([Parameter(Mandatory)][string] $Root)

    Write-Check -Kind INFO -Message 'Checking current-state and workstream metadata (strict mode)...'
    $failureCountBefore = $script:Failures.Count
    $warningCountBefore = $script:Warnings.Count

    $currentStatePath = Join-Path $Root 'docs/handoff/CURRENT_STATE.md'
    if (Test-Path -LiteralPath $currentStatePath -PathType Leaf) {
        $currentState = Get-Content -LiteralPath $currentStatePath -Raw
        $currentStateFields = [ordered]@{
            'Last verified'              = @('Last verified', 'Snapshot date')
            'Project phase'              = @('Project phase')
            'Immediate product milestone' = @('Immediate product milestone', 'Immediate milestone')
            'Implementation state'       = @('Implementation state', 'Implementation status')
        }
        $currentStateValues = @{}
        foreach ($canonicalLabel in $currentStateFields.Keys) {
            $value = $null
            foreach ($acceptedLabel in $currentStateFields[$canonicalLabel]) {
                $value = Get-BoldMetadataValue -Content $currentState -Label $acceptedLabel
                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    break
                }
            }
            $currentStateValues[$canonicalLabel] = $value
            if ([string]::IsNullOrWhiteSpace($value)) {
                Add-Failure "docs/handoff/CURRENT_STATE.md is missing non-empty '$canonicalLabel' metadata."
            }
        }

        $snapshot = $currentStateValues['Last verified']
        if (-not [string]::IsNullOrWhiteSpace($snapshot)) {
            $date = [datetime]::MinValue
            if (-not [datetime]::TryParseExact(
                    $snapshot,
                    'yyyy-MM-dd',
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::None,
                    [ref] $date
                )) {
                Add-Failure "docs/handoff/CURRENT_STATE.md Last verified must use YYYY-MM-DD; found '$snapshot'."
            }
        }
    }

    $workstreamsPath = Join-Path $Root 'docs/operations/WORKSTREAMS.md'
    if (Test-Path -LiteralPath $workstreamsPath -PathType Leaf) {
        $workstreams = Get-Content -LiteralPath $workstreamsPath -Raw
        $allowedTypes = @('Packet', 'Initiative')
        $allowedStates = @('Proposed', 'Ready', 'Active', 'Blocked', 'Review', 'Integration', 'Done', 'Cancelled')
        $allowedPriorities = @('P0', 'P1', 'P2', 'P3')
        $recordPattern = '(?im)^##\s+(?<id>[A-Z][A-Z0-9]*-[0-9]{3})\s+—\s+(?<title>\S.*?)\s*$' +
            '(?<body>.*?)(?=^##\s+|\z)'
        $recordMatches = [regex]::Matches($workstreams, $recordPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $seenIds = @{}

        foreach ($headingMatch in [regex]::Matches($workstreams, '(?im)^##\s+(?<candidate>[A-Za-z][A-Za-z0-9_-]*\d+)\b(?<rest>.*?)$')) {
            $candidate = $headingMatch.Groups['candidate'].Value
            $rest = $headingMatch.Groups['rest'].Value
            if ($candidate -cnotmatch '^[A-Z][A-Z0-9]*-[0-9]{3}$' -or $rest -notmatch '^\s+—\s+\S') {
                Add-Failure "Workstream heading '$candidate$rest' is malformed. Expected '## AREA-NNN — Short outcome'."
            }
        }

        if ($recordMatches.Count -eq 0) {
            Add-Failure 'docs/operations/WORKSTREAMS.md contains no valid workstream records.'
        }

        foreach ($recordMatch in $recordMatches) {
            $id = $recordMatch.Groups['id'].Value.ToUpperInvariant()
            if ($seenIds.ContainsKey($id)) {
                Add-Failure "Duplicate workstream ID $id in docs/operations/WORKSTREAMS.md."
                continue
            }
            $seenIds[$id] = $true

            $body = $recordMatch.Groups['body'].Value
            $requiredLabels = @(
                'Type',
                'DRI',
                'State',
                'Priority',
                'Updated',
                'Outcome',
                'Done when',
                'Base',
                'Branch / worktree',
                'Write scope',
                'Dependencies',
                'Review gate',
                'Routing',
                'Evidence',
                'Next action',
                'Blocker'
            )
            foreach ($label in $requiredLabels) {
                $value = Get-BoldMetadataValue -Content $body -Label $label
                if ([string]::IsNullOrWhiteSpace($value)) {
                    Add-Failure "Workstream $id is missing non-empty '$label' metadata."
                }
            }

            $typeRaw = Get-BoldMetadataValue -Content $body -Label 'Type'
            $stateRaw = Get-BoldMetadataValue -Content $body -Label 'State'
            $priorityRaw = Get-BoldMetadataValue -Content $body -Label 'Priority'
            $updatedRaw = Get-BoldMetadataValue -Content $body -Label 'Updated'
            $type = if ($null -eq $typeRaw) { $null } else { $typeRaw.Trim(' ', '`', '*') }
            $state = if ($null -eq $stateRaw) { $null } else { $stateRaw.Trim(' ', '`', '*') }
            $priority = if ($null -eq $priorityRaw) { $null } else { $priorityRaw.Trim(' ', '`', '*') }
            $updated = if ($null -eq $updatedRaw) { $null } else { $updatedRaw.Trim(' ', '`', '*') }

            if (-not [string]::IsNullOrWhiteSpace($type) -and -not ($allowedTypes -ccontains $type)) {
                Add-Failure "Workstream $id has invalid Type '$type'. Allowed: $($allowedTypes -join ', ')."
            }
            if (-not [string]::IsNullOrWhiteSpace($state) -and -not ($allowedStates -ccontains $state)) {
                Add-Failure "Workstream $id has invalid State '$state'. Allowed: $($allowedStates -join ', ')."
            }
            if (-not [string]::IsNullOrWhiteSpace($priority) -and -not ($allowedPriorities -ccontains $priority)) {
                Add-Failure "Workstream $id has invalid Priority '$priority'. Allowed: $($allowedPriorities -join ', ')."
            }

            if (-not [string]::IsNullOrWhiteSpace($updated)) {
                $updatedDate = [datetime]::MinValue
                if (-not [datetime]::TryParseExact(
                        $updated,
                        'yyyy-MM-dd',
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::None,
                        [ref] $updatedDate
                    )) {
                    Add-Failure "Workstream $id Updated must use YYYY-MM-DD; found '$updated'."
                }
            }

            if ($state -ceq 'Blocked') {
                $blockerRaw = Get-BoldMetadataValue -Content $body -Label 'Blocker'
                $blocker = if ($null -eq $blockerRaw) { $null } else { $blockerRaw.Trim(' ', '`', '*') }
                if ([string]::IsNullOrWhiteSpace($blocker) -or $blocker -match '^(?i:none|n/a|not applicable|—|-)$') {
                    Add-Failure "Workstream $id is Blocked but its Blocker field does not describe the blocking condition."
                }
            }
        }
    }

    if ($script:Failures.Count -eq $failureCountBefore -and $script:Warnings.Count -eq $warningCountBefore) {
        Write-Check -Kind PASS -Message 'Current-state and workstream metadata are valid.'
    }
    elseif ($script:Failures.Count -eq $failureCountBefore) {
        Write-Check -Kind INFO -Message 'Strict metadata checks completed with advisory current-state warning(s).'
    }
}

function Invoke-GitReadOnly {
    param(
        [Parameter(Mandatory)][string] $WorkingDirectory,
        [Parameter(Mandatory)][string[]] $Arguments,
        [switch] $AllowFailure
    )

    # Disable Git's optional index refresh/maintenance so the audit remains
    # byte-for-byte read-only even when file mtimes have changed.
    $output = @(& git --no-optional-locks -C $WorkingDirectory @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "git $($Arguments -join ' ') failed in '$WorkingDirectory': $($output -join [Environment]::NewLine)"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $output
    }
}

function Get-GitWorktrees {
    param([Parameter(Mandatory)][string] $Root)

    $result = Invoke-GitReadOnly -WorkingDirectory $Root -Arguments @('worktree', 'list', '--porcelain')
    $worktrees = [System.Collections.Generic.List[object]]::new()
    $current = $null

    foreach ($line in @($result.Output) + '') {
        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($null -ne $current) {
                $worktrees.Add([pscustomobject] $current)
                $current = $null
            }
            continue
        }

        $key, $value = $line -split ' ', 2
        if ($key -eq 'worktree') {
            $current = [ordered]@{
                Path     = $value
                Head     = $null
                Branch   = $null
                Detached = $false
                Prunable = $false
                Locked   = $false
            }
        }
        elseif ($null -ne $current) {
            switch ($key) {
                'HEAD' { $current.Head = $value }
                'branch' { $current.Branch = $value }
                'detached' { $current.Detached = $true }
                'prunable' { $current.Prunable = $true }
                'locked' { $current.Locked = $true }
            }
        }
    }

    return $worktrees
}

function Invoke-GitAudit {
    param([Parameter(Mandatory)][string] $Root)

    Write-Check -Kind INFO -Message 'Running read-only Git/worktree audit...'
    $inside = Invoke-GitReadOnly -WorkingDirectory $Root -Arguments @('rev-parse', '--is-inside-work-tree') -AllowFailure
    if ($inside.ExitCode -ne 0 -or ($inside.Output -join '').Trim() -ne 'true') {
        Add-ValidationWarning "Cannot audit Git state because '$Root' is not a Git worktree."
        return
    }

    $referenceCheck = Invoke-GitReadOnly -WorkingDirectory $Root -Arguments @('rev-parse', '--verify', "$ReferenceRef^{commit}") -AllowFailure
    $hasReference = $referenceCheck.ExitCode -eq 0
    if (-not $hasReference) {
        Add-ValidationWarning "Reference '$ReferenceRef' does not exist locally; per-worktree divergence cannot be calculated."
    }

    $worktrees = @(Get-GitWorktrees -Root $Root)
    $now = [DateTimeOffset]::UtcNow
    foreach ($worktree in $worktrees) {
        $displayPath = $worktree.Path
        $findings = [System.Collections.Generic.List[string]]::new()

        if ($worktree.Detached) {
            $findings.Add('detached HEAD')
        }
        if ($worktree.Prunable) {
            $findings.Add('prunable metadata')
        }
        if ($worktree.Locked) {
            $findings.Add('locked')
        }

        $pathExists = Test-Path -LiteralPath $worktree.Path -PathType Container
        if (-not $pathExists) {
            $findings.Add('missing worktree directory')
        }
        else {
            $status = Invoke-GitReadOnly -WorkingDirectory $worktree.Path -Arguments @('status', '--porcelain=v1', '--untracked-files=normal') -AllowFailure
            if ($status.ExitCode -ne 0) {
                $findings.Add('status unavailable')
            }
            elseif (@($status.Output).Count -gt 0 -and -not [string]::IsNullOrWhiteSpace(($status.Output -join ''))) {
                $findings.Add('dirty')
            }
        }

        $ahead = $null
        $behind = $null
        if ($hasReference -and -not [string]::IsNullOrWhiteSpace($worktree.Head)) {
            $divergence = Invoke-GitReadOnly -WorkingDirectory $Root -Arguments @('rev-list', '--left-right', '--count', "$($worktree.Head)...$ReferenceRef") -AllowFailure
            if ($divergence.ExitCode -eq 0) {
                $parts = (($divergence.Output | Select-Object -First 1) -split '\s+')
                if ($parts.Count -ge 2) {
                    $ahead = [int] $parts[0]
                    $behind = [int] $parts[1]
                    if ($ahead -gt 0 -or $behind -gt 0) {
                        $findings.Add("diverged from $ReferenceRef (ahead $ahead, behind $behind)")
                    }
                }
            }
        }

        $ageDays = $null
        if (-not [string]::IsNullOrWhiteSpace($worktree.Head)) {
            $timestampResult = Invoke-GitReadOnly -WorkingDirectory $Root -Arguments @('show', '-s', '--format=%ct', $worktree.Head) -AllowFailure
            $timestamp = 0L
            if ($timestampResult.ExitCode -eq 0 -and [long]::TryParse(($timestampResult.Output | Select-Object -First 1), [ref] $timestamp)) {
                $committedAt = [DateTimeOffset]::FromUnixTimeSeconds($timestamp)
                $ageDays = [math]::Floor(($now - $committedAt).TotalDays)
                if ($ageDays -ge $StaleAfterDays -and ($worktree.Detached -or ($null -ne $behind -and $behind -gt 0))) {
                    $findings.Add("stale candidate (HEAD is $ageDays days old)")
                }
            }
        }

        $branch = if ([string]::IsNullOrWhiteSpace($worktree.Branch)) { '(detached)' } else { $worktree.Branch -replace '^refs/heads/', '' }
        if ($findings.Count -eq 0) {
            Write-Check -Kind PASS -Message "$displayPath [$branch] is clean and aligned with $ReferenceRef."
        }
        else {
            Add-ValidationWarning "$displayPath [$branch]: $($findings -join '; ')."
        }
    }

    $upstreamCheck = Invoke-GitReadOnly -WorkingDirectory $Root -Arguments @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}') -AllowFailure
    if ($upstreamCheck.ExitCode -eq 0) {
        $upstream = ($upstreamCheck.Output | Select-Object -First 1).Trim()
        $remoteDivergence = Invoke-GitReadOnly -WorkingDirectory $Root -Arguments @('rev-list', '--left-right', '--count', "HEAD...$upstream") -AllowFailure
        if ($remoteDivergence.ExitCode -eq 0) {
            $parts = (($remoteDivergence.Output | Select-Object -First 1) -split '\s+')
            if ($parts.Count -ge 2) {
                Write-Check -Kind INFO -Message "Current HEAD versus ${upstream}: ahead $($parts[0]), behind $($parts[1]) (based on local remote-tracking data; no fetch performed)."
            }
        }
    }
    else {
        Write-Check -Kind INFO -Message 'Current branch has no configured upstream; remote divergence was not calculated.'
    }

    Write-Check -Kind INFO -Message 'Audit is report-only. No worktree, branch, commit, index, or remote was changed.'
}

$root = Get-RepositoryRoot
Write-Check -Kind INFO -Message "Repository root: $root"

if ($Mode -in @('Validate', 'All')) {
    Test-RequiredControlPlaneFiles -Root $root
    Test-ArtContractMarkers -Root $root
    Test-WorkstreamArtImpact -Root $root
    Test-MarkdownLinks -Root $root
    Test-DecisionRecords -Root $root
    if ($StrictMetadata) {
        Test-StrictMetadata -Root $root
    }
}

if ($Mode -in @('AuditGit', 'All')) {
    Invoke-GitAudit -Root $root
}

if ($script:Failures.Count -gt 0) {
    Write-Host ''
    Write-Check -Kind FAIL -Message "Governance validation failed with $($script:Failures.Count) error(s)."
    exit 1
}

if ($Mode -in @('Validate', 'All')) {
    Write-Check -Kind PASS -Message 'Governance validation passed.'
}
if ($Mode -in @('AuditGit', 'All')) {
    Write-Check -Kind INFO -Message "Git audit completed with $($script:Warnings.Count) finding(s). Findings do not fail validation."
}

exit 0
