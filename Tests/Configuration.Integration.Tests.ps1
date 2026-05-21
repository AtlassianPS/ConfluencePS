#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
}

Describe "Integration Test Configuration" -Tag 'Integration', 'Smoke', 'Cloud', 'DataCenter' {
    BeforeAll {
        Import-Module $env:BHManifestToTest -Force
        . "$PSScriptRoot/Helpers/IntegrationTestTools.ps1"

        $script:DeploymentType = Get-ConfluenceIntegrationDeploymentType
        $script:RequiredEnvironmentVariables = Get-ConfluenceIntegrationRequiredVariables -DeploymentType $script:DeploymentType
        $script:IntegrationEnvironment = Initialize-IntegrationEnvironment
        $script:IsIntegrationEnvironmentConfigured = $null -ne $script:IntegrationEnvironment

        if ($script:IsIntegrationEnvironmentConfigured) {
            $secureToken = ConvertTo-SecureString -String $script:IntegrationEnvironment.Password -AsPlainText -Force
            $script:Credential = [System.Management.Automation.PSCredential]::new($script:IntegrationEnvironment.Username, $secureToken)
            $script:ApiUri = '{0}/rest/api' -f $script:IntegrationEnvironment.CloudUrl.TrimEnd('/')
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    }

    Context "Required Environment Variables" {
        It "all required variables are configured for the selected track" {
            foreach ($requiredVariable in $script:RequiredEnvironmentVariables) {
                $value = [Environment]::GetEnvironmentVariable($requiredVariable)
                $value | Should -Not -BeNullOrEmpty -Because "$requiredVariable must be configured for the $script:DeploymentType integration track"
            }
        }
    }

    Context "Integration Connectivity" {
        It "can authenticate and query Confluence" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluenceSpace -ApiUri $script:ApiUri -Credential $script:Credential -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }
    }

    Context "Smoke Read Coverage" {
        BeforeAll {
            if ($script:IsIntegrationEnvironmentConfigured) {
                $script:SmokeSpace = Get-ConfluenceSpace -ApiUri $script:ApiUri -Credential $script:Credential -ErrorAction Stop |
                    Select-Object -First 1
                Set-ConfluenceInfo -BaseUri $script:IntegrationEnvironment.CloudUrl -Credential $script:Credential
            }
        }

        It "resolves an accessible space when one is available" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            if (-not $script:SmokeSpace) {
                Set-ItResult -Skipped -Because "No accessible Confluence space was returned"
                return
            }

            $script:SmokeSpace | Should -Not -BeNullOrEmpty
            $script:SmokeSpace.Key | Should -Not -BeNullOrEmpty
        }

        It "can query spaces using defaults configured by Set-ConfluenceInfo" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluenceSpace -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }

        It "can query pages from an accessible space" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }
            if (-not $script:SmokeSpace) {
                Set-ItResult -Skipped -Because "No accessible Confluence space was returned"
                return
            }

            { Get-ConfluencePage -SpaceKey $script:SmokeSpace.Key -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }
    }
}
