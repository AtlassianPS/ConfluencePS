#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath (Split-Path $PSScriptRoot -Parent)
}

Describe 'Confluence page integration' -Tag 'Integration', 'Cloud', 'DataCenter' {
    BeforeAll {
        . "$PSScriptRoot/Helpers/ConfluenceIntegrationFixture.ps1"
        $script:fixture = New-ConfluenceIntegrationFixture
        if ($script:fixture.IsConfigured) {
            $script:space = New-ConfluenceIntegrationSpace -Fixture $script:fixture -NamePrefix 'Pages'
            $script:page = New-ConfluenceIntegrationPage -Fixture $script:fixture -SpaceKey $script:space.Key -TitlePrefix 'Root Page' -Body '<p>Original body</p>'
        }
    }

    AfterAll {
        if ($script:fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:fixture
        }
    }

    It 'creates and retrieves a page by ID' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $retrieved = Get-ConfluencePage -PageID $script:page.ID -ErrorAction Stop

        $retrieved | Should -BeOfType [ConfluencePS.Page]
        $retrieved.ID | Should -Be $script:page.ID
        $retrieved.Title | Should -BeExactly $script:page.Title
        $retrieved.Body | Should -Match 'Original body'
    }

    It 'updates page content and increments the version' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $updated = Set-ConfluencePage -PageID $script:page.ID -Body '<p>Updated body</p>' -ErrorAction Stop

        $updated.ID | Should -Be $script:page.ID
        $updated.Version.Number | Should -BeGreaterThan $script:page.Version.Number
        $updated.Body | Should -Match 'Updated body'
        $script:page = $updated
    }

    It 'creates and queries child pages' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $child = New-ConfluencePage -Title (New-ConfluenceIntegrationResourceName -Prefix 'Child Page') -ParentID $script:page.ID -Body '<p>Child body</p>' -ErrorAction Stop
        $null = $script:fixture.Pages.Add($child.ID)
        $children = Get-ConfluenceChildPage -PageID $script:page.ID -ErrorAction Stop

        @($children | Where-Object { $_.ID -eq $child.ID }).Count | Should -Be 1
    }
}
