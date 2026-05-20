#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Set-Page" -Tag 'Unit' {
        BeforeAll {
            $script:lastRequestBody = $null
            Mock Invoke-Method -ModuleName ConfluencePS {
                param(
                    [string]$Body
                )

                $script:lastRequestBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                [ConfluencePS.Page]::new()
            }
        }

        It "includes version.message from input object even when unchanged" {
            $page = [ConfluencePS.Page]::new()
            $page.ID = 42
            $page.Title = "Page title"
            $page.Body = "<p>Body</p>"
            $page.Version = [ConfluencePS.Version]::new()
            $page.Version.Number = 7
            $page.Version.Message = "Same message on purpose"

            $null = Set-Page -ApiUri "https://example.com/wiki/rest/api" -InputObject $page -Confirm:$false

            $script:lastRequestBody.version.number | Should -Be 8
            $script:lastRequestBody.version.message | Should -Be "Same message on purpose"
        }

        It "omits version.message when input object message is not provided" {
            $page = [ConfluencePS.Page]::new()
            $page.ID = 43
            $page.Title = "Page title"
            $page.Body = "<p>Body</p>"
            $page.Version = [ConfluencePS.Version]::new()
            $page.Version.Number = 2

            $null = Set-Page -ApiUri "https://example.com/wiki/rest/api" -InputObject $page -Confirm:$false

            $script:lastRequestBody.version.number | Should -Be 3
            $script:lastRequestBody.version.PSObject.Properties.Name | Should -Not -Contain "message"
        }
    }
}
