﻿#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSAvoidUsingConvertToSecureStringWithPlainText",
    "",
    Justification = "Integration tests require plaintext credential conversion for API tokens"
)]
param()

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
}

$script:RequiredEnvironmentVariables = @(
    'WikiURI'
    'WikiUser'
    'WikiPass'
)

Describe "Integration Test Configuration" -Tag 'Integration', 'Smoke', 'Cloud' {
    BeforeAll {
        Import-Module $env:BHManifestToTest -Force

        $script:IsIntegrationEnvironmentConfigured = @(
            $script:RequiredEnvironmentVariables | Where-Object {
                [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_))
            }
        ).Count -eq 0

        if ($script:IsIntegrationEnvironmentConfigured) {
            $secureToken = ConvertTo-SecureString -String $env:WikiPass -AsPlainText -Force
            $script:Credential = [System.Management.Automation.PSCredential]::new($env:WikiUser, $secureToken)
            $script:ApiUri = '{0}/rest/api' -f $env:WikiURI.TrimEnd('/')
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    }

    Context "Required Environment Variables" {
        It "WikiURI is configured" {
            $value = [Environment]::GetEnvironmentVariable('WikiURI')
            $value | Should -Not -BeNullOrEmpty -Because "WikiURI secret must be configured in repository settings"
        }

        It "WikiUser is configured" {
            $value = [Environment]::GetEnvironmentVariable('WikiUser')
            $value | Should -Not -BeNullOrEmpty -Because "WikiUser secret must be configured in repository settings"
        }

        It "WikiPass is configured" {
            $value = [Environment]::GetEnvironmentVariable('WikiPass')
            $value | Should -Not -BeNullOrEmpty -Because "WikiPass secret must be configured in repository settings"
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
