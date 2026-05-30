#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath (Split-Path $PSScriptRoot -Parent)
}

Describe 'Confluence space integration' -Tag 'Integration', 'Cloud', 'DataCenter' {
    BeforeAll {
        . "$PSScriptRoot/Helpers/ConfluenceIntegrationFixture.ps1"
        $script:fixture = New-ConfluenceIntegrationFixture
        if ($script:fixture.IsConfigured) {
            $script:space = New-ConfluenceIntegrationSpace -Fixture $script:fixture -NamePrefix 'Space'
        }
    }

    AfterAll {
        if ($script:fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:fixture
        }
    }

    It 'creates a disposable space with the expected shape' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $script:space | Should -BeOfType [ConfluencePS.Space]
        $script:space.ID | Should -BeOfType [UInt64]
        $script:space.Key | Should -Not -BeNullOrEmpty
        $script:space.Homepage | Should -BeOfType [ConfluencePS.Page]
    }

    It 'retrieves the disposable space by key' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $retrieved = Get-ConfluenceSpace -Key $script:space.Key -ErrorAction Stop

        $retrieved | Should -BeOfType [ConfluencePS.Space]
        $retrieved.Key | Should -BeExactly $script:space.Key
        $retrieved.Name | Should -BeExactly $script:space.Name
    }

    It 'creates storage/table markup usable in a real page' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $table = [PSCustomObject]@{ Name = 'ConfluencePS'; Scope = 'Integration' } | ConvertTo-ConfluenceTable
        $storage = ConvertTo-ConfluenceStorageFormat -Content $table
        $page = New-ConfluenceIntegrationPage -Fixture $script:fixture -SpaceKey $script:space.Key -TitlePrefix 'Table Page' -Body $storage
        $retrieved = Get-ConfluencePage -PageID $page.ID -ErrorAction Stop

        $table | Should -Match '\|\| Name \|\| Scope \|\|'
        $retrieved.Body | Should -Match 'ConfluencePS'
        $retrieved.Body | Should -Match 'Integration'
    }
}
