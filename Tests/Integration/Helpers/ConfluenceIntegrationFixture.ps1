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
