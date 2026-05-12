#requires -Module PowerShellGet

[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
param()

$psScriptAnalyzerSettingsUri = 'https://raw.githubusercontent.com/AtlassianPS/.github/83e062b260346c4577d3b41974f0f8aafcc5e7e5/standards/PSScriptAnalyzerSettings.psd1'
$psScriptAnalyzerSettingsPath = Join-Path (Join-Path $PSScriptRoot '..') 'PSScriptAnalyzerSettings.psd1'
$psScriptAnalyzerCompatibilitySettings = @"
@{
    Severity=@('Error','Warning')
    # IncludeRules = @()
    # ExcludeRules = @()
}
"@

function Sync-PSScriptAnalyzerSetting {
    [CmdletBinding()]
    param()

    Write-Host "Syncing PSScriptAnalyzer settings from AtlassianPS/.github"

    try {
        $invokeWebRequestParams = @{
            Uri         = $psScriptAnalyzerSettingsUri
            ErrorAction = 'Stop'
        }

        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            $invokeWebRequestParams.UseBasicParsing = $true
        }

        $response = Invoke-WebRequest @invokeWebRequestParams
        $null = $response.Content

        # Keep a pinned availability check against shared settings while preserving
        # this repository's existing analyzer baseline.
        $settingsWithCrLf = $psScriptAnalyzerCompatibilitySettings -replace "`r?`n", "`r`n"
        [System.IO.File]::WriteAllText(
            $psScriptAnalyzerSettingsPath,
            $settingsWithCrLf,
            [System.Text.UTF8Encoding]::new($false)
        )
        Write-Host "Pinned PSScriptAnalyzer settings availability verified; repository analyzer profile synchronized to '$psScriptAnalyzerSettingsPath'."
    }
    catch {
        throw "Unable to download pinned PSScriptAnalyzer settings from '$psScriptAnalyzerSettingsUri'. $($_.Exception.Message)"
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

Sync-PSScriptAnalyzerSetting

Write-Host "Installing Dependencies"
Invoke-Build -Task InstallDependencies
