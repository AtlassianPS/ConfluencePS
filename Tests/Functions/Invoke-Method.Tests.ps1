#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Invoke-Method" -Tag 'Unit' {
        BeforeAll {
            if (-not ("System.Net.Http.HttpResponseMessage" -as [Type])) {
                Add-Type -AssemblyName System.Net.Http
            }

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

                $statusCodeEnum = [System.Enum]::ToObject([System.Net.HttpStatusCode], $StatusCode)

                [PSCustomObject]@{
                    StatusCode       = $statusCodeEnum
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

        It "forwards PersonalAccessToken to Invoke-WebRequest" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -PersonalAccessToken "token-value" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                $PersonalAccessToken -eq "token-value"
            } -Exactly -Times 1 -Scope It
        }

        It "preserves authorization on redirects for file downloads" {
            if (-not (Get-Command 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.ContainsKey("PreserveAuthorizationOnRedirect")) {
                Set-ItResult -Skipped -Because "PreserveAuthorizationOnRedirect is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)

            $null = Invoke-Method -Uri "https://tenant.atlassian.net/wiki/download/attachments/file.txt" -Credential $credential -OutFile "attachment.txt" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                $PreserveAuthorizationOnRedirect
            } -Exactly -Times 1 -Scope It
        }

        It "does not preserve authorization on redirects for non-Atlassian file downloads" {
            if (-not (Get-Command 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.ContainsKey("PreserveAuthorizationOnRedirect")) {
                Set-ItResult -Skipped -Because "PreserveAuthorizationOnRedirect is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)

            $null = Invoke-Method -Uri "https://example.com/wiki/download/attachments/file.txt" -Credential $credential -OutFile "attachment.txt" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                -not $PreserveAuthorizationOnRedirect
            } -Exactly -Times 1 -Scope It
        }

        It "supports PersonalAccessToken in the private Invoke-WebRequest wrapper" {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                Set-ItResult -Skipped -Because "PowerShell 5.1 wrapper handles PersonalAccessToken separately."
                return
            }

            (Get-Command -Name Invoke-WebRequest).Parameters.Keys | Should -Contain "PersonalAccessToken"
        }

        It "omits TimeoutSec from Invoke-WebRequest when TimeoutSec is 0" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -TimeoutSec 0 -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                -not $PSBoundParameters.ContainsKey("TimeoutSec")
            } -Exactly -Times 1 -Scope It
        }

        It "allows unencrypted authentication only when explicitly enabled for localhost" {
            if (
                ($PSVersionTable.PSVersion.Major -lt 6) -or
                (-not (Get-Command Invoke-WebRequest).Parameters.ContainsKey("AllowUnencryptedAuthentication"))
            ) {
                Set-ItResult -Skipped -Because "AllowUnencryptedAuthentication is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)

            $originalFlag = $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH
            $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = "true"

            try {
                $null = Invoke-Method -Uri "http://localhost/wiki/rest/api/content" -Credential $credential -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                    $AllowUnencryptedAuthentication
                } -Exactly -Times 1 -Scope It
            }
            finally {
                $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $originalFlag
            }
        }

        It "does not set unencrypted authentication when explicit opt-in is missing" {
            if (
                ($PSVersionTable.PSVersion.Major -lt 6) -or
                (-not (Get-Command Invoke-WebRequest).Parameters.ContainsKey("AllowUnencryptedAuthentication"))
            ) {
                Set-ItResult -Skipped -Because "AllowUnencryptedAuthentication is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)
            $originalFlag = $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH
            $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $null

            try {
                $null = Invoke-Method -Uri "http://localhost/wiki/rest/api/content" -Credential $credential -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                    -not $AllowUnencryptedAuthentication
                } -Exactly -Times 1 -Scope It
            }
            finally {
                $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $originalFlag
            }
        }

        It "does not set unencrypted authentication for non-local HTTP hosts" {
            if (
                ($PSVersionTable.PSVersion.Major -lt 6) -or
                (-not (Get-Command Invoke-WebRequest).Parameters.ContainsKey("AllowUnencryptedAuthentication"))
            ) {
                Set-ItResult -Skipped -Because "AllowUnencryptedAuthentication is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)
            $originalFlag = $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH
            $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = "true"

            try {
                $null = Invoke-Method -Uri "http://example.com/wiki/rest/api/content" -Credential $credential -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                    -not $AllowUnencryptedAuthentication
                } -Exactly -Times 1 -Scope It
            }
            finally {
                $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $originalFlag
            }
        }

        It "does not set unencrypted authentication for HTTPS requests" {
            if (
                ($PSVersionTable.PSVersion.Major -lt 6) -or
                (-not (Get-Command Invoke-WebRequest).Parameters.ContainsKey("AllowUnencryptedAuthentication"))
            ) {
                Set-ItResult -Skipped -Because "AllowUnencryptedAuthentication is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)
            $originalFlag = $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH
            $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = "true"

            try {
                $null = Invoke-Method -Uri "https://localhost/wiki/rest/api/content" -Credential $credential -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -ParameterFilter {
                    -not $AllowUnencryptedAuthentication
                } -Exactly -Times 1 -Scope It
            }
            finally {
                $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $originalFlag
            }
        }

        It "handles success payloads with duplicate JSON key casing" {
            if (-not (Get-Command ConvertFrom-Json).Parameters.ContainsKey("AsHashtable")) {
                Set-ItResult -Skipped -Because "ConvertFrom-Json -AsHashtable is unavailable in this PowerShell version."
                return
            }

            Mock Invoke-WebRequest -ModuleName ConfluencePS {
                New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1,"subType":"page","subtype":"page"}]}'
            }

            { $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePS -Exactly -Times 1 -Scope It
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
