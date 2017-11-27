# Pester integration/acceptance tests to use during module development. Dave Wyatt's five-part series:
# http://blogs.technet.com/b/heyscriptingguy/archive/2015/12/14/what-is-pester-and-why-should-i-care.aspx

Describe 'Load Module' {
    # ARRANGE
    Remove-Module ConfluencePS -Force -ErrorAction SilentlyContinue

    # ACT
    Import-Module "$PSScriptRoot\..\ConfluencePS" -Force -ErrorAction Stop

    #ASSERT
    It "imports the module" {
        Get-Module ConfluencePS | Should BeOfType [PSModuleInfo]
        Remove-Module ConfluencePS -ErrorAction Stop
    }

    It "imports the module with custom prefix" {
        Import-Module "$PSScriptRoot\..\ConfluencePS" -Prefix "Wiki" -Force -ErrorAction Stop
        (Get-Command -Module ConfluencePS).Name | ForEach-Object {
            $_ -match "\-Wiki" | Should Be $true
        }
        # Remove-Module ConfluencePS -ErrorAction Stop
    }
}

Import-Module "$PSScriptRoot\..\ConfluencePS" -Force -ErrorAction Stop
InModuleScope ConfluencePS {

    Describe 'Set-ConfluenceInfo' {
        # ARRANGE
        # Could be a long one-liner, but breaking down for readability
        $Pass = ConvertTo-SecureString -AsPlainText -Force -String $env:WikiPass
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($env:WikiUser, $Pass)

        # ACT
        Set-ConfluenceInfo -BaseURI $env:WikiURI -Credential $Cred

        # ASSERT
        It 'credentials are stored' {
            $global:PSDefaultParameterValues["Get-ConfluencePage:Credential"] | Should BeOfType [PSCredential]
            #TODO: extend this
        }
        It 'url is stored' {
            $global:PSDefaultParameterValues["Get-ConfluencePage:ApiURi"] | Should BeOfType [String]
            $global:PSDefaultParameterValues["Get-ConfluencePage:ApiURi"] -match "^https?://.*\/rest\/api$" | Should Be $true
        }
    }

    Describe 'New-ConfluenceSpace' {
        # ARRANGE
        # We don't want warnings on the screen
        $WarningPreference = 'SilentlyContinue'

        # Set up test values:
        $Key1 = "PESTER"
        $Key2 = "PESTER1"
        $Name1 = "Pester Test Space"
        $Name2 = "Second Pester Space"
        $Description = "<p>A nice description</p>"
        $Icon = [ConfluencePS.Icon] @{
            path = "/images/logo/default-space-logo-256.png"
            width = 48
            height = 48
            isDefault = $False
        }
        $Space1 = [ConfluencePS.Space]@{
            Key = $Key1
            Name = $Name1
            Description = $Description
        }
        # $Space3
        # Ensure the space doesn't already exist
        Get-ConfluenceSpace -Key $Key1 -ErrorAction SilentlyContinue #TODO

        # ACT
        $NewSpace1 = $Space1 | New-ConfluenceSpace -ErrorAction Stop
        $NewSpace2 = New-ConfluenceSpace -Key $Key2 -Name $Name2 -Description $Description -ErrorAction Stop

        # ASSERT
        It 'returns an object with specific properties' {
            $NewSpace1 | Should BeOfType [ConfluencePS.Space]
            $NewSpace2 | Should BeOfType [ConfluencePS.Space]
            ($NewSpace1 | Get-Member -MemberType Property).Count | Should Be 7
            ($NewSpace2 | Get-Member -MemberType Property).Count | Should Be 7
        }
        It 'ID is integer' {
            $NewSpace1.ID | Should BeOfType [Int]
            $NewSpace2.ID | Should BeOfType [Int]
        }
        It 'key matches the specified value' {
            $NewSpace1.Key | Should BeOfType [String]
            $NewSpace1.Key | Should BeExactly $Key1
            $NewSpace2.Key | Should BeOfType [String]
            $NewSpace2.Key | Should BeExactly $Key2
        }
        It 'name matches the specified value' {
            $NewSpace1.Name | Should BeOfType [String]
            $NewSpace1.Name | Should BeExactly $Name1
            $NewSpace2.Name | Should BeOfType [String]
            $NewSpace2.Name | Should BeExactly $Name2
        }
        It 'homepage is ConfluencePS.Page' {
            $NewSpace1.Homepage | Should BeOfType [ConfluencePS.Page]
            $NewSpace2.Homepage | Should BeOfType [ConfluencePS.Page]
        }
        It 'homepage matches the specified value' {
            $NewSpace1.Homepage.Title | Should BeExactly "$Name1 Home"
            $NewSpace2.Homepage.Title | Should BeExactly "$Name2 Home"
        }
    }

    Describe 'Get-ConfluenceSpace' {
        # ARRANGE
        # Set up test values:
        $Key1 = "PESTER"
        $Key2 = "PESTER1"
        $Name1 = "Pester Test Space"
        $Name2 = "Second Pester Space"
        $Description = "<p>A nice description</p>"

        # ACT
        $AllSpaces = Get-ConfluenceSpace
        $GetSpace1 = Get-ConfluenceSpace -Key $Key1
        $GetSpace2 = Get-ConfluenceSpace | Where-Object {$_.Name -like '*ter test sp*'}
        $GetSpace3 = Get-ConfluenceSpace @($Key1, $Key2)

        # ASSERT
        It 'returns an object with specific properties' {
            $AllSpaces | Should BeOfType [ConfluencePS.Space]
            $GetSpace1 | Should BeOfType [ConfluencePS.Space]
            $GetSpace2 | Should BeOfType [ConfluencePS.Space]
            $GetSpace3 | Should BeOfType [ConfluencePS.Space]
            ($GetSpace1 | Get-Member -MemberType Property).Count | Should Be 7
            ($GetSpace2 | Get-Member -MemberType Property).Count | Should Be 7
            ($GetSpace3 | Get-Member -MemberType Property).Count | Should Be 7
        }
        It 'has the correct number of results' {
            $AllSpaces.Count | Should BeGreaterThan 2
            $GetSpace1.Count | Should Be 1
            $GetSpace2.Count | Should Be 1
            $GetSpace3.Count | Should Be 2
        }
        It 'id is integer' {
            $GetSpace1.ID | Should BeOfType [Int]
            $GetSpace2.ID | Should BeOfType [Int]
            $GetSpace3.ID | Should BeOfType [Int]
        }
        It 'key is string' {
            $GetSpace1.Key | Should BeOfType [String]
            $GetSpace2.Key | Should BeOfType [String]
            $GetSpace3.Key | Should BeOfType [String]
        }
        It 'key matches the specified value' {
            $GetSpace1.Key | Should BeExactly $Key1
            $GetSpace2.Key | Should BeExactly $Key1
            $GetSpace3.Key | Should BeExactly @($Key1, $Key2)
        }
        It 'name is string' {
            $GetSpace1.Name | Should BeOfType [String]
            $GetSpace2.Name | Should BeOfType [String]
            $GetSpace3.Name | Should BeOfType [String]
        }
        It 'name matches the specified value' {
            $GetSpace1.Name | Should BeExactly $Name1
            $GetSpace2.Name | Should BeExactly $Name1
            $GetSpace3.Name | Should BeExactly @($Name1, $Name2)
        }
        It 'description is string' {
            $GetSpace1.Description | Should BeOfType [String]
            $GetSpace2.Description | Should BeOfType [String]
            $GetSpace3.Description | Should BeOfType [String]
        }
        It 'description matches the specified value' {
            $GetSpace1.Description | Should BeExactly $Description
            $GetSpace2.Description | Should BeExactly $Description
            # $GetSpace3.Description | Should BeExactly $Description
        }
        It 'type is string' {
            $GetSpace1.Type | Should BeOfType [String]
            $GetSpace2.Type | Should BeOfType [String]
            $GetSpace3.Type | Should BeOfType [String]
        }
        It 'icon is confluenceps.icon' {
            $GetSpace1.Icon | Should BeOfType [ConfluencePS.Icon]
            $GetSpace2.Icon | Should BeOfType [ConfluencePS.Icon]
            $GetSpace3.Icon | Should BeOfType [ConfluencePS.Icon]
        }
        It 'homepage is ConfluencePS.Page' {
            $GetSpace1.Homepage | Should BeOfType [ConfluencePS.Page]
            $GetSpace2.Homepage | Should BeOfType [ConfluencePS.Page]
            $GetSpace3.Homepage | Should BeOfType [ConfluencePS.Page]
        }
        It 'homepage matches the specified value' {
            $GetSpace1.Homepage.Title | Should BeExactly "$($GetSpace1.Name) Home"
            $GetSpace2.Homepage.Title | Should BeExactly "$($GetSpace2.Name) Home"
            $GetSpace3.Homepage.Title | Should BeExactly @("$Name1 Home", "$Name2 Home")
        }
        It 'has a meaningful string value' {
            $GetSpace1.Icon.ToString() | Should Be $GetSpace1.Icon.Path
        }
    }

    Describe 'ConvertTo-ConfluenceStorageFormat' {
        # ARRANGE
        $InputString = "Hi Pester!"
        $OutputString = "<p>Hi Pester!</p>"

        # ACT
        $result1 = $inputString | ConvertTo-ConfluenceStorageFormat
        $result2 = ConvertTo-ConfluenceStorageFormat -Content $inputString
        $result3 = ConvertTo-ConfluenceStorageFormat -Content $inputString, $inputString

        # ASSERT
        It 'returns a string' {
            $result1 | Should BeOfType [String]
            $result2 | Should BeOfType [String]
            $result3 | Should BeOfType [String]
        }
        It 'output matches the expected string' {
            $result1 | Should BeExactly $outputString
            $result2 | Should BeExactly $outputString
            $result3 | Should BeExactly @($outputString, $outputString)
        }
    }

    Describe 'New-ConfluencePage' {
        <# TODO:
            * Title may not be empty
            * Space may not be empty when no parent is provided
        #>

        # ARRANGE
        $SpaceKey = "PESTER"
        $parentPage = Get-ConfluencePage -Title "Pester Test Space Home" -SpaceKey "PESTER" -ErrorAction Stop
        $Title1 = "Pester New Page Piped"
        $Title2 = "Pester New Page Orphan"
        $Title3 = "Pester New Page from Object"
        $Title4 = "Pester New Page with Parent Object"
        $RawContent = "Hi Pester!"
        $FormattedContent = "<p>Hi Pester!</p>"
        $pageObject = New-Object -TypeName ConfluencePS.Page -Property @{
            Title = $Title3
            Body = $FormattedContent
            Ancestors = @($parentPage)
            Space = New-Object -TypeName ConfluencePS.Space -Property @{key = $SpaceKey}
        }

        # ACT
        $NewPage1 = $Title1 | New-ConfluencePage -ParentID $parentPage.ID -ErrorAction Stop
        $NewPage2 = New-ConfluencePage -Title $Title2 -SpaceKey $SpaceKey -Body $RawContent -Convert -ErrorAction Stop
        $NewPage3 = $pageObject | New-ConfluencePage -ErrorAction Stop
        $NewPage4 = New-ConfluencePage -Title $Title4 -Parent $parentPage -ErrorAction Stop

        # ASSERT
        It 'returns an object with specific properties' {
            $NewPage1 | Should BeOfType [ConfluencePS.Page]
            $NewPage2 | Should BeOfType [ConfluencePS.Page]
            $NewPage3 | Should BeOfType [ConfluencePS.Page]
            $NewPage4 | Should BeOfType [ConfluencePS.Page]
            ($NewPage1 | Get-Member -MemberType Property).Count | Should Be 9
            ($NewPage2 | Get-Member -MemberType Property).Count | Should Be 9
            ($NewPage3 | Get-Member -MemberType Property).Count | Should Be 9
            ($NewPage4 | Get-Member -MemberType Property).Count | Should Be 9
        }
        It 'spaceid is integer' {
            $NewPage1.ID | Should BeOfType [Int]
            $NewPage2.ID | Should BeOfType [Int]
            $NewPage3.ID | Should BeOfType [Int]
            $NewPage4.ID | Should BeOfType [Int]
        }
        It 'key matches the specified value' {
            $NewPage1.Space.Key | Should BeExactly $SpaceKey
            $NewPage2.Space.Key | Should BeExactly $SpaceKey
            $NewPage3.Space.Key | Should BeExactly $SpaceKey
            $NewPage4.Space.Key | Should BeExactly $SpaceKey
        }
        It 'title matches the specified value' {
            $NewPage1.Title | Should BeExactly $Title1
            $NewPage2.Title | Should BeExactly $Title2
            $NewPage3.Title | Should BeExactly $Title3
            $NewPage4.Title | Should BeExactly $Title4
        }
        It 'parentid is integer' {
            $NewPage1.Ancestors.ID | Should BeOfType [Int]
            $NewPage3.Ancestors.ID | Should BeOfType [Int]
            $NewPage4.Ancestors.ID | Should BeOfType [Int]
        }
        It 'parentid matches the specified value' {
            $NewPage1.Ancestors.ID | Should BeExactly $parentPage.ID
            $NewPage3.Ancestors.ID | Should BeExactly $parentPage.ID
            $NewPage4.Ancestors.ID | Should BeExactly $parentPage.ID
        }
        It 'parentid is empty' {
            $NewPage2.Ancestors | Should BeNullOrEmpty
        }
        It 'url is string' {
            $NewPage1.URL | Should BeOfType [String]
            $NewPage1.URL | Should Not BeNullOrEmpty
            $NewPage2.URL | Should BeOfType [String]
            $NewPage2.URL | Should Not BeNullOrEmpty
            $NewPage3.URL | Should BeOfType [String]
            $NewPage3.URL | Should Not BeNullOrEmpty
            $NewPage4.URL | Should BeOfType [String]
            $NewPage4.URL | Should Not BeNullOrEmpty
        }
        It 'shorturl is string' {
            $NewPage1.ShortURL | Should BeOfType [String]
            $NewPage1.ShortURL | Should Not BeNullOrEmpty
            $NewPage2.ShortURL | Should BeOfType [String]
            $NewPage2.ShortURL | Should Not BeNullOrEmpty
            $NewPage3.ShortURL | Should BeOfType [String]
            $NewPage3.ShortURL | Should Not BeNullOrEmpty
            $NewPage4.ShortURL | Should BeOfType [String]
            $NewPage4.ShortURL | Should Not BeNullOrEmpty
        }
    }

    Describe 'Get-ConfluencePage' {
        # ARRANGE
        $SpaceKey = "PESTER"
        $Title1 = "Pester New Page from Object"
        $Title2 = "Pester New Page Orphan"
        $Title3 = "Pester Test Space Home"
        $Title4 = "orphan"
        $Title5 = "*orphan"
        $Query = "space=PESTER and title~`"*Object`""
        $Content = "<p>Hi Pester!</p>"
        (Get-ConfluenceSpace -SpaceKey $SpaceKey).Homepage | Add-ConfluenceLabel -Label "important" -ErrorAction Stop
        Start-Sleep -Seconds 20 # Delay to allow DB index to update

        # ACT
        $GetTitle1   = Get-ConfluencePage -Title $Title1 -SpaceKey $SpaceKey -PageSize 200 -ErrorAction SilentlyContinue
        $GetTitle2   = Get-ConfluencePage -Title $Title2 -SpaceKey $SpaceKey -ErrorAction SilentlyContinue
        $GetPartial  = Get-ConfluencePage -Title $Title4 -SpaceKey $SpaceKey -ErrorAction SilentlyContinue
        $GetWildcard = Get-ConfluencePage -Title $Title5 -SpaceKey $SpaceKey -ErrorAction SilentlyContinue
        $GetID1 = Get-ConfluencePage -PageID $GetTitle1.ID -ErrorAction SilentlyContinue
        $GetID2 = Get-ConfluencePage -PageID $GetTitle2.ID -ErrorAction SilentlyContinue
        $GetKeys = Get-ConfluencePage -SpaceKey $SpaceKey | Sort ID -ErrorAction SilentlyContinue
        $GetByLabel = Get-ConfluencePage -Label "important" -ErrorAction SilentlyContinue
        $GetByQuery = Get-ConfluencePage -Query $query -ErrorAction SilentlyContinue
        $GetSpacePage = Get-ConfluencePage -Space (Get-ConfluenceSpace -SpaceKey $SpaceKey) -ErrorAction SilentlyContinue
        $GetSpacePiped = Get-ConfluenceSpace -SpaceKey $SpaceKey | Get-ConfluencePage -ErrorAction SilentlyContinue

        # ASSERT
        It 'returns the correct amount of results' {
            $GetTitle1.Count | Should Be 1
            $GetTitle2.Count | Should Be 1
            $GetPartial.Count | Should Be 0
            $GetWildcard.Count | Should Be 0
            $GetID1.Count | Should Be 1
            $GetID2.Count | Should Be 1
            $GetKeys.Count | Should Be 5
            $GetByLabel.Count | Should Be 1
            $GetSpacePage.Count | Should Be 5
            $GetByQuery.Count | Should Be 2
            $GetSpacePiped.Count | Should Be 5
        }
        It 'returns an object with specific properties' {
            $GetTitle1 | Should BeOfType [ConfluencePS.Page]
            $GetTitle2 | Should BeOfType [ConfluencePS.Page]
            $GetID1 | Should BeOfType [ConfluencePS.Page]
            $GetID2 | Should BeOfType [ConfluencePS.Page]
            $GetKeys | Should BeOfType [ConfluencePS.Page]
            $GetByLabel | Should BeOfType [ConfluencePS.Page]
            $GetByQuery | Should BeOfType [ConfluencePS.Page]
            ($GetTitle1 | Get-Member -MemberType Property).Count | Should Be 9
            ($GetTitle2 | Get-Member -MemberType Property).Count | Should Be 9
            ($GetID1 | Get-Member -MemberType Property).Count | Should Be 9
            ($GetID2 | Get-Member -MemberType Property).Count | Should Be 9
            ($GetKeys | Get-Member -MemberType Property).Count | Should Be 9
            ($GetByLabel | Get-Member -MemberType Property).Count | Should Be 9
            ($GetByQuery | Get-Member -MemberType Property).Count | Should Be 9
        }
        It 'id is integer' {
            $GetTitle1.ID | Should BeOfType [Int]
            $GetTitle2.ID | Should BeOfType [Int]
            $GetID1.ID | Should BeOfType [Int]
            $GetID2.ID | Should BeOfType [Int]
            $GetKeys.ID | Should BeOfType [Int]
            $GetByLabel.ID | Should BeOfType [Int]
            $GetByQuery.ID | Should BeOfType [Int]
        }
        It 'id matches the specified value' {
            $GetID1.ID | Should Be $GetTitle1.ID
            $GetID2.ID | Should Be $GetTitle2.ID
            $GetKeys.ID -contains $GetID1.ID | Should Be $true
            $GetKeys.ID -contains $GetID2.ID | Should Be $true
        }
        It 'title matches the specified value' {
            $GetTitle1.Title | Should BeExactly $Title1
            $GetTitle2.Title | Should BeExactly $Title2
            $GetID1.Title | Should BeExactly $Title1
            $GetID2.Title | Should BeExactly $Title2
            $GetKeys.Title -contains $Title3 | Should Be $true
            $GetKeys.Title -contains $GetID1.Title | Should Be $true
            $GetByLabel.Title -like "PESTER * Home" | Should Be $true
        }
        It 'space matches the specified value' {
            $GetTitle1.Space.Key | Should BeExactly $SpaceKey
            $GetTitle2.Space.Key | Should BeExactly $SpaceKey
            $GetID1.Space.Key | Should BeExactly $SpaceKey
            $GetID2.Space.Key | Should BeExactly $SpaceKey
            $GetKeys.Space.Key -contains $SpaceKey | Should Be $true
            $GetByLabel.Space.Key | Should BeExactly $SpaceKey
        }
        It 'version matches the specified value' {
            $GetTitle2.Version.Number | Should Be 1
            $GetID2.Version.Number | Should Be 1
            $GetKeys.Version.Number -contains 1 | Should Be $true
            $GetByLabel.Version.Number | Should Be 1
        }
        It 'body matches the specified value' {
            $GetTitle1.Body | Should BeExactly $Content
            $GetID1.Body | Should BeExactly $Content
            $GetKeys.Body -contains $Content | Should Be $true
        }
        It 'url is string' {
            $GetTitle1.URL | Should BeOfType [String]
            $GetTitle1.URL | Should Not BeNullOrEmpty
            $GetTitle2.URL | Should BeOfType [String]
            $GetTitle2.URL | Should Not BeNullOrEmpty
            $GetID1.URL | Should BeOfType [String]
            $GetID1.URL | Should Not BeNullOrEmpty
            $GetID2.URL | Should BeOfType [String]
            $GetID2.URL | Should Not BeNullOrEmpty
            $GetKeys.URL | Should BeOfType [String]
            $GetKeys.URL | Should Not BeNullOrEmpty
            $GetByLabel.URL | Should BeOfType [String]
            $GetByLabel.URL | Should BeOfType [String]
            $GetByQuery.URL | Should Not BeNullOrEmpty
            $GetByQuery.URL | Should Not BeNullOrEmpty
        }
        It 'shorturl is string' {
            $GetTitle1.ShortURL | Should BeOfType [String]
            $GetTitle1.ShortURL | Should Not BeNullOrEmpty
            $GetTitle2.ShortURL | Should BeOfType [String]
            $GetTitle2.ShortURL | Should Not BeNullOrEmpty
            $GetID1.ShortURL | Should BeOfType [String]
            $GetID1.ShortURL | Should Not BeNullOrEmpty
            $GetID2.ShortURL | Should BeOfType [String]
            $GetID2.ShortURL | Should Not BeNullOrEmpty
            $GetKeys.ShortURL | Should BeOfType [String]
            $GetKeys.ShortURL | Should Not BeNullOrEmpty
            $GetByLabel.ShortURL | Should BeOfType [String]
            $GetByLabel.ShortURL | Should BeOfType [String]
            $GetByQuery.ShortURL | Should Not BeNullOrEmpty
            $GetByQuery.ShortURL | Should Not BeNullOrEmpty
        }
        It 'has a meaningful string value' {
            $GetTitle1.Version.ToString() | Should Be $GetTitle1.Version.Number.ToString()
            $GetTitle1.Version.By.ToString() | Should Be $GetTitle1.Version.By.UserName
            $GetTitle1.Space.ToString() | Should Be ("[{0}] {1}" -f $GetTitle1.Space.Key, $GetTitle1.Space.Name)
        }
    }

    Describe 'Add-ConfluenceLabel' {
        # ARRANGE
        $SpaceKey = "PESTER"
        $Page1 = Get-ConfluencePage -Title "Pester New Page Piped" -SpaceKey $SpaceKey -ErrorAction Stop
        $Label1 = "pestera", "pesterb", "pesterc"
        $Label2 = "pesterall"
        $PartialLabel = "pest"

        # ACT
        $NewLabel1 = Add-ConfluenceLabel -Label $Label1 -PageID $Page1.ID -ErrorAction SilentlyContinue
        $NewLabel2 = Get-ConfluencePage -SpaceKey $SpaceKey | Add-ConfluenceLabel -Label $Label2 -ErrorAction SilentlyContinue
        $NewLabel3 = (Get-ConfluenceSpace -SpaceKey $SpaceKey).Homepage | Get-ConfluenceLabel | Add-ConfluenceLabel -PageID $Page1.ID -ErrorAction SilentlyContinue

        # ASSERT
        It 'returns the correct amount of results' {
            ($NewLabel1.Labels).Count | Should Be 3
            ($NewLabel2.Labels).Count | Should Be 9
            ($NewLabel3.Labels).Count | Should Be 5
        }
        It 'returns an object with specific properties' {
            $NewLabel1 | Should BeOfType [ConfluencePS.ContentLabelSet]
            $NewLabel1.Page | Should BeOfType [ConfluencePS.Page]
            $NewLabel1.Labels | Should BeOfType [ConfluencePS.Label]
            ($NewLabel1.Labels | Get-Member -MemberType Property).Count | Should Be 3
            $NewLabel2 | Should BeOfType [ConfluencePS.ContentLabelSet]
            $NewLabel2.Page | Should BeOfType [ConfluencePS.Page]
            $NewLabel2.Labels | Should BeOfType [ConfluencePS.Label]
            ($NewLabel2.Labels | Get-Member -MemberType Property).Count | Should Be 3
            $NewLabel3 | Should BeOfType [ConfluencePS.ContentLabelSet]
            $NewLabel3.Page | Should BeOfType [ConfluencePS.Page]
            $NewLabel3.Labels | Should BeOfType [ConfluencePS.Label]
            ($NewLabel3.Labels | Get-Member -MemberType Property).Count | Should Be 3
        }
        It 'label matches the specified value' {
            $NewLabel1.Labels.Name | Should BeExactly $Label1
            $NewLabel2.Labels.Name -contains $Label2 | Should Be $true
            ($NewLabel3.Labels.Name -match $PartialLabel | Sort) | Should Be (($Label1 + $Label2) | Sort )
        }
        It 'labelid is not null or empty' {
            $NewLabel1.Labels.ID | Should Not BeNullOrEmpty
            $NewLabel2.Labels.ID | Should Not BeNullOrEmpty
            $NewLabel3.Labels.ID | Should Not BeNullOrEmpty
        }
    }

    Describe 'Set-ConfluenceLabel' {
        # ARRANGE
        $SpaceKey = "PESTER"
        $Title1 = "Pester New Page from Object"
        $Label1 = @("overwrite", "remove")
        $Label2 = "final"
        $Page1 = Get-ConfluencePage -Title $Title1 -SpaceKey $SpaceKey -ErrorAction SilentlyContinue
        $Before1 = $Page1 | Get-ConfluenceLabel

        # ACT
        $After1 = Set-ConfluenceLabel -PageID $Page1.ID -Label $Label1 -ErrorAction Stop
        $After2 = $Page1 | Set-ConfluenceLabel -Label $Label2 -ErrorAction Stop

        # ASSERT
        It 'returns the correct amount of results' {
            ($After1.Labels).Count | Should Be 2
            ($After2.Labels).Count | Should Be 1
        }
        It 'returns an object with specific properties' {
            $After1 | Should BeOfType [ConfluencePS.ContentLabelSet]
            $After1.Page | Should BeOfType [ConfluencePS.Page]
            $After1.Labels | Should BeOfType [ConfluencePS.Label]
            ($After1 | Get-Member -MemberType Property).Count | Should Be 2
            $After2 | Should BeOfType [ConfluencePS.ContentLabelSet]
            $After2.Page | Should BeOfType [ConfluencePS.Page]
            $After2.Labels | Should BeOfType [ConfluencePS.Label]
            ($After2 | Get-Member -MemberType Property).Count | Should Be 2
        }
        It 'label matches the specified value' {
            $After1.Labels.Name | Should BeExactly $Label1
            $After2.Labels.Name | Should BeExactly $Label2
            $After1.Labels.Name -notcontains $Before.Labels.Name | Should Be $true
            $After2.Labels.Name -notcontains $Before.Labels.Name | Should Be $true
        }
        It 'labelid is not null or empty' {
            $After1.Labels.ID | Should Not BeNullOrEmpty
            $After2.Labels.ID | Should Not BeNullOrEmpty
        }
    }

    Describe 'Get-ConfluenceLabel' {
        # ARRANGE
        $SpaceKey = "PESTER"
        $patternLabel1 = "pester[abc]$"
        $patternLabel2 = "(pest|import|fin)"
        $Page = Get-ConfluencePage -Title "Pester New Page Piped" -SpaceKey $SpaceKey

        # ACT
        $GetPageLabel1 = Get-ConfluenceLabel -PageID $Page.ID
        $GetPageLabel2 = Get-ConfluencePage -SpaceKey $SpaceKey | Get-ConfluenceLabel

        # ASSERT
        It 'returns the correct amount of results' {
            ($GetPageLabel1.Labels).Count | Should Be 5
            ($GetPageLabel2.Labels).Count | Should Be 10
            ($GetPageLabel2.Labels | Where {$_.Name -match $patternLabel1}).Count | Should Be 3
        }
        It 'returns an object with specific properties' {
            $GetPageLabel1 | Should BeOfType [ConfluencePS.ContentLabelSet]
            $GetPageLabel1.Page | Should BeOfType [ConfluencePS.Page]
            $GetPageLabel1.Labels | Should BeOfType [ConfluencePS.Label]
            $GetPageLabel2 | Should BeOfType [ConfluencePS.ContentLabelSet]
            $GetPageLabel2.Page | Should BeOfType [ConfluencePS.Page]
            $GetPageLabel2.Labels | Should BeOfType [ConfluencePS.Label]
            ($GetPageLabel1 | Get-Member -MemberType Property).Count | Should Be 2
            ($GetPageLabel2 | Get-Member -MemberType Property).Count | Should Be 2
        }
        It 'label matches the specified value' {
            $GetPageLabel1.Labels.Name | Should Match $patternLabel2
            $GetPageLabel2.Labels.Name | Should Match $patternLabel2
        }
        It 'labelid is not null or empty' {
            $GetPageLabel1.Labels.ID | Should Not BeNullOrEmpty
            $GetPageLabel2.Labels.ID | Should Not BeNullOrEmpty
        }
        It 'pageid matches the specified value' {
            $GetPageLabel1.Page.ID | Should BeExactly $Page.ID
            $GetPageLabel2.Page.ID -contains $Page.ID | Should Be $true
        }
    }

    Describe 'Set-ConfluencePage' {
        <# TODO:
        * Title may not be empty
        * fails when version is 1 larger than current version
        #>

        # ARRANGE
        function dummy-Function {
            [CmdletBinding()]
            param (
                [Parameter(
                    Mandatory = $true,
                    ValueFromPipeline = $true
                )]
                [ConfluencePS.Page]$InputObject,

                $Title,
                $Body
            )

            process {
                if ($Title) {
                    $InputObject.Title = $Title
                }
                if ($Body) {
                    $InputObject.Body = $Body
                }
                $InputObject
            }
        }

        $SpaceKey = "PESTER"
        $Page1 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Piped"
        $Page2 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page Orphan"
        $Page3 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page from Object"
        $Page4 = Get-ConfluencePage -SpaceKey $SpaceKey -Title "Pester New Page with Parent Object"
        # create some more pages
        $Page5, $Page6, $Page7, $Page8 = ("Page 5", "Page 6", "Page 7", "Page 8" | New-ConfluencePage -SpaceKey $SpaceKey -Body "<p>Lorem ipsum</p>" -ErrorAction Stop)
        $AllPages = Get-ConfluencePage -SpaceKey $SpaceKey
        $ParentPage = $AllPages | Where-Object {$_.Title -like "*Home"}

        $NewTitle6 = "Renamed Page 6"
        $NewTitle7 = "Renamed Page 7"
        $NewContent1 = "<h1>Bulk Change</h1><p>Changed all bodies in this space at once</p>"
        $NewContent2 = "<h1>Set Body by property</h1>"
        $NewContent3 = "<p>Updated</p>"
        $RawContent3 = "Updated"

        # ACT
        # change the body of all pages - all pages should have version 2
        $AllChangedPages = $AllPages | dummy-Function -Body $NewContent1 | Set-ConfluencePage -ErrorAction Stop
        # set the body of a page to the same value as it already had - should remain on verion 2
        $SetPage1 = $Page1.ID | Set-ConfluencePage -Body $NewContent1 -ErrorAction Stop
        # change the body of a page by property - this page should have version 3
        $SetPage2 = $Page2.ID | Set-ConfluencePage -Body $NewContent2 -ErrorAction Stop
        # make a non-relevant change just to bump page version
        $SetPage3 = $Page3.ID | Set-ConfluencePage -Body "..."
        # change the title of a page by property - this page should have version 4
        $SetPage3 = $Page3.ID | Set-ConfluencePage -Body $RawContent3 -Convert
        # change the parent page by object
        $SetPage4 = Set-ConfluencePage -PageID $Page4.ID -Parent $Page3
        # change the parent page by pageid
        $SetPage5 = Set-ConfluencePage -PageID $Page5.ID -ParentID $Page4.ID
        # change the title of a page
        $SetPage6 = $Page6.ID | Set-ConfluencePage -Title $NewTitle6
        $SetPage7 = $AllChangedPages | Where {$_.ID -eq $Page7.ID} | dummy-Function -Title $NewTitle7 | Set-ConfluencePage
        # clear the body of a page
        $SetPage8 = Set-ConfluencePage -PageID $Page8.ID -Body ""

        # ASSERT
        It 'returns the correct amount of results' {
            $SetPage1.Count | Should Be 1
            $SetPage2.Count | Should Be 1
            $SetPage3.Count | Should Be 1
            $SetPage4.Count | Should Be 1
            $SetPage5.Count | Should Be 1
            $SetPage6.Count | Should Be 1
            $SetPage7.Count | Should Be 1
            $SetPage8.Count | Should Be 1
            $AllChangedPages.Count | Should Be 9
        }
        It 'returns an object with specific properties' {
            $SetPage1 | Should BeOfType [ConfluencePS.Page]
            $SetPage2 | Should BeOfType [ConfluencePS.Page]
            $SetPage3 | Should BeOfType [ConfluencePS.Page]
            $SetPage4 | Should BeOfType [ConfluencePS.Page]
            $SetPage5 | Should BeOfType [ConfluencePS.Page]
            $SetPage6 | Should BeOfType [ConfluencePS.Page]
            $SetPage7 | Should BeOfType [ConfluencePS.Page]
            $SetPage8 | Should BeOfType [ConfluencePS.Page]
            $AllChangedPages | Should BeOfType [ConfluencePS.Page]
            ($SetPage1 | Get-Member -MemberType Property).Count | Should Be 9
            ($SetPage2 | Get-Member -MemberType Property).Count | Should Be 9
            ($SetPage3 | Get-Member -MemberType Property).Count | Should Be 9
            ($SetPage4 | Get-Member -MemberType Property).Count | Should Be 9
            ($SetPage5 | Get-Member -MemberType Property).Count | Should Be 9
            ($SetPage6 | Get-Member -MemberType Property).Count | Should Be 9
            ($SetPage7 | Get-Member -MemberType Property).Count | Should Be 9
            ($SetPage8 | Get-Member -MemberType Property).Count | Should Be 9
        }
        It 'id is not null or empty' {
            $SetPage1.ID | Should Not BeNullOrEmpty
            $SetPage2.ID | Should Not BeNullOrEmpty
            $SetPage3.ID | Should Not BeNullOrEmpty
            $SetPage4.ID | Should Not BeNullOrEmpty
            $SetPage5.ID | Should Not BeNullOrEmpty
            $SetPage6.ID | Should Not BeNullOrEmpty
            $SetPage7.ID | Should Not BeNullOrEmpty
            $SetPage8.ID | Should Not BeNullOrEmpty
        }
        It 'key has the specified value' {
            $SetPage1.Space.Key | Should BeExactly $SpaceKey
            $SetPage2.Space.Key | Should BeExactly $SpaceKey
            $SetPage3.Space.Key | Should BeExactly $SpaceKey
            $SetPage4.Space.Key | Should BeExactly $SpaceKey
            $SetPage5.Space.Key | Should BeExactly $SpaceKey
            $SetPage6.Space.Key | Should BeExactly $SpaceKey
            $SetPage7.Space.Key | Should BeExactly $SpaceKey
            $SetPage8.Space.Key | Should BeExactly $SpaceKey
            $AllChangedPages.Space.Key | Should BeExactly (1..9 | % {$SpaceKey})
        }
        It 'title has the specified value' {
            $SetPage1.Title | Should BeExactly $Page1.Title
            $SetPage2.Title | Should BeExactly $Page2.Title
            $SetPage3.Title | Should BeExactly $Page3.Title
            $SetPage4.Title | Should BeExactly $Page4.Title
            $SetPage5.Title | Should BeExactly $Page5.Title
            $SetPage6.Title | Should BeExactly $NewTitle6
            $SetPage7.Title | Should BeExactly $NewTitle7
            $SetPage8.Title | Should BeExactly $Page8.Title
        }
        It 'parentid has the specified value' {
            $SetPage1.Ancestors | Should Not BeNullOrEmpty
            $SetPage1.Ancestors.ID | Should BeExactly $parentPage.ID
            $SetPage2.Ancestors | Should BeNullOrEmpty
            $SetPage3.Ancestors | Should Not BeNullOrEmpty
            $SetPage3.Ancestors.ID | Should BeExactly $ParentPage.ID
            $SetPage4.Ancestors | Should Not BeNullOrEmpty
            $SetPage4.Ancestors.ID | Should BeExactly @($ParentPage.ID, $SetPage3.ID)
            $SetPage5.Ancestors | Should Not BeNullOrEmpty
            $SetPage5.Ancestors.ID | Should BeExactly @($ParentPage.ID, $SetPage3.ID, $SetPage4.ID)
            $SetPage6.Ancestors | Should BeNullOrEmpty
            $SetPage7.Ancestors | Should BeNullOrEmpty
            $SetPage8.Ancestors | Should BeNullOrEmpty
        }
        It 'body has the specified value' {
            $SetPage1.Body | Should BeExactly $NewContent1
            $SetPage2.Body | Should BeExactly $NewContent2
            $SetPage3.Body | Should BeExactly $NewContent3
            $SetPage4.Body | Should BeExactly $NewContent1
            $SetPage5.Body | Should BeExactly $NewContent1
            $SetPage6.Body | Should BeExactly $NewContent1
            $SetPage7.Body | Should BeExactly $NewContent1
            $SetPage8.Body | Should BeExactly ""
        }
        It 'version has the specified value' {
            $SetPage1.Version.Number | Should BeExactly 2
            $SetPage2.Version.Number | Should BeExactly 3
            $SetPage3.Version.Number | Should BeExactly 4
            $SetPage4.Version.Number | Should BeExactly 3
            $SetPage5.Version.Number | Should BeExactly 3
            $SetPage6.Version.Number | Should BeExactly 3
            $SetPage7.Version.Number | Should BeExactly 3
            $SetPage8.Version.Number | Should BeExactly 3
        }
    }

    Describe 'Get-ConfluenceChildPage' {
        # ARRANGE

        # ACT
        $ChildPages = (Get-ConfluenceSpace -SpaceKey PESTER).Homepage | Get-ConfluenceChildPage
        $DesendantPages = (Get-ConfluenceSpace -SpaceKey PESTER).Homepage | Get-ConfluenceChildPage -Recurse

        # ASSERT
        It 'returns the correct amount of results' {
            $ChildPages.Count | Should Be 2
            $DesendantPages.Count | Should Be 4
        }
        It 'returns an object with specific properties' {
            $ChildPages | Should BeOfType [ConfluencePS.Page]
            $DesendantPages | Should BeOfType [ConfluencePS.Page]
        }
    }

    Describe 'Remove-ConfluenceLabel' {
        # ARRANGE
        $SpaceKey = "PESTER"
        $Label1 = "pesterc"
        $Page1 = Get-ConfluencePage -Title 'Pester New Page Piped' -SpaceKey $SpaceKey -ErrorAction Stop
        $Page2 = (Get-ConfluenceSpace -SpaceKey PESTER).Homepage

        # ACT
        $Before1 = $Page1 | Get-ConfluenceLabel -ErrorAction SilentlyContinue
        $Before2 = $Page2 | Get-ConfluenceLabel -ErrorAction SilentlyContinue
        Remove-ConfluenceLabel -Label $Label1 -PageID $Page1.ID -ErrorAction SilentlyContinue
        $Page2 | Remove-ConfluenceLabel -ErrorAction SilentlyContinue
        $After1 = $Page1 | Get-ConfluenceLabel -ErrorAction SilentlyContinue
        $After2 = $Page2 | Get-ConfluenceLabel -ErrorAction SilentlyContinue

        # ASSERT
        It 'page has one label less' {
            ($Before1.Labels).Count - ($After1.Labels).Count| Should Be 1
            ($Before2.Labels).Count - ($After2.Labels).Count| Should Be 2
        }
        It 'page does not have labels' {
            $After1.Labels.Name -notcontains $Label1 | Should Be $true
            $After2.Labels.Name -notcontains $Label1 | Should Be $true
        }
    }

    Describe 'Remove-ConfluencePage' {
        # ARRANGE
        $SpaceKey = "PESTER"
        $Title = "Pester New Page Orphan"
        $PageID = Get-ConfluencePage -Title $Title -SpaceKey $SpaceKey -ErrorAction Stop
        $Before = Get-ConfluencePage -SpaceKey $SpaceKey -ErrorAction Stop

        # ACT
        Remove-ConfluencePage -PageID $PageID.ID -ErrorAction SilentlyContinue
        Get-ConfluencePage -SpaceKey $SpaceKey | Remove-ConfluencePage -ErrorAction SilentlyContinue
        $After = Get-ConfluencePage -SpaceKey $SpaceKey -ErrorAction SilentlyContinue

        # ASSERT
        It 'has pages before' {
            $Before | Should Not BeNullOrEmpty
        }
        It 'space does not have pages after' {
            $After.ID | Should BeNullOrEmpty
        }
    }

    Describe 'Remove-ConfluenceSpace' {
        # ARRANGE
        # We don't want warnings on the screen
        $WarningPreference = 'SilentlyContinue'

        # ACT
        Remove-ConfluenceSpace -Key PESTER -Force -ErrorAction Stop
        "PESTER1" | Remove-ConfluenceSpace -Force -ErrorAction Stop

        # ASSERT
        Start-Sleep -Seconds 1
        It 'space is no longer available' {
            { Get-ConfluenceSpace -Key PESTER -ErrorAction Stop } | Should Throw
            { Get-ConfluenceSpace -Key PESTER1 -ErrorAction Stop } | Should Throw
        }
    }
}
