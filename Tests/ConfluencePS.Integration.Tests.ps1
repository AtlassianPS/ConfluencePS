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
            # Ensure the space doesn't already exist
            Get-WikiSpace -Key $Key -ErrorAction SilentlyContinue

        # ACT
            $NewSpace1 = New-WikiSpace -Key $Key -Name $Name -Description $Description -ErrorAction Stop
            $NewSpace2 = $Space2 | New-WikiSpace -ErrorAction Stop

        # ASSERT
            It 'returns an object with specific properties' {
                $NewSpace1 | Should BeOfType [ConfluencePS.Space]
                $NewSpace2 | Should BeOfType [ConfluencePS.Space]
                ($NewSpace1 | Get-Member -MemberType Property).Count | Should Be 6
            }
            It 'ID is integer' {
                $NewSpace1.ID | Should BeOfType [Int]
            }
            It 'key matches the specified value' {
                $NewSpace1.Key | Should BeOfType [String]
                $NewSpace1.Key | Should BeExactly $Key
            }
            It 'name matches the specified value' {
                $NewSpace1.Name | Should BeOfType [String]
                $NewSpace1.Name | Should BeExactly $Name
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
                ($GetSpace1 | Get-Member -MemberType Property).Count | Should Be 6
                ($GetSpace2 | Get-Member -MemberType Property).Count | Should Be 6
                ($GetSpace3 | Get-Member -MemberType Property).Count | Should Be 6
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
            It 'description string' {
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
        # ARRANGE
            $SpaceKey = "PESTER"
            $Title1 = "Pester New Page Piped"
            $Title2 = "Pester New Page Orphan"
            $RawContent = "Hi Pester!"
            $FormattedContent = "<p>Hi Pester!</p>"

        # ACT
            $NewPage1 = Get-WikiPage -Title 'pester test space h' -Limit 200 |
                New-WikiPage -Title $Title1 -Body $RawContent -Convert
            $NewPage2 = New-WikiPage -Title $Title2 -SpaceKey $SpaceKey -Body $FormattedContent

        # ASSERT
            It 'returns an object with specific properties' {
                $NewPage1 | Should BeOfType [ConfluecePS.Page]
                $NewPage2 | Should BeOfType [ConfluecePS.Page]
                ($NewPage1 | Get-Member -MemberType Property).Count | Should Be 4
                ($NewPage2 | Get-Member -MemberType Property).Count | Should Be 4
            }
            It 'spaceid is string' {
                $NewPage1.ID | Should BeOfType [Int]
                $NewPage2.ID | Should BeOfType [Int]
            }
            It 'key matches the specified value' {
                $NewPage1.Key | Should BeExactly $SpaceKey
                $NewPage2.Key | Should BeExactly $SpaceKey
            }
            It 'title matches the specified value' {
                $NewPage1.Title | Should BeExactly $Title1
                $NewPage2.Title | Should BeExactly $Title2
            }
            It 'parentid is string' {
                $NewPage1.ParentID | Should BeOfType [Int]
            }
            It 'parentid is empty' {
                $NewPage2.ParentID | Should BeNullOrEmpty
            }
    }

    Describe 'Get-WikiPage' {
        # ARRANGE
            $SpaceKey = "PESTER"
            $Title1 = "Pester New Page Piped"
            $Title2 = "Pester New Page Orphan"
            $Title3 = "Pester Test Space Home"
            $Content = "<p>Hi Pester!</p>"

        # ACT
            $GetTitle1 = Get-WikiPage -Title 'new page pipe' -Limit 200
            $GetTitle2 = Get-WikiPage -Title 'new page orph' -Limit 200 -Expand
            $GetID1 = Get-WikiPage -PageID $GetTitle2.ID
            $GetID2 = Get-WikiPage -PageID $GetTitle1.ID -Expand
            $GetKey1 = Get-WikiPage -SpaceKey $SpaceKey | Sort ID
            $GetKey2 = Get-WikiPage -SpaceKey $SpaceKey -Expand | Sort ID
            $GetSpacePage = Get-WikiSpace -SpaceKey $SpaceKey | Get-WikiPage

        # ASSERT
            It 'returns the correct amount of results' {
                ($GetKey1).Count | Should Be 3
                ($GetKey2).Count | Should Be 3
                ($GetSpacePage).Count | Should Be 3
            }
            It 'returns an object with specific properties' {
                $GetTitle1 | Should BeOfType [PSObject]
                $GetTitle2 | Should BeOfType [PSObject]
                $GetID1 | Should BeOfType [PSObject]
                $GetID2 | Should BeOfType [PSObject]
                $GetKey1 | Should BeOfType [PSObject]
                $GetKey2 | Should BeOfType [PSObject]
                ($GetTitle1 | Get-Member -MemberType NoteProperty).Count | Should Be 3
                ($GetTitle2 | Get-Member -MemberType NoteProperty).Count | Should Be 5
                ($GetID1 | Get-Member -MemberType NoteProperty).Count | Should Be 3
                ($GetID2 | Get-Member -MemberType NoteProperty).Count | Should Be 5
                ($GetKey1 | Get-Member -MemberType NoteProperty).Count | Should Be 3
                ($GetKey2 | Get-Member -MemberType NoteProperty).Count | Should Be 5
            }
            It 'id is string' {
                $GetTitle1.ID | Should BeOfType [String]
                $GetTitle2.ID | Should BeOfType [String]
                $GetID1.ID | Should BeOfType [String]
                $GetID2.ID | Should BeOfType [String]
                $GetKey1.ID | Should BeOfType [String]
                $GetKey2.ID | Should BeOfType [String]
            }
            It 'id matches the specified value' {
                $GetID1.ID | Should Be $GetTitle2.ID
                $GetID2.ID | Should Be $GetTitle1.ID
                $GetKey1.ID -contains $GetID2.ID | Should Be $true
                $GetKey2.ID -contains $GetID1.ID | Should Be $true
            }
            It 'title matches the specified value' {
                $GetTitle1.Title | Should BeExactly $Title1
                $GetTitle2.Title | Should BeExactly $Title2
                $GetID1.Title | Should BeExactly $Title2
                $GetID2.Title | Should BeExactly $Title1
                $GetKey1.Title -contains $Title3 | Should Be $true
                $GetKey2.Title -contains $GetID1.Title | Should Be $true
            }
            It 'space matches the specified value' {
                $GetTitle1.Space | Should BeExactly $SpaceKey
                $GetTitle2.Space | Should BeExactly $SpaceKey
                $GetID1.Space | Should BeExactly $SpaceKey
                $GetID2.Space | Should BeExactly $SpaceKey
                $GetKey1.Space -contains $SpaceKey | Should Be $true
                $GetKey2.Space -contains $SpaceKey | Should Be $true
            }
            It 'version matches the specified value' {
                $GetTitle2.Ver | Should Be 1
                $GetID2.Ver | Should Be 1
                $GetKey2.Ver -contains 1 | Should Be $true
            }
            It 'body matches the specified value' {
                $GetTitle2.Body | Should BeExactly $Content
                $GetID2.Body | Should BeExactly $Content
                $GetKey2.Body -contains $Content | Should Be $true
            }
    }

    Describe 'New-WikiLabel' {
        # ARRANGE
            $SpaceKey = "PESTER"
            $PageID = Get-WikiPage -Title 'pester new page piped' -Limit 200 | Select -ExpandProperty ID
            $Labels1 = @("pestera", "pesterb", "pesterc")
            $Labels2 = "pester"
            $PartialLabel = "pest"

        # ACT
            $NewLabel1 = New-WikiLabel -Label $Labels1 -PageID $PageID
            $NewLabel2 = Get-WikiPage -SpaceKey $SpaceKey | Sort ID | New-WikiLabel -Label $Labels2

        # ASSERT
            It 'returns the correct amount of results' {
                ($NewLabel1).Count | Should Be 3
                ($NewLabel2).Count | Should Be 6
            }
            It 'returns an object with specific properties' {
                $NewLabel1 | Should BeOfType [PSObject]
                $NewLabel2 | Should BeOfType [PSObject]
                ($NewLabel1 | Get-Member -MemberType NoteProperty).Count | Should Be 4
                ($NewLabel2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            }
            It 'label matches the specified value' {
                $NewLabel1.Label | Should Match $PartialLabel
                $NewLabel2.Label | Should Match $PartialLabel
            }
            It 'labelid is not null or empty' {
                $NewLabel1.LabelID | Should Not BeNullOrEmpty
                $NewLabel2.LabelID | Should Not BeNullOrEmpty
            }
            It 'pageid matches the specified value' {
                $NewLabel1.PageID -contains $PageID | Should Be $true
                $NewLabel2.PageID -contains $PageID | Should Be $true
            }
    }

    Describe 'Get-WikiPageLabel' {
        # ARRANGE
            $SpaceKey = "PESTER"
            $Label1 = "pester"
            $PartialLabel = "pest"
            $PageID = Get-WikiPage -Title 'pester new page piped'

        # ACT
            $GetPageLabel1 = Get-WikiPageLabel -PageID $PageID
            $GetPageLabel2 = Get-WikiPage -SpaceKey $SpaceKey | Sort ID | Get-WikiPageLabel

        # ASSERT
            It 'returns the correct amount of results' {
                ($GetPageLabel1).Count | Should Be 4
                ($GetPageLabel2).Count | Should Be 6
                ($GetPageLabel2 | Where {$_.Label -eq $Label1}).Count | Should Be 3
            }
            It 'returns an object with specific properties' {
                $GetPageLabel1 | Should BeOfType [ConfluencePS.Page]
                $GetPageLabel2 | Should BeOfType [ConfluencePS.Page]
                ($GetPageLabel1 | Get-Member -MemberType NoteProperty).Count | Should Be 4
                ($GetPageLabel2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            }
            It 'label matches the specified value' {
                $GetPageLabel1.Label | Should Match $PartialLabel
                $GetPageLabel2.Label | Should Match $PartialLabel
            }
            It 'labelid is not null or empty' {
                $GetPageLabel1.LabelID | Should Not BeNullOrEmpty
                $GetPageLabel2.LabelID | Should Not BeNullOrEmpty
            }
            It 'pageid matches the specified value' {
                $GetPageLabel1.PageID -contains $PageID | Should Be $true
                $GetPageLabel2.PageID -contains $PageID | Should Be $true
            }
    }

    # Can't get this working...always works during manual testing
    # Start-Sleep (and wait loop variants) haven't helped during full runs
    Describe 'Get-WikiLabelApplied' {
        # ARRANGE
            Start-Sleep -sec 30
            $SpaceKey = "PESTER"
            $Label1 = "pesterc"
            $Label2 = "pester"
            $Title1 = "Pester New Page Piped"
            $Title2 = "Pester New Page Orphan"
            $Type = "page"

        # ACT
            $GetApplied1 = Get-WikiLabelApplied -Label $Label1
            $GetApplied2 = Get-WikiSpace -Key $SpaceKey | Get-WikiLabelApplied -Label $Label2 | Sort ID

        # ASSERT
        It 'returns the correct amount of results' {
            @($GetApplied1).Count | Should Be 1
            @($GetApplied2).Count | Should Be 3
        }
        It 'returns an object with specific properties' {
            ($GetApplied1 | Get-Member -MemberType NoteProperty).Count | Should Be 3
            ($GetApplied2 | Get-Member -MemberType NoteProperty).Count | Should Be 3
        }
        It 'id is not null or empty' {
            $GetApplied1.ID | Should Not BeNullOrEmpty
            $GetApplied2.ID | Should Not BeNullOrEmpty
        }
        It 'title has the specified value' {
            $GetApplied1.Title | Should BeExactly $Title1
            $GetApplied2[2].Title | Should BeExactly $Title2
        }
        It 'type has the specified value' {
            $GetApplied1.Type | Should BeExactly $Type
            $GetApplied2.Type -contains $Type | Should Be $true
        }
    }

    Describe 'Set-WikiPage' {
        # ARRANGE
            $SpaceKey = "PESTER"
            $Title1 = "pester new page piped"
            $Title2 = "pester new page orphan"
            $Title3 = "Pester New Page Adopted"
            $TitlePartial = "pester new page"
            $Content1 = "<p>asdf</p>"
            $Content2 = "<p>I'm adopted!</p>"
            $Content3 = "<p>Updated</p>"
            $RawContent3 = "Updated"
            $SetParentID = (Get-WikiPage -Title 'Pester Test Space Home' -Limit 200).ID

        # ACT
            $SetPage1 = Get-WikiPage -Title $Title1 -Limit 100 -Expand |
                Set-WikiPage -Body $Content1
            $SetPage2 = Get-WikiPage -Title $Title2 -Limit 100 -Expand |
                Set-WikiPage -Title $Title3 -Body $Content2 -ParentID $SetParentID
            $SetPage3 = Get-WikiPage -Title $TitlePartial -Limit 100 -Expand |
                Set-WikiPage -Body $RawContent3 -Convert

        # ASSERT
            It 'returns the correct amount of results' {
                $SetPage3.Count | Should Be 2
            }
            It 'returns an object with specific properties' {
                ($SetPage1 | Get-Member -MemberType NoteProperty).Count | Should Be 4
                ($SetPage2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
                ($SetPage3 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            }
            It 'id is not null or empty' {
                $SetPage1.ID | Should Not BeNullOrEmpty
                $SetPage2.ID | Should Not BeNullOrEmpty
                $SetPage3.ID | Should Not BeNullOrEmpty
            }
            It 'id should be unique' {
                $SetPage3[0].ID | Should Not Be $SetPage3[1].ID
            }
            It 'key has the specified value' {
                $SetPage1.Key | Should BeExactly $SpaceKey
                $SetPage2.Key | Should BeExactly $SpaceKey
                $SetPage3.Key | Should BeExactly @($SpaceKey, $SpaceKey)
            }
            It 'title has the specified value' {
                $SetPage1.Title | Should BeLike $Title1
                $SetPage2.Title | Should BeExactly $Title3
                # (BeLike / BeLikeExactly hasn't been published to the PS Gallery yet)
                $SetPage3.Title | Should Match $TitlePartial
            }
            It 'parentid has the specified value' {
                $SetPage1.ParentID | Should Not BeNullOrEmpty
                $SetPage2.ParentID | Should Be $SetParentID
                $SetPage3.ParentID | Should Be @($SetParentID, $SetParentID)
            }
            It 'body has the specified value' {
                (Get-WikiPage -PageID $SetPage1.ID -Expand).Body | Should BeExactly $Content3
                (Get-WikiPage -PageID $SetPage2.ID -Expand).Body | Should BeExactly $Content3
                (Get-WikiPage -PageID ($SetPage3[0]).ID -Expand).Body | Should BeExactly $Content3
            }
    }

    Describe 'Remove-WikiLabel' {
        # ARRANGE
            $Label = "pesterc"
            $PageID = Get-WikiPage -Title 'pester new page piped' -Limit 200 | Select -ExpandProperty ID

        # ACT
            $Before = Get-WikiPage -PageID $PageID | Get-WikiPageLabel
            Remove-WikiLabel -Label $Label -PageID $PageID
            $After = Get-WikiPage -PageID $PageID | Get-WikiPageLabel

        # ASSERT
            It 'page has one label less' {
                ($Before).Count - ($After).Count| Should Be 1
            }
            It 'page does not have label' {
                $After -notcontains $Label | Should Be $true
            }
    }

    Describe 'Remove-WikiPage' {
        # ARRANGE
            $SpaceKey = "PESTER"
            $Title = "Pester New Page Adopted"
            $PageID = Get-WikiPage -Title $Title -Limit 200 -ErrorAction Stop | Select -ExpandProperty ID
            $Before = Get-WikiPage -SpaceKey $SpaceKey -Limit 200 -ErrorAction Stop

        # ACT
            Remove-WikiPage -PageID $PageID -ErrorAction Stop
            Get-WikiPage -SpaceKey $SpaceKey -Limit 200 | Remove-WikiPage
            $After = Get-WikiPage -SpaceKey $SpaceKey -Limit 200 -ErrorAction SilentlyContinue

        # ASSERT
            It 'had pages before' {
                $Before | Should Not BeNullOrEmpty
            }
            It 'space has no more pages after' {
                $After | Should BeNullOrEmpty
            }
    }

    Describe 'Remove-WikiSpace' {
        # ARRANGE
            # We don't want warnings on the screen
            $WarningPreference = 'SilentlyContinue'

        # ACT
            Remove-WikiSpace -Key PESTER -ErrorAction Stop
            Remove-WikiSpace -Key PESTER1 -ErrorAction Stop

        # ASSERT
            Start-Sleep -Seconds 1
            It 'space is no longer available' {
                { Get-WikiSpace -Key PESTER -ErrorAction Stop } | Should Throw
                { Get-WikiSpace -Key PESTER1 -ErrorAction Stop } | Should Throw
            }
    }
}
