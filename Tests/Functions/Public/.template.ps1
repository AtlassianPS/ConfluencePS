#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope ConfluencePS {
    Describe "%FUNCTION-NAME%" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:apiUri = 'https://confluence.example.com/wiki/rest/api'
            $script:credential = [System.Management.Automation.PSCredential]::Empty

            $resourceJson = @"
{
    "id": "123",
    "title": "Example"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Invoke-Method -ModuleName ConfluencePS {
                throw "Unhandled Invoke-Method call: $Method $Uri"
            }
            #endregion Mocks
        }

        Describe 'Signature' {
            <#
            Signature tests lock down parameters, types, default values, and mandatory status.
            Add only contract assertions that should fail when the public interface changes.
            #>
            BeforeAll {
                $script:command = Get-Command -Name '%FUNCTION-NAME%'
            }

            Context 'Parameter Types' {
                It "has a parameter '<ParameterName>' of type '<ParameterType>'" -TestCases @(
                    @{ ParameterName = 'ApiUri'; ParameterType = [uri] }
                    @{ ParameterName = 'Credential'; ParameterType = [System.Management.Automation.PSCredential] }
                ) {
                    $script:command | Should -HaveParameter $ParameterName -Type $ParameterType
                }
            }

            Context 'Mandatory Parameters' {
                It "marks '<ParameterName>' as mandatory" -TestCases @(
                    @{ ParameterName = 'ApiUri' }
                ) {
                    $script:command | Should -HaveParameter $ParameterName -Mandatory
                }
            }
        }

        Describe 'Behavior' {
            <#
            Behavior tests should cover request shape, branching, output conversion,
            paging, pipeline input, and expected error paths.
            #>
            Context 'API calls' {
                It 'calls Invoke-Method with the expected request shape' {
                    Mock Invoke-Method -ModuleName ConfluencePS -ParameterFilter {
                        $Method -eq 'Get' -and $Uri -like "$script:apiUri/*"
                    } {
                        ConvertFrom-Json -InputObject $resourceJson
                    }

                    { %FUNCTION-NAME% -ApiUri $script:apiUri -Credential $script:credential } | Should -Not -Throw

                    Should -Invoke Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and $Uri -like "$script:apiUri/*"
                    }
                }
            }

            Context 'Output conversion' {
                It 'returns the expected output shape' {
                    Mock Invoke-Method -ModuleName ConfluencePS {
                        ConvertFrom-Json -InputObject $resourceJson
                    }

                    $result = %FUNCTION-NAME% -ApiUri $script:apiUri -Credential $script:credential

                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe 'Input Validation' {
            <#
            Input validation tests should cover invalid and valid parameter-set combinations,
            pipeline binding, multiple-item input, and useful error messages.
            #>
            Context 'Negative cases' {
                It 'rejects invalid input with a useful error' {
                    { %INVALID-COMMAND% } | Should -Throw -ExpectedMessage '%ERROR MESSAGE%'
                }
            }

            Context 'Positive cases' {
                It 'accepts valid input' {
                    Mock Invoke-Method -ModuleName ConfluencePS {
                        ConvertFrom-Json -InputObject $resourceJson
                    }

                    { %FUNCTION-NAME% -ApiUri $script:apiUri -Credential $script:credential } | Should -Not -Throw
                }
            }

            Context 'Pipeline support' {
                It 'accepts pipeline input when supported' {
                    Mock Invoke-Method -ModuleName ConfluencePS {
                        ConvertFrom-Json -InputObject $resourceJson
                    }

                    { %PIPELINE-INPUT% | %FUNCTION-NAME% -ApiUri $script:apiUri -Credential $script:credential } | Should -Not -Throw
                }
            }

            Context 'Multiple items' {
                It 'processes every item in a collection when supported' {
                    Mock Invoke-Method -ModuleName ConfluencePS {
                        ConvertFrom-Json -InputObject $resourceJson
                    }

                    { %FUNCTION-NAME% -%PARAMETER% @('one', 'two') -ApiUri $script:apiUri -Credential $script:credential } | Should -Not -Throw

                    Should -Invoke Invoke-Method -ModuleName ConfluencePS -Exactly -Times 2 -Scope It
                }
            }
        }
    }
}
