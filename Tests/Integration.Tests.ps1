#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSUseDeclaredVarsMoreThanAssigments",
    "",
    Justification = ""
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSAvoidUsingConvertToSecureStringWithPlainText",
    "",
    Justification = "Converting received plaintext token to SecureString"
)]
param()
# Pester integration/acceptance tests to use during module development. Dave Wyatt's five-part series:
# http://blogs.technet.com/b/heyscriptingguy/archive/2015/12/14/what-is-pester-and-why-should-i-care.aspx

Describe 'Integration Tests' -Tag Integration, Cloud, DataCenter {

    BeforeAll {
        $script:SpaceID = Get-Random
        . "$PSScriptRoot/Helpers/TestTools.ps1"
        . "$PSScriptRoot/Helpers/IntegrationTestTools.ps1"
        $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
        $script:integrationEnvironment = Initialize-IntegrationEnvironment
        if (-not $script:integrationEnvironment) {
            throw "Integration environment not configured. Copy .env.example to .env and configure required variables."
        }
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    Context 'Set-ConfluenceInfo' {
        BeforeAll {
            # Could be a long one-liner, but breaking down for readability
            $pass = ConvertTo-SecureString -AsPlainText -Force -String $script:integrationEnvironment.Password
            $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($script:integrationEnvironment.Username, $pass)

            Set-ConfluenceInfo -BaseURI $script:integrationEnvironment.CloudUrl -Credential $cred
        }

        # ASSERT
        It 'credentials are stored' {
            $PSDefaultParameterValues["Get-ConfluencePage:Credential"] | Should -BeOfType [PSCredential]
            #TODO: extend this
        }
        It 'url is stored' {
            $global:PSDefaultParameterValues["Get-ConfluencePage:ApiUri"] | Should -BeOfType [String]
            $global:PSDefaultParameterValues["Get-ConfluencePage:ApiUri"] -match "^https?://.*\/rest\/api$" | Should -Be $true
        }
    }

    Context 'New-ConfluenceSpace' {
        BeforeAll {
            # We don't want warnings on the screen
            $script:originalWarningPreference = $WarningPreference
            $WarningPreference = 'SilentlyContinue'

            # Set up test values:
            $script:Key1 = "PESTER$SpaceID"
            $script:Key2 = "PESTER1$SpaceID"
            $script:Name1 = "Pester Test Space"
            $script:Name2 = "Second Pester Space"
            $script:Description = "<p>A nice description</p>"
            $script:Icon = [ConfluencePS.Icon] @{
                path      = "/images/logo/default-space-logo-256.png"
                width     = 48
                height    = 48
                isDefault = $False
            }
            $script:Space1 = [ConfluencePS.Space]@{
                Key         = $Key1
                Name        = $Name1
                Description = $Description
            }

            $script:spaceAlreadyExisted = $false
            try {
                $null = Get-ConfluenceSpace -Key $Key1 -ErrorAction Stop
                $script:spaceAlreadyExisted = $true
            }
            catch {
                # Expected for fresh test runs.
            }

            Get-ConfluenceSpace | Where-Object {
                $_.Name -in @($Name1, $Name2)
            } | ForEach-Object {
                Write-Warning "Removing space: $($_.Name) $($_.key)"
                Remove-ConfluenceSpace $_.Key -Force -ErrorAction Stop
            }

            $script:NewSpace1 = $Space1 | New-ConfluenceSpace -ErrorAction Stop
            $script:NewSpace2 = New-ConfluenceSpace -Key $Key2 -Name $Name2 -Description $Description -ErrorAction Stop
        }
        AfterAll {
            $WarningPreference = $script:originalWarningPreference
        }

        # ASSERT
        It 'space does not exist before creation' {
            $spaceAlreadyExisted | Should -Be $false
        }
        It 'returns an object with specific properties' {
            $NewSpace1 | Should -BeOfType [ConfluencePS.Space]
            $NewSpace2 | Should -BeOfType [ConfluencePS.Space]
            ($NewSpace1 | Get-Member -MemberType Property).Count | Should -Be 7
            ($NewSpace2 | Get-Member -MemberType Property).Count | Should -Be 7
        }
        It 'ID is integer' {
            $NewSpace1.ID | Should -BeOfType [UInt64]
            $NewSpace2.ID | Should -BeOfType [UInt64]
        }
        It 'key matches the specified value' {
            $NewSpace1.Key | Should -BeOfType [String]
            $NewSpace1.Key | Should -BeExactly $Key1
            $NewSpace2.Key | Should -BeOfType [String]
            $NewSpace2.Key | Should -BeExactly $Key2
        }
        It 'name matches the specified value' {
            $NewSpace1.Name | Should -BeOfType [String]
            $NewSpace1.Name | Should -BeExactly $Name1
            $NewSpace2.Name | Should -BeOfType [String]
            $NewSpace2.Name | Should -BeExactly $Name2
        }
        It 'homepage is ConfluencePS.Page' {
            $NewSpace1.Homepage | Should -BeOfType [ConfluencePS.Page]
            $NewSpace2.Homepage | Should -BeOfType [ConfluencePS.Page]
        }
        It 'homepage matches the specified value' {
            $NewSpace1.Homepage.Title | Should -BeExactly "$Name1 Home"
            $NewSpace2.Homepage.Title | Should -BeExactly "$Name2 Home"
        }
    }

    Context 'Get-ConfluenceSpace' {
        # ARRANGE
        # Set up test values:
        $Key1 = "PESTER$SpaceID"
        $Key2 = "PESTER1$SpaceID"
        $Name1 = "Pester Test Space"
        $Name2 = "Second Pester Space"
        $Description = "<p>A nice description</p>"

        BeforeAll {

            # ACT
        $AllSpaces = Get-ConfluenceSpace
        $GetSpace1 = Get-ConfluenceSpace -Key $Key1
        $GetSpace2 = Get-ConfluenceSpace | Where-Object {$_.Name -like '*ter test sp*'}
        $GetSpace3 = Get-ConfluenceSpace @($Key1, $Key2)

        }


        # ASSERT
        It 'returns an object with specific properties' {
            $AllSpaces | Should -BeOfType [ConfluencePS.Space]
            $GetSpace1 | Should -BeOfType [ConfluencePS.Space]
            $GetSpace2 | Should -BeOfType [ConfluencePS.Space]
            $GetSpace3 | Should -BeOfType [ConfluencePS.Space]
            ($GetSpace1 | Get-Member -MemberType Property).Count | Should -Be 7
            ($GetSpace2 | Get-Member -MemberType Property).Count | Should -Be 7
            ($GetSpace3 | Get-Member -MemberType Property).Count | Should -Be 7
        }
        It 'has the correct number of results' {
            @($AllSpaces).Count | Should -BeGreaterOrEqual 2
            @($GetSpace1).Count | Should -Be 1
            @($GetSpace2).Count | Should -Be 1
            @($GetSpace3).Count | Should -Be 2
        }
        It 'id is integer' {
            $GetSpace1.ID | Should -BeOfType [UInt64]
            $GetSpace2.ID | Should -BeOfType [UInt64]
            $GetSpace3.ID | Should -BeOfType [UInt64]
        }
        It 'key is string' {
            $GetSpace1.Key | Should -BeOfType [String]
            $GetSpace2.Key | Should -BeOfType [String]
            $GetSpace3.Key | Should -BeOfType [String]
        }
        It 'key matches the specified value' {
            $GetSpace1.Key | Should -BeExactly $Key1
            $GetSpace2.Key | Should -BeExactly $Key1
            $GetSpace3.Key | Should -BeExactly @($Key1, $Key2)
        }
        It 'name is string' {
            $GetSpace1.Name | Should -BeOfType [String]
            $GetSpace2.Name | Should -BeOfType [String]
            $GetSpace3.Name | Should -BeOfType [String]
        }
        It 'name matches the specified value' {
            $GetSpace1.Name | Should -BeExactly $Name1
            $GetSpace2.Name | Should -BeExactly $Name1
            $GetSpace3.Name | Should -BeExactly @($Name1, $Name2)
        }
        It 'description is string' {
            $GetSpace1.Description | Should -BeOfType [String]
            $GetSpace2.Description | Should -BeOfType [String]
            $GetSpace3.Description | Should -BeOfType [String]
        }
        It 'description matches the specified value' {
            $GetSpace1.Description | Should -BeExactly $Description
            $GetSpace2.Description | Should -BeExactly $Description
            # $GetSpace3.Description | Should -BeExactly $Description
        }
        It 'type is string' {
            $GetSpace1.Type | Should -BeOfType [String]
            $GetSpace2.Type | Should -BeOfType [String]
            $GetSpace3.Type | Should -BeOfType [String]
        }
        It 'icon is confluenceps.icon' {
            $GetSpace1.Icon | Should -BeOfType [ConfluencePS.Icon]
            $GetSpace2.Icon | Should -BeOfType [ConfluencePS.Icon]
            $GetSpace3.Icon | Should -BeOfType [ConfluencePS.Icon]
        }
        It 'homepage is ConfluencePS.Page' {
            $GetSpace1.Homepage | Should -BeOfType [ConfluencePS.Page]
            $GetSpace2.Homepage | Should -BeOfType [ConfluencePS.Page]
            $GetSpace3.Homepage | Should -BeOfType [ConfluencePS.Page]
        }
        It 'homepage matches the specified value' {
            $GetSpace1.Homepage.Title | Should -BeExactly "$($GetSpace1.Name) Home"
            $GetSpace2.Homepage.Title | Should -BeExactly "$($GetSpace2.Name) Home"
            $GetSpace3.Homepage.Title | Should -BeExactly @("$Name1 Home", "$Name2 Home")
        }
        It 'has a meaningful string value' {
            $GetSpace1.Icon.ToString() | Should -Be $GetSpace1.Icon.Path
        }
    }

    Context 'ConvertTo-ConfluenceStorageFormat' {
        # ARRANGE
        BeforeAll {
            $script:InputString = "Hi Pester!"
            $script:OutputString = "<p>Hi Pester!</p>"

            # ACT
            $result1 = $script:InputString | ConvertTo-ConfluenceStorageFormat
            $result2 = ConvertTo-ConfluenceStorageFormat -Content $script:InputString
            $result3 = ConvertTo-ConfluenceStorageFormat -Content $script:InputString, $script:InputString
            $result4 = ConvertTo-ConfluenceStorageFormat -Content 'h1. *bold* !image.png!' -AsPlainText

        }


        # ASSERT
        It 'returns a string' {
            $result1 | Should -BeOfType [String]
            $result2 | Should -BeOfType [String]
            $result3 | Should -BeOfType [String]
            $result4 | Should -BeOfType [String]
        }
        It 'output matches the expected string' {
            $result1 | Should -BeExactly $script:OutputString
            $result2 | Should -BeExactly $script:OutputString
            $result3 | Should -BeExactly @($script:OutputString, $script:OutputString)
        }
        It 'can preserve wiki markup characters as literal text' {
            $result4 | Should -Match 'h1&#46;'
            $result4 | Should -Match '&#42;bold&#42;'
            $result4 | Should -Match '&#33;image&#46;png&#33;'
            $result4 | Should -Not -Match '<h1|<strong|<ac:image'
        }
    }

    Context 'Invoke-ConfluenceMethod' {
        BeforeAll {
            $script:InvokeMethodApiUri = '{0}/rest/api' -f $script:integrationEnvironment.CloudUrl.TrimEnd('/')
            $script:InvokeMethodSecurePassword = ConvertTo-SecureString -AsPlainText -Force -String $script:integrationEnvironment.Password
            $script:InvokeMethodCredential = [System.Management.Automation.PSCredential]::new($script:integrationEnvironment.Username, $script:InvokeMethodSecurePassword)

            $script:InvokeMethodSpaceResults = Invoke-ConfluenceMethod -Uri "$script:InvokeMethodApiUri/space" -GetParameters @{ limit = 1 } -Credential $script:InvokeMethodCredential -ErrorAction Stop
            $script:InvokeMethodTypedSpaceResults = Invoke-ConfluenceMethod -Uri "$script:InvokeMethodApiUri/space" -GetParameters @{ limit = 1 } -Credential $script:InvokeMethodCredential -OutputType ([ConfluencePS.Space]) -ErrorAction Stop
        }

        It 'returns at least one space result from a direct API call' {
            @($script:InvokeMethodSpaceResults).Count | Should -BeGreaterThan 0
            @($script:InvokeMethodSpaceResults)[0].ID | Should -Not -BeNullOrEmpty
            @($script:InvokeMethodSpaceResults)[0].Key | Should -Not -BeNullOrEmpty
        }

        It 'can cast direct API results to ConfluencePS.Space' {
            @($script:InvokeMethodTypedSpaceResults).Count | Should -BeGreaterThan 0
            @($script:InvokeMethodTypedSpaceResults)[0] | Should -BeOfType [ConfluencePS.Space]
            @($script:InvokeMethodTypedSpaceResults)[0].Key | Should -Not -BeNullOrEmpty
        }
    }

    Context 'ConvertTo-ConfluenceTable' {
        BeforeAll {
            $script:TableIntegrationSpaceKey = "PESTER$SpaceID"
            $script:TableIntegrationTitle = "Pester Confluence Table Page $SpaceID"
            $script:TableInput = [PSCustomObject]@{
                Name  = 'ConfluencePS'
                Scope = 'SmokeCoverage'
            }
            $script:TableMarkup = $script:TableInput | ConvertTo-ConfluenceTable
            $script:TableStorageMarkup = ConvertTo-ConfluenceStorageFormat -Content $script:TableMarkup
            $script:TableIntegrationPage = New-ConfluencePage -Title $script:TableIntegrationTitle -SpaceKey $script:TableIntegrationSpaceKey -Body $script:TableStorageMarkup -ErrorAction Stop
            $script:FetchedTableIntegrationPage = Get-ConfluencePage -PageID $script:TableIntegrationPage.ID -ErrorAction Stop
        }

        AfterAll {
            if ($script:TableIntegrationPage) {
                try {
                    Remove-ConfluencePage -PageID $script:TableIntegrationPage.ID -Confirm:$false -ErrorAction Stop
                }
                catch {
                    Write-Warning "Failed to clean up table integration page $($script:TableIntegrationPage.ID): $($_.Exception.Message)"
                }
            }
        }

        It 'creates Confluence table markup that contains the expected header row' {
            $script:TableMarkup | Should -Match '\|\| Name \|\| Scope \|\|'
            $script:TableMarkup | Should -Match '\| ConfluencePS \| SmokeCoverage \|'
        }

        It 'can be used in a real page creation flow' {
            $script:FetchedTableIntegrationPage | Should -BeOfType [ConfluencePS.Page]
            $script:FetchedTableIntegrationPage.Title | Should -BeExactly $script:TableIntegrationTitle
            $script:FetchedTableIntegrationPage.Body | Should -Match 'ConfluencePS'
            $script:FetchedTableIntegrationPage.Body | Should -Match 'SmokeCoverage'
        }
    }

    Context 'New-ConfluencePage' {
        <# TODO:
            * Title may not be empty
            * Space may not be empty when no parent is provided
        #>

        BeforeAll {
            # ARRANGE
            $script:SpaceKey = "PESTER$SpaceID"
            $script:parentPage = Get-ConfluencePage -Title "Pester Test Space Home" -SpaceKey $SpaceKey -ErrorAction Stop
            $script:Title1 = "Pester New Page Piped"
            $script:Title2 = "Pester New Page Orphan"
            $script:Title3 = "Pester New Page from Object"
            $script:Title4 = "Pester New Page with Parent Object"
            $script:RawContent = "Hi Pester!👋"
            $script:FormattedContent = "<p>Hi Pester!</p><p>👋</p>"
            $script:pageObject = New-Object -TypeName ConfluencePS.Page -Property @{
                Title     = $Title3
                Body      = $FormattedContent
                Ancestors = @($parentPage)
                Space     = New-Object -TypeName ConfluencePS.Space -Property @{key = $SpaceKey}
            }

            # ACT
            $script:NewPage1 = $Title1 | New-ConfluencePage -ParentID $parentPage.ID -ErrorAction Stop
            $script:NewPage2 = New-ConfluencePage -Title $Title2 -SpaceKey $SpaceKey -Body $RawContent -Convert -ErrorAction Stop
            $script:NewPage3 = $pageObject | New-ConfluencePage -ErrorAction Stop
            $script:NewPage4 = New-ConfluencePage -Title $Title4 -Parent $parentPage -ErrorAction Stop

        }


        # ASSERT
        It 'returns an object with specific properties' {
            $NewPage1 | Should -BeOfType [ConfluencePS.Page]
            $NewPage2 | Should -BeOfType [ConfluencePS.Page]
            $NewPage3 | Should -BeOfType [ConfluencePS.Page]
            $NewPage4 | Should -BeOfType [ConfluencePS.Page]
            ($NewPage1 | Get-Member -MemberType Property).Count | Should -Be 9
            ($NewPage2 | Get-Member -MemberType Property).Count | Should -Be 9
            ($NewPage3 | Get-Member -MemberType Property).Count | Should -Be 9
            ($NewPage4 | Get-Member -MemberType Property).Count | Should -Be 9
        }
        It 'spaceid is integer' {
            $NewPage1.ID | Should -BeOfType [UInt64]
            $NewPage2.ID | Should -BeOfType [UInt64]
            $NewPage3.ID | Should -BeOfType [UInt64]
            $NewPage4.ID | Should -BeOfType [UInt64]
        }
        It 'key matches the specified value' {
            $NewPage1.Space.Key | Should -BeExactly $SpaceKey
            $NewPage2.Space.Key | Should -BeExactly $SpaceKey
            $NewPage3.Space.Key | Should -BeExactly $SpaceKey
            $NewPage4.Space.Key | Should -BeExactly $SpaceKey
        }
        It 'title matches the specified value' {
            $NewPage1.Title | Should -BeExactly $Title1
            $NewPage2.Title | Should -BeExactly $Title2
            $NewPage3.Title | Should -BeExactly $Title3
            $NewPage4.Title | Should -BeExactly $Title4
        }
        It 'parentid is integer' {
            $NewPage1.Ancestors.ID | Should -BeOfType [UInt64]
            $NewPage3.Ancestors.ID | Should -BeOfType [UInt64]
            $NewPage4.Ancestors.ID | Should -BeOfType [UInt64]
        }
        It 'parentid matches the specified value' {
            $NewPage1.Ancestors.ID | Should -BeExactly $parentPage.ID
            $NewPage3.Ancestors.ID | Should -BeExactly $parentPage.ID
            $NewPage4.Ancestors.ID | Should -BeExactly $parentPage.ID
        }
        It 'parentid is empty' {
            $NewPage2.Ancestors | Should -BeNullOrEmpty
        }
        It 'url is string' {
            $NewPage1.URL | Should -BeOfType [String]
            $NewPage1.URL | Should -Not -BeNullOrEmpty
            $NewPage2.URL | Should -BeOfType [String]
            $NewPage2.URL | Should -Not -BeNullOrEmpty
            $NewPage3.URL | Should -BeOfType [String]
            $NewPage3.URL | Should -Not -BeNullOrEmpty
            $NewPage4.URL | Should -BeOfType [String]
            $NewPage4.URL | Should -Not -BeNullOrEmpty
        }
        It 'shorturl is string' {
            $NewPage1.ShortURL | Should -BeOfType [String]
            $NewPage1.ShortURL | Should -Not -BeNullOrEmpty
            $NewPage2.ShortURL | Should -BeOfType [String]
            $NewPage2.ShortURL | Should -Not -BeNullOrEmpty
            $NewPage3.ShortURL | Should -BeOfType [String]
            $NewPage3.ShortURL | Should -Not -BeNullOrEmpty
            $NewPage4.ShortURL | Should -BeOfType [String]
            $NewPage4.ShortURL | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ConfluencePage' {
        BeforeAll {
            # ARRANGE
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Title1 = "Pester New Page from Object"
            $script:Title2 = "Pester New Page Orphan"
            $script:Title3 = "Pester Test Space Home"
            $script:Title4 = "orphan"
            $script:Title5 = "*orphan"
            $script:Query = $null
            $script:ContentRaw = "<p>Hi Pester!👋</p>"
            $script:ContentFormatted = "<p>Hi Pester!</p><p>👋</p>"
            $script:SearchLabel = "searchlabel$SpaceID"
            (Get-ConfluenceSpace -SpaceKey $SpaceKey).Homepage | Add-ConfluenceLabel -Label $SearchLabel -ErrorAction Stop
            Start-Sleep -Seconds 20 # Delay to allow DB index to update

            # ACT
            $script:GetTitle1 = Get-ConfluencePage -Title $Title1.ToLower() -SpaceKey $SpaceKey -PageSize 200 -ErrorAction SilentlyContinue
            $script:GetTitle2 = Get-ConfluencePage -Title $Title2 -SpaceKey $SpaceKey -ErrorAction SilentlyContinue
            $script:GetPartial = Get-ConfluencePage -Title $Title4 -SpaceKey $SpaceKey -ErrorAction SilentlyContinue
            $script:GetWildcard = Get-ConfluencePage -Title $Title5 -SpaceKey $SpaceKey -ErrorAction SilentlyContinue
            $script:GetID1 = Get-ConfluencePage -PageID $GetTitle1.ID -ErrorAction SilentlyContinue
            $script:GetID2 = Get-ConfluencePage -PageID $GetTitle2.ID -ErrorAction SilentlyContinue
            $script:Query = "id in ($($GetID1.ID), $($GetID2.ID))"
            $script:GetKeys = Get-ConfluencePage -SpaceKey $SpaceKey -ErrorAction SilentlyContinue | Sort-Object ID
            $script:GetByLabel = @()
            $script:GetByQuery = @()
            $maxSearchRetries = if ($script:integrationEnvironment.IsCloud) { 24 } else { 6 }
            for ($retry = 0; $retry -lt $maxSearchRetries; $retry++) {
                $script:GetByLabel = Get-ConfluencePage -Label $SearchLabel -SpaceKey $SpaceKey -ErrorAction SilentlyContinue
                $script:GetByQuery = Get-ConfluencePage -Query $query -ErrorAction SilentlyContinue
                if ((@($GetByLabel).Count -ge 1) -and (@($GetByQuery).Count -eq 2)) {
                    break
                }

                Start-Sleep -Seconds 5
            }
            $script:GetByLabelIndexed = @($GetByLabel).Count -ge 1
            $script:GetByLabelRequired = -not $script:integrationEnvironment.IsCloud
            $script:GetByLabelCanBeAsserted = $script:GetByLabelIndexed -or $script:GetByLabelRequired
            $script:GetByQueryIndexed = @($GetByQuery).Count -eq 2
            $script:GetByQueryRequired = -not $script:integrationEnvironment.IsCloud
            $script:GetByQueryCanBeAsserted = $script:GetByQueryIndexed -or $script:GetByQueryRequired
            $script:GetSpacePage = Get-ConfluencePage -Space (Get-ConfluenceSpace -SpaceKey $SpaceKey) -ErrorAction SilentlyContinue
            $script:GetSpacePiped = Get-ConfluenceSpace -SpaceKey $SpaceKey | Get-ConfluencePage -ErrorAction SilentlyContinue

        }


        # ASSERT
        It 'returns the correct amount of results' {
            @($GetTitle1).Count | Should -Be 1
            @($GetTitle2).Count | Should -Be 1
            @($GetPartial).Count | Should -Be 0
            @($GetWildcard).Count | Should -Be 1
            @($GetID1).Count | Should -Be 1
            @($GetID2).Count | Should -Be 1
            @($GetKeys).Count | Should -Be 5
            if ($script:GetByLabelCanBeAsserted) {
                @($GetByLabel).Count | Should -Be 1
            }
            @($GetSpacePage).Count | Should -Be 5
            if ($script:GetByQueryCanBeAsserted) {
                @($GetByQuery).Count | Should -Be 2
            }
            @($GetSpacePiped).Count | Should -Be 5
        }
        It 'returns an object with specific properties' {
            $GetTitle1 | Should -BeOfType [ConfluencePS.Page]
            $GetTitle2 | Should -BeOfType [ConfluencePS.Page]
            $GetID1 | Should -BeOfType [ConfluencePS.Page]
            $GetID2 | Should -BeOfType [ConfluencePS.Page]
            $GetKeys | Should -BeOfType [ConfluencePS.Page]
            if ($script:GetByLabelCanBeAsserted) {
                $GetByLabel | Should -BeOfType [ConfluencePS.Page]
            }
            if ($script:GetByQueryCanBeAsserted) {
                $GetByQuery | Should -BeOfType [ConfluencePS.Page]
            }
            ($GetTitle1 | Get-Member -MemberType Property).Count | Should -Be 9
            ($GetTitle2 | Get-Member -MemberType Property).Count | Should -Be 9
            ($GetID1 | Get-Member -MemberType Property).Count | Should -Be 9
            ($GetID2 | Get-Member -MemberType Property).Count | Should -Be 9
            ($GetKeys | Get-Member -MemberType Property).Count | Should -Be 9
            if ($script:GetByLabelCanBeAsserted) {
                ($GetByLabel | Get-Member -MemberType Property).Count | Should -Be 9
            }
            if ($script:GetByQueryCanBeAsserted) {
                ($GetByQuery | Get-Member -MemberType Property).Count | Should -Be 9
            }
        }
        It 'id is integer' {
            $GetTitle1.ID | Should -BeOfType [UInt64]
            $GetTitle2.ID | Should -BeOfType [UInt64]
            $GetID1.ID | Should -BeOfType [UInt64]
            $GetID2.ID | Should -BeOfType [UInt64]
            $GetKeys.ID | Should -BeOfType [UInt64]
            if ($script:GetByLabelCanBeAsserted) {
                $GetByLabel.ID | Should -BeOfType [UInt64]
            }
            if ($script:GetByQueryCanBeAsserted) {
                $GetByQuery.ID | Should -BeOfType [UInt64]
            }
        }
        It 'id matches the specified value' {
            $GetID1.ID | Should -Be $GetTitle1.ID
            $GetID2.ID | Should -Be $GetTitle2.ID
            $GetKeys.ID -contains $GetID1.ID | Should -Be $true
            $GetKeys.ID -contains $GetID2.ID | Should -Be $true
        }
        It 'title matches the specified value' {
            $GetTitle1.Title | Should -BeExactly $Title1
            $GetTitle2.Title | Should -BeExactly $Title2
            $GetID1.Title | Should -BeExactly $Title1
            $GetID2.Title | Should -BeExactly $Title2
            $GetKeys.Title -contains $Title3 | Should -Be $true
            $GetKeys.Title -contains $GetID1.Title | Should -Be $true
            if ($script:GetByLabelCanBeAsserted) {
                $GetByLabel.Title -like "PESTER Test Space Home" | Should -Be $true
            }
        }
        It 'space matches the specified value' {
            $GetTitle1.Space.Key | Should -BeExactly $SpaceKey
            $GetTitle2.Space.Key | Should -BeExactly $SpaceKey
            $GetID1.Space.Key | Should -BeExactly $SpaceKey
            $GetID2.Space.Key | Should -BeExactly $SpaceKey
            $GetKeys.Space.Key -contains $SpaceKey | Should -Be $true
            if ($script:GetByLabelCanBeAsserted) {
                $GetByLabel.Space.Key | Should -BeExactly $SpaceKey
            }
        }
        It 'version matches the specified value' {
            $GetTitle2.Version.Number | Should -Be 1
            $GetID2.Version.Number | Should -Be 1
            $GetKeys.Version.Number -contains 1 | Should -Be $true
            if ($script:GetByLabelCanBeAsserted) {
                $GetByLabel.Version.Number | Should -Be 1
            }
        }
        It 'body matches the specified value' {
            . "$env:BHProjectPath/$env:BHProjectName/Private/ConvertFrom-HTMLEncoded.ps1"

            ConvertFrom-HTMLEncoded $GetTitle1.Body | Should -BeExactly $ContentFormatted
            ConvertFrom-HTMLEncoded $GetTitle2.Body | Should -BeExactly $ContentRaw
            ConvertFrom-HTMLEncoded $GetID1.Body | Should -BeExactly $ContentFormatted
        }
        It 'url is string' {
            $GetTitle1.URL | Should -BeOfType [String]
            $GetTitle1.URL | Should -Not -BeNullOrEmpty
            $GetTitle2.URL | Should -BeOfType [String]
            $GetTitle2.URL | Should -Not -BeNullOrEmpty
            $GetID1.URL | Should -BeOfType [String]
            $GetID1.URL | Should -Not -BeNullOrEmpty
            $GetID2.URL | Should -BeOfType [String]
            $GetID2.URL | Should -Not -BeNullOrEmpty
            $GetKeys.URL | Should -BeOfType [String]
            $GetKeys.URL | Should -Not -BeNullOrEmpty
            if ($script:GetByLabelCanBeAsserted) {
                $GetByLabel.URL | Should -BeOfType [String]
                $GetByLabel.URL | Should -Not -BeNullOrEmpty
            }
            if ($script:GetByQueryCanBeAsserted) {
                $GetByQuery.URL | Should -BeOfType [String]
                $GetByQuery.URL | Should -Not -BeNullOrEmpty
            }
        }
        It 'shorturl is string' {
            $GetTitle1.ShortURL | Should -BeOfType [String]
            $GetTitle1.ShortURL | Should -Not -BeNullOrEmpty
            $GetTitle2.ShortURL | Should -BeOfType [String]
            $GetTitle2.ShortURL | Should -Not -BeNullOrEmpty
            $GetID1.ShortURL | Should -BeOfType [String]
            $GetID1.ShortURL | Should -Not -BeNullOrEmpty
            $GetID2.ShortURL | Should -BeOfType [String]
            $GetID2.ShortURL | Should -Not -BeNullOrEmpty
            $GetKeys.ShortURL | Should -BeOfType [String]
            $GetKeys.ShortURL | Should -Not -BeNullOrEmpty
            if ($script:GetByLabelCanBeAsserted) {
                $GetByLabel.ShortURL | Should -BeOfType [String]
                $GetByLabel.ShortURL | Should -Not -BeNullOrEmpty
            }
            if ($script:GetByQueryCanBeAsserted) {
                $GetByQuery.ShortURL | Should -BeOfType [String]
                $GetByQuery.ShortURL | Should -Not -BeNullOrEmpty
            }
        }
        It 'has a meaningful string value' {
            $GetTitle1.Version.ToString() | Should -Be $GetTitle1.Version.Number.ToString()
            $GetTitle1.Version.By.ToString() | Should -Be $GetTitle1.Version.By.UserName
            $GetTitle1.Space.ToString() | Should -Be ("[{0}] {1}" -f $GetTitle1.Space.Key, $GetTitle1.Space.Name)
        }
    }

    Context 'Add-ConfluenceLabel' {
        BeforeAll {
            # ARRANGE
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Page1 = Get-ConfluencePage -Title "Pester New Page Piped" -SpaceKey $SpaceKey -ErrorAction Stop
            $script:Label1 = "pestera", "pesterb", "pesterc"
            $script:Label2 = "pesterall"
            $script:PartialLabel = "pest"

            # ACT
            $script:NewLabel1 = Add-ConfluenceLabel -Label $Label1 -PageID $Page1.ID -ErrorAction SilentlyContinue
            $script:NewLabel2 = Get-ConfluencePage -SpaceKey $SpaceKey | Add-ConfluenceLabel -Label $Label2 -ErrorAction SilentlyContinue
            $script:NewLabel3 = (Get-ConfluenceSpace -SpaceKey $SpaceKey).Homepage | Get-ConfluenceLabel | Add-ConfluenceLabel -PageID $Page1.ID -ErrorAction SilentlyContinue

        }


        # ASSERT
        It 'returns the correct amount of results' {
            ($NewLabel1.Labels).Count | Should -Be 3
            ($NewLabel2.Labels).Count | Should -Be 9
            ($NewLabel3.Labels).Count | Should -Be 5
        }
        It 'returns an object with specific properties' {
            $NewLabel1 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $NewLabel1.Page | Should -BeOfType [ConfluencePS.Page]
            $NewLabel1.Labels | Should -BeOfType [ConfluencePS.Label]
            ($NewLabel1.Labels | Get-Member -MemberType Property).Count | Should -Be 3
            $NewLabel2 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $NewLabel2.Page | Should -BeOfType [ConfluencePS.Page]
            $NewLabel2.Labels | Should -BeOfType [ConfluencePS.Label]
            ($NewLabel2.Labels | Get-Member -MemberType Property).Count | Should -Be 3
            $NewLabel3 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $NewLabel3.Page | Should -BeOfType [ConfluencePS.Page]
            $NewLabel3.Labels | Should -BeOfType [ConfluencePS.Label]
            ($NewLabel3.Labels | Get-Member -MemberType Property).Count | Should -Be 3
        }
        It 'label matches the specified value' {
            $NewLabel1.Labels.Name | Should -BeExactly $Label1
            $NewLabel2.Labels.Name -contains $Label2 | Should -Be $true
            ($NewLabel3.Labels.Name -match $PartialLabel | Sort-Object) | Should -Be (($Label1 + $Label2) | Sort-Object )
        }
        It 'labelid is not null or empty' {
            $NewLabel1.Labels.ID | Should -Not -BeNullOrEmpty
            $NewLabel2.Labels.ID | Should -Not -BeNullOrEmpty
            $NewLabel3.Labels.ID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-ConfluenceLabel' {
        BeforeAll {
            # ARRANGE
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Title1 = "Pester New Page from Object"
            $script:Label1 = @("overwrite", "remove")
            $script:Label2 = "final"
            $script:Page1 = Get-ConfluencePage -Title $Title1 -SpaceKey $SpaceKey -ErrorAction SilentlyContinue
            $script:Before1 = $Page1 | Get-ConfluenceLabel

            # ACT
            $script:After1 = Set-ConfluenceLabel -PageID $Page1.ID -Label $Label1 -ErrorAction Stop
            $script:After2 = $Page1 | Set-ConfluenceLabel -Label $Label2 -ErrorAction Stop

        }


        # ASSERT
        It 'returns the correct amount of results' {
            ($After1.Labels).Count | Should -Be 2
            ($After2.Labels).Count | Should -Be 1
        }
        It 'returns an object with specific properties' {
            $After1 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $After1.Page | Should -BeOfType [ConfluencePS.Page]
            $After1.Labels | Should -BeOfType [ConfluencePS.Label]
            ($After1 | Get-Member -MemberType Property).Count | Should -Be 2
            $After2 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $After2.Page | Should -BeOfType [ConfluencePS.Page]
            $After2.Labels | Should -BeOfType [ConfluencePS.Label]
            ($After2 | Get-Member -MemberType Property).Count | Should -Be 2
        }
        It 'label matches the specified value' {
            $After1.Labels.Name | Should -BeExactly $Label1
            $After2.Labels.Name | Should -BeExactly $Label2
            $After1.Labels.Name -notcontains $Before1.Labels.Name | Should -Be $true
            $After2.Labels.Name -notcontains $Before1.Labels.Name | Should -Be $true
        }
        It 'labelid is not null or empty' {
            $After1.Labels.ID | Should -Not -BeNullOrEmpty
            $After2.Labels.ID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ConfluenceLabel' {
        BeforeAll {
            # ARRANGE
            $script:SpaceKey = "PESTER$SpaceID"
            $script:patternLabel1 = "pester[abc]$"
            $script:patternLabel2 = "(pest|import|fin)"
            $script:Page = Get-ConfluencePage -Title "Pester New Page Piped" -SpaceKey $SpaceKey

            # ACT
            $script:GetPageLabel1 = Get-ConfluenceLabel -PageID $Page.ID
            $script:GetPageLabel2 = Get-ConfluencePage -SpaceKey $SpaceKey | Get-ConfluenceLabel

        }


        # ASSERT
        It 'returns the correct amount of results' {
            ($GetPageLabel1.Labels).Count | Should -Be 5
            ($GetPageLabel2.Labels).Count | Should -Be 10
            ($GetPageLabel2.Labels | Where-Object {$_.Name -match $patternLabel1}).Count | Should -Be 3
        }
        It 'returns an object with specific properties' {
            $GetPageLabel1 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $GetPageLabel1.Page | Should -BeOfType [ConfluencePS.Page]
            $GetPageLabel1.Labels | Should -BeOfType [ConfluencePS.Label]
            $GetPageLabel2 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $GetPageLabel2.Page | Should -BeOfType [ConfluencePS.Page]
            $GetPageLabel2.Labels | Should -BeOfType [ConfluencePS.Label]
            ($GetPageLabel1 | Get-Member -MemberType Property).Count | Should -Be 2
            ($GetPageLabel2 | Get-Member -MemberType Property).Count | Should -Be 2
        }
        It 'label matches the specified value' {
            ($GetPageLabel1.Labels.Name | Where-Object { $_ -ne $script:SearchLabel }) | Should -Match $patternLabel2
            ($GetPageLabel2.Labels.Name | Where-Object { $_ -ne $script:SearchLabel }) | Should -Match $patternLabel2
        }
        It 'labelid is not null or empty' {
            $GetPageLabel1.Labels.ID | Should -Not -BeNullOrEmpty
            $GetPageLabel2.Labels.ID | Should -Not -BeNullOrEmpty
        }
        It 'pageid matches the specified value' {
            $GetPageLabel1.Page.ID | Should -BeExactly $Page.ID
            $GetPageLabel2.Page.ID -contains $Page.ID | Should -Be $true
        }
    }

    Context 'Set-ConfluencePage' {
        <# TODO:
        * Title may not be empty
        * fails when version is 1 larger than current version
        #>

        BeforeAll {
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Page1 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Piped"
            $script:Page2 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Orphan"
            $script:Page3 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page from Object"
            $script:Page4 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page with Parent Object"
            # create some more pages
            $script:Page5, $script:Page6, $script:Page7, $script:Page8, $script:Page9 = ("Page 5", "Page 6", "Page 7", "Page 8", "Page 9" | New-ConfluencePage -SpaceKey $SpaceKey -Body "<p>Lorem ipsum</p>" -ErrorAction Stop)
            $script:AllPages = Get-ConfluencePage -SpaceKey $SpaceKey | Where-Object { $_.Title -notlike "*Home" }
            $script:ParentPage = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester Test Space Home" -ErrorAction Stop

            $script:NewTitle6 = "Renamed Page 6"
            $script:NewTitle7 = "Renamed Page 7"
            $script:NewVersionMessage9 = "Updated body content"
            $script:NewContent1 = "<h1>Bulk Change</h1><p>Changed all bodies in this space at once</p>"
            $script:NewContent2 = "<h1>Set Body by property</h1>"
            $script:NewContent3 = "<p>Updated</p>"
            $script:NewContent9 = "<h1>Bulk Change</h1><p>Changed all bodies in this space at once</p><p>Updated body for version message test</p>"
            $script:RawContent3 = "Updated"

            # ACT
            # change the body of all pages - all pages should have version 2
            $script:AllChangedPages = $AllPages | ForEach-Object {
                $_.Body = $NewContent1
                $_
            } | Set-ConfluencePage -ErrorAction Stop
            # set the body of a page to the same value as it already had - should remain on verion 2
            $script:SetPage1 = $Page1.ID | Set-ConfluencePage -Body $NewContent1 -ErrorAction Stop
            # change the body of a page by property - this page should have version 3
            $script:SetPage2 = $Page2.ID | Set-ConfluencePage -Body $NewContent2 -ErrorAction Stop
            # make a non-relevant change just to bump page version
            $script:SetPage3 = $Page3.ID | Set-ConfluencePage -Body "..." -ErrorAction Stop
            # change the title of a page by property - this page should have version 4
            $script:SetPage3 = $Page3.ID | Set-ConfluencePage -Body $RawContent3 -Convert -ErrorAction Stop
            # change the parent page by object
            $script:SetPage4 = Set-ConfluencePage -PageID $Page4.ID -Parent $Page3 -ErrorAction Stop
            # change the parent page by pageid
            $script:SetPage5 = Set-ConfluencePage -PageID $Page5.ID -ParentID $Page4.ID -ErrorAction Stop
            # change the title of a page
            $script:SetPage6 = $Page6.ID | Set-ConfluencePage -Title $NewTitle6 -ErrorAction Stop
            $script:SetPage7 = $AllChangedPages | Where-Object { $_.ID -eq $Page7.ID } | ForEach-Object {
                $_.Title = $NewTitle7
                $_
            } | Set-ConfluencePage -ErrorAction Stop
            # clear the body of a page
            $script:SetPage8 = Set-ConfluencePage -PageID $Page8.ID -Body "" -ErrorAction Stop
            # change the version message of a page
            $script:SetPage9 = $AllChangedPages | Where-Object { $_.ID -eq $Page9.ID } | ForEach-Object {
                $_.Body = $NewContent9
                $_.Version.Message = $NewVersionMessage9
                $_
            } | Set-ConfluencePage -ErrorAction Stop

        }


        # ASSERT
        It 'returns the correct amount of results' {
            @($SetPage1).Count | Should -Be 1
            @($SetPage2).Count | Should -Be 1
            @($SetPage3).Count | Should -Be 1
            @($SetPage4).Count | Should -Be 1
            @($SetPage5).Count | Should -Be 1
            @($SetPage6).Count | Should -Be 1
            @($SetPage7).Count | Should -Be 1
            @($SetPage8).Count | Should -Be 1
            @($SetPage9).Count | Should -Be 1
            @($AllChangedPages).Count | Should -Be 9
        }
        It 'returns an object with specific properties' {
            $SetPage1 | Should -BeOfType [ConfluencePS.Page]
            $SetPage2 | Should -BeOfType [ConfluencePS.Page]
            $SetPage3 | Should -BeOfType [ConfluencePS.Page]
            $SetPage4 | Should -BeOfType [ConfluencePS.Page]
            $SetPage5 | Should -BeOfType [ConfluencePS.Page]
            $SetPage6 | Should -BeOfType [ConfluencePS.Page]
            $SetPage7 | Should -BeOfType [ConfluencePS.Page]
            $SetPage8 | Should -BeOfType [ConfluencePS.Page]
            $SetPage9 | Should -BeOfType [ConfluencePS.Page]
            $AllChangedPages | Should -BeOfType [ConfluencePS.Page]
            ($SetPage1 | Get-Member -MemberType Property).Count | Should -Be 9
            ($SetPage2 | Get-Member -MemberType Property).Count | Should -Be 9
            ($SetPage3 | Get-Member -MemberType Property).Count | Should -Be 9
            ($SetPage4 | Get-Member -MemberType Property).Count | Should -Be 9
            ($SetPage5 | Get-Member -MemberType Property).Count | Should -Be 9
            ($SetPage6 | Get-Member -MemberType Property).Count | Should -Be 9
            ($SetPage7 | Get-Member -MemberType Property).Count | Should -Be 9
            ($SetPage8 | Get-Member -MemberType Property).Count | Should -Be 9
            ($SetPage9 | Get-Member -MemberType Property).Count | Should -Be 9
        }
        It 'id is not null or empty' {
            $SetPage1.ID | Should -Not -BeNullOrEmpty
            $SetPage2.ID | Should -Not -BeNullOrEmpty
            $SetPage3.ID | Should -Not -BeNullOrEmpty
            $SetPage4.ID | Should -Not -BeNullOrEmpty
            $SetPage5.ID | Should -Not -BeNullOrEmpty
            $SetPage6.ID | Should -Not -BeNullOrEmpty
            $SetPage7.ID | Should -Not -BeNullOrEmpty
            $SetPage8.ID | Should -Not -BeNullOrEmpty
            $SetPage9.ID | Should -Not -BeNullOrEmpty
        }
        It 'key has the specified value' {
            $SetPage1.Space.Key | Should -BeExactly $SpaceKey
            $SetPage2.Space.Key | Should -BeExactly $SpaceKey
            $SetPage3.Space.Key | Should -BeExactly $SpaceKey
            $SetPage4.Space.Key | Should -BeExactly $SpaceKey
            $SetPage5.Space.Key | Should -BeExactly $SpaceKey
            $SetPage6.Space.Key | Should -BeExactly $SpaceKey
            $SetPage7.Space.Key | Should -BeExactly $SpaceKey
            $SetPage8.Space.Key | Should -BeExactly $SpaceKey
            $SetPage9.Space.Key | Should -BeExactly $SpaceKey
            $AllChangedPages.Space.Key | Should -BeExactly (1..9 | ForEach-Object {$SpaceKey})
        }
        It 'title has the specified value' {
            $SetPage1.Title | Should -BeExactly $Page1.Title
            $SetPage2.Title | Should -BeExactly $Page2.Title
            $SetPage3.Title | Should -BeExactly $Page3.Title
            $SetPage4.Title | Should -BeExactly $Page4.Title
            $SetPage5.Title | Should -BeExactly $Page5.Title
            $SetPage6.Title | Should -BeExactly $NewTitle6
            $SetPage7.Title | Should -BeExactly $NewTitle7
            $SetPage8.Title | Should -BeExactly $Page8.Title
            $SetPage9.Version.Message | Should -BeExactly $NewVersionMessage9
        }
        It 'parentid has the specified value' {
            $SetPage1.Ancestors | Should -Not -BeNullOrEmpty
            $SetPage1.Ancestors.ID | Should -BeExactly $parentPage.ID
            $SetPage2.Ancestors | Should -BeNullOrEmpty
            $SetPage3.Ancestors | Should -Not -BeNullOrEmpty
            $SetPage3.Ancestors.ID | Should -BeExactly $ParentPage.ID
            $SetPage4.Ancestors | Should -Not -BeNullOrEmpty
            $SetPage4.Ancestors.ID | Should -BeExactly @($ParentPage.ID, $SetPage3.ID)
            $SetPage5.Ancestors | Should -Not -BeNullOrEmpty
            $SetPage5.Ancestors.ID | Should -BeExactly @($ParentPage.ID, $SetPage3.ID, $SetPage4.ID)
            $SetPage6.Ancestors | Should -BeNullOrEmpty
            $SetPage7.Ancestors | Should -BeNullOrEmpty
            $SetPage8.Ancestors | Should -BeNullOrEmpty
            $SetPage9.Ancestors | Should -BeNullOrEmpty
        }
        It 'body has the specified value' {
            $SetPage1.Body | Should -BeExactly $NewContent1
            $SetPage2.Body | Should -BeExactly $NewContent2
            $SetPage3.Body | Should -BeExactly $NewContent3
            $SetPage4.Body | Should -BeExactly $NewContent1
            $SetPage5.Body | Should -BeExactly $NewContent1
            $SetPage6.Body | Should -BeExactly $NewContent1
            $SetPage7.Body | Should -BeExactly $NewContent1
            $SetPage8.Body | Should -BeExactly ""
            $SetPage9.Body | Should -BeExactly $NewContent9
        }
        It 'version has the specified value' {
            $SetPage1.Version.Number | Should -BeExactly 2
            $SetPage2.Version.Number | Should -BeExactly 3
            $SetPage3.Version.Number | Should -BeExactly 4
            $SetPage4.Version.Number | Should -BeExactly 3
            $SetPage5.Version.Number | Should -BeExactly 3
            $SetPage6.Version.Number | Should -BeExactly 3
            $SetPage7.Version.Number | Should -BeExactly 3
            $SetPage8.Version.Number | Should -BeExactly 3
            $SetPage9.Version.Number | Should -BeExactly 3
        }
    }

    Context 'Get-ConfluenceChildPage' {
        # ARRANGE

        BeforeAll {

            # ACT
            $script:ChildPages = @()
            $script:DesendantPages = @()
            $lastChildPageError = $null
            for ($retry = 0; $retry -lt 12; $retry++) {
                try {
                    $script:ChildPages = (Get-ConfluenceSpace -SpaceKey "PESTER$SpaceID").Homepage | Get-ConfluenceChildPage -ErrorAction Stop
                    $script:DesendantPages = (Get-ConfluenceSpace -SpaceKey "PESTER$SpaceID").Homepage | Get-ConfluenceChildPage -Recurse -ErrorAction Stop
                    $lastChildPageError = $null
                    break
                }
                catch {
                    $lastChildPageError = $_
                    Start-Sleep -Seconds 5
                }
            }
            $script:lastChildPageError = $lastChildPageError

        }


        # ASSERT
        It 'returns the correct amount of results' {
            if ($script:lastChildPageError) {
                throw $script:lastChildPageError
            }
            $ChildPages.Count | Should -Be 2
            $DesendantPages.Count | Should -Be 4
        }
        It 'returns an object with specific properties' {
            if ($script:lastChildPageError) {
                throw $script:lastChildPageError
            }
            $ChildPages | Should -BeOfType [ConfluencePS.Page]
            $DesendantPages | Should -BeOfType [ConfluencePS.Page]
        }
    }

    Context 'Add-ConfluenceAttachment' {
        # ARRANGE
        BeforeAll {
            $script:originalWarningPreference = $WarningPreference
            $WarningPreference = 'SilentlyContinue'
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Page1 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Piped" -ErrorAction Stop
            $script:Page2 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Orphan" -ErrorAction Stop
            $script:Page3 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page from Object" -ErrorAction Stop
            $script:Page4 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page with Parent Object" -ErrorAction Stop
            $script:TextFile = Get-Item -Path "$PSScriptRoot/resources/Test.txt"
            $script:ImageFile = Get-Item -Path "$PSScriptRoot/resources/Test.png"
            $script:ExcelFile = Get-Item -Path "$PSScriptRoot/resources/Test.xlsx"

            # ACT
            $script:result1 = Add-ConfluenceAttachment -PageId $Page1.Id -FilePath $TextFile.FullName -ErrorAction Stop
            $script:result2 = Add-ConfluenceAttachment -PageId $Page1.Id -FilePath $ImageFile.FullName, $ExcelFile.FullName -ErrorAction Stop
            $script:result3 = Add-ConfluenceAttachment $Page2.Id -FilePath $TextFile.FullName -ErrorAction Stop
            $script:result4 = $Page2 | Add-ConfluenceAttachment -FilePath $ImageFile.FullName -ErrorAction Stop
            $script:result5 = $Page3 | Add-ConfluenceAttachment -FilePath $ImageFile.FullName, $ExcelFile.FullName -ErrorAction Stop
            $script:result6 = $TextFile, $ImageFile, $ExcelFile | Add-ConfluenceAttachment -PageId $Page4.Id -ErrorAction Stop

        }
        AfterAll {
            $WarningPreference = $script:originalWarningPreference
        }


        # ASSERT
        It 'attaches a file to a page' {
            $result1 | Should -Not -BeNullOrEmpty
            @($result1).Count | Should -Be 1
        }
        It 'attaches multiple files at a time' {
            $result2 | Should -Not -BeNullOrEmpty
            @($result2).Count | Should -Be 2
        }
        It 'can be used with positional parameters' {
            $result3 | Should -Not -BeNullOrEmpty
            @($result3).Count | Should -Be 1
        }
        It 'accepts the PageId over the pipeline' {
            $result4 | Should -Not -BeNullOrEmpty
            @($result4).Count | Should -Be 1
            $result5 | Should -Not -BeNullOrEmpty
            @($result5).Count | Should -Be 2
        }
        It 'accepts the FilePath over the pipeline' {
            $result6 | Should -Not -BeNullOrEmpty
            @($result6).Count | Should -Be 3
        }
        It 'returns an Attachment object' {
            $result1 | Should -BeOfType [ConfluencePS.Attachment]
            $result2 | Should -BeOfType [ConfluencePS.Attachment]
            $result3 | Should -BeOfType [ConfluencePS.Attachment]
            $result4 | Should -BeOfType [ConfluencePS.Attachment]
            $result5 | Should -BeOfType [ConfluencePS.Attachment]
            $result6 | Should -BeOfType [ConfluencePS.Attachment]

            $result1.Id | Should -Not -BeNullOrEmpty
            $result1.Title | Should -Not -BeNullOrEmpty
            $result1.Filename | Should -Not -BeNullOrEmpty
            $result1.MediaType | Should -Not -BeNullOrEmpty
            $result1.FileSize | Should -Not -BeNullOrEmpty
            $result1.SpaceKey | Should -Not -BeNullOrEmpty
            $result1.PageID | Should -Not -BeNullOrEmpty
            $result1.Version | Should -BeOfType [ConfluencePS.Version]
            $result1.Version.Number | Should -Be 1
            $result1.URL | Should -Not -BeNullOrEmpty
            ([uri]$result1.URL).AbsoluteUri | Should -Not -BeNullOrEmpty
        }
        It 'throws if the file does not exist' {
            { Add-ConfluenceAttachment -PageId $Page1.Id -FilePath "$PSScriptRoot/non-existing.file" } | Should -Throw
        }
        It 'throws if the item to attach is not a file' {
            { Add-ConfluenceAttachment -PageId $Page1.Id -FilePath "$PSScriptRoot" } | Should -Throw
        }
        It 'fails if the page already has the file attached' {
            { Add-ConfluenceAttachment -PageId $Page1.Id -FilePath $TextFile.FullName -ErrorAction Stop } | Should -Throw
            { Add-ConfluenceAttachment -PageId $Page1.Id -FilePath $TextFile.FullName -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Get-ConfluenceAttachment' {
        BeforeAll {
            # ARRANGE
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Page1 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Piped" -ErrorAction Stop
            $script:Page2 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Orphan" -ErrorAction Stop
            $script:Page3 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page from Object" -ErrorAction Stop
            $script:Page4 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page with Parent Object" -ErrorAction Stop

            # ACT
            $script:result1 = Get-ConfluenceAttachment -PageId $Page1.Id -ErrorAction Stop
            $script:result2 = Get-ConfluenceAttachment -PageId $Page2.Id, $Page3.Id -ErrorAction Stop
            $script:result3 = $Page3, $Page4 | Get-ConfluenceAttachment -ErrorAction Stop
            $script:result4 = $Page1, $Page2, $Page3, $Page4 | Get-ConfluenceAttachment -FileNameFilter "Test.xlsx" -ErrorAction Stop
            $script:result5 = $Page1, $Page2, $Page3, $Page4 | Get-ConfluenceAttachment -MediaTypeFilter "text/plain" -ErrorAction Stop

        }


        # ASSERT
        It 'retrieves the Attachments of a Page' {
            $result1 | Should -Not -BeNullOrEmpty
            $result1 | Should -BeOfType [ConfluencePS.Attachment]
            @($result1).Count | Should -Be 3
        }
        It 'retrieves the Attachments of multiple Pages' {
            $result2 | Should -Not -BeNullOrEmpty
            $result2 | Should -BeOfType [ConfluencePS.Attachment]
            @($result2).Count | Should -Be 4
        }
        It 'accepts the PageId over the Pipeline' {
            $result3 | Should -Not -BeNullOrEmpty
            $result3 | Should -BeOfType [ConfluencePS.Attachment]
            @($result3).Count | Should -Be 5
        }
        It 'filters the Attachments by FileName' {
            $result4 | Should -Not -BeNullOrEmpty
            $result4 | Should -BeOfType [ConfluencePS.Attachment]
            @($result4).Count | Should -Be 3
            $result4.Title | Should -Be ("Test.xlsx", "Test.xlsx", "Test.xlsx")
        }
        It 'filters the Attachments by MediaType' {
            $result5 | Should -Not -BeNullOrEmpty
            $result5 | Should -BeOfType [ConfluencePS.Attachment]
            @($result5).Count | Should -Be 3
            $result5.MediaType | Should -Be ("text/plain", "text/plain", "text/plain")
        }
    }

    Context 'Get-ConfluenceAttachmentFile' {
        # ARRANGE
        BeforeAll {
            Push-Location -Path "TestDrive:\"
            $null = New-Item -Path "TestDrive:\Folder1" -ItemType Directory
            $null = New-Item -Path "TestDrive:\Folder2" -ItemType Directory
            $null = New-Item -Path "TestDrive:\Folder3" -ItemType Directory
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Page1 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Piped" -ErrorAction Stop
            $script:Page2 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Orphan" -ErrorAction Stop
            $script:Attachments = $Page1, $Page2 | Get-ConfluenceAttachment -ErrorAction Stop

            # ACT
            $script:result1 = Get-ConfluenceAttachmentFile -Attachment $Attachments[0] -Path "TestDrive:\Folder1" -ErrorAction Stop
            $script:result2 = Get-ConfluenceAttachmentFile $Attachments[-1] -ErrorAction Stop
            $script:result3 = Get-ConfluenceAttachmentFile -Attachment $Attachments -Path "TestDrive:\Folder2" -ErrorAction Stop
            $script:result4 = $Attachments | Get-ConfluenceAttachmentFile -Path "TestDrive:\Folder3" -ErrorAction Stop

        }
        AfterAll {
            Pop-Location
        }


        # ASSERT
        It 'downloads an Attachment to a specific Path' {
            $result1 | Should -Be $true
            $files1 = Get-ChildItem -Path "TestDrive:\Folder1"
            @($files1).Count | Should -Be 1
            $files1.Name | Should -Be "$($Page1.Id)_$($Attachments[0].Title)"
        }
        It 'downloads an Attachment to the current Directory' {
            $result2 | Should -Be $true
            $files2 = Get-ChildItem -Path $pwd.Path -File
            @($files2).Count | Should -Be 1
            $files2.Name | Should -Be "$($Page2.Id)_$($Attachments[-1].Title)"
        }
        It 'downloads several Attachments to a specific Path' {
            $result3 | Should -Be ($true, $true, $true, $true, $true)
            $files3 = Get-ChildItem -Path "TestDrive:\Folder2"
            @($files3).Count | Should -Be 5
            ($files3.Name -match "^$($Page1.Id)").Count | Should -Be 3
            ($files3.Name -match "^$($Page2.Id)").Count | Should -Be 2
        }
        It 'accepts the Attachments over the pipeline' {
            $result4 | Should -Be ($true, $true, $true, $true, $true)
            $files4 = Get-ChildItem -Path "TestDrive:\Folder3"
            @($files4).Count | Should -Be 5
            ($files4.Name -match "^$($Page1.Id)").Count | Should -Be 3
            ($files4.Name -match "^$($Page2.Id)").Count | Should -Be 2
        }
        It 'throws if the specified Path does not exist' {
            { $Attachments | Get-ConfluenceAttachmentFile -Path "non-existing-path" } | Should -Throw
        }
    }

    Context 'Set-ConfluenceAttachment' {
        BeforeAll {
            # ARRANGE
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Page1 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Piped" -ErrorAction Stop
            $script:Attachment = $Page1 | Get-ConfluenceAttachment -FileNameFilter "Test.txt" -ErrorAction Stop
            $script:TextFile = Get-Item -Path "$PSScriptRoot/resources/Test.txt"

            # ACT
            $script:result1 = Set-ConfluenceAttachment -Attachment $Attachment -FilePath $TextFile.FullName -ErrorAction Stop
            $script:result2 = Set-ConfluenceAttachment $Attachment -FilePath $TextFile.FullName -ErrorAction Stop
            $script:result3 = $Attachment | Set-ConfluenceAttachment -FilePath $TextFile.FullName -ErrorAction Stop

        }


        # ASSERT
        It 'updates an Attachment' {
            $result1 | Should -Not -BeNullOrEmpty
            @($result1).Count | Should -Be 1
            $result1.Version.Number | Should -Be 2
        }
        It 'can be used with positional parameters' {
            $result2 | Should -Not -BeNullOrEmpty
            @($result2).Count | Should -Be 1
            $result2.Version.Number | Should -Be 3
        }
        It 'accepts the Attachment over the pipeline' {
            $result3 | Should -Not -BeNullOrEmpty
            @($result3).Count | Should -Be 1
            $result3.Version.Number | Should -Be 4
        }
        It 'returns an Attachment object' {
            $result1 | Should -BeOfType [ConfluencePS.Attachment]
            $result2 | Should -BeOfType [ConfluencePS.Attachment]
            $result3 | Should -BeOfType [ConfluencePS.Attachment]

            $result1.Id | Should -Not -BeNullOrEmpty
            $result1.Title | Should -Not -BeNullOrEmpty
            $result1.Filename | Should -Not -BeNullOrEmpty
            $result1.MediaType | Should -Not -BeNullOrEmpty
            $result1.FileSize | Should -Not -BeNullOrEmpty
            $result1.SpaceKey | Should -Not -BeNullOrEmpty
            $result1.PageID | Should -Not -BeNullOrEmpty
            $result1.URL | Should -Not -BeNullOrEmpty
            ([uri]$result1.URL).AbsoluteUri | Should -Not -BeNullOrEmpty
        }
        It 'throws if the file does not exist' {
            { Set-ConfluenceAttachment -Attachment $Attachment -FilePath "non-existing.file" } | Should -Throw
        }
    }

    Context 'Remove-ConfluenceAttachment' {
        # ARRANGE
        BeforeAll {
            $script:originalWarningPreference = $WarningPreference
            $WarningPreference = 'SilentlyContinue'
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Page1 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Piped" -ErrorAction Stop
            $script:Page2 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Orphan" -ErrorAction Stop
            $script:Page3 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page from Object" -ErrorAction Stop
            $script:preAttachments1 = Get-ConfluenceAttachment -PageId $Page1.Id -ErrorAction Stop
            $script:preAttachments2 = Get-ConfluenceAttachment -PageId $Page2.Id -ErrorAction Stop
            $script:preAttachments3 = Get-ConfluenceAttachment -PageId $Page3.Id -ErrorAction Stop

            # ACT
            Remove-ConfluenceAttachment -Attachment $preAttachments1[0] -ErrorAction Stop
            Remove-ConfluenceAttachment $preAttachments2 -ErrorAction Stop
            $preAttachments3 | Remove-ConfluenceAttachment -ErrorAction Stop

            $script:postAttachments1 = Get-ConfluenceAttachment -PageId $Page1.Id -ErrorAction SilentlyContinue
            $script:postAttachments2 = Get-ConfluenceAttachment -PageId $Page2.Id -ErrorAction SilentlyContinue
            $script:postAttachments3 = Get-ConfluenceAttachment -PageId $Page3.Id -ErrorAction SilentlyContinue

        }
        AfterAll {
            $WarningPreference = $script:originalWarningPreference
        }


        # ASSERT
        It 'removes an Attachment' {
            @($postAttachments1).Count | Should -Be (@($preAttachments1).Count - 1)
        }
        It 'removes several Attachments' {
            $postAttachments2 | Should -BeNullOrEmpty
        }
        It 'accepts Attachments over the pipeline' {
            $postAttachments3 | Should -BeNullOrEmpty
        }
        It 'fails to delete a non exisiting Attachment' {
            { Remove-ConfluenceAttachment -Attachment $preAttachments1 -ErrorAction Stop } | Should -Throw
            { Remove-ConfluenceAttachment -Attachment $preAttachments1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Remove-ConfluenceLabel' {
        BeforeAll {
            # ARRANGE
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Label1 = "pesterc"
            $script:Page1 = Get-ConfluencePage -Title 'Pester New Page Piped' -SpaceKey $SpaceKey -ErrorAction Stop
            $script:Page2 = (Get-ConfluenceSpace -SpaceKey $SpaceKey).Homepage

            # ACT
            $script:Before1 = $Page1 | Get-ConfluenceLabel -ErrorAction SilentlyContinue
            $script:Before2 = $Page2 | Get-ConfluenceLabel -ErrorAction SilentlyContinue
            Remove-ConfluenceLabel -Label $Label1 -PageID $Page1.ID -ErrorAction SilentlyContinue
            $Page2 | Remove-ConfluenceLabel -ErrorAction SilentlyContinue
            $script:After1 = $Page1 | Get-ConfluenceLabel -ErrorAction SilentlyContinue
            $script:After2 = $Page2 | Get-ConfluenceLabel -ErrorAction SilentlyContinue

        }


        # ASSERT
        It 'page has one label less' {
            @($Before1.Labels).Count - @($After1.Labels).Count | Should -Be 1
            ($After1.Labels).Name -notcontains $Label1 | Should -Be $true
        }
        It 'page does not have labels' {
            @($Before2.Labels).Count | Should -Be 2
            $After2.Labels | Should -BeNullOrEmpty
        }
    }

    Context 'Remove-ConfluencePage' {
        BeforeAll {
            # ARRANGE
            $script:SpaceKey = "PESTER$SpaceID"
            $script:Title = "Pester New Page Orphan"
            $script:PageID = Get-ConfluencePage -Title $Title -SpaceKey $SpaceKey -ErrorAction Stop
            $script:Before = Get-ConfluencePage -SpaceKey $SpaceKey -ErrorAction Stop

            # ACT
            Remove-ConfluencePage -PageID $PageID.ID -ErrorAction SilentlyContinue
            Get-ConfluencePage -SpaceKey $SpaceKey | Remove-ConfluencePage -ErrorAction SilentlyContinue
            $script:After = Get-ConfluencePage -SpaceKey $SpaceKey -ErrorAction SilentlyContinue

        }


        # ASSERT
        It 'has pages before' {
            $Before | Should -Not -BeNullOrEmpty
        }
        It 'space does not have pages after' {
            $After | Should -BeNullOrEmpty
        }
    }

    Context 'Remove-ConfluenceSpace' {
        BeforeAll {
            # We don't want warnings on the screen
            $script:originalWarningPreference = $WarningPreference
            $WarningPreference = 'SilentlyContinue'
        }
        AfterAll {
            $WarningPreference = $script:originalWarningPreference
        }

        BeforeAll {

            # ACT
        Remove-ConfluenceSpace -Key "PESTER$SpaceID" -Force -ErrorAction Stop
        "PESTER1$SpaceID" | Remove-ConfluenceSpace -Force -ErrorAction Stop

        }


        # ASSERT
        It 'space is no longer available' {
            Start-Sleep -Seconds 20
            { Get-ConfluenceSpace -Key "PESTER$SpaceID" -ErrorAction Stop } | Should -Throw
            { Get-ConfluenceSpace -Key "PESTER1$SpaceID" -ErrorAction Stop } | Should -Throw
        }
    }
}
