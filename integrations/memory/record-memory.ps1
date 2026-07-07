[CmdletBinding()]
param(
    [ValidateSet("global", "project")]
    [string]$Scope = "global",

    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [string]$Content,

    [string]$ContentFile,

    [ValidateSet("recorded", "promoted", "discarded")]
    [string]$Status = "recorded",

    [ValidateSet("manual", "auto")]
    [string]$Source = "manual",

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$HarnessHome = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if ([string]::IsNullOrWhiteSpace($Title)) {
    throw "Title is required."
}

if ([string]::IsNullOrWhiteSpace($Content) -and [string]::IsNullOrWhiteSpace($ContentFile)) {
    throw "Either -Content or -ContentFile is required."
}

if (-not [string]::IsNullOrWhiteSpace($Content) -and -not [string]::IsNullOrWhiteSpace($ContentFile)) {
    throw "Use either -Content or -ContentFile, not both."
}

if (-not [string]::IsNullOrWhiteSpace($ContentFile)) {
    if (-not (Test-Path -LiteralPath $ContentFile -PathType Leaf)) {
        throw "Content file not found: $ContentFile"
    }

    $memoryContent = Get-Content -LiteralPath $ContentFile -Raw
}
else {
    $memoryContent = $Content
}

if ([string]::IsNullOrWhiteSpace($memoryContent)) {
    throw "Memory content is empty."
}

switch ($Scope) {
    "global" {
        $target = Join-Path $HarnessHome "memory.md"
    }

    "project" {
        if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
            throw "ProjectPath is required when Scope is project."
        }

        $resolvedProject = [System.IO.Path]::GetFullPath($ProjectPath)
        $targetDir = Join-Path $resolvedProject ".harness"
        $target = Join-Path $targetDir "memory.md"
    }
}

$targetParent = Split-Path -Parent $target
New-Item -ItemType Directory -Path $targetParent -Force | Out-Null

if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    Set-Content -LiteralPath $target -Value "# Harness Memory`r`n" -Encoding UTF8
}

$date = Get-Date -Format "yyyy-MM-dd"
$titleText = $Title.Trim()
$contentText = $memoryContent.Trim()

$entry = @"

## $date — $titleText

$contentText

状态：$Status
"@

if ($DryRun) {
    [pscustomobject]@{
        Target = $target
        Scope  = $Scope
        Source = $Source
        Status = $Status
        Entry  = $entry
    }

    return
}

Add-Content -LiteralPath $target -Value $entry -Encoding UTF8

[pscustomobject]@{
    Target  = $target
    Scope   = $Scope
    Source  = $Source
    Status  = $Status
    Written = $true
}
