#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-ServerInformation" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePS {
                $response = [PSCustomObject]@{
                    cloudId          = 'cloud-id'
                    commitHash       = 'abc123'
                    baseUrl          = 'https://docs.example.com/wiki'
                    fallbackBaseUrl  = 'https://tenant.atlassian.net/wiki'
                    edition          = 'standard'
                    siteTitle        = 'Docs'
                    defaultLocale    = 'en_US'
                    defaultTimeZone  = 'UTC'
                    microsPerimeter  = 'commercial'
                }
                if ($OutputType -eq [ConfluencePS.ServerInformation]) { return $response | ConvertTo-ServerInformation }
                $response
            }
        }

        It "calls the system info endpoint" {
            $result = Get-ServerInformation -ApiUri "https://docs.example.com/wiki/rest/api"

            $result | Should -BeOfType [ConfluencePS.ServerInformation]
            $result.DeploymentType | Should -Be 'Cloud'
            $result.CloudId | Should -Be 'cloud-id'
            $result.BaseUrl.AbsoluteUri | Should -Be 'https://docs.example.com/wiki'
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq 'https://docs.example.com/wiki/rest/api/settings/systemInfo' -and
                $OutputType -eq [ConfluencePS.ServerInformation]
            }
        }

        It "maps responses without cloudId to DataCenter" {
            Mock Invoke-Method -ModuleName ConfluencePS {
                $response = [PSCustomObject]@{
                    baseUrl     = 'https://docs.example.com/wiki'
                    version     = '9.2.0'
                    buildNumber = 9200
                    siteTitle   = 'Docs'
                }
                if ($OutputType -eq [ConfluencePS.ServerInformation]) { return $response | ConvertTo-ServerInformation }
                $response
            }

            $result = Get-ServerInformation -ApiUri "https://docs.example.com/wiki/rest/api"

            $result.DeploymentType | Should -Be 'DataCenter'
            $result.Version | Should -Be '9.2.0'
            $result.BuildNumber | Should -Be 9200
        }

        It "prefers cloudId when determining deployment type" {
            Mock Invoke-Method -ModuleName ConfluencePS {
                $response = [PSCustomObject]@{
                    cloudId        = 'cloud-id'
                    deploymentType = 'DataCenter'
                }
                if ($OutputType -eq [ConfluencePS.ServerInformation]) { return $response | ConvertTo-ServerInformation }
                $response
            }

            $result = Get-ServerInformation -ApiUri "https://docs.example.com/wiki/rest/api"

            $result.DeploymentType | Should -Be 'Cloud'
        }

        It "defaults to DataCenter when system info cannot be retrieved" {
            Mock Invoke-Method -ModuleName ConfluencePS { throw "failed" }

            $result = Get-ServerInformation -ApiUri "https://docs.example.com/wiki/rest/api"

            $result | Should -BeOfType [ConfluencePS.ServerInformation]
            $result.DeploymentType | Should -Be 'DataCenter'
        }

        It "defaults to DataCenter when system info returns no object" {
            Mock Invoke-Method -ModuleName ConfluencePS {}

            $result = Get-ServerInformation -ApiUri "https://docs.example.com/wiki/rest/api"

            $result | Should -BeOfType [ConfluencePS.ServerInformation]
            $result.DeploymentType | Should -Be 'DataCenter'
        }
    }
}
