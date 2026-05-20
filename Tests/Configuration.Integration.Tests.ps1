#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"
    . "$PSScriptRoot/Helpers/IntegrationTestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    $script:DeploymentType = Get-ConfluenceIntegrationDeploymentType
    $script:RequiredEnvironmentVariables = Get-ConfluenceIntegrationRequiredVariables -DeploymentType $script:DeploymentType
}

Describe "Integration Test Configuration" -Tag 'Integration', 'Smoke', 'Cloud', 'DataCenter' {
    BeforeAll {
        Import-Module $env:BHManifestToTest -Force

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
        foreach ($requiredVariable in $script:RequiredEnvironmentVariables) {
            It "$requiredVariable is configured" {
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
}
