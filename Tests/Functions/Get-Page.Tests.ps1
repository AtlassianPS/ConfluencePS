#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-Page" -Tag 'Unit' {
        BeforeEach {
            $script:lastCql = $null
            $script:lastUri = $null

            Mock Invoke-Method -ModuleName ConfluencePS {
                param(
                    [string]$Uri,
                    [hashtable]$GetParameters
                )

                $script:lastUri = $Uri
                $script:lastCql = $GetParameters['cql']
                [ConfluencePS.Page]::new()
            }
        }

        It "builds one label clause per label value for byLabel queries" {
            $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Label @("labelA", "labelB")

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/search"
            $script:lastCql | Should -Be "type=page AND label=labelA AND label=labelB"
        }

        It "builds one label clause for a single byLabel value" {
            $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Label @("labelA")

            $script:lastCql | Should -Be "type=page AND label=labelA"
        }

        It "appends space filtering to multi-label byLabel queries" {
            $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -SpaceKey "HOTH" -Label @("labelA", "labelB")

            $script:lastCql | Should -Be "type=page AND label=labelA AND label=labelB AND space=HOTH"
        }

        It "prefixes byQuery CQL with type=page without pre-encoding" {
            $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Query 'space=HOTH and title~"*Object"'

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/search"
            $script:lastCql | Should -Be 'type=page AND space=HOTH and title~"*Object"'
        }

        It "throws when Label is an empty array" {
            { $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Label @() } | Should -Throw

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 0 -Scope It
        }
    }
}
