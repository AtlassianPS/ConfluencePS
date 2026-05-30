#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

Describe 'Label integration tests' -Tag Integration, Cloud, DataCenter {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
        $script:fixture = New-ConfluenceIntegrationFixture

        if ($script:fixture.IsConfigured) {
            $script:pageSet = New-ConfluenceIntegrationPageSet -Fixture $script:fixture -SpaceNamePrefix 'ConfluencePS Labels'
            $script:spaceKey = $script:pageSet.Space.Key
            $script:label1 = "labela$($script:pageSet.Suffix)", "labelb$($script:pageSet.Suffix)", "labelc$($script:pageSet.Suffix)"
            $script:label2 = "labelall$($script:pageSet.Suffix)"
            $script:setLabel1 = "overwrite$($script:pageSet.Suffix)", "remove$($script:pageSet.Suffix)"
            $script:setLabel2 = "final$($script:pageSet.Suffix)"
            $script:removeLabel = "removeme$($script:pageSet.Suffix)"
            $script:homeLabel1 = "homea$($script:pageSet.Suffix)"
            $script:homeLabel2 = "homeb$($script:pageSet.Suffix)"
        }
    }

    AfterAll {
        if ($script:fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:fixture
        }
    }

    Context 'Add-ConfluenceLabel' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:newLabel1 = Add-ConfluenceLabel -Label $script:label1 -PageID $script:pageSet.Page1.ID -ErrorAction Stop
                $script:newLabel2 = Get-ConfluencePage -SpaceKey $script:spaceKey | Add-ConfluenceLabel -Label $script:label2 -ErrorAction Stop
                $script:newLabel3 = $script:pageSet.Page1 | Get-ConfluenceLabel | Add-ConfluenceLabel -PageID $script:pageSet.Page2.ID -ErrorAction Stop
            }
        }

        It 'adds labels by page ID, page pipeline, and label-set pipeline' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            $script:newLabel1 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:newLabel1.Page | Should -BeOfType [ConfluencePS.Page]
            $script:newLabel1.Labels | Should -BeOfType [ConfluencePS.Label]
            $script:newLabel1.Labels.Name | Should -BeExactly $script:label1
            @($script:newLabel2).Count | Should -Be 5
            ($script:newLabel2.Labels.Name -contains $script:label2) | Should -Be $true
            $script:newLabel3.Labels.Name | Should -BeExactly $script:label1
            $script:newLabel1.Labels.ID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-ConfluenceLabel' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:labelsBeforeSet = $script:pageSet.Page3 | Get-ConfluenceLabel -ErrorAction Stop
                $script:setResult1 = Set-ConfluenceLabel -PageID $script:pageSet.Page3.ID -Label $script:setLabel1 -ErrorAction Stop
                $script:setResult2 = $script:pageSet.Page3 | Set-ConfluenceLabel -Label $script:setLabel2 -ErrorAction Stop
            }
        }

        It 'replaces labels by page ID and page pipeline input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:setResult1.Labels).Count | Should -Be 2
            @($script:setResult2.Labels).Count | Should -Be 1
            $script:setResult1 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:setResult2 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:setResult1.Labels.Name | Should -BeExactly $script:setLabel1
            $script:setResult2.Labels.Name | Should -BeExactly $script:setLabel2
            $script:setResult2.Labels.Name -notcontains $script:labelsBeforeSet.Labels.Name | Should -Be $true
            $script:setResult2.Labels.ID | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ConfluenceLabel' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:getPageLabel1 = Get-ConfluenceLabel -PageID $script:pageSet.Page1.ID -ErrorAction Stop
                $script:getPageLabel2 = Get-ConfluencePage -SpaceKey $script:spaceKey | Get-ConfluenceLabel -ErrorAction Stop
            }
        }

        It 'gets labels by page ID and by page pipeline input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            $script:getPageLabel1 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:getPageLabel1.Page | Should -BeOfType [ConfluencePS.Page]
            $script:getPageLabel1.Labels | Should -BeOfType [ConfluencePS.Label]
            $script:getPageLabel2 | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $script:getPageLabel2.Labels | Should -BeOfType [ConfluencePS.Label]
            @($script:getPageLabel1.Labels).Count | Should -BeGreaterOrEqual 4
            @($script:getPageLabel2.Labels | Where-Object { $_.Name -eq $script:label2 }).Count | Should -Be 5
            ($script:getPageLabel1.Labels.Name | Where-Object { $_ -in $script:label1 }).Count | Should -Be 3
            $script:getPageLabel1.Page.ID | Should -BeExactly $script:pageSet.Page1.ID
            $script:getPageLabel2.Page.ID | Should -Contain $script:pageSet.Page1.ID
        }
    }

    Context 'Remove-ConfluenceLabel' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $null = Add-ConfluenceLabel -PageID $script:pageSet.Page4.ID -Label $script:removeLabel -ErrorAction Stop
                $null = Add-ConfluenceLabel -PageID $script:pageSet.HomePage.ID -Label $script:homeLabel1, $script:homeLabel2 -ErrorAction Stop
                $script:beforeRemoveSingle = $script:pageSet.Page4 | Get-ConfluenceLabel -ErrorAction Stop
                $script:beforeRemoveAll = $script:pageSet.HomePage | Get-ConfluenceLabel -ErrorAction Stop
                Remove-ConfluenceLabel -Label $script:removeLabel -PageID $script:pageSet.Page4.ID -ErrorAction Stop
                $script:pageSet.HomePage | Remove-ConfluenceLabel -ErrorAction Stop
                $script:afterRemoveSingle = $script:pageSet.Page4 | Get-ConfluenceLabel -ErrorAction SilentlyContinue
                $script:afterRemoveAll = $script:pageSet.HomePage | Get-ConfluenceLabel -ErrorAction SilentlyContinue
            }
        }

        It 'removes a named label and can remove all labels from a page' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:beforeRemoveSingle.Labels).Count - @($script:afterRemoveSingle.Labels).Count | Should -Be 1
            $script:afterRemoveSingle.Labels.Name -notcontains $script:removeLabel | Should -Be $true
            @($script:beforeRemoveAll.Labels).Count | Should -BeGreaterOrEqual 2
            $script:afterRemoveAll.Labels | Should -BeNullOrEmpty
        }
    }
}
