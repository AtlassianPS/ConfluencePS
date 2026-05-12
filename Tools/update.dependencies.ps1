#requires -Module PowerShellGet

[CmdletBinding()]
param()

$requirementsPath = Join-Path $PSScriptRoot 'build.requirements.psd1'
$setupScriptPath = Join-Path $PSScriptRoot 'setup.ps1'

function Get-LatestModuleVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    try {
        $latest = Find-Module -Name $ModuleName -Repository PSGallery -ErrorAction Stop
        return $latest.Version.ToString()
    }
    catch {
        Write-Warning "Unable to resolve latest version for module '$ModuleName'. Keeping existing version."
        Write-Warning $_
        return $null
    }
}

function Update-DependencyRequirements {
    [CmdletBinding()]
    param()

    if (-not (Test-Path -Path $requirementsPath)) {
        Write-Warning "Dependency file '$requirementsPath' not found."
        return
    }

    $requirements = Import-PowerShellDataFile -Path $requirementsPath
    if (-not ($requirements -is [hashtable])) {
        Write-Warning "Expected hashtable requirements in '$requirementsPath'."
        return
    }

    $outputLines = @(
        '@{'
        '    PSDependOptions  = @{'
        '        Target = "CurrentUser"'
        '    }'
        ''
    )

    foreach ($moduleName in ($requirements.Keys | Sort-Object)) {
        if ($moduleName -eq 'PSDependOptions') {
            continue
        }

        $entry = $requirements[$moduleName]
        if ($entry -is [string]) {
            $outputLines += "    $moduleName      = `"$entry`""
            continue
        }

        if (-not ($entry -is [hashtable])) {
            $outputLines += "    $moduleName      = `"$entry`""
            continue
        }

        $version = $entry.Version
        $newVersion = $version
        if ($version -and ($version -ne 'latest')) {
            $latestVersion = Get-LatestModuleVersion -ModuleName $moduleName
            if ($latestVersion -and ([version]$latestVersion -gt [version]$version)) {
                Write-Output "Updating ${moduleName}: v$version --> $latestVersion"
                $newVersion = $latestVersion
            }
        }

        $outputLines += "    $moduleName      = @{"
        if ($entry.Parameters) {
            $outputLines += '        Parameters = @{'
            foreach ($parameterKey in ($entry.Parameters.Keys | Sort-Object)) {
                $parameterValue = $entry.Parameters[$parameterKey]
                $outputLines += "            $parameterKey = `$$parameterValue"
            }
            $outputLines += '        }'
        }
        $outputLines += "        Version    = `"$newVersion`""
        $outputLines += '    }'
    }

    $outputLines += '}'
    $fileContent = ($outputLines -join "`r`n") + "`r`n"
    [System.IO.File]::WriteAllText($requirementsPath, $fileContent, [System.Text.UTF8Encoding]::new($false))
}

function Update-PinnedPSScriptAnalyzerSettingsUri {
    [CmdletBinding()]
    param()

    $settingsFilePath = 'standards/PSScriptAnalyzerSettings.psd1'
    $commitApiUri = "https://api.github.com/repos/AtlassianPS/.github/commits?path=$settingsFilePath&sha=master&per_page=1"

    Write-Output "Checking pinned .github commit for $settingsFilePath"
    try {
        $response = Invoke-RestMethod -Uri $commitApiUri -Method Get -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to query latest commit for shared PSScriptAnalyzer settings."
        Write-Warning $_
        return
    }

    if (-not $response -or -not $response[0] -or -not $response[0].sha) {
        Write-Warning "No commit data returned for shared PSScriptAnalyzer settings; skipping setup.ps1 pin update."
        return
    }

    $latestCommit = $response[0].sha
    $newUri = "https://raw.githubusercontent.com/AtlassianPS/.github/$latestCommit/$settingsFilePath"
    $setupContent = [System.IO.File]::ReadAllText($setupScriptPath)
    $oldUriPattern = "(?m)^\$psScriptAnalyzerSettingsUri = 'https://raw\.githubusercontent\.com/AtlassianPS/\.github/[^']+/standards/PSScriptAnalyzerSettings\.psd1'$"
    $newUriLine = "`$psScriptAnalyzerSettingsUri = '$newUri'"

    if ($setupContent -notmatch $oldUriPattern) {
        Write-Warning "Unable to locate pinned PSScriptAnalyzer URI in setup.ps1; skipping."
        return
    }

    $updatedContent = [System.Text.RegularExpressions.Regex]::Replace($setupContent, $oldUriPattern, $newUriLine, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($updatedContent -eq $setupContent) {
        Write-Output "Pinned PSScriptAnalyzer URI already up to date."
        return
    }

    $updatedContent = $updatedContent -replace "`r?`n", "`r`n"
    [System.IO.File]::WriteAllText($setupScriptPath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    Write-Output "Updated pinned PSScriptAnalyzer URI to commit $latestCommit"
}

Update-DependencyRequirements
Update-PinnedPSScriptAnalyzerSettingsUri
