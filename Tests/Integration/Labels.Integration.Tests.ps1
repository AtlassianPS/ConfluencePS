#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

Describe 'Label integration tests' -Tag Integration, Cloud, DataCenter {
    BeforeAll {
        . "$PSScriptRoot/Helpers/ConfluenceIntegrationFixture.ps1"
        $script:Fixture = New-ConfluenceIntegrationFixture

        if ($script:Fixture.IsConfigured) {
            $script:PageSet = New-ConfluenceIntegrationPageSet -Fixture $script:Fixture -SpaceNamePrefix 'ConfluencePS Labels'
            $script:SpaceKey = $script:PageSet.Space.Key
            $script:Label1 = "labela$($script:PageSet.Suffix)", "labelb$($script:PageSet.Suffix)", "labelc$($script:PageSet.Suffix)"
            $script:Label2 = "labelall$($script:PageSet.Suffix)"
            $script:SetLabel1 = "overwrite$($script:PageSet.Suffix)", "remove$($script:PageSet.Suffix)"
            $script:SetLabel2 = "final$($script:PageSet.Suffix)"
            $script:RemoveLabel = "removeme$($script:PageSet.Suffix)"
            $script:HomeLabel1 = "homea$($script:PageSet.Suffix)"
            $script:HomeLabel2 = "homeb$($script:PageSet.Suffix)"
        }
    }

    AfterAll {
        if ($script:Fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:Fixture
        }
    }

    Context 'Add-ConfluenceLabel' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:NewLabel1 = Add-ConfluenceLabel -Label $script:Label1 -PageID $script:PageSet.Page1.ID -ErrorAction Stop
                $script:NewLabel2 = Get-ConfluencePage -SpaceKey $script:SpaceKey | Add-ConfluenceLabel -Label $script:Label2 -ErrorAction Stop
                $script:NewLabel3 = $script:PageSet.Page1 | Get-ConfluenceLabel | Add-ConfluenceLabel -PageID $script:PageSet.Page2.ID -ErrorAction Stop
            }
        }

        It 'adds labels by page ID, page pipeline, and label-set pipeline' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            $script:NewLabel1 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:NewLabel1.Page | Should -BeOfType [ConfluencePS.Page]
            $script:NewLabel1.Labels | Should -BeOfType [ConfluencePS.Label]
            $script:NewLabel1.Labels.Name | Should -BeExactly $script:Label1
            @($script:NewLabel2).Count | Should -Be 5
            ($script:NewLabel2.Labels.Name -contains $script:Label2) | Should -Be $true
            $script:NewLabel3.Labels.Name | Should -BeExactly $script:Label1
            $script:NewLabel1.Labels.ID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-ConfluenceLabel' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:LabelsBeforeSet = $script:PageSet.Page3 | Get-ConfluenceLabel -ErrorAction Stop
                $script:SetResult1 = Set-ConfluenceLabel -PageID $script:PageSet.Page3.ID -Label $script:SetLabel1 -ErrorAction Stop
                $script:SetResult2 = $script:PageSet.Page3 | Set-ConfluenceLabel -Label $script:SetLabel2 -ErrorAction Stop
            }
        }

        It 'replaces labels by page ID and page pipeline input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:SetResult1.Labels).Count | Should -Be 2
            @($script:SetResult2.Labels).Count | Should -Be 1
            $script:SetResult1 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:SetResult2 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:SetResult1.Labels.Name | Should -BeExactly $script:SetLabel1
            $script:SetResult2.Labels.Name | Should -BeExactly $script:SetLabel2
            $script:SetResult2.Labels.Name -notcontains $script:LabelsBeforeSet.Labels.Name | Should -Be $true
            $script:SetResult2.Labels.ID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ConfluenceLabel' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:GetPageLabel1 = Get-ConfluenceLabel -PageID $script:PageSet.Page1.ID -ErrorAction Stop
                $script:GetPageLabel2 = Get-ConfluencePage -SpaceKey $script:SpaceKey | Get-ConfluenceLabel -ErrorAction Stop
            }
        }

        It 'gets labels by page ID and by page pipeline input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            $script:GetPageLabel1 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:GetPageLabel1.Page | Should -BeOfType [ConfluencePS.Page]
            $script:GetPageLabel1.Labels | Should -BeOfType [ConfluencePS.Label]
            $script:GetPageLabel2 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:GetPageLabel2.Labels | Should -BeOfType [ConfluencePS.Label]
            @($script:GetPageLabel1.Labels).Count | Should -BeGreaterOrEqual 4
            @($script:GetPageLabel2.Labels | Where-Object { $_.Name -eq $script:Label2 }).Count | Should -Be 5
            ($script:GetPageLabel1.Labels.Name | Where-Object { $_ -in $script:Label1 }).Count | Should -Be 3
            $script:GetPageLabel1.Page.ID | Should -BeExactly $script:PageSet.Page1.ID
            $script:GetPageLabel2.Page.ID | Should -Contain $script:PageSet.Page1.ID
        }
    }

    Context 'Remove-ConfluenceLabel' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $null = Add-ConfluenceLabel -PageID $script:PageSet.Page4.ID -Label $script:RemoveLabel -ErrorAction Stop
                $null = Add-ConfluenceLabel -PageID $script:PageSet.HomePage.ID -Label $script:HomeLabel1, $script:HomeLabel2 -ErrorAction Stop
                $script:BeforeRemoveSingle = $script:PageSet.Page4 | Get-ConfluenceLabel -ErrorAction Stop
                $script:BeforeRemoveAll = $script:PageSet.HomePage | Get-ConfluenceLabel -ErrorAction Stop
                Remove-ConfluenceLabel -Label $script:RemoveLabel -PageID $script:PageSet.Page4.ID -ErrorAction Stop
                $script:PageSet.HomePage | Remove-ConfluenceLabel -ErrorAction Stop
                $script:AfterRemoveSingle = $script:PageSet.Page4 | Get-ConfluenceLabel -ErrorAction SilentlyContinue
                $script:AfterRemoveAll = $script:PageSet.HomePage | Get-ConfluenceLabel -ErrorAction SilentlyContinue
            }
        }

        It 'removes a named label and can remove all labels from a page' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:BeforeRemoveSingle.Labels).Count - @($script:AfterRemoveSingle.Labels).Count | Should -Be 1
            $script:AfterRemoveSingle.Labels.Name -notcontains $script:RemoveLabel | Should -Be $true
            @($script:BeforeRemoveAll.Labels).Count | Should -BeGreaterOrEqual 2
            $script:AfterRemoveAll.Labels | Should -BeNullOrEmpty
        }
    }
}
