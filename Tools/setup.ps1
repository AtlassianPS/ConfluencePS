#requires -Module PowerShellGet

[CmdletBinding()]
param()

$psScriptAnalyzerSettingsPath = Join-Path (Join-Path $PSScriptRoot '..') 'PSScriptAnalyzerSettings.psd1'
function Sync-PSScriptAnalyzerSetting {
    [CmdletBinding()]
    param()

    if (-not (Test-Path $psScriptAnalyzerSettingsPath)) {
        throw "Missing pinned PSScriptAnalyzer settings file at '$psScriptAnalyzerSettingsPath'."
    }

    Write-Host "Using pinned PSScriptAnalyzer settings from '$psScriptAnalyzerSettingsPath'."
}

Write-Output "Installing PackageProvider NuGet"
$null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue

if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Write-Output "Registering PSGallery repository"
    Register-PSRepository -Default -ErrorAction SilentlyContinue
}

$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
    Write-Output "Setting PSGallery to Trusted"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

if ((Get-Module PowershellGet -ListAvailable)[0].Version -lt [version]"1.6.0") {
    Write-Output "Updating PowershellGet"
    Install-Module PowershellGet -Scope CurrentUser -Force
}

Sync-PSScriptAnalyzerSetting

Write-Output "Installing Dependencies"
Import-Module "$PSScriptRoot/BuildTools.psm1" -Force
Install-Dependency
