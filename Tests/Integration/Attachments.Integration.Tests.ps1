#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

param()

Describe 'Attachment integration tests' -Tag Integration, Cloud, DataCenter {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
        $script:fixture = New-ConfluenceIntegrationFixture

        if ($script:fixture.IsConfigured) {
            $script:pageSet = New-ConfluenceIntegrationPageSet -Fixture $script:fixture -SpaceNamePrefix 'ConfluencePS Attachments'
            $script:textFile = Get-Item -Path "$PSScriptRoot/../resources/Test.txt"
            $script:imageFile = Get-Item -Path "$PSScriptRoot/../resources/Test.png"
            $script:excelFile = Get-Item -Path "$PSScriptRoot/../resources/Test.xlsx"
        }
    }

    AfterAll {
        if ($script:fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:fixture
        }
    }

    Context 'Add-ConfluenceAttachment' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:originalWarningPreference = $WarningPreference
                $WarningPreference = 'SilentlyContinue'

                $script:addResult1 = Add-ConfluenceAttachment -PageId $script:pageSet.Page1.Id -FilePath $script:textFile.FullName -ErrorAction Stop
                $script:addResult2 = Add-ConfluenceAttachment -PageId $script:pageSet.Page1.Id -FilePath $script:imageFile.FullName, $script:excelFile.FullName -ErrorAction Stop
                $script:addResult3 = Add-ConfluenceAttachment $script:pageSet.Page2.Id -FilePath $script:textFile.FullName -ErrorAction Stop
                $script:addResult4 = $script:pageSet.Page2 | Add-ConfluenceAttachment -FilePath $script:imageFile.FullName -ErrorAction Stop
                $script:addResult5 = $script:pageSet.Page3 | Add-ConfluenceAttachment -FilePath $script:imageFile.FullName, $script:excelFile.FullName -ErrorAction Stop
                $script:addResult6 = $script:textFile, $script:imageFile, $script:excelFile | Add-ConfluenceAttachment -PageId $script:pageSet.Page4.Id -ErrorAction Stop
            }
        }

        AfterAll {
            if ($script:fixture.IsConfigured) {
                $WarningPreference = $script:originalWarningPreference
            }
        }

        It 'attaches files by page ID, page pipeline, positional input, and file pipeline' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:addResult1).Count | Should -Be 1
            @($script:addResult2).Count | Should -Be 2
            @($script:addResult3).Count | Should -Be 1
            @($script:addResult4).Count | Should -Be 1
            @($script:addResult5).Count | Should -Be 2
            @($script:addResult6).Count | Should -Be 3
            $script:addResult1 | Should -BeOfType [ConfluencePS.Attachment]
            $script:addResult1.Id | Should -Not -BeNullOrEmpty
            $script:addResult1.Title | Should -Not -BeNullOrEmpty
            $script:addResult1.Filename | Should -Not -BeNullOrEmpty
            $script:addResult1.MediaType | Should -Not -BeNullOrEmpty
            $script:addResult1.FileSize | Should -Not -BeNullOrEmpty
            $script:addResult1.SpaceKey | Should -Not -BeNullOrEmpty
            $script:addResult1.PageID | Should -Not -BeNullOrEmpty
            $script:addResult1.Version | Should -BeOfType [ConfluencePS.Version]
            $script:addResult1.Version.Number | Should -Be 1
            ([uri]$script:addResult1.URL).AbsoluteUri | Should -Not -BeNullOrEmpty
        }

        It 'throws for invalid file paths and reports duplicate attachments without stopping when requested' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            { Add-ConfluenceAttachment -PageId $script:pageSet.Page1.Id -FilePath "$PSScriptRoot/non-existing.file" -ErrorAction Stop } | Should -Throw
            { Add-ConfluenceAttachment -PageId $script:pageSet.Page1.Id -FilePath $PSScriptRoot -ErrorAction Stop } | Should -Throw
            { Add-ConfluenceAttachment -PageId $script:pageSet.Page1.Id -FilePath $script:textFile.FullName -ErrorAction Stop } | Should -Throw
            { Add-ConfluenceAttachment -PageId $script:pageSet.Page1.Id -FilePath $script:textFile.FullName -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Get-ConfluenceAttachment' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:getResult1 = Get-ConfluenceAttachment -PageId $script:pageSet.Page1.Id -ErrorAction Stop
                $script:getResult2 = Get-ConfluenceAttachment -PageId $script:pageSet.Page2.Id, $script:pageSet.Page3.Id -ErrorAction Stop
                $script:getResult3 = $script:pageSet.Page3, $script:pageSet.Page4 | Get-ConfluenceAttachment -ErrorAction Stop
                $script:getResult4 = $script:pageSet.Page1, $script:pageSet.Page2, $script:pageSet.Page3, $script:pageSet.Page4 | Get-ConfluenceAttachment -FileNameFilter 'Test.xlsx' -ErrorAction Stop
                $script:getResult5 = $script:pageSet.Page1, $script:pageSet.Page2, $script:pageSet.Page3, $script:pageSet.Page4 | Get-ConfluenceAttachment -MediaTypeFilter 'text/plain' -ErrorAction Stop
            }
        }

        It 'gets page attachments by page ID, page pipeline, file name, and media type' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:getResult1).Count | Should -Be 3
            @($script:getResult2).Count | Should -Be 4
            @($script:getResult3).Count | Should -Be 5
            @($script:getResult4).Count | Should -Be 3
            @($script:getResult5).Count | Should -Be 3
            $script:getResult1 | Should -BeOfType [ConfluencePS.Attachment]
            $script:getResult4.Title | Should -Be ('Test.xlsx', 'Test.xlsx', 'Test.xlsx')
            $script:getResult5.MediaType | Should -Be ('text/plain', 'text/plain', 'text/plain')
        }
    }

    Context 'Get-ConfluenceAttachmentFile' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                Push-Location -Path 'TestDrive:\'
                $null = New-Item -Path 'TestDrive:\Folder1' -ItemType Directory
                $null = New-Item -Path 'TestDrive:\Folder2' -ItemType Directory
                $null = New-Item -Path 'TestDrive:\Folder3' -ItemType Directory
                $script:downloadAttachments = $script:pageSet.Page1, $script:pageSet.Page2 | Get-ConfluenceAttachment -ErrorAction Stop

                $script:downloadResult1 = Get-ConfluenceAttachmentFile -Attachment $script:downloadAttachments[0] -Path 'TestDrive:\Folder1' -ErrorAction Stop
                $script:downloadResult2 = Get-ConfluenceAttachmentFile $script:downloadAttachments[-1] -ErrorAction Stop
                $script:downloadResult3 = Get-ConfluenceAttachmentFile -Attachment $script:downloadAttachments -Path 'TestDrive:\Folder2' -ErrorAction Stop
                $script:downloadResult4 = $script:downloadAttachments | Get-ConfluenceAttachmentFile -Path 'TestDrive:\Folder3' -ErrorAction Stop
            }
        }

        AfterAll {
            if ($script:fixture.IsConfigured) {
                Pop-Location
            }
        }

        It 'downloads one or many attachments to explicit and current paths' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            $script:downloadResult1 | Should -Be $true
            $files1 = Get-ChildItem -Path 'TestDrive:\Folder1'
            @($files1).Count | Should -Be 1
            $files1.Name | Should -Be "$($script:pageSet.Page1.Id)_$($script:downloadAttachments[0].Title)"

            $script:downloadResult2 | Should -Be $true
            $files2 = Get-ChildItem -Path $pwd.Path -File
            @($files2).Count | Should -Be 1
            $files2.Name | Should -Be "$($script:pageSet.Page2.Id)_$($script:downloadAttachments[-1].Title)"

            $script:downloadResult3 | Should -Be ($true, $true, $true, $true, $true)
            $script:downloadResult4 | Should -Be ($true, $true, $true, $true, $true)
            @((Get-ChildItem -Path 'TestDrive:\Folder2')).Count | Should -Be 5
            @((Get-ChildItem -Path 'TestDrive:\Folder3')).Count | Should -Be 5
        }

        It 'throws when the download path does not exist' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            { $script:downloadAttachments | Get-ConfluenceAttachmentFile -Path 'non-existing-path' -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Set-ConfluenceAttachment' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:attachmentToUpdate = $script:pageSet.Page1 | Get-ConfluenceAttachment -FileNameFilter 'Test.txt' -ErrorAction Stop
                $script:setResult1 = Set-ConfluenceAttachment -Attachment $script:attachmentToUpdate -FilePath $script:textFile.FullName -ErrorAction Stop
                $script:setResult2 = Set-ConfluenceAttachment $script:attachmentToUpdate -FilePath $script:textFile.FullName -ErrorAction Stop
                $script:setResult3 = $script:attachmentToUpdate | Set-ConfluenceAttachment -FilePath $script:textFile.FullName -ErrorAction Stop
            }
        }

        It 'updates an attachment by parameter, positional input, and pipeline input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:setResult1).Count | Should -Be 1
            @($script:setResult2).Count | Should -Be 1
            @($script:setResult3).Count | Should -Be 1
            $script:setResult1 | Should -BeOfType [ConfluencePS.Attachment]
            $script:setResult2 | Should -BeOfType [ConfluencePS.Attachment]
            $script:setResult3 | Should -BeOfType [ConfluencePS.Attachment]
            $script:setResult1.Version.Number | Should -Be 2
            $script:setResult2.Version.Number | Should -Be 3
            $script:setResult3.Version.Number | Should -Be 4
            ([uri]$script:setResult1.URL).AbsoluteUri | Should -Not -BeNullOrEmpty
        }

        It 'throws if the replacement file does not exist' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            { Set-ConfluenceAttachment -Attachment $script:attachmentToUpdate -FilePath 'non-existing.file' -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Remove-ConfluenceAttachment' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:originalWarningPreferenceForRemove = $WarningPreference
                $WarningPreference = 'SilentlyContinue'
                $script:preAttachments1 = Get-ConfluenceAttachment -PageId $script:pageSet.Page1.Id -ErrorAction Stop
                $script:preAttachments2 = Get-ConfluenceAttachment -PageId $script:pageSet.Page2.Id -ErrorAction Stop
                $script:preAttachments3 = Get-ConfluenceAttachment -PageId $script:pageSet.Page3.Id -ErrorAction Stop

                Remove-ConfluenceAttachment -Attachment $script:preAttachments1[0] -ErrorAction Stop
                Remove-ConfluenceAttachment $script:preAttachments2 -ErrorAction Stop
                $script:preAttachments3 | Remove-ConfluenceAttachment -ErrorAction Stop

                $script:postAttachments1 = Get-ConfluenceAttachment -PageId $script:pageSet.Page1.Id -ErrorAction SilentlyContinue
                $script:postAttachments2 = Get-ConfluenceAttachment -PageId $script:pageSet.Page2.Id -ErrorAction SilentlyContinue
                $script:postAttachments3 = Get-ConfluenceAttachment -PageId $script:pageSet.Page3.Id -ErrorAction SilentlyContinue
            }
        }

        AfterAll {
            if ($script:fixture.IsConfigured) {
                $WarningPreference = $script:originalWarningPreferenceForRemove
            }
        }

        It 'removes one attachment, several attachments, and piped attachments' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:postAttachments1).Count | Should -Be (@($script:preAttachments1).Count - 1)
            $script:postAttachments2 | Should -BeNullOrEmpty
            $script:postAttachments3 | Should -BeNullOrEmpty
        }

        It 'throws for a deleted attachment with Stop but not with SilentlyContinue' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            { Remove-ConfluenceAttachment -Attachment $script:preAttachments1 -ErrorAction Stop } | Should -Throw
            { Remove-ConfluenceAttachment -Attachment $script:preAttachments1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}
