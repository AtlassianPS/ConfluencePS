$script:_CachedIntegrationEnv = $null
$script:_EnvLoaded = $false

function Read-DotEnvFile {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Loading .env into process-scoped environment variables is intentional and idempotent')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_
        if ($line -match '^\s*#' -or $line -match '^\s*$') {
            return
        }
        if ($line -notmatch '^\s*([^#=]+?)\s*=\s*(.*)$') {
            return
        }

        $name = $matches[1].Trim()
        if ([string]::IsNullOrEmpty($name)) {
            return
        }

        $rawValue = $matches[2].TrimStart()

        if ($rawValue.Length -gt 0 -and ($rawValue[0] -eq '"' -or $rawValue[0] -eq "'")) {
            $quote = $rawValue[0]
            $endIdx = $rawValue.IndexOf($quote, 1)
            $value = if ($endIdx -gt 0) {
                $rawValue.Substring(1, $endIdx - 1)
            }
            else {
                $rawValue.Substring(1)
            }
        }
        else {
            if ($rawValue -match '^(.*?)\s+#') {
                $value = $matches[1]
            }
            else {
                $value = $rawValue
            }
            $value = $value.TrimEnd()
        }

        [System.Environment]::SetEnvironmentVariable($name, $value)
    }
}

function Get-ConfluenceIntegrationDeploymentType {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $deploymentType = if ($env:CI_CONFLUENCE_TYPE) { $env:CI_CONFLUENCE_TYPE } else { 'Cloud' }
    if ($deploymentType -notin @('Cloud', 'DataCenter')) {
        throw "Invalid CI_CONFLUENCE_TYPE '$deploymentType'. Must be 'Cloud' or 'DataCenter'."
    }
    return $deploymentType
}

function Get-ConfluenceIntegrationRequiredVariables {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Cloud', 'DataCenter')]
        [string]$DeploymentType
    )

    if ($DeploymentType -eq 'DataCenter') {
        return @(
            'CI_CONFLUENCE_URL'
            'CI_CONFLUENCE_USER'
            'CI_CONFLUENCE_PASSWORD'
        )
    }

    return @(
        'CONFLUENCE_CLOUD_URL'
        'ATLASSIAN_CLOUD_USER'
        'ATLASSIAN_CLOUD_PAT'
    )
}

function Initialize-IntegrationEnvironment {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Process-wide warn-once guard shared across dot-sourced integration files')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if ($script:_EnvLoaded) {
        return $script:_CachedIntegrationEnv
    }

    $projectRoot = if (-not [string]::IsNullOrWhiteSpace($env:BHProjectPath)) {
        $env:BHProjectPath
    }
    else {
        (Get-Location).Path
    }
    $envFile = Join-Path $projectRoot '.env'
    if (Test-Path $envFile) {
        Read-DotEnvFile -Path $envFile
    }

    $deploymentType = Get-ConfluenceIntegrationDeploymentType
    $requiredVars = Get-ConfluenceIntegrationRequiredVariables -DeploymentType $deploymentType

    $missing = @()
    foreach ($var in $requiredVars) {
        if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($var))) {
            $missing += $var
        }
    }

    if ($missing.Count -gt 0) {
        if (-not $global:_ConfluencePSIntegrationEnvWarned) {
            Write-Warning "Integration tests ($deploymentType track) require the following environment variables: $($missing -join ', ')"
            if ($deploymentType -eq 'DataCenter') {
                Write-Warning "Set CI_CONFLUENCE_TYPE=DataCenter and CI_CONFLUENCE_* variables. See .env.example."
            }
            else {
                Write-Warning "Copy .env.example to .env and configure your Confluence Cloud connection."
            }
            $global:_ConfluencePSIntegrationEnvWarned = $true
        }

        $script:_EnvLoaded = $true
        $script:_CachedIntegrationEnv = $null
        return $null
    }

    if ($deploymentType -eq 'DataCenter') {
        $result = [PSCustomObject]@{
            DeploymentType = 'DataCenter'
            IsCloud        = $false
            CloudUrl       = $env:CI_CONFLUENCE_URL.TrimEnd('/')
            Username       = $env:CI_CONFLUENCE_USER
            Password       = $env:CI_CONFLUENCE_PASSWORD
        }
    }
    else {
        $result = [PSCustomObject]@{
            DeploymentType = 'Cloud'
            IsCloud        = $true
            CloudUrl       = $env:CONFLUENCE_CLOUD_URL.TrimEnd('/')
            Username       = $env:ATLASSIAN_CLOUD_USER
            Password       = $env:ATLASSIAN_CLOUD_PAT
        }
    }

    $script:_EnvLoaded = $true
    $script:_CachedIntegrationEnv = $result
    return $result
}
