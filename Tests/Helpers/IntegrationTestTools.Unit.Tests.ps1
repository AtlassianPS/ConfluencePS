#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

Describe 'Integration test readiness helpers' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/IntegrationTestTools.ps1"
    }

    BeforeEach {
        Mock -CommandName Start-Sleep -MockWith {}
    }

    It 'returns the first successful polling result' {
        $script:attemptCount = 0

        $result = Wait-ConfluenceIntegrationResult -MaximumAttempts 3 -DelaySeconds 1 -FailureMessage 'Resource did not become readable.' -Operation {
            $script:attemptCount++
            if ($script:attemptCount -eq 3) { 'ready' }
        }

        $result | Should -BeExactly 'ready'
        $script:attemptCount | Should -Be 3
        Should -Invoke -CommandName Start-Sleep -Times 2 -Exactly -ParameterFilter { $Seconds -eq 1 }
    }

    It 'retries terminating errors and reports the last error' {
        $script:attemptCount = 0

        {
            Wait-ConfluenceIntegrationResult -MaximumAttempts 2 -DelaySeconds 1 -FailureMessage 'Resource did not become readable.' -Operation {
                $script:attemptCount++
                throw [System.ArgumentException]::new('Invalid Server Response')
            }
        } | Should -Throw -ExpectedMessage 'Resource did not become readable. Last error: Invalid Server Response'

        $script:attemptCount | Should -Be 2
        Should -Invoke -CommandName Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 1 }
    }

    It 'reports a falsy final attempt instead of an earlier transient error' {
        $script:attemptCount = 0

        {
            Wait-ConfluenceIntegrationResult -MaximumAttempts 2 -DelaySeconds 1 -FailureMessage 'Resource did not become readable.' -Operation {
                $script:attemptCount++
                if ($script:attemptCount -eq 1) {
                    throw [System.ArgumentException]::new('Invalid Server Response')
                }
                $null
            }
        } | Should -Throw -ExpectedMessage 'Resource did not become readable.'

        $script:attemptCount | Should -Be 2
    }

    It 'does not retry unexpected errors' {
        {
            Wait-ConfluenceIntegrationResult -MaximumAttempts 3 -DelaySeconds 1 -FailureMessage 'Resource did not become readable.' -Operation {
                throw [System.InvalidOperationException]::new('Broken test operation')
            }
        } | Should -Throw -ExpectedMessage 'Broken test operation'

        Should -Invoke -CommandName Start-Sleep -Times 0 -Exactly
    }

    It 'does not sleep after the final unsuccessful attempt' {
        {
            Wait-ConfluenceIntegrationResult -MaximumAttempts 1 -DelaySeconds 1 -FailureMessage 'Resource did not become readable.' -Operation { $null }
        } | Should -Throw -ExpectedMessage 'Resource did not become readable.'

        Should -Invoke -CommandName Start-Sleep -Times 0 -Exactly
    }
}
