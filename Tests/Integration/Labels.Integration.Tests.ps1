#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath (Split-Path $PSScriptRoot -Parent)
}

Describe 'Confluence label integration' -Tag 'Integration', 'Cloud', 'DataCenter' {
    BeforeAll {
        . "$PSScriptRoot/Helpers/ConfluenceIntegrationFixture.ps1"
        $script:fixture = New-ConfluenceIntegrationFixture
        if ($script:fixture.IsConfigured) {
            $script:space = New-ConfluenceIntegrationSpace -Fixture $script:fixture -NamePrefix 'Labels'
            $script:page = New-ConfluenceIntegrationPage -Fixture $script:fixture -SpaceKey $script:space.Key -TitlePrefix 'Label Page'
            $script:labelOne = "label-$([Guid]::NewGuid().ToString('N').Substring(0, 8))"
            $script:labelTwo = "label-$([Guid]::NewGuid().ToString('N').Substring(0, 8))"
        }
    }

    AfterAll {
        if ($script:fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:fixture
        }
    }

    It 'adds and reads a page label' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $added = Add-ConfluenceLabel -PageID $script:page.ID -Label $script:labelOne -ErrorAction Stop
        $labels = Get-ConfluenceLabel -PageID $script:page.ID -ErrorAction Stop

        $added | Should -BeOfType [ConfluencePS.ContentLabelSet]
        ($labels.Labels.Name -contains $script:labelOne) | Should -Be $true
    }

    It 'replaces labels with Set-ConfluenceLabel' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $updated = Set-ConfluenceLabel -PageID $script:page.ID -Label $script:labelTwo -ErrorAction Stop
        $labels = Get-ConfluenceLabel -PageID $script:page.ID -ErrorAction Stop

        $updated | Should -BeOfType [ConfluencePS.ContentLabelSet]
        ($labels.Labels.Name -contains $script:labelTwo) | Should -Be $true
        ($labels.Labels.Name -contains $script:labelOne) | Should -Be $false
    }

    It 'removes a page label' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $null = Remove-ConfluenceLabel -PageID $script:page.ID -Label $script:labelTwo -Confirm:$false -ErrorAction Stop
        $labels = Get-ConfluenceLabel -PageID $script:page.ID -ErrorAction Stop

        ($labels.Labels.Name -contains $script:labelTwo) | Should -Be $false
    }
}
