# Pester integration/acceptance tests to use during module development. Dave Wyatt's five-part series:
# http://blogs.technet.com/b/heyscriptingguy/archive/2015/12/14/what-is-pester-and-why-should-i-care.aspx

Get-Module ConfluencePS | Remove-Module -Force
Import-Module .\ConfluencePS -Force

InModuleScope ConfluencePS {
    Describe 'New-ConfSpace' {
        It 'Creates a new space' {
            $NewSpace = New-ConfSpace -Key 'PESTER' -Name 'Pester Test Space'
            ($NewSpace | Get-Member -MemberType NoteProperty).Count | Should Be 3
            $NewSpace[0].ID | Should Not BeNullOrEmpty
            $NewSpace[0].Key | Should BeExactly 'PESTER'
            $NewSpace[0].Name | Should BeExactly 'Pester Test Space'
        }
    }

    Describe 'Get-ConfSpace' {
        It 'Returns expected space properties' {
            $GetSpace1 = Get-ConfSpace -Key 'pester'
            ($GetSpace1 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $GetSpace1.SpaceID | Should Not BeNullOrEmpty
            $GetSpace1.Key | Should BeExactly 'PESTER'
            $GetSpace1.Name | Should BeExactly 'Pester Test Space'

            $GetSpace2 = Get-ConfSpace -Name 'ter test sp'
            ($GetSpace2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $GetSpace2.SpaceID | Should Not BeNullOrEmpty
            $GetSpace2.Key | Should BeExactly 'PESTER'
            $GetSpace2.Name | Should BeExactly 'Pester Test Space'

            $GetSpace3 = Get-ConfSpace -ID $GetSpace1.SpaceID
            ($GetSpace3 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $GetSpace3.SpaceID | Should Be $GetSpace2.SpaceID
            $GetSpace3.Key | Should BeExactly 'PESTER'
            $GetSpace3.Name | Should BeExactly 'Pester Test Space'
        }
    }

    Describe 'ConvertTo-ConfStorageFormat' {
        It 'Prepares a string for wiki use' {
            'Hi Pester!' | ConvertTo-ConfStorageFormat | Should BeExactly '<p>Hi Pester!</p>'
        }
    }

    Describe 'New-ConfPage' {
        It 'Creates expected page' {
            $NewPage1 = Get-ConfPage -Title 'pester test space h' -Limit 200 |
                New-ConfPage -Title 'Pester New Page Piped' -Body 'Hi Pester!' -Convert
            ($NewPage1 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $NewPage1.ID | Should Not BeNullOrEmpty
            $NewPage1.Key | Should BeExactly 'PESTER'
            $NewPage1.Title | Should BeExactly 'Pester New Page Piped'
            $NewPage1.ParentID | Should Not BeNullOrEmpty

            $NewPage2 = New-ConfPage -Title 'Pester New Page Orphan' -SpaceKey PESTER -Body '<p>Hi Pester!</p>'
            ($NewPage2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $NewPage2.ID | Should Not BeNullOrEmpty
            $NewPage2.Key | Should BeExactly 'PESTER'
            $NewPage2.Title | Should BeExactly 'Pester New Page Orphan'
            $NewPage2.ParentID | Should BeNullOrEmpty
        }
    }

    Describe 'Get-ConfPage' {
        It 'Returns expected page properties' {
            $GetTitle1 = Get-ConfPage -Title 'new page pipe' -Limit 200
            ($GetTitle1 | Get-Member -MemberType NoteProperty).Count | Should Be 3
            $GetTitle1.ID | Should Not BeNullOrEmpty
            $GetTitle1.Title | Should BeExactly 'Pester New Page Piped'
            $GetTitle1.Space | Should BeExactly 'PESTER'

            $GetTitle2 = Get-ConfPage -Title 'new page orph' -Limit 200 -Expand
            ($GetTitle2 | Get-Member -MemberType NoteProperty).Count | Should Be 5
            $GetTitle2.ID | Should Not BeNullOrEmpty
            $GetTitle2.Title | Should BeExactly 'Pester New Page Orphan'
            $GetTitle2.Space | Should BeExactly 'PESTER'
            $GetTitle2.Ver | Should Be 1
            $GetTitle2.Body | Should BeExactly '<p>Hi Pester!</p>'

            $GetID1 = Get-ConfPage -PageID $GetTitle2.ID
            ($GetID1 | Get-Member -MemberType NoteProperty).Count | Should Be 3
            $GetID1[0].ID | Should Be $GetTitle2.ID
            $GetID1[0].Title | Should BeExactly 'Pester New Page Orphan'
            $GetID1[0].Space | Should BeExactly 'PESTER'

            $GetID2 = Get-ConfPage -PageID $GetTitle1.ID -Expand
            ($GetID2 | Get-Member -MemberType NoteProperty).Count | Should Be 5
            $GetID2[0].ID | Should Be $GetTitle1.ID
            $GetID2[0].Title | Should BeExactly 'Pester New Page Piped'
            $GetID2[0].Space | Should BeExactly 'PESTER'
            $GetID2[0].Ver | Should Be 1
            $GetID2[0].Body | Should BeExactly '<p>Hi Pester!</p>'

            $GetKey1 = Get-ConfPage -SpaceKey PESTER | Sort ID
            ($GetKey1).Count | Should Be 3
            ($GetKey1 | Get-Member -MemberType NoteProperty).Count | Should Be 3
            $GetKey1.ID[1] | Should Be $GetID2.ID
            $GetKey1[0].Title | Should BeExactly 'Pester Test Space Home'
            $GetKey1[0].Space | Should BeExactly 'PESTER'

            $GetKey2 = Get-ConfPage -SpaceKey PESTER -Expand | Sort ID
            ($GetKey2).Count | Should Be 3
            ($GetKey2 | Get-Member -MemberType NoteProperty).Count | Should Be 5
            $GetKey2[2].ID | Should Be $GetID1.ID
            $GetKey2[2].Title | Should BeExactly $GetID1.Title
            $GetKey2[0].Space | Should BeExactly 'PESTER'
            $GetKey2[0].Ver | Should Be 1
            $GetKey2[2].Body | Should BeExactly '<p>Hi Pester!</p>'
        }
    }

    Describe 'New-ConfLabel' {
        It 'Applies labels to pages' {
            $PageID = Get-ConfPage -Title 'pester new page piped' -Limit 200 | Select -ExpandProperty ID

            $NewLabel1 = New-ConfLabel -Label pestera,pesterb,pesterc -PageID $PageID
            ($NewLabel1).Count | Should Be 3
            ($NewLabel1 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $NewLabel1.Label | Should Match 'pest'
            $NewLabel1.LabelID | Should Not BeNullOrEmpty
            $NewLabel1[0].PageID | Should Be $PageID

            $NewLabel2 = Get-ConfPage -SpaceKey PESTER | Sort ID | New-ConfLabel -Label pester
            ($NewLabel2).Count | Should Be 6
            ($NewLabel2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $NewLabel2.Label | Should Match 'pest'
            $NewLabel2.LabelID | Should Not BeNullOrEmpty
            $NewLabel2[1].PageID | Should Be $PageID
        }
    }

    Describe 'Get-ConfPageLabel' {
        It 'Returns expected labels' {
            $PageID = Get-ConfPage -Title 'pester new page piped' -Limit 200 | Select -ExpandProperty ID

            $GetPageLabel1 = Get-ConfPageLabel -PageID $PageID
            ($GetPageLabel1).Count | Should Be 4
            ($GetPageLabel1 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $GetPageLabel1.Label | Should Match 'pest'
            $GetPageLabel1.LabelID | Should Not BeNullOrEmpty
            $GetPageLabel1[0].PageID | Should Be $PageID

            $GetPageLabel2 = Get-ConfPage -SpaceKey PESTER | Sort ID | Get-ConfPageLabel
            ($GetPageLabel2).Count | Should Be 6
            ($GetPageLabel2 | Where Label -eq 'pester').Count | Should Be 3
            ($GetPageLabel2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $GetPageLabel2.Label | Should Match 'pest'
            $GetPageLabel2.LabelID | Should Not BeNullOrEmpty
            $GetPageLabel2[1].PageID | Should Be $PageID
        }
    }

    # Can't get this working...always works during manual testing
    # Start-Sleep (and wait loop variants) haven't helped during full runs
    <#
    Describe 'Get-ConfLabelApplied' {
        It 'Returns applications of a label' {
            $GetApplied1 = Get-ConfLabelApplied -Label pesterc
            ($GetApplied1 | Get-Member -MemberType NoteProperty).Count | Should Be 3
            $GetApplied1.ID | Should Not BeNullOrEmpty
            $GetApplied1.Title | Should BeExactly 'Pester New Page Piped'
            $GetApplied1.Type | Should BeExactly 'page'

            $GetApplied2 = Get-ConfSpace -Key PESTER | Get-ConfLabelApplied -Label pester | Sort ID
            ($GetApplied2).Count | Should Be 3
            ($GetApplied2 | Get-Member -MemberType NoteProperty).Count | Should Be 3
            $GetApplied2.ID | Should Not BeNullOrEmpty
            $GetApplied2[2].Title | Should BeExactly 'Pester New Page Orphan'
            $GetApplied2.Type | Should BeExactly 'page'
        }
    }
    #>

    Describe 'Set-ConfPage' {
        It 'Edits existing pages' {
            $SetPage1 = Get-ConfPage -Title 'pester new page piped' -Limit 100 -Expand |
                Set-ConfPage -Body '<p>asdf</p>'
            ($SetPage1 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $SetPage1.ID | Should Not BeNullOrEmpty
            $SetPage1.Key | Should BeExactly 'PESTER'
            $SetPage1.Title | Should BeExactly 'Pester New Page Piped'
            $SetPage1.ParentID | Should Not BeNullOrEmpty
            (Get-ConfPage -PageID $SetPage1.ID -Expand).Body | Should BeExactly '<p>asdf</p>'

            $SetParentID = (Get-ConfPage -Title 'Pester Test Space Home' -Limit 200).ID
            $SetPage2 = Get-ConfPage -Title 'pester new page orphan' -Limit 100 -Expand |
                Set-ConfPage -Title 'Pester New Page Adopted' -Body "<p>I'm adopted!</p>" `
                             -ParentID $SetParentID
            ($SetPage2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $SetPage2.ID | Should Not BeNullOrEmpty
            $SetPage2.Key | Should BeExactly 'PESTER'
            $SetPage2.Title | Should BeExactly 'Pester New Page Adopted'
            $SetPage2.ParentID | Should Be $SetParentID
            (Get-ConfPage -PageID $SetPage2.ID -Expand).Body | Should BeExactly "<p>I'm adopted!</p>"

            $SetPage3 = Get-ConfPage -Title 'pester new page' -Limit 100 -Expand |
                Set-ConfPage -Body 'Updated' -Convert
            $SetPage3.Count | Should Be 2
            $SetPage3[0].ID | Should Not Be $SetPage3[1].ID
            ($SetPage3 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $SetPage3.ID | Should Not BeNullOrEmpty
            $SetPage3.Key | Should BeExactly 'PESTER'
            # (BeLike / BeLikeExactly hasn't been published to the PS Gallery yet)
            # $SetPage3.Title | Should BeLikeExactly 'Pester New Page*'
            $SetPage3.ParentID | Should Be $SetParentID
            (Get-ConfPage -PageID ($SetPage3[0]).ID -Expand).Body | Should BeExactly '<p>Updated</p>'
        }
    }

    Describe 'Remove-ConfLabel' {
        It 'Removes labels from content' {
            $PageID = Get-ConfPage -Title 'pester new page piped' -Limit 200 | Select -ExpandProperty ID

            Remove-ConfLabel -Label pesterc -PageID $PageID

            $RemoveLabel1 = Get-ConfPage -PageID $PageID | Get-ConfPageLabel
            ($RemoveLabel1).Count | Should Be 3

            # This seems to occasionally fail during full runs
            # Prob some overarching Get-ConfLabelApplied delay or other issue
            Get-ConfLabelApplied -Label pester | Remove-ConfLabel -Label pester

            $RemoveLabel2 = Get-ConfPage -SpaceKey PESTER | Get-ConfPageLabel | Sort ID
            ($RemoveLabel2).Count | Should Be 2
            $RemoveLabel2[0].Label | Should Be 'pestera'
            $RemoveLabel2.PageID | Should Be $PageID
        }
    }

    Describe 'Remove-ConfPage' {
        It 'Removes the test pages' {
            $PageID1 = Get-ConfPage -Title 'Pester New Page Adopted' -Limit 200 | Select -ExpandProperty ID
            $PageID1 | Should Not BeNullOrEmpty

            Remove-ConfPage -PageID $PageID1

            $RemovePage1 = Get-ConfPage -SpaceKey PESTER -Limit 200
            ($RemovePage1).Count | Should Be 2
            $RemovePage1[0].ID | Should Not Be $PageID1
            $RemovePage1[1].ID | Should Not Be $PageID1

            Get-ConfPage -SpaceKey PESTER -Limit 200 | Remove-ConfPage

            Get-ConfPage -SpaceKey PESTER -Limit 200 | Should BeNullOrEmpty
        }
    }

    Describe 'Remove-ConfSpace' {
        It 'Removes the test space' {
            Remove-ConfSpace -Key PESTER
            Start-Sleep -Seconds 1
            Get-ConfSpace -Key PESTER | Should BeNullOrEmpty
        }
    }
}
