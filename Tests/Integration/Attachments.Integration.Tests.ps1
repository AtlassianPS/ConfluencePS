#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath (Split-Path $PSScriptRoot -Parent)
}

Describe 'Confluence attachment integration' -Tag 'Integration', 'Cloud', 'DataCenter' {
    BeforeAll {
        . "$PSScriptRoot/Helpers/ConfluenceIntegrationFixture.ps1"
        $script:fixture = New-ConfluenceIntegrationFixture
        if ($script:fixture.IsConfigured) {
            $script:space = New-ConfluenceIntegrationSpace -Fixture $script:fixture -NamePrefix 'Attachments'
            $script:page = New-ConfluenceIntegrationPage -Fixture $script:fixture -SpaceKey $script:space.Key -TitlePrefix 'Attachment Page'
            $script:firstFile = New-ConfluenceIntegrationAttachmentFile -Fixture $script:fixture -Content 'First attachment body'
            $script:secondFile = New-ConfluenceIntegrationAttachmentFile -Fixture $script:fixture -Content 'Updated attachment body'
            $script:downloadDir = Join-Path ([System.IO.Path]::GetTempPath()) "ConfluencePS-IntTest-Download-$([Guid]::NewGuid().ToString('N'))"
            $null = New-Item -Path $script:downloadDir -ItemType Directory -Force
            $null = $script:fixture.Files.Add($script:downloadDir)
        }
    }

    AfterAll {
        if ($script:fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:fixture
        }
    }

    It 'adds and lists a page attachment' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $script:attachment = Add-ConfluenceAttachment -PageID $script:page.ID -FilePath $script:firstFile -ErrorAction Stop
        $attachments = Get-ConfluenceAttachment -PageID $script:page.ID -ErrorAction Stop
        $fileName = [IO.Path]::GetFileName($script:firstFile)

        $script:attachment | Should -BeOfType [ConfluencePS.Attachment]
        @($attachments | Where-Object { $_.Title -eq $fileName }).Count | Should -BeGreaterThan 0
    }

    It 'updates an existing attachment' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $updated = Set-ConfluenceAttachment -Attachment $script:attachment -FilePath $script:secondFile -ErrorAction Stop

        $updated | Should -BeOfType [ConfluencePS.Attachment]
        $updated.ID | Should -Be $script:attachment.ID
        $script:attachment = $updated
    }

    It 'downloads and removes the attachment' {
        if (-not $script:fixture.IsConfigured) {
            Set-ItResult -Skipped -Because $script:fixture.SkipReason
            return
        }

        $downloaded = Get-ConfluenceAttachmentFile -Attachment $script:attachment -Path $script:downloadDir -ErrorAction Stop
        $downloaded | Should -Be $true

        $null = Remove-ConfluenceAttachment -Attachment $script:attachment -Confirm:$false -ErrorAction Stop
        $attachments = Get-ConfluenceAttachment -PageID $script:page.ID -ErrorAction Stop

        @($attachments | Where-Object { $_.ID -eq $script:attachment.ID }).Count | Should -Be 0
    }
}
