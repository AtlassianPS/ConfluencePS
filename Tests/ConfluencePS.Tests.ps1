# Integration/Acceptance tests to use during module development. Dave Wyatt's five-part series:
# http://blogs.technet.com/b/heyscriptingguy/archive/2015/12/14/what-is-pester-and-why-should-i-care.aspx

Get-Module ConfluencePS | Remove-Module -Force
Import-Module ConfluencePS -Force

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
            $GetSpace1.ID | Should Not BeNullOrEmpty
            $GetSpace1.Key | Should BeExactly 'PESTER'
            $GetSpace1.Name | Should BeExactly 'Pester Test Space'

            $GetSpace2 = Get-ConfSpace -Name 'ter test sp'
            ($GetSpace2 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $GetSpace2.ID | Should Not BeNullOrEmpty
            $GetSpace2.Key | Should BeExactly 'PESTER'
            $GetSpace2.Name | Should BeExactly 'Pester Test Space'

            $GetSpace3 = Get-ConfSpace -ID $GetSpace1.ID
            ($GetSpace3 | Get-Member -MemberType NoteProperty).Count | Should Be 4
            $GetSpace3.ID | Should Be $GetSpace2.ID
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
            $PageID = Get-ConfPage -Title 'pester new page piped' | Select -ExpandProperty ID

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

    }

    Describe 'Get-ConfLabelApplied' {

    }

    Describe 'Set-ConfPage' {

    }

    Describe 'Remove-ConfLabel' {

    }

    Describe 'Remove-ConfPage' {
        It 'Removes the test pages' {
            $PageID1 = Get-ConfPage -Title 'Pester New Page Orphan' -Limit 200 | Select -ExpandProperty ID
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

    }
}
