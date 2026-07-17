[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Executor,

    [Parameter(Mandatory)]
    [string] $WorkingDirectory,

    [switch] $DryRun,

    [Parameter(ValueFromRemainingArguments)]
    [string[]] $CodexArguments
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) {
    throw "Working directory does not exist: $WorkingDirectory"
}

$HarnessHome = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ConfigPath  = Join-Path $HarnessHome "config\executors.yaml"

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "Executor configuration does not exist: $ConfigPath"
}

# executors.yaml is the single source of executor configuration. Its current
# flat structure is parsed here to avoid an extra YAML runtime dependency.
$configContent = [System.Collections.Generic.List[string]]::new()

foreach ($yamlLine in [System.IO.File]::ReadAllLines($ConfigPath)) {
    [void] $configContent.Add($yamlLine)
}

$startIndex = -1
$executorPattern = "^\s{2}$([regex]::Escape($Executor)):\s*$"

for ($index = 0; $index -lt $configContent.Count; $index++) {
    if ($configContent[$index] -match $executorPattern) {
        $startIndex = $index
        break
    }
}

if ($startIndex -lt 0) {
    throw "Unregistered executor: ${Executor}"
}

$properties = @{}

for ($index = $startIndex + 1; $index -lt $configContent.Count; $index++) {
    $line = $configContent[$index]

    if ($line -match "^\s{2}\S[^:]*:\s*$") {
        break
    }

    if ($line -match "^\s{4}(?<key>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?<value>.*?)\s*$") {
        $value = $matches.value.Trim()

        if (
            $value.Length -ge 2 -and
            (($value.StartsWith('"') -and $value.EndsWith('"')) -or
             ($value.StartsWith("'") -and $value.EndsWith("'")))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $properties[$matches.key] = $value
    }
}

foreach ($requiredProperty in @("host", "model")) {
    if ([string]::IsNullOrWhiteSpace($properties[$requiredProperty])) {
        throw "Executor '$Executor' is missing required configuration: $requiredProperty"
    }
}

if ($properties.host -ne "codex-cli") {
    throw "Executor '$Executor' has host '$($properties.host)' and cannot use the Codex launcher"
}

$codexCommand = Get-Command codex -ErrorAction SilentlyContinue

if ($null -ne $codexCommand) {
    $codexExecutable = $codexCommand.Source
}
else {
    $fallbackCodex = Join-Path $env:APPDATA "npm\codex.ps1"

    if (Test-Path -LiteralPath $fallbackCodex -PathType Leaf) {
        $codexExecutable = $fallbackCodex
    }
    else {
        throw "Codex CLI was not found in PATH and fallback does not exist: $fallbackCodex"
    }
}

$arguments = @(
    "--cd", $WorkingDirectory,
    "--model", $properties.model
)

$providerStatus = "default"

if (-not [string]::IsNullOrWhiteSpace($properties.provider)) {
    switch ($properties.provider) {
        "mimo" {
            # MiMo exposes an OpenAI Responses-compatible endpoint.
            $arguments += @(
                "--config", 'model_provider="mimo"',
                "--config", 'model_providers.mimo.name="MiMo"',
                "--config", 'model_providers.mimo.base_url="https://api.xiaomimimo.com/v1"',
                "--config", 'model_providers.mimo.env_key="MIMO_API_KEY"',
                "--config", 'model_providers.mimo.wire_api="responses"',
                "--config", 'web_search="disabled"',
                "--disable", "image_generation"
            )
            $providerStatus = "responses-compatible"
        }

        default {
            throw "Unsupported Codex provider: $($properties.provider)"
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($properties.reasoning_effort)) {
    $reasoningOverride = 'model_reasoning_effort="{0}"' -f $properties.reasoning_effort
    $arguments += @("--config", $reasoningOverride)
}

$arguments += $CodexArguments

if ($DryRun) {
    [pscustomobject]@{
        Executor        = $Executor
        Host            = $properties.host
        Model           = $properties.model
        ReasoningEffort = $properties.reasoning_effort
        ProviderStatus  = $providerStatus
        Executable      = $codexExecutable
        Arguments       = $arguments
    }

    return
}

& $codexExecutable @arguments
exit $LASTEXITCODE
