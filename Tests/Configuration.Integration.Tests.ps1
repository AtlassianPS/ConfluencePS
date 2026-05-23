#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
}

Describe "Integration Test Configuration" -Tag 'Integration', 'Smoke', 'Cloud', 'DataCenter' {
    BeforeAll {
        Import-Module $env:BHManifestToTest -Force
        . "$PSScriptRoot/Helpers/IntegrationTestTools.ps1"

        $script:DeploymentType = Get-ConfluenceIntegrationDeploymentType
        $script:RequiredEnvironmentVariables = Get-ConfluenceIntegrationRequiredVariables -DeploymentType $script:DeploymentType
        $script:IntegrationEnvironment = Initialize-IntegrationEnvironment
        $script:IsIntegrationEnvironmentConfigured = $null -ne $script:IntegrationEnvironment

        if ($script:IsIntegrationEnvironmentConfigured) {
            $secureToken = ConvertTo-SecureString -String $script:IntegrationEnvironment.Password -AsPlainText -Force
            $script:Credential = [System.Management.Automation.PSCredential]::new($script:IntegrationEnvironment.Username, $secureToken)
            $script:ApiUri = '{0}/rest/api' -f $script:IntegrationEnvironment.CloudUrl.TrimEnd('/')
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    }

    Context "Required Environment Variables" {
        It "all required variables are configured for the selected track" {
            foreach ($requiredVariable in $script:RequiredEnvironmentVariables) {
                $value = [Environment]::GetEnvironmentVariable($requiredVariable)
                $value | Should -Not -BeNullOrEmpty -Because "$requiredVariable must be configured for the $script:DeploymentType integration track"
            }
        }
    }

    Context "Integration Connectivity" {
        It "can authenticate and query Confluence" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluenceSpace -ApiUri $script:ApiUri -Credential $script:Credential -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }
    }

    Context "Smoke Read Coverage" {
        BeforeAll {
            if ($script:IsIntegrationEnvironmentConfigured) {
                $script:SmokeSpace = Get-ConfluenceSpace -ApiUri $script:ApiUri -Credential $script:Credential -ErrorAction Stop |
                    Select-Object -First 1
                Set-ConfluenceInfo -BaseUri $script:IntegrationEnvironment.CloudUrl -Credential $script:Credential
            }
        }

        It "sets default connection values for Confluence commands" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            $global:PSDefaultParameterValues["Get-ConfluenceSpace:ApiUri"] | Should -BeExactly $script:ApiUri
            $global:PSDefaultParameterValues["Get-ConfluenceSpace:Credential"] | Should -BeOfType [PSCredential]
            $global:PSDefaultParameterValues["Get-ConfluencePage:ApiUri"] | Should -BeExactly $script:ApiUri
            $global:PSDefaultParameterValues["Get-ConfluencePage:Credential"] | Should -BeOfType [PSCredential]
        }

        It "resolves an accessible space when one is available" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            if (-not $script:SmokeSpace) {
                Set-ItResult -Skipped -Because "No accessible Confluence space was returned"
                return
            }

            $script:SmokeSpace | Should -Not -BeNullOrEmpty
            $script:SmokeSpace.Key | Should -Not -BeNullOrEmpty
        }

        It "can query spaces using defaults configured by Set-ConfluenceInfo" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluenceSpace -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }

        It "can execute a CQL page query using configured defaults" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluencePage -Query "type=page" -PageSize 1 -ErrorAction Stop | Out-Null } | Should -Not -Throw
        }

        It "can query pages from an accessible space" {
            if (-not $script:IsIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }
            if (-not $script:SmokeSpace) {
                Set-ItResult -Skipped -Because "No accessible Confluence space was returned"
                return
            }

            { Get-ConfluencePage -SpaceKey $script:SmokeSpace.Key -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }
    }

    Context "Smoke Write Coverage" {
        BeforeAll {
            $script:SmokeWriteReady = $false
            $script:SmokeWritePage = $null
            $script:SmokeWriteSpace = $null
            $script:SmokeWriteSkipReason = $null
            $script:SmokeWriteLabel = "smoke-write-$([Guid]::NewGuid().ToString('N').Substring(0, 8))"

            if (-not $script:IsIntegrationEnvironmentConfigured) {
                $script:SmokeWriteSkipReason = "Environment not configured"
                return
            }

            Set-ConfluenceInfo -BaseUri $script:IntegrationEnvironment.CloudUrl -Credential $script:Credential
            $script:SmokeWriteSpaceKey = "SMOKE$([Guid]::NewGuid().ToString('N').Substring(0, 8))".ToUpperInvariant()
            $script:SmokeWriteTitle = "ConfluencePS Smoke Write $([Guid]::NewGuid().ToString('N').Substring(0, 12))"

            $script:SmokeWriteSpace = New-ConfluenceSpace -Key $script:SmokeWriteSpaceKey -Name "ConfluencePS Smoke Write $($script:SmokeWriteSpaceKey)" -Description "Disposable smoke-test space" -ErrorAction Stop
            $script:SmokeWritePage = New-ConfluencePage -Title $script:SmokeWriteTitle -SpaceKey $script:SmokeWriteSpace.Key -Body "<p>ConfluencePS smoke create</p>" -ErrorAction Stop
            $script:SmokeWriteReady = $true
        }

        AfterAll {
            if ($script:SmokeWritePage) {
                try {
                    Remove-ConfluencePage -PageID $script:SmokeWritePage.ID -Confirm:$false -ErrorAction Stop
                }
                catch {
                    Write-Warning "Failed to remove smoke-write page $($script:SmokeWritePage.ID): $($_.Exception.Message)"
                }
            }
            if ($script:SmokeWriteSpace) {
                try {
                    Remove-ConfluenceSpace -Key $script:SmokeWriteSpace.Key -Force -ErrorAction Stop
                }
                catch {
                    Write-Warning "Failed to remove smoke-write space $($script:SmokeWriteSpace.Key): $($_.Exception.Message)"
                }
            }
        }

        It "can create a page in a writable space" {
            if (-not $script:SmokeWriteReady) {
                if ($script:SmokeWriteSkipReason) {
                    Set-ItResult -Skipped -Because $script:SmokeWriteSkipReason
                    return
                }
                throw "Smoke write setup did not create a writable disposable space and page."
            }

            $script:SmokeWritePage | Should -BeOfType [ConfluencePS.Page]
            $script:SmokeWritePage.ID | Should -Not -BeNullOrEmpty
            $script:SmokeWritePage.Space.Key | Should -BeExactly $script:SmokeWriteSpace.Key
        }

        It "can update the smoke-write page body" {
            if (-not $script:SmokeWriteReady) {
                if ($script:SmokeWriteSkipReason) {
                    Set-ItResult -Skipped -Because $script:SmokeWriteSkipReason
                    return
                }
                throw "Smoke write setup did not create a writable disposable space and page."
            }

            $script:UpdatedSmokeWritePage = Set-ConfluencePage -PageID $script:SmokeWritePage.ID -Body "<p>ConfluencePS smoke updated</p>" -ErrorAction Stop

            $script:UpdatedSmokeWritePage.ID | Should -BeExactly $script:SmokeWritePage.ID
            $script:UpdatedSmokeWritePage.Version.Number | Should -BeGreaterThan $script:SmokeWritePage.Version.Number
            $script:UpdatedSmokeWritePage.Body | Should -Match "ConfluencePS smoke updated"
        }

        It "supports label add/remove lifecycle on the smoke-write page" {
            if (-not $script:SmokeWriteReady) {
                if ($script:SmokeWriteSkipReason) {
                    Set-ItResult -Skipped -Because $script:SmokeWriteSkipReason
                    return
                }
                throw "Smoke write setup did not create a writable disposable space and page."
            }

            $null = Add-ConfluenceLabel -PageID $script:SmokeWritePage.ID -Label $script:SmokeWriteLabel -ErrorAction Stop
            $labelsAfterAdd = Get-ConfluenceLabel -PageID $script:SmokeWritePage.ID -ErrorAction Stop
            ($labelsAfterAdd.Labels.Name -contains $script:SmokeWriteLabel) | Should -Be $true

            $null = Remove-ConfluenceLabel -PageID $script:SmokeWritePage.ID -Label $script:SmokeWriteLabel -Confirm:$false -ErrorAction Stop
            $labelsAfterRemove = Get-ConfluenceLabel -PageID $script:SmokeWritePage.ID -ErrorAction Stop
            ($labelsAfterRemove.Labels.Name -contains $script:SmokeWriteLabel) | Should -Be $false
        }

        It "supports attachment add/remove lifecycle on the smoke-write page" {
            if (-not $script:SmokeWriteReady) {
                if ($script:SmokeWriteSkipReason) {
                    Set-ItResult -Skipped -Because $script:SmokeWriteSkipReason
                    return
                }
                throw "Smoke write setup did not create a writable disposable space and page."
            }

            $smokeAttachmentPath = Join-Path $PSScriptRoot 'resources/Test.txt'
            $smokeAttachmentName = [IO.Path]::GetFileName($smokeAttachmentPath)

            $addedAttachment = Add-ConfluenceAttachment -PageID $script:SmokeWritePage.ID -FilePath $smokeAttachmentPath -ErrorAction Stop
            $addedAttachment | Should -Not -BeNullOrEmpty

            $attachmentsAfterAdd = Get-ConfluenceAttachment -PageID $script:SmokeWritePage.ID -ErrorAction Stop
            @($attachmentsAfterAdd | Where-Object { $_.FileName -eq $smokeAttachmentName }).Count | Should -BeGreaterThan 0

            $null = Remove-ConfluenceAttachment -Attachment $addedAttachment -Confirm:$false -ErrorAction Stop
            $attachmentsAfterRemove = Get-ConfluenceAttachment -PageID $script:SmokeWritePage.ID -ErrorAction Stop
            @($attachmentsAfterRemove | Where-Object { $_.FileName -eq $smokeAttachmentName }).Count | Should -Be 0
        }
    }
}
