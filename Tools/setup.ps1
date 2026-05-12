#requires -Module PowerShellGet

[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
param()

$psScriptAnalyzerSettingsUri = 'https://raw.githubusercontent.com/AtlassianPS/.github/83e062b260346c4577d3b41974f0f8aafcc5e7e5/standards/PSScriptAnalyzerSettings.psd1'
$psScriptAnalyzerSettingsSha256 = '89207270e49dd58895d146c7182e661c55c4092f3d3cdc280a4de26f407daa6e'
$psScriptAnalyzerSettingsPath = Join-Path (Join-Path $PSScriptRoot '..') 'PSScriptAnalyzerSettings.psd1'

function Sync-PSScriptAnalyzerSetting {
    [CmdletBinding()]
    param()

    Write-Host "Syncing PSScriptAnalyzer settings from AtlassianPS/.github"

    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "PSScriptAnalyzerSettings.$([System.Guid]::NewGuid().ToString('N')).psd1"
    try {
        $invokeWebRequestParams = @{
            Uri         = $psScriptAnalyzerSettingsUri
            OutFile     = $tempPath
            ErrorAction = 'Stop'
        }

        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            $invokeWebRequestParams.UseBasicParsing = $true
        }

        Invoke-WebRequest @invokeWebRequestParams

        $downloadHash = (Get-FileHash -Path $tempPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($downloadHash -ne $psScriptAnalyzerSettingsSha256) {
            throw "Downloaded PSScriptAnalyzer settings hash mismatch. Expected '$psScriptAnalyzerSettingsSha256' but received '$downloadHash'."
        }

        if ($env:ATLASSIANPS_PSSA_UPDATE_LOCAL -ne '1') {
            Write-Host "Pinned PSScriptAnalyzer settings validated."
            return
        }

        # Keep repo-consistent line endings while still pinning source payload hash.
        $settingsContent = [System.IO.File]::ReadAllText($tempPath)
        $settingsWithCrLf = $settingsContent -replace "`r?`n", "`r`n"
        [System.IO.File]::WriteAllText(
            $psScriptAnalyzerSettingsPath,
            $settingsWithCrLf,
            [System.Text.UTF8Encoding]::new($false)
        )
    }
    catch {
        throw "Unable to refresh pinned PSScriptAnalyzer settings from '$psScriptAnalyzerSettingsUri'. $($_.Exception.Message)"
    }
    finally {
        if (Test-Path -Path $tempPath) {
            Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
        }
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
