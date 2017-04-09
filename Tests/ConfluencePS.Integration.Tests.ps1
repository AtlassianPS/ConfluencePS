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
    }
}

InModuleScope ConfluencePS {

    Describe 'Set-WikiInfo' {
        # ARRANGE
        # Could be a long one-liner, but breaking down for readability
        $Pass = ConvertTo-SecureString -AsPlainText -Force -String $env:WikiPass
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($env:WikiUser, $Pass)

        # ACT
        Set-WikiInfo -BaseURI $env:WikiURI -Credential $Cred

        # ASSERT
        It 'credentials are stored' {
            $script:Credential | Should BeOfType [PSCredential]
        }
        It 'url is stored' {
            $script:BaseURI | Should Not BeNullOrEmpty
        }
    }

    Describe 'New-WikiSpace' {
        # ARRANGE
        # We don't want warnings on the screen
        $WarningPreference = 'SilentlyContinue'

        # Set up test values:
        $Key = "PESTER"
        $Name = "Pester Test Space"
        $Description = "<p>A nice description</p>"
        $Icon = [ConfluencePS.Icon] @{
            path = "/images/logo/default-space-logo-256.png"
            width = 48
            height = 48
            isDefault = $False
        }
        $Space2 = [ConfluencePS.Space]@{
            Key = "PESTER1"
            Name = "Second Pester Space"
        }
        # $Space3
        # Ensure the space doesn't already exist
        Get-WikiSpace -Key $Key -ErrorAction SilentlyContinue #TODO


        # ACT
        $NewSpace1 = New-WikiSpace -Key $Key -Name $Name -Description $Description -ErrorAction Stop
        $NewSpace2 = $Space2 | New-WikiSpace -ErrorAction Stop

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
            $NewSpace1.Key | Should BeExactly $Key
            $NewSpace2.Key | Should BeOfType [String]
            $NewSpace2.Key | Should BeExactly $Space2.Key
        }
        It 'name matches the specified value' {
            $NewSpace1.Name | Should BeOfType [String]
            $NewSpace1.Name | Should BeExactly $Name
            $NewSpace2.Name | Should BeOfType [String]
            $NewSpace2.Name | Should BeExactly $Space2.Name
        }
        It 'homepage is ConfluencePS.Page' {
            $NewSpace1.Homepage | Should BeOfType [ConfluencePS.Page]
            $NewSpace2.Homepage | Should BeOfType [ConfluencePS.Page]
        }
        It 'homepage matches the specified value' {
            $NewSpace1.Homepage.Title | Should BeExactly "$Name Home"
            $NewSpace2.Homepage.Title | Should BeExactly "$($Space2.Name) Home"
        }
    }

    Describe 'Get-WikiSpace' {
        # ARRANGE
        # Set up test values:
        $Key = "PESTER"
        $Name = "Pester Test Space"
        $Description = "<p>A nice description</p>"

        # ACT
        $AllSpaces = Get-WikiSpace
        $GetSpace1 = Get-WikiSpace -Key $Key
        $GetSpace2 = Get-WikiSpace | Where-Object {$_.Name -like '*ter test sp*'}
        $GetSpace3 = Get-WikiSpace | Where-Object {$_.ID -eq $GetSpace1.ID}

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
            $GetSpace3.Count | Should Be 1
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
            $GetSpace1.Key | Should BeExactly $Key
            $GetSpace2.Key | Should BeExactly $Key
            $GetSpace3.Key | Should BeExactly $Key
        }
        It 'name is string' {
            $GetSpace1.Name | Should BeOfType [String]
            $GetSpace2.Name | Should BeOfType [String]
            $GetSpace3.Name | Should BeOfType [String]
        }
        It 'name matches the specified value' {
            $GetSpace1.Name | Should BeExactly $Name
            $GetSpace2.Name | Should BeExactly $Name
            $GetSpace3.Name | Should BeExactly $Name
        }
        It 'description is string' {
            $GetSpace1.Description | Should BeOfType [String]
            $GetSpace2.Description | Should BeOfType [String]
            $GetSpace3.Description | Should BeOfType [String]
        }
        It 'description matches the specified value' {
            $GetSpace1.Description | Should BeExactly $Description
            $GetSpace2.Description | Should BeExactly $Description
            $GetSpace3.Description | Should BeExactly $Description
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
            $GetSpace3.Homepage.Title | Should BeExactly "$($GetSpace3.Name) Home"
        }
    }

    Describe 'ConvertTo-WikiStorageFormat' {
        # ARRANGE
        $InputString = "Hi Pester!"
        $OutputString = "<p>Hi Pester!</p>"

        # ACT
        $result1 = $inputString | ConvertTo-WikiStorageFormat
        $result2 = ConvertTo-WikiStorageFormat -Content $inputString

        # ASSERT
        It 'returns a string' {
            $result1 | Should BeOfType [String]
            $result2 | Should BeOfType [String]
        }
        It 'output matches the expected string' {
            $result1 | Should BeExactly $outputString
            $result2 | Should BeExactly $outputString
        }
    }

    Describe 'New-WikiPage' {
        <# TODO:
            * Title may not be empty
            * Space may not be empty when no parent is provided
        #>

        # ARRANGE
        $SpaceKey = "PESTER"
        $parentPage = Get-WikiPage -Title "Pester Test Space Home"
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
        $NewPage1 = $Title1 | New-WikiPage -ParentID $parentPage.ID -ErrorAction Stop
        $NewPage2 = New-WikiPage -Title $Title2 -SpaceKey $SpaceKey -Body $RawContent -Convert -ErrorAction Stop
        $NewPage3 = $pageObject | New-WikiPage -ErrorAction Stop
        $NewPage4 = New-WikiPage -Title $Title4 -Parent $parentPage -ErrorAction Stop

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

    Describe 'Get-WikiPage' {
        # ARRANGE
        Start-Sleep -Seconds 5 # Delay to allow DB index to update
        $SpaceKey = "PESTER"
        $Title1 = "Pester New Page from Object"
        $Title2 = "Pester New Page Orphan"
        $Title3 = "Pester Test Space Home"
        $Content = "<p>Hi Pester!</p>"

        # ACT
        $GetTitle1 = Get-WikiPage -Title $Title1 -PageSize 200 -ErrorAction Stop
        $GetTitle2 = Get-WikiPage -Title $Title2 -SpaceKey $SpaceKey -PageSize 200 -ErrorAction Stop
        $GetID1 = Get-WikiPage -PageID $GetTitle1.ID -ErrorAction Stop
        $GetID2 = Get-WikiPage -PageID $GetTitle2.ID -ErrorAction Stop
        $GetKeys = Get-WikiPage -SpaceKey $SpaceKey | Sort ID -ErrorAction Stop
        $GetSpacePage = Get-WikiPage -Space (Get-WikiSpace -SpaceKey $SpaceKey) -ErrorAction Stop

        # ASSERT
        It 'returns the correct amount of results' {
            $GetTitle1.Count | Should Be 1
            $GetTitle2.Count | Should Be 1
            $GetID1.Count | Should Be 1
            $GetID2.Count | Should Be 1
            $GetKeys.Count | Should Be 5
            $GetSpacePage.Count | Should Be 5
        }
        It 'returns an object with specific properties' {
            $GetTitle1 | Should BeOfType [ConfluencePS.Page]
            $GetTitle2 | Should BeOfType [ConfluencePS.Page]
            $GetID1 | Should BeOfType [ConfluencePS.Page]
            $GetID2 | Should BeOfType [ConfluencePS.Page]
            $GetKeys | Should BeOfType [ConfluencePS.Page]
            ($GetTitle1 | Get-Member -MemberType Property).Count | Should Be 9
            ($GetTitle2 | Get-Member -MemberType Property).Count | Should Be 9
            ($GetID1 | Get-Member -MemberType Property).Count | Should Be 9
            ($GetID2 | Get-Member -MemberType Property).Count | Should Be 9
            ($GetKeys | Get-Member -MemberType Property).Count | Should Be 9
        }
        It 'id is integer' {
            $GetTitle1.ID | Should BeOfType [Int]
            $GetTitle2.ID | Should BeOfType [Int]
            $GetID1.ID | Should BeOfType [Int]
            $GetID2.ID | Should BeOfType [Int]
            $GetKeys.ID | Should BeOfType [Int]
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
        }
        It 'space matches the specified value' {
            $GetTitle1.Space.Key | Should BeExactly $SpaceKey
            $GetTitle2.Space.Key | Should BeExactly $SpaceKey
            $GetID1.Space.Key | Should BeExactly $SpaceKey
            $GetID2.Space.Key | Should BeExactly $SpaceKey
            $GetKeys.Space.Key -contains $SpaceKey | Should Be $true
        }
        It 'version matches the specified value' {
            $GetTitle2.Version.Number | Should Be 1
            $GetID2.Version.Number | Should Be 1
            $GetKeys.Version.Number -contains 1 | Should Be $true
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
        }
    }

    Describe 'New-WikiLabel' {
        # ARRANGE
        $SpaceKey = "PESTER"
        $Page1 = Get-WikiPage -Title "Pester New Page Piped"
        $Label1 = @("pestera", "pesterb", "pesterc")
        $Label2 = "pesterall"
        $PartialLabel = "pest"

        # ACT
        $NewLabel1 = New-WikiLabel -Label $Label1 -PageID $Page1.ID -ErrorAction Stop
        $NewLabel2 = Get-WikiPage -SpaceKey $SpaceKey | New-WikiLabel -Label $Label2 -ErrorAction Stop

        # ASSERT
        It 'returns the correct amount of results' {
            ($NewLabel1).Count | Should Be 3
            ($NewLabel2).Count | Should Be 8
        }
        It 'returns an object with specific properties' {
            $NewLabel1 | Should BeOfType [ConfluencePS.Label]
            $NewLabel2 | Should BeOfType [ConfluencePS.Label]
            ($NewLabel1 | Get-Member -MemberType Property).Count | Should Be 3
            ($NewLabel2 | Get-Member -MemberType Property).Count | Should Be 3
        }
        It 'label matches the specified value' {
            $NewLabel1.Name | Should BeExactly $Label1
            $NewLabel2.Name -contains $Label2 | Should Be $true
        }
        It 'labelid is not null or empty' {
            $NewLabel1.ID | Should Not BeNullOrEmpty
            $NewLabel2.ID | Should Not BeNullOrEmpty
        }
    }

    # Describe 'Get-WikiPageLabel' {
    #     # ARRANGE
    #     $SpaceKey = "PESTER"
    #     $Label1 = "pester"
    #     $PartialLabel = "pest"
    #     $Page = Get-WikiPage -Title "Pester New Page Piped"

    #     # ACT
    #     $GetPageLabel1 = Get-WikiPageLabel -PageID $Page.ID
    #     $GetPageLabel2 = Get-WikiPage -SpaceKey $SpaceKey | Sort ID | Select -ExpandProperty ID | Get-WikiPageLabel

    #     # ASSERT
    #     It 'returns the correct amount of results' {
    #         ($GetPageLabel1).Count | Should Be 4
    #         ($GetPageLabel2).Count | Should Be 6
    #         ($GetPageLabel2 | Where {$_.Label -eq $Label1}).Count | Should Be 3
    #     }
    #     It 'returns an object with specific properties' {
    #         $GetPageLabel1 | Should BeOfType [ConfluencePS.Page]
    #         $GetPageLabel2 | Should BeOfType [ConfluencePS.Page]
    #         ($GetPageLabel1 | Get-Member -MemberType NoteProperty).Count | Should Be 4
    #         ($GetPageLabel2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
    #     }
    #     It 'label matches the specified value' {
    #         $GetPageLabel1.Label | Should Match $PartialLabel
    #         $GetPageLabel2.Label | Should Match $PartialLabel
    #     }
    #     It 'labelid is not null or empty' {
    #         $GetPageLabel1.LabelID | Should Not BeNullOrEmpty
    #         $GetPageLabel2.LabelID | Should Not BeNullOrEmpty
    #     }
    #     It 'pageid matches the specified value' {
    #         $GetPageLabel1.PageID -contains $PageID | Should Be $true
    #         $GetPageLabel2.PageID -contains $PageID | Should Be $true
    #     }
    # }

    # Can't get this working...always works during manual testing
    # Start-Sleep (and wait loop variants) haven't helped during full runs
    # Describe 'Get-WikiLabelApplied' {
    #     # ARRANGE
    #     Start-Sleep -sec 30
    #     $SpaceKey = "PESTER"
    #     $Label1 = "pesterc"
    #     $Label2 = "pester"
    #     $Title1 = "Pester New Page Piped"
    #     $Title2 = "Pester New Page Orphan"
    #     $Type = "page"

    #     # ACT
    #     $GetApplied1 = Get-WikiLabelApplied -Label $Label1
    #     $GetApplied2 = Get-WikiSpace -Key $SpaceKey | Get-WikiLabelApplied -Label $Label2 | Sort ID

    #     # ASSERT
    #     It 'returns the correct amount of results' {
    #         @($GetApplied1).Count | Should Be 1
    #         @($GetApplied2).Count | Should Be 3
    #     }
    #     It 'returns an object with specific properties' {
    #         ($GetApplied1 | Get-Member -MemberType NoteProperty).Count | Should Be 3
    #         ($GetApplied2 | Get-Member -MemberType NoteProperty).Count | Should Be 3
    #     }
    #     It 'id is not null or empty' {
    #         $GetApplied1.ID | Should Not BeNullOrEmpty
    #         $GetApplied2.ID | Should Not BeNullOrEmpty
    #     }
    #     It 'title has the specified value' {
    #         $GetApplied1.Title | Should BeExactly $Title1
    #         $GetApplied2[2].Title | Should BeExactly $Title2
    #     }
    #     It 'type has the specified value' {
    #         $GetApplied1.Type | Should BeExactly $Type
    #         $GetApplied2.Type -contains $Type | Should Be $true
    #     }
    # }

    Describe 'Set-WikiPage' {
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
        $Page1 = Get-WikiPage -SpaceKey $SpaceKey -Title "Pester New Page Piped"
        $Page2 = Get-WikiPage -SpaceKey $SpaceKey -Title "Pester New Page Orphan"
        $Page3 = Get-WikiPage -SpaceKey $SpaceKey -Title "Pester New Page from Object"
        $Page4 = Get-WikiPage -SpaceKey $SpaceKey -Title "Pester New Page with Parent Object"
        # create some more pages
        $Page5, $Page6, $Page7, $Page8 = ("Page 5", "Page 6", "Page 7", "Page 8" | New-WikiPage -SpaceKey $SpaceKey -Body "<p>Lorem ipsum</p>" -ErrorAction Stop)
        $AllPages = Get-WikiPage -SpaceKey $SpaceKey
        $ParentPage = $AllPages | Where-Object {$_.Title -like "*Home"}

        $NewTitle6 = "Renamed Page 6"
        $NewTitle7 = "Renamed Page 7"
        $NewContent1 = "<h1>Bulk Change</h1><p>Changed all bodies in this space at once</p>"
        $NewContent2 = "<h1>Set Body by property</h1>"
        $NewContent3 = "<p>Updated</p>"
        $RawContent3 = "Updated"

        # ACT
        # change the body of all pages - all pages should have version 2
        $AllChangedPages = $AllPages | dummy-Function -Body $NewContent1 | Set-WikiPage -ErrorAction Stop
        # set the body of a page to the same value as it already had - should remain on verion 2
        $SetPage1 = $Page1.ID | Set-WikiPage -Body $NewContent1 -ErrorAction Stop
        # change the body of a page by property - this page should have version 3
        $SetPage2 = $Page2.ID | Set-WikiPage -Body $NewContent2 -ErrorAction Stop
        # make a non-relevant change just to bump page version
        $SetPage3 = $Page3.ID | Set-WikiPage -Body "..."
        # change the title of a page by property - this page should have version 4
        $SetPage3 = $Page3.ID | Set-WikiPage -Body $RawContent3 -Convert
        # change the parent page by object
        $SetPage4 = Set-WikiPage -PageID $Page4.ID -Parent $Page3
        # change the parent page by pageid
        $SetPage5 = Set-WikiPage -PageID $Page5.ID -ParentID $Page4.ID
        # change the title of a page
        $SetPage6 = $Page6.ID | Set-WikiPage -Title $NewTitle6
        $SetPage7 = $AllChangedPages | Where {$_.ID -eq $Page7.ID} | dummy-Function -Title $NewTitle7 | Set-WikiPage
        # clear the body of a page
        $SetPage8 = Set-WikiPage -PageID $Page8.ID -Body ""

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

    Describe 'Remove-WikiLabel' {
        # ARRANGE
        $Label1 = "pesterc"
        $Page1 = Get-WikiPage -Title 'Pester New Page Piped' -ErrorAction Stop

        # ACT
        $Before = Get-WikiPage -PageID $Page1.ID | Get-WikiPageLabel -ErrorAction SilentlyContinue
        Remove-WikiLabel -Label $Label1 -PageID $Page1.ID  -ErrorAction SilentlyContinue
        $After = Get-WikiPage -PageID $Page1.ID | Get-WikiPageLabel -ErrorAction SilentlyContinue

        # ASSERT
        It 'page has one label less' {
            ($Before).Count - ($After).Count| Should Be 1
        }
        It 'page does not have label' {
            $After -notcontains $Label1 | Should Be $true
        }
    }

    Describe 'Remove-WikiPage' {
        # ARRANGE
        $SpaceKey = "PESTER"
        $Title = "Pester New Page Orphan"
        $PageID = Get-WikiPage -Title $Title -ErrorAction Stop
        $Before = Get-WikiPage -SpaceKey $SpaceKey -ErrorAction Stop

        # ACT
        Remove-WikiPage -PageID $PageID.ID -ErrorAction SilentlyContinue
        Get-WikiPage -SpaceKey $SpaceKey | Remove-WikiPage -ErrorAction SilentlyContinue
        $After = Get-WikiPage -SpaceKey $SpaceKey -ErrorAction SilentlyContinue

        # ASSERT
        It 'has pages before' {
            $Before | Should Not BeNullOrEmpty
        }
        It 'space does not have pages after' {
            $After.ID | Should BeNullOrEmpty
        }
    }

    Describe 'Remove-WikiSpace' {
        # ARRANGE
        # We don't want warnings on the screen
        $WarningPreference = 'SilentlyContinue'

        # ACT
        Remove-WikiSpace -Key PESTER -ErrorAction Stop
        "PESTER1" | Remove-WikiSpace -ErrorAction Stop

        # ASSERT
        Start-Sleep -Seconds 1
        It 'space is no longer available' {
            { Get-WikiSpace -Key PESTER -ErrorAction Stop } | Should Throw
            { Get-WikiSpace -Key PESTER1 -ErrorAction Stop } | Should Throw
        }
    }
}
