#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-AttachmentFile" -Tag 'Unit' {
        BeforeAll {
            function New-TestAttachment {
                param(
                    [UInt64]$ID = 456,
                    [UInt64]$PageID = 123,
                    [string]$URL = "https://example.com/wiki/download/attachments/123/Test.txt"
                )

                $attachment = [ConfluencePS.Attachment]::new()
                $attachment.ID = $ID
                $attachment.PageID = $PageID
                $attachment.URL = $URL
                $attachment.Filename = "Test.txt"
                $attachment.MediaType = "text/plain"
                $attachment
            }
        }

        BeforeEach {
            Mock Get-ServerInformation -ModuleName ConfluencePS { [ConfluencePS.ServerInfo]@{ DeploymentType = 'Cloud' } }
            Mock Invoke-Method -ModuleName ConfluencePS {}
        }

        It "uses the REST download endpoint for Cloud API paths on custom domains" {
            $attachment = New-TestAttachment -URL "https://docs.example.com/wiki/download/attachments/123/Test.txt"

            $result = Get-AttachmentFile -ApiUri "https://docs.example.com/wiki/rest/api" -Attachment $attachment

            $result | Should -Be $true
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "https://docs.example.com/wiki/rest/api/content/123/child/attachment/456/download" -and
                $Headers.Accept -eq "*/*"
            }
        }

        It "preserves Data Center attachment URLs" {
            $attachment = New-TestAttachment -URL "http://localhost:1990/confluence/download/attachments/123/Test.txt"

            Mock Get-ServerInformation -ModuleName ConfluencePS { [ConfluencePS.ServerInfo]@{ DeploymentType = 'DataCenter' } }

            $result = Get-AttachmentFile -ApiUri "http://localhost:1990/confluence/rest/api" -Attachment $attachment

            $result | Should -Be $true
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "http://localhost:1990/confluence/download/attachments/123/Test.txt" -and
                $Headers.Accept -eq "text/plain"
            }
        }

        It "preserves Data Center attachment URLs when Data Center is hosted under /wiki" {
            $attachment = New-TestAttachment -URL "https://docs.example.com/wiki/download/attachments/123/Test.txt"

            Mock Get-ServerInformation -ModuleName ConfluencePS { [ConfluencePS.ServerInfo]@{ DeploymentType = 'DataCenter' } }

            $result = Get-AttachmentFile -ApiUri "https://docs.example.com/wiki/rest/api" -Attachment $attachment

            $result | Should -Be $true
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "https://docs.example.com/wiki/download/attachments/123/Test.txt" -and
                $Headers.Accept -eq "text/plain"
            }
        }

        It "preserves attachment URLs when server information falls back to Data Center" {
            $attachment = New-TestAttachment -URL "https://docs.example.com/wiki/download/attachments/123/Test.txt"

            Mock Get-ServerInformation -ModuleName ConfluencePS { [ConfluencePS.ServerInfo]@{ DeploymentType = 'DataCenter' } }

            $result = Get-AttachmentFile -ApiUri "https://docs.example.com/wiki/rest/api" -Attachment $attachment

            $result | Should -Be $true
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "https://docs.example.com/wiki/download/attachments/123/Test.txt" -and
                $Headers.Accept -eq "text/plain"
            }
        }
    }
}
