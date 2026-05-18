#requires -Module PowerShellGet

[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
param()

$psScriptAnalyzerSettingsPath = Join-Path (Join-Path $PSScriptRoot '..') 'PSScriptAnalyzerSettings.psd1'
function Sync-PSScriptAnalyzerSetting {
    [CmdletBinding()]
    param()

    Write-Host "Syncing PSScriptAnalyzer settings from AtlassianPS.Standards"

    try {
        Import-Module AtlassianPS.Standards -RequiredVersion '0.1.2' -Force -ErrorAction Stop
        $resolvedSettingsPath = Sync-AtlassianPSScriptAnalyzerSettings `
            -DestinationPath $psScriptAnalyzerSettingsPath `
            -ErrorAction Stop
        Write-Host "Shared PSScriptAnalyzer settings synchronized to '$resolvedSettingsPath'."
    }
    catch {
        throw "Unable to sync PSScriptAnalyzer settings from AtlassianPS.Standards. $($_.Exception.Message)"
    }
}

# PowerShell 5.1 and bellow need the PSGallery to be intialized
if (-not ($gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PackageProvider NuGet"
    $null = Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
}

# Make PSGallery trusted, to aviod a confirmation in the console
if (-not ($gallery.Trusted)) {
    Write-Host "Trusting PSGallery"
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
}

Write-Host "Installing PSDepend"
Install-Module PSDepend -Scope CurrentUser -Force
Write-Host "Installing InvokeBuild"
Install-Module InvokeBuild -Scope CurrentUser -Force

Write-Host "Installing Dependencies"
Invoke-Build -Task InstallDependencies

Sync-PSScriptAnalyzerSetting
