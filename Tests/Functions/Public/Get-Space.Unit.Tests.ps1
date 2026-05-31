#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-Space" -Tag 'Unit' {
        BeforeEach {
            $script:lastGetParameters = $null

            Mock Invoke-Method -ModuleName ConfluencePS {
                param(
                    [hashtable]$GetParameters
                )

                $script:lastGetParameters = $GetParameters
                [ConfluencePS.Space]::new()
            }
        }

        It "does not request metadata labels when listing spaces" {
            $null = Get-Space -ApiUri "https://example.com/wiki/rest/api"

            $script:lastGetParameters['expand'] | Should -BeExactly "description.plain,icon,homepage"
        }
    }
}
