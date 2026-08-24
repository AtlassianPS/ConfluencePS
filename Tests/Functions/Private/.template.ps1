#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope ConfluencePS {
    Describe "%FUNCTION-NAME%" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $sampleJson = @"
{
    "id": "123",
    "title": "Example",
    "created": "2025-01-01T00:00:00.000Z"
}
"@

            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            # Converter functions typically do not need mocks.
            # Add mocks here only when the helper calls other functions.
            #endregion Mocks
        }

        Describe 'Behavior' {
            BeforeAll {
                $script:result = %FUNCTION-NAME% -InputObject $script:sampleObject
            }

            Context 'Object conversion' {
                It 'creates a PSObject out of JSON input' {
                    $script:result | Should -Not -BeNullOrEmpty
                    $script:result | Should -BeOfType [PSCustomObject]
                }

                It "adds the expected custom type name" {
                    $script:result.PSObject.TypeNames[0] | Should -Be 'ConfluencePS.%RESOURCE%'
                }
            }

            Context 'Property mapping' {
                It "defines '<Property>' of type '<Type>' with value '<Value>'" -TestCases @(
                    @{ Property = 'ID'; Type = [string]; Value = '123' }
                    @{ Property = 'Title'; Type = [string]; Value = 'Example' }
                    @{ Property = 'Created'; Type = [System.DateTime]; Value = (Get-Date '2025-01-01T00:00:00.000Z') }
                ) {
                    if ($Value) {
                        $script:result.$Property | Should -Be $Value
                    }
                    else {
                        $script:result.$Property | Should -Not -BeNullOrEmpty
                    }

                    if ($Type -is [string]) {
                        $script:result.$Property.PSObject.TypeNames[0] | Should -Be $Type
                    }
                    else {
                        $script:result.$Property | Should -BeOfType $Type
                    }
                }
            }

            Context 'Pipeline support' {
                It 'accepts input from the pipeline' {
                    $pipelineResult = $script:sampleObject | %FUNCTION-NAME%

                    $pipelineResult | Should -Not -BeNullOrEmpty
                    $pipelineResult.PSObject.TypeNames[0] | Should -Be 'ConfluencePS.%RESOURCE%'
                }

                It 'handles array input' {
                    $arrayResult = @($script:sampleObject, $script:sampleObject) | %FUNCTION-NAME%

                    @($arrayResult).Count | Should -Be 2
                }
            }
        }
    }
}
