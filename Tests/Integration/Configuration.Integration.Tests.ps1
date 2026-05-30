#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment -CallerPath (Split-Path $PSScriptRoot -Parent)
}

Describe "Integration Test Configuration" -Tag 'Integration', 'Smoke', 'Cloud', 'DataCenter' {
    BeforeAll {
        Import-Module $env:BHManifestToTest -Force
        . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

        $script:deploymentType = Get-ConfluenceIntegrationDeploymentType
        $script:requiredEnvironmentVariables = Get-ConfluenceIntegrationRequiredVariables -DeploymentType $script:deploymentType
        $script:integrationEnvironment = Initialize-IntegrationEnvironment
        $script:isIntegrationEnvironmentConfigured = $null -ne $script:integrationEnvironment

        if ($script:isIntegrationEnvironmentConfigured) {
            $secureToken = ConvertTo-SecureString -String $script:integrationEnvironment.Password -AsPlainText -Force
            $script:credential = [System.Management.Automation.PSCredential]::new($script:integrationEnvironment.Username, $secureToken)
            $script:apiUri = '{0}/rest/api' -f $script:integrationEnvironment.CloudUrl.TrimEnd('/')
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    }

    Context "Required Environment Variables" {
        It "all required variables are configured for the selected track" {
            foreach ($requiredVariable in $script:requiredEnvironmentVariables) {
                $value = [Environment]::GetEnvironmentVariable($requiredVariable)
                $value | Should -Not -BeNullOrEmpty -Because "$requiredVariable must be configured for the $script:deploymentType integration track"
            }
        }
    }

    Context "Integration Connectivity" {
        It "can authenticate and query Confluence" {
            if (-not $script:isIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluenceSpace -ApiUri $script:apiUri -Credential $script:credential -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }
    }

    Context "Smoke Read Coverage" {
        BeforeAll {
            if ($script:isIntegrationEnvironmentConfigured) {
                $script:smokeSpace = Get-ConfluenceSpace -ApiUri $script:apiUri -Credential $script:credential -ErrorAction Stop |
                    Select-Object -First 1
                Set-ConfluenceInfo -BaseUri $script:integrationEnvironment.CloudUrl -Credential $script:credential
            }
        }

        It "sets default connection values for Confluence commands" {
            if (-not $script:isIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            $global:PSDefaultParameterValues["Get-ConfluenceSpace:ApiUri"] | Should -BeExactly $script:apiUri
            $global:PSDefaultParameterValues["Get-ConfluenceSpace:Credential"] | Should -BeOfType [PSCredential]
            $global:PSDefaultParameterValues["Get-ConfluencePage:ApiUri"] | Should -BeExactly $script:apiUri
            $global:PSDefaultParameterValues["Get-ConfluencePage:Credential"] | Should -BeOfType [PSCredential]
        }

        It "resolves an accessible space when one is available" {
            if (-not $script:isIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            if (-not $script:smokeSpace) {
                Set-ItResult -Skipped -Because "No accessible Confluence space was returned"
                return
            }

            $script:smokeSpace | Should -Not -BeNullOrEmpty
            $script:smokeSpace.Key | Should -Not -BeNullOrEmpty
        }

        It "can query spaces using defaults configured by Set-ConfluenceInfo" {
            if (-not $script:isIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluenceSpace -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }

        It "can list spaces without expanded label metadata" {
            if (-not $script:isIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluenceSpace -PageSize 1 -ErrorAction Stop | Out-Null } | Should -Not -Throw
        }

        It "can execute a CQL page query using configured defaults" {
            if (-not $script:isIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            { Get-ConfluencePage -Query "type=page" -PageSize 1 -ErrorAction Stop | Out-Null } | Should -Not -Throw
        }

        It "can query pages from an accessible space" {
            if (-not $script:isIntegrationEnvironmentConfigured) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }
            if (-not $script:smokeSpace) {
                Set-ItResult -Skipped -Because "No accessible Confluence space was returned"
                return
            }

            { Get-ConfluencePage -SpaceKey $script:smokeSpace.Key -ErrorAction Stop | Select-Object -First 1 | Out-Null } | Should -Not -Throw
        }
    }

    Context "Smoke Write Coverage" {
        BeforeAll {
            $script:smokeWriteReady = $false
            $script:smokeWritePage = $null
            $script:smokeWriteSpace = $null
            $script:smokeWriteSkipReason = $null
            $script:smokeWriteLabel = "smoke-write-$([Guid]::NewGuid().ToString('N').Substring(0, 8))"

            if (-not $script:isIntegrationEnvironmentConfigured) {
                $script:smokeWriteSkipReason = "Environment not configured"
                return
            }

            Set-ConfluenceInfo -BaseUri $script:integrationEnvironment.CloudUrl -Credential $script:credential
            $script:smokeWriteSpaceKey = "SMOKE$([Guid]::NewGuid().ToString('N').Substring(0, 8))".ToUpperInvariant()
            $script:smokeWriteTitle = "ConfluencePS Smoke Write $([Guid]::NewGuid().ToString('N').Substring(0, 12))"

            $script:smokeWriteSpace = New-ConfluenceSpace -Key $script:smokeWriteSpaceKey -Name "ConfluencePS Smoke Write $($script:smokeWriteSpaceKey)" -Description "Disposable smoke-test space" -ErrorAction Stop
            $script:smokeWritePage = New-ConfluencePage -Title $script:smokeWriteTitle -SpaceKey $script:smokeWriteSpace.Key -Body "<p>ConfluencePS smoke create</p>" -ErrorAction Stop
            $script:smokeWriteReady = $true
        }

        AfterAll {
            if ($script:smokeWritePage) {
                try {
                    Remove-ConfluencePage -PageID $script:smokeWritePage.ID -Confirm:$false -ErrorAction Stop
                }
                catch {
                    Write-Warning "Failed to remove smoke-write page $($script:smokeWritePage.ID): $($_.Exception.Message)"
                }
            }
            if ($script:smokeWriteSpace) {
                try {
                    Remove-ConfluenceSpace -Key $script:smokeWriteSpace.Key -Force -ErrorAction Stop
                }
                catch {
                    Write-Warning "Failed to remove smoke-write space $($script:smokeWriteSpace.Key): $($_.Exception.Message)"
                }
            }
        }

        It "can create a page in a writable space" {
            if (-not $script:smokeWriteReady) {
                if ($script:smokeWriteSkipReason) {
                    Set-ItResult -Skipped -Because $script:smokeWriteSkipReason
                    return
                }
                throw "Smoke write setup did not create a writable disposable space and page."
            }

            $script:smokeWritePage | Should -BeOfType [ConfluencePS.Page]
            $script:smokeWritePage.ID | Should -Not -BeNullOrEmpty
            $script:smokeWritePage.Space.Key | Should -BeExactly $script:smokeWriteSpace.Key
        }

        It "can update the smoke-write page body" {
            if (-not $script:smokeWriteReady) {
                if ($script:smokeWriteSkipReason) {
                    Set-ItResult -Skipped -Because $script:smokeWriteSkipReason
                    return
                }
                throw "Smoke write setup did not create a writable disposable space and page."
            }

            $script:updatedSmokeWritePage = Set-ConfluencePage -PageID $script:smokeWritePage.ID -Body "<p>ConfluencePS smoke updated</p>" -ErrorAction Stop

            $script:updatedSmokeWritePage.ID | Should -BeExactly $script:smokeWritePage.ID
            $script:updatedSmokeWritePage.Version.Number | Should -BeGreaterThan $script:smokeWritePage.Version.Number
            $script:updatedSmokeWritePage.Body | Should -Match "ConfluencePS smoke updated"
        }

        It "supports label add/remove lifecycle on the smoke-write page" {
            if (-not $script:smokeWriteReady) {
                if ($script:smokeWriteSkipReason) {
                    Set-ItResult -Skipped -Because $script:smokeWriteSkipReason
                    return
                }
                throw "Smoke write setup did not create a writable disposable space and page."
            }

            $null = Add-ConfluenceLabel -PageID $script:smokeWritePage.ID -Label $script:smokeWriteLabel -ErrorAction Stop
            $labelsAfterAdd = Get-ConfluenceLabel -PageID $script:smokeWritePage.ID -ErrorAction Stop
            ($labelsAfterAdd.Labels.Name -contains $script:smokeWriteLabel) | Should -Be $true

            $null = Remove-ConfluenceLabel -PageID $script:smokeWritePage.ID -Label $script:smokeWriteLabel -Confirm:$false -ErrorAction Stop
            $labelsAfterRemove = Get-ConfluenceLabel -PageID $script:smokeWritePage.ID -ErrorAction Stop
            ($labelsAfterRemove.Labels.Name -contains $script:smokeWriteLabel) | Should -Be $false
        }

        It "supports attachment add/remove lifecycle on the smoke-write page" {
            if (-not $script:smokeWriteReady) {
                if ($script:smokeWriteSkipReason) {
                    Set-ItResult -Skipped -Because $script:smokeWriteSkipReason
                    return
                }
                throw "Smoke write setup did not create a writable disposable space and page."
            }

            $smokeAttachmentPath = Join-Path $PSScriptRoot '../resources/Test.txt'
            $smokeAttachmentName = [IO.Path]::GetFileName($smokeAttachmentPath)

            $addedAttachment = Add-ConfluenceAttachment -PageID $script:smokeWritePage.ID -FilePath $smokeAttachmentPath -ErrorAction Stop
            $addedAttachment | Should -Not -BeNullOrEmpty

            $attachmentsAfterAdd = Get-ConfluenceAttachment -PageID $script:smokeWritePage.ID -ErrorAction Stop
            @($attachmentsAfterAdd | Where-Object { $_.Title -eq $smokeAttachmentName }).Count | Should -BeGreaterThan 0

            $null = Remove-ConfluenceAttachment -Attachment $addedAttachment -Confirm:$false -ErrorAction Stop
            $attachmentsAfterRemove = Get-ConfluenceAttachment -PageID $script:smokeWritePage.ID -ErrorAction Stop
            @($attachmentsAfterRemove | Where-Object { $_.Title -eq $smokeAttachmentName }).Count | Should -Be 0
        }
    }
}
