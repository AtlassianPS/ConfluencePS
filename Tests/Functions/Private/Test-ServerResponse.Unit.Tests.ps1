#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Test-ServerResponse" -Tag 'Unit' {
        BeforeAll {
            if (-not ("System.Net.Http.HttpResponseMessage" -as [Type])) {
                Add-Type -AssemblyName System.Net.Http
            }

            Mock Start-Sleep -ModuleName ConfluencePS {}
        }

        BeforeEach {
            Mock Get-Random -ModuleName ConfluencePS { 1.0 }
        }

        It "uses Retry-After HTTP-date as minimum retry delay" {
            Mock Get-Date -ModuleName ConfluencePS { [DateTimeOffset]"2026-01-01T00:00:00Z" }
            $response = [PSCustomObject]@{
                StatusCode = 429
                Headers    = @{ "Retry-After" = "Thu, 01 Jan 2026 00:02:00 GMT" }
            }

            $result = Test-ServerResponse -InputObject $response -Method Get -RetryCount 0 -MaxRetries 3

            $result | Should -BeTrue
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePS -ParameterFilter {
                [Math]::Abs([double]$Seconds - 120.0) -lt 0.001
            } -Exactly -Times 1 -Scope It
        }

        It "uses Retry-After from HttpResponseHeaders RetryAfter property" {
            $response = [System.Net.Http.HttpResponseMessage]::new(
                [System.Enum]::ToObject([System.Net.HttpStatusCode], 429)
            )
            $response.Headers.RetryAfter = [System.Net.Http.Headers.RetryConditionHeaderValue]::new([TimeSpan]::FromSeconds(90))

            $result = Test-ServerResponse -InputObject $response -Method Get -RetryCount 0 -MaxRetries 3

            $result | Should -BeTrue
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePS -ParameterFilter {
                [Math]::Abs([double]$Seconds - 90.0) -lt 0.001
            } -Exactly -Times 1 -Scope It
        }

        It "uses capped exponential backoff when Retry-After is absent" {
            $response = [PSCustomObject]@{
                StatusCode = 429
                Headers    = @{}
            }

            $result = Test-ServerResponse -InputObject $response -Method Get -RetryCount 2 -MaxRetries 3

            $result | Should -BeTrue
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePS -ParameterFilter {
                [Math]::Abs([double]$Seconds - 60.0) -lt 0.001
            } -Exactly -Times 1 -Scope It
        }

        It "does not retry POST by default" {
            $response = [PSCustomObject]@{
                StatusCode = 503
                Headers    = @{ "Retry-After" = "10" }
            }

            $result = Test-ServerResponse -InputObject $response -Method Post -RetryCount 0 -MaxRetries 3

            $result | Should -BeNullOrEmpty
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePS -Exactly -Times 0 -Scope It
        }
    }
}
