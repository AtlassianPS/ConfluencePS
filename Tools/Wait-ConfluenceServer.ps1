#requires -version 5.1

<#
.SYNOPSIS
    Waits for a Dockerized Confluence instance to become reachable for integration tests.

.DESCRIPTION
    Used by the Data Center integration workflow and StartConfluenceDocker task to
    poll the Confluence REST API until authenticated requests succeed.

    This script intentionally uses Invoke-RestMethod directly as test infrastructure
    that runs before any module command execution.

.PARAMETER Url
    Base URL for Confluence. Defaults to $env:WikiURI or http://localhost:1990/confluence.

.PARAMETER User
    Username for readiness probes. Defaults to $env:WikiUser or 'admin'.

.PARAMETER Password
    Password for readiness probes. Defaults to $env:WikiPass or 'admin'.

.PARAMETER TimeoutSeconds
    Maximum wait duration before failing. Defaults to 1500 seconds.

.PARAMETER PollIntervalSeconds
    Delay between probes. Defaults to 10 seconds.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test infrastructure script for disposable Docker instances only')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'Defaults match disposable atlas-run-standalone defaults in CI')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeRestMethod', '', Justification = 'Infrastructure readiness probe before test execution')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Operator-oriented CI diagnostics')]
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Url = $(if ($env:WikiURI) { $env:WikiURI } else { 'http://localhost:1990/confluence' }),

    [Parameter()]
    [string]$User = $(if ($env:WikiUser) { $env:WikiUser } else { 'admin' }),

    [Parameter()]
    [string]$Password = $(if ($env:WikiPass) { $env:WikiPass } else { 'admin' }),

    [Parameter()]
    [int]$TimeoutSeconds = 1500,

    [Parameter()]
    [int]$PollIntervalSeconds = 10
)

$ErrorActionPreference = 'Stop'

$baseUrl = $Url.TrimEnd('/')
$spaceApiUrl = "$baseUrl/rest/api/space?limit=1"

$pair = "${User}:${Password}"
$encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization       = "Basic $encoded"
    'X-Atlassian-Token' = 'no-check'
}

Write-Host "==> Waiting for Confluence at $spaceApiUrl (timeout: ${TimeoutSeconds}s, poll: ${PollIntervalSeconds}s)"

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$attempt = 0
$ready = $false

while ((Get-Date) -lt $deadline) {
    $attempt++
    try {
        $response = Invoke-RestMethod -Uri $spaceApiUrl -Method Get -Headers $headers -TimeoutSec 15
        if ($null -ne $response) {
            $ready = $true
            break
        }
    }
    catch {
        $remaining = [int][Math]::Max(0, ($deadline - (Get-Date)).TotalSeconds)
        Write-Host ("    attempt {0}: not ready yet ({1}); {2}s remaining" -f $attempt, $_.Exception.Message, $remaining)
    }

    Start-Sleep -Seconds $PollIntervalSeconds
}

if (-not $ready) {
    Write-Error "Confluence did not become reachable within ${TimeoutSeconds} seconds at $spaceApiUrl."
    exit 1
}

Write-Host "==> Confluence is reachable at $baseUrl"

if ($env:GITHUB_ENV) {
    Add-Content -Path $env:GITHUB_ENV -Value "WikiURI=$baseUrl"
    Add-Content -Path $env:GITHUB_ENV -Value "WikiUser=$User"
    Add-Content -Path $env:GITHUB_ENV -Value "WikiPass=$Password"
    Write-Host "==> Exported WikiURI/WikiUser/WikiPass to GITHUB_ENV"
}
