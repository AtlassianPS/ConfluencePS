#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-AttachmentFile" -Tag 'Unit' {
        BeforeEach {
            $script:preserveAuthorizationOnRedirectAtInvoke = $null
            Mock Invoke-Method -ModuleName ConfluencePS {
                $script:preserveAuthorizationOnRedirectAtInvoke = $script:ConfluencePSPreserveAuthorizationOnRedirect
                $null
            }
        }

        It "preserves authorization for Confluence Cloud attachment downloads" {
            $attachment = [ConfluencePS.Attachment]::new()
            $attachment.URL = "https://tenant.atlassian.net/wiki/download/attachments/123/Test.txt"
            $attachment.MediaType = "text/plain"
            $attachment.Filename = "123_Test.txt"

            $null = Get-AttachmentFile -ApiUri "https://tenant.atlassian.net/wiki/rest/api" -Attachment $attachment

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It
            $script:preserveAuthorizationOnRedirectAtInvoke | Should -BeTrue
        }

        It "does not preserve authorization for non-Cloud attachment downloads" {
            $attachment = [ConfluencePS.Attachment]::new()
            $attachment.URL = "http://localhost:1990/confluence/download/attachments/123/Test.txt"
            $attachment.MediaType = "text/plain"
            $attachment.Filename = "123_Test.txt"

            $null = Get-AttachmentFile -ApiUri "http://localhost:1990/confluence/rest/api" -Attachment $attachment

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It
            $script:preserveAuthorizationOnRedirectAtInvoke | Should -BeNullOrEmpty
        }
    }
}
