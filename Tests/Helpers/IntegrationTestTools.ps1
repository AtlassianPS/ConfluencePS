$script:TestResourcePrefix = 'ConfluencePS-IntTest-'
$script:_CachedIntegrationEnv = $null
$script:_EnvLoaded = $false

function Get-DotEnvExcludedName {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @()
}

function Read-DotEnvFile {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Loading .env into process-scoped environment variables is intentional and idempotent')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [string[]]$ExcludeName = @()
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
        if ([string]::IsNullOrEmpty($name) -or $name -in $ExcludeName) {
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

function Resolve-ConfluenceRepositoryRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if (
        -not [string]::IsNullOrWhiteSpace($env:BHProjectPath) -and
        (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'ConfluencePS.build.ps1')) -and
        (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'Tools/build.requirements.psd1'))
    ) {
        return (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
    }

    $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
    while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
        if (
            (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'ConfluencePS.build.ps1')) -and
            (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'Tools/build.requirements.psd1'))
        ) {
            return $candidate
        }

        $candidate = Split-Path -Path $candidate -Parent
    }

    throw "Could not resolve repository root from '$PSScriptRoot'."
}

function Initialize-IntegrationEnvironment {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Process-wide warn-once guard shared across dot-sourced integration files')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if ($script:_EnvLoaded) {
        return $script:_CachedIntegrationEnv
    }

    $projectRoot = Resolve-ConfluenceRepositoryRoot
    $envFile = Join-Path $projectRoot '.env'
    if (Test-Path $envFile) {
        Read-DotEnvFile -Path $envFile -ExcludeName (Get-DotEnvExcludedName)
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

function New-ConfluenceIntegrationResourceName {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Prefix
    )

    $safePrefix = $Prefix -replace '[^A-Za-z0-9-]', '-'
    return "$script:TestResourcePrefix$safePrefix-$([Guid]::NewGuid().ToString('N').Substring(0, 10))"
}

function New-ConfluenceIntegrationFixture {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Integration tests convert test credentials from environment variables')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    . "$PSScriptRoot/TestTools.ps1"

    $null = Initialize-TestEnvironment -CallerPath (Split-Path $PSScriptRoot -Parent)
    Import-Module $env:BHManifestToTest -Force

    $environment = Initialize-IntegrationEnvironment
    $fixture = [PSCustomObject]@{
        IsConfigured = $null -ne $environment
        SkipReason   = 'Environment not configured'
        Environment  = $environment
        Credential   = $null
        ApiUri       = $null
        Spaces       = [System.Collections.ArrayList]::new()
        Pages        = [System.Collections.ArrayList]::new()
        Files        = [System.Collections.ArrayList]::new()
    }

    if (-not $environment) {
        return $fixture
    }

    $secureToken = ConvertTo-SecureString -String $environment.Password -AsPlainText -Force
    $fixture.Credential = [System.Management.Automation.PSCredential]::new($environment.Username, $secureToken)
    $fixture.ApiUri = '{0}/rest/api' -f $environment.CloudUrl.TrimEnd('/')
    $fixture.SkipReason = $null

    Set-ConfluenceInfo -BaseUri $environment.CloudUrl -Credential $fixture.Credential
    return $fixture
}

function New-ConfluenceIntegrationSpaceKey {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return "IT$([Guid]::NewGuid().ToString('N').Substring(0, 8))".ToUpperInvariant()
}

function New-ConfluenceIntegrationSpace {
    [CmdletBinding()]
    [OutputType('ConfluencePS.Space')]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Fixture,

        [Parameter()]
        [string]$NamePrefix = 'ConfluencePS Integration'
    )

    $key = New-ConfluenceIntegrationSpaceKey
    $name = New-ConfluenceIntegrationResourceName -Prefix $NamePrefix
    $space = New-ConfluenceSpace -Key $key -Name $name -Description '<p>Disposable ConfluencePS integration test space</p>' -ErrorAction Stop
    $null = $Fixture.Spaces.Add($space.Key)
    return $space
}

function New-ConfluenceIntegrationPage {
    [CmdletBinding()]
    [OutputType('ConfluencePS.Page')]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Fixture,

        [Parameter(Mandatory)]
        [string]$SpaceKey,

        [Parameter()]
        [string]$TitlePrefix = 'Integration Page',

        [Parameter()]
        [string]$Body = '<p>ConfluencePS integration test page</p>'
    )

    $title = New-ConfluenceIntegrationResourceName -Prefix $TitlePrefix
    $page = New-ConfluencePage -Title $title -SpaceKey $SpaceKey -Body $Body -ErrorAction Stop
    $null = $Fixture.Pages.Add($page.ID)
    return $page
}

function Assert-ConfluenceIntegrationFixtureReady {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Fixture
    )

    if (-not $Fixture.IsConfigured) {
        Set-ItResult -Skipped -Because $Fixture.SkipReason
        return $false
    }

    return $true
}

function New-ConfluenceIntegrationPageSet {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Fixture,

        [Parameter()]
        [string]$SpaceNamePrefix = 'ConfluencePS Page Set',

        [Parameter()]
        [string]$Body = '<p>ConfluencePS integration test page</p>'
    )

    $space = New-ConfluenceIntegrationSpace -Fixture $Fixture -NamePrefix $SpaceNamePrefix
    $homePage = (Get-ConfluenceSpace -SpaceKey $space.Key -ErrorAction Stop).Homepage
    $nameSuffix = [Guid]::NewGuid().ToString('N').Substring(0, 8)

    $page1 = "Page Piped $nameSuffix" | New-ConfluencePage -ParentID $homePage.ID -Body $Body -ErrorAction Stop
    $null = $Fixture.Pages.Add($page1.ID)

    $page2 = New-ConfluencePage -Title "Page Orphan $nameSuffix" -SpaceKey $space.Key -Body $Body -ErrorAction Stop
    $null = $Fixture.Pages.Add($page2.ID)

    $pageObject = [ConfluencePS.Page]@{
        Title     = "Page from Object $nameSuffix"
        Body      = $Body
        Ancestors = @($homePage)
        Space     = [ConfluencePS.Space]@{ Key = $space.Key }
    }
    $page3 = $pageObject | New-ConfluencePage -ErrorAction Stop
    $null = $Fixture.Pages.Add($page3.ID)

    $page4 = New-ConfluencePage -Title "Page with Parent Object $nameSuffix" -Parent $homePage -Body $Body -ErrorAction Stop
    $null = $Fixture.Pages.Add($page4.ID)

    return [PSCustomObject]@{
        Space    = $space
        HomePage = $homePage
        Page1    = $page1
        Page2    = $page2
        Page3    = $page3
        Page4    = $page4
        Suffix   = $nameSuffix
    }
}

function Remove-ConfluenceIntegrationFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Fixture
    )

    foreach ($pageId in @($Fixture.Pages)) {
        try {
            Remove-ConfluencePage -PageID $pageId -Confirm:$false -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to remove integration page $($pageId): $($_.Exception.Message)"
        }
    }

    foreach ($spaceKey in @($Fixture.Spaces)) {
        try {
            Remove-ConfluenceSpace -Key $spaceKey -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to remove integration space $($spaceKey): $($_.Exception.Message)"
        }
    }

    foreach ($filePath in @($Fixture.Files)) {
        Remove-Item -LiteralPath $filePath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
}
