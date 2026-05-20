#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
}

$script:RequiredEnvironmentVariables = @(
    'CONFLUENCE_CLOUD_URL'
    'ATLASSIAN_CLOUD_USER'
    'ATLASSIAN_CLOUD_PAT'
)

Describe "Integration Test Configuration" -Tag 'Integration', 'Smoke', 'Cloud' {
    BeforeAll {
        Import-Module $env:BHManifestToTest -Force

        $script:CloudUrl = [Environment]::GetEnvironmentVariable('CONFLUENCE_CLOUD_URL')
        if ([string]::IsNullOrWhiteSpace($script:CloudUrl)) {
            $script:CloudUrl = [Environment]::GetEnvironmentVariable('WikiURI')
        }

        $script:CloudUser = [Environment]::GetEnvironmentVariable('ATLASSIAN_CLOUD_USER')
        if ([string]::IsNullOrWhiteSpace($script:CloudUser)) {
            $script:CloudUser = [Environment]::GetEnvironmentVariable('WikiUser')
        }

        $script:CloudPat = [Environment]::GetEnvironmentVariable('ATLASSIAN_CLOUD_PAT')
        if ([string]::IsNullOrWhiteSpace($script:CloudPat)) {
            $script:CloudPat = [Environment]::GetEnvironmentVariable('WikiPass')
        }

        $script:IsIntegrationEnvironmentConfigured = @(
            $script:RequiredEnvironmentVariables | Where-Object {
                [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_))
            }
        ).Count -eq 0

        if ($script:IsIntegrationEnvironmentConfigured) {
            $secureToken = ConvertTo-SecureString -String $script:CloudPat -AsPlainText -Force
            $script:Credential = [System.Management.Automation.PSCredential]::new($script:CloudUser, $secureToken)
            $script:ApiUri = '{0}/rest/api' -f $script:CloudUrl.TrimEnd('/')
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    }

    Context "Required Environment Variables" {
        It "CONFLUENCE_CLOUD_URL is configured" {
            $value = [Environment]::GetEnvironmentVariable('CONFLUENCE_CLOUD_URL')
            $value | Should -Not -BeNullOrEmpty -Because "CONFLUENCE_CLOUD_URL variable must be configured in repository settings"
        }

        It "ATLASSIAN_CLOUD_USER is configured" {
            $value = [Environment]::GetEnvironmentVariable('ATLASSIAN_CLOUD_USER')
            $value | Should -Not -BeNullOrEmpty -Because "ATLASSIAN_CLOUD_USER variable must be configured in repository settings"
        }

        It "ATLASSIAN_CLOUD_PAT is configured" {
            $value = [Environment]::GetEnvironmentVariable('ATLASSIAN_CLOUD_PAT')
            $value | Should -Not -BeNullOrEmpty -Because "ATLASSIAN_CLOUD_PAT secret must be configured in repository settings"
        }
    }

    Context "Cloud Connectivity" {
        It "can authenticate and query Confluence Cloud" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluenceSpace -ApiUri $script:ApiUri -Credential $script:Credential -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }
    }
}
