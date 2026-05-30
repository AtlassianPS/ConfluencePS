#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope ConfluencePS {
    Describe "%FUNCTION-NAME%" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $sampleJson = @"
{
    "id": "123",
    "title": "Example"
}
"@

            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
        }

        Describe 'Behavior' {
            Context 'Object conversion' {
                It 'creates the expected object' {
                    $result = %FUNCTION-NAME% -InputObject $script:sampleObject

                    $result | Should -Not -BeNullOrEmpty
                    $result.ID | Should -Be '123'
                }
            }

            Context 'Pipeline support' {
                It 'accepts input from the pipeline' {
                    $result = $script:sampleObject | %FUNCTION-NAME%

                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
