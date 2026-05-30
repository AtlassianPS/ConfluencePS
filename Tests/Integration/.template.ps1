#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

<#
.SYNOPSIS
    Integration test template for ConfluencePS functions.

.DESCRIPTION
    Copy this file and rename it to <Area>.Integration.Tests.ps1.
    Integration tests run against a real Confluence Cloud or Data Center API and should use disposable resources.
#>

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath (Split-Path $PSScriptRoot -Parent)
}

Describe '%AREA%' -Tag 'Integration', 'Cloud', 'DataCenter' {
    BeforeAll {
        . "$PSScriptRoot/Helpers/ConfluenceIntegrationFixture.ps1"

        $script:fixture = New-ConfluenceIntegrationFixture
        if (-not $script:fixture.IsConfigured) {
            return
        }

        $script:space = New-ConfluenceIntegrationSpace -Fixture $script:fixture -NamePrefix 'ConfluencePS Template'
        $script:page = New-ConfluenceIntegrationPage -Fixture $script:fixture -SpaceKey $script:space.Key -TitlePrefix 'Template Page'
    }

    AfterAll {
        if ($script:fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:fixture
        }
    }

    Context 'Read behavior' {
        It 'performs the expected operation' {
            if (-not $script:fixture.IsConfigured) {
                Set-ItResult -Skipped -Because $script:fixture.SkipReason
                return
            }

            $result = Get-ConfluencePage -PageID $script:page.ID -ErrorAction Stop

            $result | Should -BeOfType [ConfluencePS.Page]
            $result.ID | Should -Be $script:page.ID
        }
    }
}
