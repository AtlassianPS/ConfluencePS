[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Integration tests convert test credentials from environment variables')]
param()

function New-ConfluenceIntegrationResourceName {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Prefix
    )

    $safePrefix = $Prefix -replace '[^A-Za-z0-9-]', '-'
    return "ConfluencePS-IntTest-$safePrefix-$([Guid]::NewGuid().ToString('N').Substring(0, 10))"
}

function New-ConfluenceIntegrationFixture {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../../Helpers/IntegrationTestTools.ps1"

    $null = Initialize-TestEnvironment -CallerPath (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
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

function New-ConfluenceIntegrationAttachmentFile {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Fixture,

        [Parameter()]
        [string]$Content = 'ConfluencePS integration attachment'
    )

    $filePath = Join-Path ([System.IO.Path]::GetTempPath()) "ConfluencePS-IntTest-$([Guid]::NewGuid().ToString('N')).txt"
    Set-Content -Path $filePath -Value $Content -Encoding UTF8
    $null = $Fixture.Files.Add($filePath)
    return $filePath
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
