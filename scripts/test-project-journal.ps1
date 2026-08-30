$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$builder = Join-Path $PSScriptRoot 'build-project-journal.ps1'
$checksPassed = 0
$expectedChecks = 79
$utf8 = [Text.UTF8Encoding]::new($false)

function Invoke-Builder([string]$TestRoot) {
    $output = & pwsh -NoProfile -File $builder -Check -RootPath $TestRoot 2>&1 | Out-String
    return @{ ExitCode = $LASTEXITCODE; Output = $output }
}

function Invoke-Generator([string]$TestRoot) {
    $output = & pwsh -NoProfile -File $builder -RootPath $TestRoot 2>&1 | Out-String
    return @{ ExitCode = $LASTEXITCODE; Output = $output }
}

function Invoke-SiteCheck([string]$TestRoot) {
    $script = Join-Path $TestRoot 'project-journal-site/scripts/sync-journal.mjs'
    $output = & node $script --check 2>&1 | Out-String
    return @{ ExitCode = $LASTEXITCODE; Output = $output }
}

function Invoke-DocsCheck([string]$TestRoot) {
    $script = Join-Path $TestRoot 'scripts/check-docs.ps1'
    $output = & pwsh -NoProfile -File $script 2>&1 | Out-String
    return @{ ExitCode = $LASTEXITCODE; Output = $output }
}

function New-TestRoot {
    $path = Join-Path ([IO.Path]::GetTempPath()) ("project-journal-test-" + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $path
    Copy-Item -LiteralPath (Join-Path $root 'docs') -Destination $path -Recurse
    Copy-Item -LiteralPath (Join-Path $root 'README.md') -Destination (Join-Path $path 'README.md')
    Copy-Item -LiteralPath (Join-Path $root 'Cargo.toml') -Destination (Join-Path $path 'Cargo.toml')
    Copy-Item -LiteralPath (Join-Path $root 'src') -Destination (Join-Path $path 'src') -Recurse
    $null = New-Item -ItemType Directory -Path (Join-Path $path 'scripts')
    Copy-Item -LiteralPath $builder -Destination (Join-Path $path 'scripts/build-project-journal.ps1')
    Copy-Item -LiteralPath (Join-Path $root 'scripts/check-docs.ps1') -Destination (Join-Path $path 'scripts/check-docs.ps1')
    $null = New-Item -ItemType Directory -Path (Join-Path $path 'project-journal-site/scripts') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $path 'project-journal-site/app') -Force
    Copy-Item -LiteralPath (Join-Path $root 'project-journal-site/scripts/sync-journal.mjs') -Destination (Join-Path $path 'project-journal-site/scripts/sync-journal.mjs')
    Copy-Item -LiteralPath (Join-Path $root 'project-journal-site/app/generated-journal.ts') -Destination (Join-Path $path 'project-journal-site/app/generated-journal.ts')
    return $path
}

function Remove-TestRoot([string]$Path) {
    $resolved = [IO.Path]::GetFullPath($Path)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or
        -not ([IO.Path]::GetFileName($resolved)).StartsWith('project-journal-test-', [StringComparison]::Ordinal)) {
        throw "Refusing to remove unexpected test path '$resolved'."
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}

function Get-Registry([string]$TestRoot) {
    return Get-Content -Raw -LiteralPath (Join-Path $TestRoot 'docs/project-journal/SYSTEMS.json') | ConvertFrom-Json -Depth 100
}

function Set-Registry([string]$TestRoot, $Registry) {
    $json = $Registry | ConvertTo-Json -Depth 100
    [IO.File]::WriteAllText((Join-Path $TestRoot 'docs/project-journal/SYSTEMS.json'), $json + "`n", $utf8)
}

function Invoke-MutationCase {
    param(
        [string]$Name,
        [scriptblock]$Mutate,
        [string]$ExpectedPattern,
        [switch]$ExpectSuccess,
        [switch]$Rebuild
    )
    $testRoot = New-TestRoot
    try {
        & $Mutate $testRoot
        if ($Rebuild) {
            $generated = Invoke-Generator $testRoot
            if ($generated.ExitCode -ne 0) { throw "$Name could not rebuild its valid fixture.`n$($generated.Output)" }
        }
        $result = Invoke-Builder $testRoot
        if ($ExpectSuccess) {
            if ($result.ExitCode -ne 0) { throw "$Name should pass but failed.`n$($result.Output)" }
        } else {
            if ($result.ExitCode -eq 0) { throw "$Name should fail but passed." }
            if ($result.Output -notmatch $ExpectedPattern) { throw "$Name did not report expected evidence '$ExpectedPattern'.`n$($result.Output)" }
        }
        $script:checksPassed++
    } finally {
        Remove-TestRoot $testRoot
    }
}

function Invoke-SemanticStalenessCase {
    param([string]$Name, [scriptblock]$Mutate)
    $testRoot = New-TestRoot
    try {
        & $Mutate $testRoot
        $result = Invoke-Builder $testRoot
        if ($result.ExitCode -eq 0 -or $result.Output -notmatch 'stale or hand-edited') {
            throw "$Name did not make generated Markdown detectably stale.`n$($result.Output)"
        }
        $script:checksPassed++
    } finally { Remove-TestRoot $testRoot }
}

$baseline = Invoke-Builder $root
if ($baseline.ExitCode -ne 0) { throw "The live Project Journal baseline failed.`n$($baseline.Output)" }
$checksPassed++

Invoke-MutationCase 'malformed registry' {
    param($testRoot)
    [IO.File]::WriteAllText((Join-Path $testRoot 'docs/project-journal/SYSTEMS.json'), '{', $utf8)
} 'malformed JSON'

Invoke-MutationCase 'blank system name' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].name = ' '
    Set-Registry $testRoot $registry
} 'blank name'

Invoke-MutationCase 'duplicate system name' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[1].name = $registry.systems[0].name
    Set-Registry $testRoot $registry
} 'System name .* is duplicated'

Invoke-MutationCase 'vague system name' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].name = 'Misc changes'
    Set-Registry $testRoot $registry
} "vague name segment 'misc'"

Invoke-MutationCase 'missing parent field' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[1].PSObject.Properties.Remove('parent')
    Set-Registry $testRoot $registry
} "missing required field 'parent'"

Invoke-MutationCase 'unknown parent' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[1].parent = 'missing-system'
    Set-Registry $testRoot $registry
} 'unknown parent'

Invoke-MutationCase 'parent cycle' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].parent = $registry.systems[1].id
    Set-Registry $testRoot $registry
} 'Parent cycle detected'

Invoke-MutationCase 'unknown relationship target' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].relationships = @([pscustomobject]@{ type = 'depends-on'; target = 'missing-system' })
    Set-Registry $testRoot $registry
} 'relationship to unknown system'

Invoke-MutationCase 'unknown relationship type' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].relationships = @([pscustomobject]@{ type = 'mystery'; target = 'natural-world-foundation' })
    Set-Registry $testRoot $registry
} 'unknown relationship type'

Invoke-MutationCase 'self relationship' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].relationships = @([pscustomobject]@{ type = 'depends-on'; target = $registry.systems[0].id })
    Set-Registry $testRoot $registry
} 'self relationship'

Invoke-MutationCase 'duplicate relationship' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $target = $registry.systems[1].id
    $registry.systems[0].relationships = @(
        [pscustomobject]@{ type = 'supports'; target = $target },
        [pscustomobject]@{ type = 'supports'; target = $target }
    )
    Set-Registry $testRoot $registry
} 'duplicates relationship'

Invoke-MutationCase 'missing document coverage' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].documents = @($registry.systems[0].documents | Where-Object { $_ -ne 'VISION-001' })
    Set-Registry $testRoot $registry
} "Document 'VISION-001' has no primary system coverage"

Invoke-MutationCase 'duplicate document coverage' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[1].documents = @($registry.systems[1].documents) + 'VISION-001'
    Set-Registry $testRoot $registry
} "Document 'VISION-001' has duplicate primary system coverage"

Invoke-MutationCase 'unknown authority' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].authorities[0] = 'UNKNOWN-AUTHORITY'
    Set-Registry $testRoot $registry
} 'references unknown authority'

Invoke-MutationCase 'superseded authority' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/foundations/PROJECT_VISION.md'
    $text = [IO.File]::ReadAllText($path).Replace('status: accepted', 'status: superseded')
    [IO.File]::WriteAllText($path, $text, $utf8)
} 'superseded'

Invoke-MutationCase 'missing world-generation coverage' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $system = @($registry.systems | Where-Object { $_.id -eq 'planetary-foundation' })[0]
    $system.worldGenerationConcepts = @($system.worldGenerationConcepts | Where-Object { $_ -ne 'WG-001' })
    Set-Registry $testRoot $registry
} "World-generation concept 'WG-001' has no primary system coverage"

Invoke-MutationCase 'duplicate world-generation coverage' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $system = @($registry.systems | Where-Object { $_.id -eq 'geological-history-and-material' })[0]
    $system.worldGenerationConcepts = @($system.worldGenerationConcepts) + 'WG-001'
    Set-Registry $testRoot $registry
} "World-generation concept 'WG-001' has duplicate primary system coverage"

Invoke-MutationCase 'recognized ownerless topic remains valid' {
    param($testRoot)
    $index = [IO.File]::ReadAllText((Join-Path $testRoot 'docs/world-generation/README.md'))
    if ($index -notmatch '\| `WG-017` \| `recognized` .* \| Not created \|') { throw 'Ownerless recognized-topic fixture is absent.' }
} 'unused' -ExpectSuccess

Invoke-MutationCase 'CRLF world index and current phase remain parseable' {
    param($testRoot)
    foreach ($relative in @('docs/world-generation/README.md', 'docs/operations/CURRENT_STATE.md')) {
        $path = Join-Path $testRoot $relative
        $text = [IO.File]::ReadAllText($path).Replace("`r`n", "`n").Replace("`n", "`r`n")
        [IO.File]::WriteAllText($path, $text, $utf8)
    }
} 'unused' -ExpectSuccess

Invoke-MutationCase 'shared concept owners remain valid' {
    param($testRoot)
    $index = [IO.File]::ReadAllText((Join-Path $testRoot 'docs/world-generation/README.md'))
    $owners = [regex]::Matches($index, '(?m)^\| `WG-0(?:09|10)` .*?\]\((?<owner>[^)]+)\)')
    if ($owners.Count -ne 2 -or $owners[0].Groups['owner'].Value -ne $owners[1].Groups['owner'].Value) { throw 'Shared-owner fixture is absent.' }
} 'unused' -ExpectSuccess

Invoke-MutationCase 'missing open-decision coverage' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $system = @($registry.systems | Where-Object { $_.id -eq 'map-and-spatial-model-prototype' })[0]
    $system.openDecisions = @()
    Set-Registry $testRoot $registry
} "Open decision 'ARCH-OPEN-001' has no primary system coverage"

Invoke-MutationCase 'duplicate open-decision coverage' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $system = @($registry.systems | Where-Object { $_.id -eq 'runtime-architecture' })[0]
    $system.openDecisions = @($system.openDecisions) + 'ARCH-OPEN-001'
    Set-Registry $testRoot $registry
} "Open decision 'ARCH-OPEN-001' has duplicate primary system coverage"

Invoke-MutationCase 'spelling-only source edit has no Journal impact' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/foundations/PROJECT_VISION.md'
    [IO.File]::AppendAllText($path, "`n<!-- spelling-only editorial note -->`n", $utf8)
} 'unused' -ExpectSuccess

Invoke-MutationCase 'hand-edited generated page drift' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/project-journal/README.md'
    [IO.File]::AppendAllText($path, "`nHand edit.`n", $utf8)
} 'stale or hand-edited'

Invoke-MutationCase 'historical post missing snapshot metadata' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/project-journal/posts/2026-08-29-WORLD_GENERATION_FOUNDATION.md'
    $text = [IO.File]::ReadAllText($path) -replace '(?m)^snapshot_date:.*\r?\n', ''
    [IO.File]::WriteAllText($path, $text, $utf8)
} "missing 'snapshot_date'"

Invoke-MutationCase 'historical post missing banner' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/project-journal/posts/2026-08-29-WORLD_GENERATION_FOUNDATION.md'
    $text = [IO.File]::ReadAllText($path).Replace('> **Historical snapshot', '> Snapshot')
    [IO.File]::WriteAllText($path, $text, $utf8)
} 'missing its dated visible historical-snapshot banner'

Invoke-MutationCase 'historical post missing current link' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/project-journal/posts/2026-08-29-WORLD_GENERATION_FOUNDATION.md'
    $text = [IO.File]::ReadAllText($path).Replace('../WORLD_GENERATION_STATUS.md', '../README.md')
    [IO.File]::WriteAllText($path, $text, $utf8)
} 'does not link to the current world-generation status'

Invoke-MutationCase 'journal entry prohibited as authority' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].authorities[0] = 'JOURNAL-HOME'
    Set-Registry $testRoot $registry
} 'uses journal entry .* as authority, which is prohibited'

Invoke-MutationCase 'authority-side knowledge evidence mutation' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/foundations/PROJECT_VISION.md'
    [IO.File]::WriteAllText($path, ([IO.File]::ReadAllText($path).Replace('status: accepted', 'status: draft')), $utf8)
} "knowledge evidence .* expected 'accepted' but found 'draft'"

Invoke-MutationCase 'registry-side knowledge mutation' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    (@($registry.systems | Where-Object id -eq 'state-of-consequence'))[0].knowledgeState = 'recognized'
    Set-Registry $testRoot $registry
} 'knowledgeState .* disagrees with profile'

Invoke-MutationCase 'authority-side coverage evidence mutation' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/world-generation/BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md'
    [IO.File]::WriteAllText($path, ([IO.File]::ReadAllText($path).Replace('coverage: partial', 'coverage: exploratory')), $utf8)
} "coverage evidence .* expected 'partial' but found 'exploratory'"

Invoke-MutationCase 'registry-side coverage mutation' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    (@($registry.systems | Where-Object id -eq 'broad-solid-earth-geometry'))[0].coverage = 'exploratory'
    Set-Registry $testRoot $registry
} 'coverage .* disagrees with profile'

Invoke-MutationCase 'authority-side implementation evidence mutation' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/architecture/MAP_AND_SPATIAL_MODEL_PROTOTYPE.md'
    [IO.File]::WriteAllText($path, ([IO.File]::ReadAllText($path).Replace('implementation: not-started', 'implementation: partial')), $utf8)
} "implementation evidence .* expected 'not-started' but found 'partial'"

Invoke-MutationCase 'registry-side implementation mutation' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    (@($registry.systems | Where-Object id -eq 'map-and-spatial-model-prototype'))[0].implementationState = 'partial'
    Set-Registry $testRoot $registry
} 'implementationState .* disagrees with profile'

Invoke-MutationCase 'authority-side attention and milestone mutation' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/operations/CURRENT_STATE.md'
    [IO.File]::WriteAllText($path, ([IO.File]::ReadAllText($path).Replace('**Immediate milestone:**', '**Planned milestone:**')), $utf8)
} 'does not expose a parseable immediate milestone'

Invoke-MutationCase 'registry-side attention mutation' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    (@($registry.systems | Where-Object id -eq 'map-and-spatial-model-prototype'))[0].attention = 'later'
    Set-Registry $testRoot $registry
} 'attention .* disagrees with profile'

Invoke-MutationCase 'registry current-focus mutation' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.currentView.focus.label = 'Something else'
    Set-Registry $testRoot $registry
} 'current focus label disagrees'

Invoke-MutationCase 'registry current-milestone mutation' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.currentView.milestone.id = 'PROTO-999'
    Set-Registry $testRoot $registry
} 'current milestone disagrees'

Invoke-MutationCase 'governed review date is not hardcoded' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.currentView.reviewedOn = '2026-08-30'
    Set-Registry $testRoot $registry
    $current = Join-Path $testRoot 'docs/operations/CURRENT_STATE.md'
    [IO.File]::WriteAllText($current, ([IO.File]::ReadAllText($current).Replace('last_reviewed: 2026-08-29', 'last_reviewed: 2026-08-30').Replace('**Snapshot date:** 2026-08-29', '**Snapshot date:** 2026-08-30')), $utf8)
    $readme = Join-Path $testRoot 'README.md'
    [IO.File]::WriteAllText($readme, ([IO.File]::ReadAllText($readme).Replace('**Status reviewed:** 2026-08-29', '**Status reviewed:** 2026-08-30')), $utf8)
} 'unused' -ExpectSuccess -Rebuild

Invoke-MutationCase 'exploring lifecycle renders explicitly' {
    param($testRoot)
    $owner = Join-Path $testRoot 'docs/world-generation/SURFACE_PROCESSES_EXPLORATION.md'
    [IO.File]::WriteAllText($owner, "---`nid: WG-017-DRAFT`ntype: world-generation-exploration`nstatus: draft`nconcept_state: exploring`ncoverage: exploratory`nimplementation: not-investigated`n---`n`n# Surface Processes Exploration`n", $utf8)
    $indexPath = Join-Path $testRoot 'docs/world-generation/README.md'
    $index = [IO.File]::ReadAllText($indexPath).Replace('| `WG-017` | `recognized` |', '| `WG-017` | `exploring` |')
    $index = ([regex]::new('\| Not created \|')).Replace($index, '| [Surface Processes Exploration](SURFACE_PROCESSES_EXPLORATION.md) |', 1)
    [IO.File]::WriteAllText($indexPath, $index, $utf8)
    $registry = Get-Registry $testRoot
    $registry.sourceDocuments = @($registry.sourceDocuments) + [pscustomobject]@{ id='WG-017-DRAFT'; path='docs/world-generation/SURFACE_PROCESSES_EXPLORATION.md'; fingerprint=$true }
    $system = (@($registry.systems | Where-Object id -eq 'surface-natural-systems'))[0]
    $system.documents = @($system.documents) + 'WG-017-DRAFT'; $system.knowledgeState = 'exploring'
    $registry.systemEvidence.'surface-natural-systems'.profile = 'surface-exploring'
    $registry.systemEvidence.'surface-natural-systems'.knowledge[0].equals = 'exploring'
    Set-Registry $testRoot $registry
} 'unused' -ExpectSuccess -Rebuild

Invoke-MutationCase 'proposed lifecycle renders explicitly' {
    param($testRoot)
    $owner = Join-Path $testRoot 'docs/world-generation/SURFACE_PROCESSES_PROPOSAL.md'
    [IO.File]::WriteAllText($owner, "---`nid: WG-017-PROPOSAL`ntype: world-generation-proposal`nstatus: proposed`nconcept_state: proposed`ncoverage: exploratory`nimplementation: not-investigated`n---`n`n# Surface Processes Proposal`n", $utf8)
    $indexPath = Join-Path $testRoot 'docs/world-generation/README.md'
    $index = [IO.File]::ReadAllText($indexPath).Replace('| `WG-017` | `recognized` |', '| `WG-017` | `proposed` |')
    $index = ([regex]::new('\| Not created \|')).Replace($index, '| [Surface Processes Proposal](SURFACE_PROCESSES_PROPOSAL.md) |', 1)
    [IO.File]::WriteAllText($indexPath, $index, $utf8)
    $registry = Get-Registry $testRoot
    $registry.sourceDocuments = @($registry.sourceDocuments) + [pscustomobject]@{ id='WG-017-PROPOSAL'; path='docs/world-generation/SURFACE_PROCESSES_PROPOSAL.md'; fingerprint=$true }
    $system = (@($registry.systems | Where-Object id -eq 'surface-natural-systems'))[0]
    $system.documents = @($system.documents) + 'WG-017-PROPOSAL'; $system.knowledgeState = 'proposed'
    $registry.systemEvidence.'surface-natural-systems'.profile = 'surface-proposed'
    $registry.systemEvidence.'surface-natural-systems'.knowledge[0].equals = 'proposed'
    Set-Registry $testRoot $registry
} 'unused' -ExpectSuccess -Rebuild

Invoke-MutationCase 'accepted lifecycle progression remains covered' {
    param($testRoot)
    $owner = Join-Path $testRoot 'docs/world-generation/SURFACE_PROCESSES.md'
    [IO.File]::WriteAllText($owner, "---`nid: WG-017`ntype: world-generation-specification`nstatus: accepted`nconcept_state: accepted`ncoverage: partial`nimplementation: unresolved`n---`n`n# Surface Processes`n", $utf8)
    $indexPath = Join-Path $testRoot 'docs/world-generation/README.md'
    $index = [IO.File]::ReadAllText($indexPath)
    $row = [regex]::Match($index, '(?m)^\| `WG-017` .*\r?\n').Value
    $index = $index.Replace($row, '').Replace('## Recognized exploration topics', "| ``WG-017`` | Surface processes transform inherited geometry. | [Surface Processes](SURFACE_PROCESSES.md) | Unresolved |`n`n## Recognized exploration topics")
    [IO.File]::WriteAllText($indexPath, $index, $utf8)
    $registry = Get-Registry $testRoot
    $registry.sourceDocuments = @($registry.sourceDocuments) + [pscustomobject]@{ id='WG-017'; path='docs/world-generation/SURFACE_PROCESSES.md'; fingerprint=$true }
    $system = (@($registry.systems | Where-Object id -eq 'surface-natural-systems'))[0]
    $system.documents = @($system.documents) + 'WG-017'; $system.knowledgeState = 'partially-accepted'; $system.coverage = 'partial'; $system.implementationState = 'unresolved'
    $registry.systemEvidence.'surface-natural-systems'.profile = 'surface-partially-accepted'
    $registry.systemEvidence.'surface-natural-systems'.knowledge[0].equals = 'partially-accepted'
    $registry.systemEvidence.'surface-natural-systems'.coverage[0].equals = 'partial'
    $registry.systemEvidence.'surface-natural-systems'.implementation[0].equals = 'unresolved'
    Set-Registry $testRoot $registry
} 'unused' -ExpectSuccess -Rebuild

Invoke-MutationCase 'superseded lifecycle exits current coverage explicitly' {
    param($testRoot)
    $indexPath = Join-Path $testRoot 'docs/world-generation/README.md'
    $index = [IO.File]::ReadAllText($indexPath).Replace('| `WG-017` | `recognized` |', '| `WG-017` | `superseded` |')
    $index = ([regex]::new('\| Not created \|')).Replace($index, '| Replaced by `WG-001` |', 1)
    [IO.File]::WriteAllText($indexPath, $index, $utf8)
    $registry = Get-Registry $testRoot
    $system = (@($registry.systems | Where-Object id -eq 'surface-natural-systems'))[0]
    $system.worldGenerationConcepts = @($system.worldGenerationConcepts | Where-Object { $_ -ne 'WG-017' })
    Set-Registry $testRoot $registry
} 'unused' -ExpectSuccess -Rebuild

Invoke-MutationCase 'superseded concept cannot remain hidden in coverage' {
    param($testRoot)
    $indexPath = Join-Path $testRoot 'docs/world-generation/README.md'
    $index = [IO.File]::ReadAllText($indexPath).Replace('| `WG-017` | `recognized` |', '| `WG-017` | `superseded` |')
    $index = ([regex]::new('\| Not created \|')).Replace($index, '| Replaced by `WG-001` |', 1)
    [IO.File]::WriteAllText($indexPath, $index, $utf8)
} "covers superseded world-generation concept 'WG-017'"

Invoke-MutationCase 'semantic decision placement rejects exact-once wrong owner' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $geo = (@($registry.systems | Where-Object id -eq 'geological-history-and-material'))[0]
    $canonical = (@($registry.systems | Where-Object id -eq 'canonical-geological-world'))[0]
    $geo.openDecisions = @($geo.openDecisions | Where-Object { $_ -ne 'ARCH-OPEN-005' })
    $canonical.openDecisions = @($canonical.openDecisions) + 'ARCH-OPEN-005'
    Set-Registry $testRoot $registry
} "semantic association requires 'geological-history-and-material'"

Invoke-MutationCase 'prototype geology relation remains nonblocking' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $prototype = (@($registry.systems | Where-Object id -eq 'map-and-spatial-model-prototype'))[0]
    (@($prototype.relationships | Where-Object target -eq 'canonical-geological-world'))[0].type = 'depends-on'
    Set-Registry $testRoot $registry
} "must have exactly one 'constrained-by' relationship"

Invoke-MutationCase 'support operational claim requires authority evidence' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/README.md'
    [IO.File]::WriteAllText($path, ([IO.File]::ReadAllText($path).Replace('./scripts/check-docs.ps1', './scripts/removed-check.ps1')), $utf8)
} "implementation evidence .* expected './scripts/check-docs.ps1'"

Invoke-MutationCase 'second historical post has independent metadata' {
    param($testRoot)
    $source = Join-Path $testRoot 'docs/project-journal/posts/2026-08-29-WORLD_GENERATION_FOUNDATION.md'
    $target = Join-Path $testRoot 'docs/project-journal/posts/2026-08-30-SECOND_SNAPSHOT.md'
    $text = [IO.File]::ReadAllText($source).Replace('JOURNAL-POST-20260829-WORLD-GENERATION-FOUNDATION', 'JOURNAL-POST-20260830-SECOND-SNAPSHOT').Replace('2026-08-29', '2026-08-30').Replace('e877daf2c00fe18227933ee1357f4333009d6b95', '1111111111111111111111111111111111111111')
    [IO.File]::WriteAllText($target, $text, $utf8)
    $registry = Get-Registry $testRoot
    $registry.historicalPosts = @($registry.historicalPosts) + 'docs/project-journal/posts/2026-08-30-SECOND_SNAPSHOT.md'
    Set-Registry $testRoot $registry
} 'unused' -ExpectSuccess -Rebuild

Invoke-MutationCase 'CRLF historical post generates a clean title link' {
    param($testRoot)
    $postPath = Join-Path $testRoot 'docs/project-journal/posts/2026-08-29-WORLD_GENERATION_FOUNDATION.md'
    $postText = [IO.File]::ReadAllText($postPath).Replace("`r`n", "`n").Replace("`n", "`r`n")
    [IO.File]::WriteAllText($postPath, $postText, $utf8)
    $generated = Invoke-Generator $testRoot
    if ($generated.ExitCode -ne 0) { throw "CRLF historical-post fixture could not rebuild Markdown.`n$($generated.Output)" }
    $generatedHomeText = [IO.File]::ReadAllText((Join-Path $testRoot 'docs/project-journal/README.md'))
    $expectedLink = '- [World Generation Has a Foundation, Not Yet a Generator](posts/2026-08-29-WORLD_GENERATION_FOUNDATION.md) — snapshot 2026-08-29'
    if (-not $generatedHomeText.Contains($expectedLink)) { throw 'CRLF historical-post fixture did not preserve a valid title link.' }
    if ($generatedHomeText.Contains("`r")) { throw 'CRLF historical-post fixture emitted a bare carriage return in the generated home.' }
} 'unused' -ExpectSuccess

Invoke-SemanticStalenessCase 'system inventory impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems = @($registry.systems) + [pscustomobject]@{
        id='test-support-system'; name='Test support system'; purpose='Exercise complete system inventory freshness.'; kind='support'; parent='state-of-consequence'
        knowledgeState='operational'; coverage='complete-at-scope'; implementationState='operational'; attention='supporting'
        authorities=@('DOCS-001'); documents=@(); worldGenerationConcepts=@(); openDecisions=@(); relationships=@()
    }
    $registry.systemEvidence | Add-Member -NotePropertyName 'test-support-system' -NotePropertyValue ([pscustomobject]@{
        profile='support-operational'
        knowledge=@([pscustomobject]@{source='DOCS-001';field='front.status';equals='accepted'})
        coverage=@([pscustomobject]@{source='SYSTEMS.json';field='profile.coverage';equals='complete-at-scope'})
        implementation=@([pscustomobject]@{source='scripts/build-project-journal.ps1';field='path.exists';equals='true'})
        attention=@([pscustomobject]@{source='SYSTEMS.json';field='profile.attention';equals='supporting'})
    })
    Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system name impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot; $registry.systems[0].name = 'State of Consequence project'; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system purpose impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot; $registry.systems[0].purpose += ' It also proves semantic freshness.'; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system kind impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot; (@($registry.systems | Where-Object id -eq 'player-map-experience'))[0].kind = 'support'; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system parent impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot; (@($registry.systems | Where-Object id -eq 'optional-web3-layer'))[0].parent = 'living-nation-simulation'; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system authority impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot; $registry.systems[0].authorities = @($registry.systems[0].authorities) + 'DOCS-001'; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'document coverage impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.systems[0].documents = @($registry.systems[0].documents | Where-Object { $_ -ne 'BRAND-001' })
    $target = (@($registry.systems | Where-Object id -eq 'optional-web3-layer'))[0]
    $target.documents = @($target.documents) + 'BRAND-001'
    Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'concept coverage assignment impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $from = (@($registry.systems | Where-Object id -eq 'canonical-geological-world'))[0]
    $to = (@($registry.systems | Where-Object id -eq 'runtime-architecture'))[0]
    $from.worldGenerationConcepts = @($from.worldGenerationConcepts | Where-Object { $_ -ne 'WG-015' })
    $to.worldGenerationConcepts = @($to.worldGenerationConcepts) + 'WG-015'
    Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system knowledge-state impact' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/foundations/DESIGN_PRINCIPLES.md'
    [IO.File]::WriteAllText($path, ([IO.File]::ReadAllText($path).Replace('status: accepted', 'status: proposed')), $utf8)
    $registry = Get-Registry $testRoot
    $registry.statusProfiles | Add-Member -NotePropertyName 'player-proposed-test' -NotePropertyValue ([pscustomobject]@{knowledge='proposed';coverage='partial';implementation='not-started';attention='supporting'})
    $system = (@($registry.systems | Where-Object id -eq 'player-map-experience'))[0]; $system.knowledgeState='proposed'
    $declaration = $registry.systemEvidence.'player-map-experience'; $declaration.profile='player-proposed-test'; $declaration.knowledge[0].equals='proposed'
    Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system coverage-state impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.statusProfiles | Add-Member -NotePropertyName 'state-exploratory-test' -NotePropertyValue ([pscustomobject]@{knowledge='accepted';coverage='exploratory';implementation='not-started';attention='supporting'})
    $registry.systems[0].coverage='exploratory'; $registry.systemEvidence.'state-of-consequence'.profile='state-exploratory-test'; $registry.systemEvidence.'state-of-consequence'.coverage[0].equals='exploratory'
    Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system implementation-state impact' {
    param($testRoot)
    $path = Join-Path $testRoot 'docs/architecture/ARCHITECTURE_OVERVIEW.md'
    [IO.File]::WriteAllText($path, ([IO.File]::ReadAllText($path).Replace('implementation: partial', 'implementation: not-investigated')), $utf8)
    $registry = Get-Registry $testRoot
    $registry.statusProfiles | Add-Member -NotePropertyName 'runtime-investigating-test' -NotePropertyValue ([pscustomobject]@{knowledge='accepted';coverage='partial';implementation='not-investigated';attention='supporting'})
    $system = (@($registry.systems | Where-Object id -eq 'runtime-architecture'))[0]; $system.implementationState='not-investigated'
    $declaration = $registry.systemEvidence.'runtime-architecture'; $declaration.profile='runtime-investigating-test'; $declaration.implementation[0].equals='not-investigated'
    Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system attention impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $registry.statusProfiles | Add-Member -NotePropertyName 'state-next-test' -NotePropertyValue ([pscustomobject]@{knowledge='accepted';coverage='partial';implementation='not-started';attention='next'})
    $registry.systems[0].attention='next'; $registry.systemEvidence.'state-of-consequence'.profile='state-next-test'; $registry.systemEvidence.'state-of-consequence'.attention[0].equals='next'
    Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system relationship impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot; $registry.systems[0].relationships = @([pscustomobject]@{type='supports';target='player-map-experience'}); Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'system open-decision association impact' {
    param($testRoot)
    $registry = Get-Registry $testRoot
    $from = (@($registry.systems | Where-Object id -eq 'living-nation-simulation'))[0]
    $from.openDecisions = @($from.openDecisions | Where-Object { $_ -ne 'ARCH-OPEN-015' })
    $registry.systems[0].openDecisions = @($registry.systems[0].openDecisions) + 'ARCH-OPEN-015'
    $registry.decisionAssociations.'ARCH-OPEN-015'.system = 'state-of-consequence'
    Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'concept inventory impact' {
    param($testRoot)
    $indexPath = Join-Path $testRoot 'docs/world-generation/README.md'
    $index = [IO.File]::ReadAllText($indexPath).Replace('| `WG-024` |', '| `WG-026` | `recognized` | What additional surface process must be represented? | Not created |' + "`n" + '| `WG-024` |')
    [IO.File]::WriteAllText($indexPath, $index, $utf8)
    $registry = Get-Registry $testRoot; $surface = (@($registry.systems | Where-Object id -eq 'surface-natural-systems'))[0]; $surface.worldGenerationConcepts = @($surface.worldGenerationConcepts) + 'WG-026'; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'concept lifecycle impact' {
    param($testRoot)
    $owner = Join-Path $testRoot 'docs/world-generation/SURFACE_PROCESSES_EXPLORATION.md'
    [IO.File]::WriteAllText($owner, "---`nid: WG-017-DRAFT`ntype: world-generation-exploration`nstatus: draft`nconcept_state: exploring`ncoverage: exploratory`nimplementation: not-investigated`nlast_reviewed: 2026-08-29`nscope: Test exploration`nauthority: Test owner`n---`n`n# Surface Processes Exploration`n", $utf8)
    $indexPath = Join-Path $testRoot 'docs/world-generation/README.md'; $index = [IO.File]::ReadAllText($indexPath).Replace('| `WG-017` | `recognized` |', '| `WG-017` | `exploring` |'); $index = ([regex]::new('\| Not created \|')).Replace($index, '| [Surface Processes Exploration](SURFACE_PROCESSES_EXPLORATION.md) |', 1); [IO.File]::WriteAllText($indexPath, $index, $utf8)
    $registry = Get-Registry $testRoot; $registry.sourceDocuments = @($registry.sourceDocuments) + [pscustomobject]@{id='WG-017-DRAFT';path='docs/world-generation/SURFACE_PROCESSES_EXPLORATION.md';fingerprint=$true}; $system=(@($registry.systems|Where-Object id -eq 'surface-natural-systems'))[0]; $system.documents=@($system.documents)+'WG-017-DRAFT'; $system.knowledgeState='exploring'; $registry.systemEvidence.'surface-natural-systems'.profile='surface-exploring'; $registry.systemEvidence.'surface-natural-systems'.knowledge[0].equals='exploring'; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'concept truth impact' {
    param($testRoot)
    $path=Join-Path $testRoot 'docs/world-generation/README.md'; [IO.File]::WriteAllText($path,([IO.File]::ReadAllText($path).Replace('Compatible worlds share one versioned Earth-like physical ruleset','Compatible worlds share one governed Earth-like physical ruleset')),$utf8)
}

Invoke-SemanticStalenessCase 'concept owner impact' {
    param($testRoot)
    $path=Join-Path $testRoot 'docs/world-generation/README.md'; $text=[IO.File]::ReadAllText($path).Replace('[Earth-Like Physical Framework](EARTH_LIKE_PHYSICAL_FRAMEWORK.md)','[Earth-Like Planetary Contract](EARTH_LIKE_PLANETARY_CONTRACT.md)'); [IO.File]::WriteAllText($path,$text,$utf8)
}

Invoke-SemanticStalenessCase 'concept coverage-value impact' {
    param($testRoot)
    $path=Join-Path $testRoot 'docs/world-generation/BROAD_ELEVATION_AND_ISOSTATIC_RESPONSE.md'; [IO.File]::WriteAllText($path,([IO.File]::ReadAllText($path).Replace('coverage: partial','coverage: complete-at-scope')),$utf8)
    $registry=Get-Registry $testRoot; $registry.statusProfiles | Add-Member -NotePropertyName 'broad-complete-test' -NotePropertyValue ([pscustomobject]@{knowledge='accepted';coverage='complete-at-scope';implementation='unresolved';attention='supporting'}); $system=(@($registry.systems|Where-Object id -eq 'broad-solid-earth-geometry'))[0]; $system.coverage='complete-at-scope'; $declaration=$registry.systemEvidence.'broad-solid-earth-geometry'; $declaration.profile='broad-complete-test'; $declaration.coverage[0].equals='complete-at-scope'; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'concept implementation impact' {
    param($testRoot)
    $path=Join-Path $testRoot 'docs/world-generation/README.md'; $text=[IO.File]::ReadAllText($path); $text=[regex]::Replace($text,'(?m)^(\| `WG-016` .*? \| )Not started( \|)\r?$','$1Unresolved$2'); [IO.File]::WriteAllText($path,$text,$utf8)
}

Invoke-SemanticStalenessCase 'open-decision inventory impact' {
    param($testRoot)
    $path=Join-Path $testRoot 'docs/architecture/OPEN_DECISIONS.md'; [IO.File]::AppendAllText($path,"`n## ARCH-OPEN-020 — Test decision inventory`n`nTest-only unresolved question.`n",$utf8)
    $registry=Get-Registry $testRoot; $registry.systems[0].openDecisions=@($registry.systems[0].openDecisions)+'ARCH-OPEN-020'; $registry.decisionAssociations | Add-Member -NotePropertyName 'ARCH-OPEN-020' -NotePropertyValue ([pscustomobject]@{system='state-of-consequence';evidence=@('VISION-001')}); Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'open-decision title impact' {
    param($testRoot)
    $path=Join-Path $testRoot 'docs/architecture/OPEN_DECISIONS.md'; [IO.File]::WriteAllText($path,([IO.File]::ReadAllText($path).Replace('ARCH-OPEN-001 — Spatial foundations','ARCH-OPEN-001 — Spatial foundation contract')),$utf8)
}

Invoke-SemanticStalenessCase 'current review-date impact' {
    param($testRoot)
    $registry=Get-Registry $testRoot; $registry.currentView.reviewedOn='2026-08-31'; Set-Registry $testRoot $registry
    $path=Join-Path $testRoot 'docs/operations/CURRENT_STATE.md'; [IO.File]::WriteAllText($path,([IO.File]::ReadAllText($path).Replace('last_reviewed: 2026-08-30','last_reviewed: 2026-08-31').Replace('**Snapshot date:** 2026-08-30','**Snapshot date:** 2026-08-31')),$utf8)
    $path=Join-Path $testRoot 'README.md'; [IO.File]::WriteAllText($path,([IO.File]::ReadAllText($path).Replace('**Status reviewed:** 2026-08-30','**Status reviewed:** 2026-08-31')),$utf8)
}

Invoke-SemanticStalenessCase 'current focus impact' {
    param($testRoot)
    $old='**Active phase:** Natural-world foundation (`0.0.1`–`0.1.0`)'; $new='**Active phase:** Physical-world foundation (`0.0.1`–`0.1.0`)'
    $path=Join-Path $testRoot 'docs/operations/CURRENT_STATE.md'; [IO.File]::WriteAllText($path,([IO.File]::ReadAllText($path).Replace($old,$new)),$utf8)
    $registry=Get-Registry $testRoot; $registry.currentView.focus.label='Physical-world foundation and the map and spatial model prototype'; $registry.currentView.focus.evidence[0].equals=$new; $registry.systemEvidence.'natural-world-foundation'.attention[0].equals=$new; $registry.systemEvidence.'world-generation'.attention[0].equals=$new; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'current milestone impact' {
    param($testRoot)
    $old='**Immediate milestone:** `PROTO-001` — map and spatial model prototype'; $new='**Immediate milestone:** `ARCH-001` — architecture overview'
    $path=Join-Path $testRoot 'docs/operations/CURRENT_STATE.md'; [IO.File]::WriteAllText($path,([IO.File]::ReadAllText($path).Replace($old,$new)),$utf8)
    $registry=Get-Registry $testRoot; $registry.currentView.milestone.id='ARCH-001'; $registry.currentView.milestone.name='architecture overview'; $registry.currentView.milestone.evidence[0].equals=$new; $registry.currentView.milestone.evidence[1].source='ARCH-001'; $registry.currentView.milestone.evidence[1].equals='partial'; $registry.currentView.focus.label='Natural-world foundation and the architecture overview'; $registry.currentView.focus.evidence[1].equals=$new; $registry.systemEvidence.'map-and-spatial-model-prototype'.attention[0].equals=$new; Set-Registry $testRoot $registry
}

Invoke-SemanticStalenessCase 'runtime artifact impact' {
    param($testRoot)
    [IO.File]::WriteAllText((Join-Path $testRoot 'src/runtime_evidence_test.rs'),"// Temporary runtime-fingerprint fixture.`n",$utf8)
}

Invoke-MutationCase 'target build outputs are ignored as runtime evidence' {
    param($testRoot)
    $directory = Join-Path $testRoot 'target/debug/build/dependency/out'
    $null = New-Item -ItemType Directory -Path $directory -Force
    [IO.File]::WriteAllText((Join-Path $directory 'generated.rs'),"// Ignored Cargo build output.`n",$utf8)
} 'unused' -ExpectSuccess

Invoke-SemanticStalenessCase 'historical account impact' {
    param($testRoot)
    $path=Join-Path $testRoot 'docs/project-journal/posts/2026-08-29-WORLD_GENERATION_FOUNDATION.md'; [IO.File]::AppendAllText($path,"`nHistorical clarification represented by the Journal.`n",$utf8)
}

$siteTestRoot = New-TestRoot
try {
    $siteBaseline = Invoke-SiteCheck $siteTestRoot
    if ($siteBaseline.ExitCode -ne 0) { throw "Site-staleness fixture baseline is not current.`n$($siteBaseline.Output)" }
    $registry = Get-Registry $siteTestRoot
    $system = (@($registry.systems | Where-Object id -eq 'state-of-consequence'))[0]
    $system.purpose = $system.purpose + ' Mutation proving site freshness.'
    Set-Registry $siteTestRoot $registry
    $generated = Invoke-Generator $siteTestRoot
    if ($generated.ExitCode -ne 0) { throw "Site-staleness fixture could not rebuild Markdown.`n$($generated.Output)" }
    $siteDataPath = Join-Path $siteTestRoot 'project-journal-site/app/generated-journal.ts'
    $beforeCheck = [IO.File]::ReadAllText($siteDataPath)
    $docsResult = Invoke-DocsCheck $siteTestRoot
    $afterCheck = [IO.File]::ReadAllText($siteDataPath)
    if ($docsResult.ExitCode -eq 0 -or $docsResult.Output -notmatch '(?s)Project Journal website check failed:.*Website Journal data is stale') {
        throw "A Journal-impacting registry change did not make check-docs reject stale website data.`n$($docsResult.Output)"
    }
    if ($beforeCheck -ne $afterCheck) {
        throw 'The documentation validator wrote website data while checking freshness.'
    }
    $checksPassed++
} finally {
    Remove-TestRoot $siteTestRoot
}

if ($checksPassed -ne $expectedChecks) { throw "Project Journal tests executed $checksPassed checks; expected $expectedChecks." }
Write-Host "Project Journal tests passed: $checksPassed/$expectedChecks." -ForegroundColor Green
exit 0
