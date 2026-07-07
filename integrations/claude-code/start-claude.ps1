[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("deepseek", "mimo")]
    [string] $Provider,

    [Parameter(Mandatory)]
    [string] $WorkingDirectory,

    [Parameter(ValueFromRemainingArguments)]
    [string[]] $ClaudeArguments
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) {
    throw "工作目录不存在：$WorkingDirectory"
}

$managedVariables = @(
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_AUTH_TOKEN",
    "ANTHROPIC_BASE_URL",
    "ANTHROPIC_MODEL",
    "ANTHROPIC_DEFAULT_OPUS_MODEL",
    "ANTHROPIC_DEFAULT_SONNET_MODEL",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL",
    "CLAUDE_CODE_SUBAGENT_MODEL",
    "CLAUDE_CODE_EFFORT_LEVEL",
    "CLAUDE_CODE_OAUTH_TOKEN",
    "CLAUDE_CODE_USE_BEDROCK",
    "CLAUDE_CODE_USE_VERTEX",
    "CLAUDE_CODE_USE_FOUNDRY"
)

$originalEnvironment = @{}

foreach ($name in $managedVariables) {
    $originalEnvironment[$name] =
        [Environment]::GetEnvironmentVariable($name, "Process")

    [Environment]::SetEnvironmentVariable(
        $name,
        $null,
        "Process"
    )
}

try {
    switch ($Provider) {
        "deepseek" {
            $apiKey = [Environment]::GetEnvironmentVariable(
                "DEEPSEEK_API_KEY",
                "User"
            )

            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                throw "未找到用户级 DEEPSEEK_API_KEY"
            }

            $providerEnvironment = @{
                ANTHROPIC_BASE_URL             = "https://api.deepseek.com/anthropic"
                ANTHROPIC_AUTH_TOKEN           = $apiKey
                ANTHROPIC_MODEL                = "deepseek-v4-pro[1m]"
                ANTHROPIC_DEFAULT_OPUS_MODEL   = "deepseek-v4-pro[1m]"
                ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-pro[1m]"
                ANTHROPIC_DEFAULT_HAIKU_MODEL  = "deepseek-v4-flash"
                CLAUDE_CODE_SUBAGENT_MODEL     = "deepseek-v4-flash"
                CLAUDE_CODE_EFFORT_LEVEL       = "max"
            }
        }

        "mimo" {
            $apiKey = [Environment]::GetEnvironmentVariable(
                "MIMO_API_KEY",
                "User"
            )

            if ([string]::IsNullOrWhiteSpace($apiKey)) {
                throw "未找到用户级 MIMO_API_KEY"
            }

            $providerEnvironment = @{
                ANTHROPIC_BASE_URL             = "https://api.xiaomimimo.com/anthropic"
                ANTHROPIC_AUTH_TOKEN           = $apiKey
                ANTHROPIC_MODEL                = "mimo-v2.5-pro"
                ANTHROPIC_DEFAULT_OPUS_MODEL   = "mimo-v2.5-pro"
                ANTHROPIC_DEFAULT_SONNET_MODEL = "mimo-v2.5-pro"
                ANTHROPIC_DEFAULT_HAIKU_MODEL  = "mimo-v2.5-pro"
            }
        }
    }

    foreach ($entry in $providerEnvironment.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable(
            $entry.Key,
            $entry.Value,
            "Process"
        )
    }

    Push-Location -LiteralPath $WorkingDirectory

    try {
        $claudeCommand = Get-Command claude -ErrorAction SilentlyContinue

        if ($null -ne $claudeCommand) {
            $claudeExecutable = $claudeCommand.Source
        }
        else {
            $fallbackClaude = Join-Path $env:APPDATA "npm\claude.ps1"

            if (Test-Path -LiteralPath $fallbackClaude -PathType Leaf) {
                $claudeExecutable = $fallbackClaude
            }
            else {
                throw "未找到 Claude Code CLI。PATH 中无 claude，且 fallback 不存在：$fallbackClaude"
            }
        }

        & $claudeExecutable @ClaudeArguments
    }
    finally {
        Pop-Location
    }
}
finally {
    foreach ($name in $managedVariables) {
        [Environment]::SetEnvironmentVariable(
            $name,
            $originalEnvironment[$name],
            "Process"
        )
    }
}
