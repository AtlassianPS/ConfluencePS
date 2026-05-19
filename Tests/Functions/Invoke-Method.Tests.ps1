#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Invoke-Method" -Tag 'Unit' {
        BeforeAll {
            if (-not ("ConfluencePS.Tests.FakeHttpException" -as [Type])) {
                Add-Type -TypeDefinition @"
namespace ConfluencePS.Tests {
    using System;

    public class FakeHttpException : Exception {
        public object Response { get; private set; }

        public FakeHttpException(string message, object response) : base(message) {
            this.Response = response;
        }
    }
}
"@
            }

            function script:New-FakeWebResponse {
                param(
                    [int]$StatusCode = 200,
                    [string]$Json = '{"results":[]}',
                    [hashtable]$Headers = @{}
                )

                [PSCustomObject]@{
                    StatusCode       = [System.Net.HttpStatusCode]$StatusCode
                    Content          = $Json
                    RawContentStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($Json))
                    Headers          = $Headers
                }
            }

            Mock Set-TlsLevel -ModuleName ConfluencePS {}
            Mock Test-Captcha -ModuleName ConfluencePS {}
            Mock Start-Sleep -ModuleName ConfluencePS {}
        }

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName ConfluencePS {
                New-FakeWebResponse -StatusCode 200 -Json '{"results":[]}'
            }
        }

        It "URL-encodes GET parameters before invoking the request" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -GetParameters @{
                "sp ace" = "hello/world & me"
            } -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                $Uri.Query -match 'sp(\+|%20)ace=hello%2fworld(\+|%20)%26(\+|%20)me'
            } -Exactly -Times 1 -Scope It
        }

        It "forwards default TimeoutSec to Invoke-WebRequest" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                $TimeoutSec -eq 100
            } -Exactly -Times 1 -Scope It
        }

        It "forwards explicit TimeoutSec to Invoke-WebRequest" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -TimeoutSec 30 -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                $TimeoutSec -eq 30
            } -Exactly -Times 1 -Scope It
        }

        It "omits TimeoutSec from Invoke-WebRequest when TimeoutSec is 0" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -TimeoutSec 0 -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                -not $PSBoundParameters.ContainsKey("TimeoutSec")
            } -Exactly -Times 1 -Scope It
        }

        It "retries once on HTTP 429 and continues successfully" {
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePS {
                if ($script:invokeCount -eq 0) {
                    $script:invokeCount++
                    New-FakeWebResponse -StatusCode 429 -Json '{"message":"rate limited"}' -Headers @{ "Retry-After" = "0" }
                }
                else {
                    New-FakeWebResponse -StatusCode 200 -Json '{"results":[]}'
                }
            }

            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePS -Exactly -Times 1 -Scope It
        }

        It "honors Retry-After without capping or downward jitter" {
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePS {
                if ($script:invokeCount -eq 0) {
                    $script:invokeCount++
                    New-FakeWebResponse -StatusCode 429 -Json '{"message":"rate limited"}' -Headers @{ "Retry-After" = "120" }
                }
                else {
                    New-FakeWebResponse -StatusCode 200 -Json '{"results":[]}'
                }
            }

            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop

            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePS -ParameterFilter {
                [Math]::Abs([double]$Seconds - 120.0) -lt 0.001
            } -Exactly -Times 1 -Scope It
        }

        It "does not retry non-idempotent methods by default" {
            Mock Invoke-WebRequest -ModuleName ConfluencePS {
                New-FakeWebResponse -StatusCode 429 -Json '{"message":"rate limited"}' -Headers @{ "Retry-After" = "1" }
            }

            { Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -Method Post -Body '{}' -ErrorAction Stop } | Should -Throw

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePS -Exactly -Times 0 -Scope It
        }

        It "propagates TimeoutSec to pagination follow-up calls" {
            $script:timeouts = @()
            $script:requestUris = @()
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePS {
                param($Uri, $TimeoutSec)

                $script:timeouts += if ($null -ne $TimeoutSec) { [int]$TimeoutSec } else { $null }
                $script:requestUris += $Uri.AbsoluteUri

                if ($script:invokeCount -eq 0) {
                    $script:invokeCount++
                    return New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1}],"_links":{"base":"https://example.com","next":"/wiki/rest/api/content?start=25"}}'
                }

                New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":2}]}'
            }

            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -TimeoutSec 33 -ErrorAction Stop

            $script:timeouts | Should -HaveCount 2
            $script:timeouts[0] | Should -Be 33
            $script:timeouts[1] | Should -Be 33
            $script:requestUris[1] | Should -Be "https://example.com/wiki/rest/api/content?start=25"
        }

        It "surfaces JSON errorMessages from HTTP error responses" {
            Mock Invoke-WebRequest -ModuleName ConfluencePS {
                New-FakeWebResponse -StatusCode 400 -Json '{"errorMessages":["Alpha issue","Beta issue"]}'
            }

            $thrown = $null
            try {
                $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails.Message | Should -Match "Alpha issue"
        }

        It "surfaces JSON errors object-map messages from HTTP error responses" {
            Mock Invoke-WebRequest -ModuleName ConfluencePS {
                New-FakeWebResponse -StatusCode 400 -Json '{"errors":{"title":"Title invalid","space":"Space denied"}}'
            }

            $thrown = $null
            try {
                $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails.Message | Should -Match "Title invalid"
            $thrown.ErrorDetails.Message | Should -Match "Space denied"
        }

        It "reads HttpResponseMessage content when request throws" {
            $httpResponse = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::BadRequest)
            $httpResponse.Content = [System.Net.Http.StringContent]::new(
                '{"errors":{"field":"Field problem from response content"}}',
                [System.Text.Encoding]::UTF8,
                "application/json"
            )

            Mock Invoke-WebRequest -ModuleName ConfluencePS {
                throw [ConfluencePS.Tests.FakeHttpException]::new("request failed", $httpResponse)
            }

            $thrown = $null
            try {
                $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails.Message | Should -Match "Field problem from response content"
        }
    }
}
