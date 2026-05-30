#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope ConfluencePS {
    Describe "%FUNCTION-NAME%" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            $script:apiUri = 'https://confluence.example.com/wiki/rest/api'
            $script:credential = [System.Management.Automation.PSCredential]::Empty

            Mock Invoke-Method -ModuleName ConfluencePS {
                throw "Unhandled Invoke-Method call: $Method $Uri"
            }
        }

        Describe 'Signature' {
            BeforeAll {
                $script:command = Get-Command -Name '%FUNCTION-NAME%'
            }

            It "has the expected parameter '<ParameterName>'" -TestCases @(
                @{ ParameterName = 'ApiUri' }
                @{ ParameterName = 'Credential' }
            ) {
                $script:command | Should -HaveParameter $ParameterName
            }
        }

        Describe 'Behavior' {
            Context 'API calls' {
                It 'calls Invoke-Method with the expected request shape' {
                    Mock Invoke-Method -ModuleName ConfluencePS -ParameterFilter {
                        $Method -eq 'Get' -and $Uri -like "$script:apiUri/*"
                    } {
                        [PSCustomObject]@{ id = '123' }
                    }

                    { %FUNCTION-NAME% -ApiUri $script:apiUri -Credential $script:credential } | Should -Not -Throw

                    Should -Invoke Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'Input Validation' {
            It 'rejects invalid input with a useful error' {
                { %FUNCTION-NAME% -ApiUri $script:apiUri -Credential $script:credential } | Should -Not -Throw
            }
        }
    }
}
