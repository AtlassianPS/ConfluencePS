#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

Describe 'Attachment integration tests' -Tag Integration, Cloud, DataCenter {
    BeforeAll {
        . "$PSScriptRoot/Helpers/ConfluenceIntegrationFixture.ps1"
        $script:Fixture = New-ConfluenceIntegrationFixture

        if ($script:Fixture.IsConfigured) {
            $script:PageSet = New-ConfluenceIntegrationPageSet -Fixture $script:Fixture -SpaceNamePrefix 'ConfluencePS Attachments'
            $script:TextFile = Get-Item -Path "$PSScriptRoot/../resources/Test.txt"
            $script:ImageFile = Get-Item -Path "$PSScriptRoot/../resources/Test.png"
            $script:ExcelFile = Get-Item -Path "$PSScriptRoot/../resources/Test.xlsx"
        }
    }

    AfterAll {
        if ($script:Fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:Fixture
        }
    }

    Context 'Add-ConfluenceAttachment' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:OriginalWarningPreference = $WarningPreference
                $WarningPreference = 'SilentlyContinue'

                $script:AddResult1 = Add-ConfluenceAttachment -PageId $script:PageSet.Page1.Id -FilePath $script:TextFile.FullName -ErrorAction Stop
                $script:AddResult2 = Add-ConfluenceAttachment -PageId $script:PageSet.Page1.Id -FilePath $script:ImageFile.FullName, $script:ExcelFile.FullName -ErrorAction Stop
                $script:AddResult3 = Add-ConfluenceAttachment $script:PageSet.Page2.Id -FilePath $script:TextFile.FullName -ErrorAction Stop
                $script:AddResult4 = $script:PageSet.Page2 | Add-ConfluenceAttachment -FilePath $script:ImageFile.FullName -ErrorAction Stop
                $script:AddResult5 = $script:PageSet.Page3 | Add-ConfluenceAttachment -FilePath $script:ImageFile.FullName, $script:ExcelFile.FullName -ErrorAction Stop
                $script:AddResult6 = $script:TextFile, $script:ImageFile, $script:ExcelFile | Add-ConfluenceAttachment -PageId $script:PageSet.Page4.Id -ErrorAction Stop
            }
        }

        AfterAll {
            if ($script:Fixture.IsConfigured) {
                $WarningPreference = $script:OriginalWarningPreference
            }
        }

        It 'attaches files by page ID, page pipeline, positional input, and file pipeline' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:AddResult1).Count | Should -Be 1
            @($script:AddResult2).Count | Should -Be 2
            @($script:AddResult3).Count | Should -Be 1
            @($script:AddResult4).Count | Should -Be 1
            @($script:AddResult5).Count | Should -Be 2
            @($script:AddResult6).Count | Should -Be 3
            $script:AddResult1 | Should -BeOfType [ConfluencePS.Attachment]
            $script:AddResult1.Id | Should -Not -BeNullOrEmpty
            $script:AddResult1.Title | Should -Not -BeNullOrEmpty
            $script:AddResult1.Filename | Should -Not -BeNullOrEmpty
            $script:AddResult1.MediaType | Should -Not -BeNullOrEmpty
            $script:AddResult1.FileSize | Should -Not -BeNullOrEmpty
            $script:AddResult1.SpaceKey | Should -Not -BeNullOrEmpty
            $script:AddResult1.PageID | Should -Not -BeNullOrEmpty
            $script:AddResult1.Version | Should -BeOfType [ConfluencePS.Version]
            $script:AddResult1.Version.Number | Should -Be 1
            ([uri]$script:AddResult1.URL).AbsoluteUri | Should -Not -BeNullOrEmpty
        }

        It 'throws for invalid file paths and reports duplicate attachments without stopping when requested' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            { Add-ConfluenceAttachment -PageId $script:PageSet.Page1.Id -FilePath "$PSScriptRoot/non-existing.file" -ErrorAction Stop } | Should -Throw
            { Add-ConfluenceAttachment -PageId $script:PageSet.Page1.Id -FilePath $PSScriptRoot -ErrorAction Stop } | Should -Throw
            { Add-ConfluenceAttachment -PageId $script:PageSet.Page1.Id -FilePath $script:TextFile.FullName -ErrorAction Stop } | Should -Throw
            { Add-ConfluenceAttachment -PageId $script:PageSet.Page1.Id -FilePath $script:TextFile.FullName -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Get-ConfluenceAttachment' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:GetResult1 = Get-ConfluenceAttachment -PageId $script:PageSet.Page1.Id -ErrorAction Stop
                $script:GetResult2 = Get-ConfluenceAttachment -PageId $script:PageSet.Page2.Id, $script:PageSet.Page3.Id -ErrorAction Stop
                $script:GetResult3 = $script:PageSet.Page3, $script:PageSet.Page4 | Get-ConfluenceAttachment -ErrorAction Stop
                $script:GetResult4 = $script:PageSet.Page1, $script:PageSet.Page2, $script:PageSet.Page3, $script:PageSet.Page4 | Get-ConfluenceAttachment -FileNameFilter 'Test.xlsx' -ErrorAction Stop
                $script:GetResult5 = $script:PageSet.Page1, $script:PageSet.Page2, $script:PageSet.Page3, $script:PageSet.Page4 | Get-ConfluenceAttachment -MediaTypeFilter 'text/plain' -ErrorAction Stop
            }
        }

        It 'gets page attachments by page ID, page pipeline, file name, and media type' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:GetResult1).Count | Should -Be 3
            @($script:GetResult2).Count | Should -Be 4
            @($script:GetResult3).Count | Should -Be 5
            @($script:GetResult4).Count | Should -Be 3
            @($script:GetResult5).Count | Should -Be 3
            $script:GetResult1 | Should -BeOfType [ConfluencePS.Attachment]
            $script:GetResult4.Title | Should -Be ('Test.xlsx', 'Test.xlsx', 'Test.xlsx')
            $script:GetResult5.MediaType | Should -Be ('text/plain', 'text/plain', 'text/plain')
        }
    }

    Context 'Get-ConfluenceAttachmentFile' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                Push-Location -Path 'TestDrive:\'
                $null = New-Item -Path 'TestDrive:\Folder1' -ItemType Directory
                $null = New-Item -Path 'TestDrive:\Folder2' -ItemType Directory
                $null = New-Item -Path 'TestDrive:\Folder3' -ItemType Directory
                $script:DownloadAttachments = $script:PageSet.Page1, $script:PageSet.Page2 | Get-ConfluenceAttachment -ErrorAction Stop

                $script:DownloadResult1 = Get-ConfluenceAttachmentFile -Attachment $script:DownloadAttachments[0] -Path 'TestDrive:\Folder1' -ErrorAction Stop
                $script:DownloadResult2 = Get-ConfluenceAttachmentFile $script:DownloadAttachments[-1] -ErrorAction Stop
                $script:DownloadResult3 = Get-ConfluenceAttachmentFile -Attachment $script:DownloadAttachments -Path 'TestDrive:\Folder2' -ErrorAction Stop
                $script:DownloadResult4 = $script:DownloadAttachments | Get-ConfluenceAttachmentFile -Path 'TestDrive:\Folder3' -ErrorAction Stop
            }
        }

        AfterAll {
            if ($script:Fixture.IsConfigured) {
                Pop-Location
            }
        }

        It 'downloads one or many attachments to explicit and current paths' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            $script:DownloadResult1 | Should -Be $true
            $files1 = Get-ChildItem -Path 'TestDrive:\Folder1'
            @($files1).Count | Should -Be 1
            $files1.Name | Should -Be "$($script:PageSet.Page1.Id)_$($script:DownloadAttachments[0].Title)"

            $script:DownloadResult2 | Should -Be $true
            $files2 = Get-ChildItem -Path $pwd.Path -File
            @($files2).Count | Should -Be 1
            $files2.Name | Should -Be "$($script:PageSet.Page2.Id)_$($script:DownloadAttachments[-1].Title)"

            $script:DownloadResult3 | Should -Be ($true, $true, $true, $true, $true)
            $script:DownloadResult4 | Should -Be ($true, $true, $true, $true, $true)
            @((Get-ChildItem -Path 'TestDrive:\Folder2')).Count | Should -Be 5
            @((Get-ChildItem -Path 'TestDrive:\Folder3')).Count | Should -Be 5
        }

        It 'throws when the download path does not exist' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            { $script:DownloadAttachments | Get-ConfluenceAttachmentFile -Path 'non-existing-path' -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Set-ConfluenceAttachment' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:AttachmentToUpdate = $script:PageSet.Page1 | Get-ConfluenceAttachment -FileNameFilter 'Test.txt' -ErrorAction Stop
                $script:SetResult1 = Set-ConfluenceAttachment -Attachment $script:AttachmentToUpdate -FilePath $script:TextFile.FullName -ErrorAction Stop
                $script:SetResult2 = Set-ConfluenceAttachment $script:AttachmentToUpdate -FilePath $script:TextFile.FullName -ErrorAction Stop
                $script:SetResult3 = $script:AttachmentToUpdate | Set-ConfluenceAttachment -FilePath $script:TextFile.FullName -ErrorAction Stop
            }
        }

        It 'updates an attachment by parameter, positional input, and pipeline input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:SetResult1).Count | Should -Be 1
            @($script:SetResult2).Count | Should -Be 1
            @($script:SetResult3).Count | Should -Be 1
            $script:SetResult1 | Should -BeOfType [ConfluencePS.Attachment]
            $script:SetResult2 | Should -BeOfType [ConfluencePS.Attachment]
            $script:SetResult3 | Should -BeOfType [ConfluencePS.Attachment]
            $script:SetResult1.Version.Number | Should -Be 2
            $script:SetResult2.Version.Number | Should -Be 3
            $script:SetResult3.Version.Number | Should -Be 4
            ([uri]$script:SetResult1.URL).AbsoluteUri | Should -Not -BeNullOrEmpty
        }

        It 'throws if the replacement file does not exist' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            { Set-ConfluenceAttachment -Attachment $script:AttachmentToUpdate -FilePath 'non-existing.file' -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Remove-ConfluenceAttachment' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:OriginalWarningPreferenceForRemove = $WarningPreference
                $WarningPreference = 'SilentlyContinue'
                $script:PreAttachments1 = Get-ConfluenceAttachment -PageId $script:PageSet.Page1.Id -ErrorAction Stop
                $script:PreAttachments2 = Get-ConfluenceAttachment -PageId $script:PageSet.Page2.Id -ErrorAction Stop
                $script:PreAttachments3 = Get-ConfluenceAttachment -PageId $script:PageSet.Page3.Id -ErrorAction Stop

                Remove-ConfluenceAttachment -Attachment $script:PreAttachments1[0] -ErrorAction Stop
                Remove-ConfluenceAttachment $script:PreAttachments2 -ErrorAction Stop
                $script:PreAttachments3 | Remove-ConfluenceAttachment -ErrorAction Stop

                $script:PostAttachments1 = Get-ConfluenceAttachment -PageId $script:PageSet.Page1.Id -ErrorAction SilentlyContinue
                $script:PostAttachments2 = Get-ConfluenceAttachment -PageId $script:PageSet.Page2.Id -ErrorAction SilentlyContinue
                $script:PostAttachments3 = Get-ConfluenceAttachment -PageId $script:PageSet.Page3.Id -ErrorAction SilentlyContinue
            }
        }

        AfterAll {
            if ($script:Fixture.IsConfigured) {
                $WarningPreference = $script:OriginalWarningPreferenceForRemove
            }
        }

        It 'removes one attachment, several attachments, and piped attachments' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:PostAttachments1).Count | Should -Be (@($script:PreAttachments1).Count - 1)
            $script:PostAttachments2 | Should -BeNullOrEmpty
            $script:PostAttachments3 | Should -BeNullOrEmpty
        }

        It 'throws for a deleted attachment with Stop but not with SilentlyContinue' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            { Remove-ConfluenceAttachment -Attachment $script:PreAttachments1 -ErrorAction Stop } | Should -Throw
            { Remove-ConfluenceAttachment -Attachment $script:PreAttachments1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}
