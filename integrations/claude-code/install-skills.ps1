[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$HarnessHome = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$SourceRoot  = Join-Path $HarnessHome "skills"
$TargetRoot  = Join-Path $HOME ".claude\skills"

$skillNames = @(
    "workflow-controller"
    "multi-agent-coordination"
    "brainstorming"
    "writing-plans"
    "reviewing-plans"
    "using-git-worktrees"
    "executing-plans"
    "subagent-driven-development"
    "test-driven-development"
    "systematic-debugging"
    "code-review"
    "receiving-code-review"
    "verification-before-completion"
    "finishing-a-development-branch"
    "writing-skills"
)

foreach ($name in $skillNames) {
    $source = Join-Path $SourceRoot $name

    if (-not (Test-Path (Join-Path $source "SKILL.md") -PathType Leaf)) {
        throw "Missing skill source: $source"
    }
}

New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null

$conflicts = @()
$toCreate  = @()
$skipped   = @()

foreach ($name in $skillNames) {
    $source = Join-Path $SourceRoot $name
    $target = Join-Path $TargetRoot $name
    $item   = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue

    if (-not $item) {
        $toCreate += [pscustomobject]@{
            Name   = $name
            Source = $source
            Target = $target
        }
        continue
    }

    $actualTarget = if ($item.Target) {
        [string]($item.Target | Select-Object -First 1)
    } else {
        $null
    }

    $expected = [System.IO.Path]::GetFullPath($source)
    $actual   = if ($actualTarget) {
        [System.IO.Path]::GetFullPath($actualTarget)
    } else {
        $null
    }

    if (
        $item.LinkType -in @("Junction", "SymbolicLink") -and
        $actual -eq $expected
    ) {
        $skipped += $name
    }
    else {
        $conflicts += $target
    }
}

if ($conflicts.Count -gt 0) {
    throw "Conflicting targets:`n$($conflicts -join "`n")"
}

$created = @()

foreach ($entry in $toCreate) {
    New-Item `
        -ItemType Junction `
        -Path $entry.Target `
        -Target $entry.Source |
        Out-Null

    $created += $entry.Name
}

[pscustomobject]@{
    Created = $created.Count
    Skipped = $skipped.Count
    Total   = $skillNames.Count
}

"`nCreated:"
$created

"`nSkipped:"
$skipped
