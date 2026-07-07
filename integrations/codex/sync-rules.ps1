[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$HarnessHome  = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$RulesFile    = Join-Path $HarnessHome "config\rules.md"
$GeneratedDir = Join-Path $HarnessHome "generated\codex"
$GeneratedFile = Join-Path $GeneratedDir "AGENTS.md"
$BackupDir    = Join-Path $HarnessHome "backups\codex"

$CodexHome = if ($env:CODEX_HOME) {
    $env:CODEX_HOME
} else {
    Join-Path $HOME ".codex"
}

$TargetFile = Join-Path $CodexHome "AGENTS.md"

if (-not (Test-Path $RulesFile -PathType Leaf)) {
    throw "规则真源不存在：$RulesFile"
}

if (-not (Test-Path $CodexHome -PathType Container)) {
    throw "Codex 用户目录不存在：$CodexHome"
}

New-Item -ItemType Directory -Path $GeneratedDir -Force | Out-Null

# 保持规则真源的字节内容不变。
Copy-Item -LiteralPath $RulesFile -Destination $GeneratedFile -Force

$changed = $true

if (Test-Path $TargetFile -PathType Leaf) {
    $generatedHash = (Get-FileHash $GeneratedFile -Algorithm SHA256).Hash
    $targetHash    = (Get-FileHash $TargetFile -Algorithm SHA256).Hash
    $changed       = $generatedHash -ne $targetHash

    if ($changed) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

        Copy-Item -LiteralPath $TargetFile `
            -Destination (Join-Path $BackupDir "AGENTS.$timestamp.md")
    }
}

if ($changed) {
    Copy-Item -LiteralPath $GeneratedFile -Destination $TargetFile -Force
    "Codex 规则已同步。"
} else {
    "Codex 规则无变化。"
}

"`n有效 Codex 目录：$CodexHome"

Get-FileHash $RulesFile, $GeneratedFile, $TargetFile -Algorithm SHA256 |
    Select-Object Path, Hash |
    Format-Table -AutoSize