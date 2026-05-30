#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

Describe 'Space integration tests' -Tag Integration, Cloud, DataCenter {
    BeforeAll {
        . "$PSScriptRoot/Helpers/ConfluenceIntegrationFixture.ps1"
        $script:Fixture = New-ConfluenceIntegrationFixture
    }

    AfterAll {
        if ($script:Fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:Fixture
        }
    }

    Context 'Set-ConfluenceInfo' {
        It 'stores default credential and API URI values for Confluence commands' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            Set-ConfluenceInfo -BaseUri $script:Fixture.Environment.CloudUrl -Credential $script:Fixture.Credential

            $global:PSDefaultParameterValues['Get-ConfluencePage:Credential'] | Should -BeOfType [PSCredential]
            $global:PSDefaultParameterValues['Get-ConfluencePage:ApiUri'] | Should -BeOfType [String]
            $global:PSDefaultParameterValues['Get-ConfluencePage:ApiUri'] | Should -Match '^https?://.*/rest/api$'
        }
    }

    Context 'New-ConfluenceSpace' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:SpaceObjectKey = New-ConfluenceIntegrationSpaceKey
                $script:SpaceParameterKey = New-ConfluenceIntegrationSpaceKey
                $script:SpaceObjectName = New-ConfluenceIntegrationResourceName -Prefix 'Space Object'
                $script:SpaceParameterName = New-ConfluenceIntegrationResourceName -Prefix 'Space Parameters'
                $script:SpaceDescription = '<p>A disposable integration test space</p>'
                $spaceObject = [ConfluencePS.Space]@{
                    Key         = $script:SpaceObjectKey
                    Name        = $script:SpaceObjectName
                    Description = $script:SpaceDescription
                }

                $script:SpaceAlreadyExisted = $false
                try {
                    $null = Get-ConfluenceSpace -SpaceKey $script:SpaceObjectKey -ErrorAction Stop
                    $script:SpaceAlreadyExisted = $true
                }
                catch {
                }

                $script:NewSpaceFromObject = $spaceObject | New-ConfluenceSpace -ErrorAction Stop
                $script:NewSpaceFromParameters = New-ConfluenceSpace -Key $script:SpaceParameterKey -Name $script:SpaceParameterName -Description $script:SpaceDescription -ErrorAction Stop
                $null = $script:Fixture.Spaces.Add($script:NewSpaceFromObject.Key)
                $null = $script:Fixture.Spaces.Add($script:NewSpaceFromParameters.Key)
            }
        }

        It 'creates new spaces from object and parameter input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            $script:SpaceAlreadyExisted | Should -Be $false
            $script:NewSpaceFromObject | Should -BeOfType [ConfluencePS.Space]
            $script:NewSpaceFromParameters | Should -BeOfType [ConfluencePS.Space]
            $script:NewSpaceFromObject.ID | Should -BeOfType [UInt64]
            $script:NewSpaceFromParameters.ID | Should -BeOfType [UInt64]
            $script:NewSpaceFromObject.Key | Should -BeExactly $script:SpaceObjectKey
            $script:NewSpaceFromParameters.Key | Should -BeExactly $script:SpaceParameterKey
            $script:NewSpaceFromObject.Name | Should -BeExactly $script:SpaceObjectName
            $script:NewSpaceFromParameters.Name | Should -BeExactly $script:SpaceParameterName
            $script:NewSpaceFromObject.Homepage | Should -BeOfType [ConfluencePS.Page]
            $script:NewSpaceFromParameters.Homepage | Should -BeOfType [ConfluencePS.Page]
        }
    }

    Context 'Get-ConfluenceSpace' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:GetAllSpaces = Get-ConfluenceSpace -ErrorAction Stop
                $script:GetSpaceByKey = Get-ConfluenceSpace -Key $script:SpaceObjectKey -ErrorAction Stop
                $script:GetSpaceByPipeline = $script:SpaceParameterKey | Get-ConfluenceSpace -ErrorAction Stop
                $script:GetSpacesByArray = Get-ConfluenceSpace @($script:SpaceObjectKey, $script:SpaceParameterKey) -ErrorAction Stop
            }
        }

        It 'gets spaces by key, pipeline, and multiple keys' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:GetAllSpaces).Count | Should -BeGreaterOrEqual 2
            @($script:GetSpaceByKey).Count | Should -Be 1
            @($script:GetSpaceByPipeline).Count | Should -Be 1
            @($script:GetSpacesByArray).Count | Should -Be 2
            $script:GetSpaceByKey | Should -BeOfType [ConfluencePS.Space]
            $script:GetSpaceByKey.Key | Should -BeExactly $script:SpaceObjectKey
            $script:GetSpaceByPipeline.Key | Should -BeExactly $script:SpaceParameterKey
            $script:GetSpacesByArray.Key | Should -BeExactly @($script:SpaceObjectKey, $script:SpaceParameterKey)
            $script:GetSpaceByKey.Icon | Should -BeOfType [ConfluencePS.Icon]
            $script:GetSpaceByKey.Homepage | Should -BeOfType [ConfluencePS.Page]
            $script:GetSpaceByKey.Icon.ToString() | Should -Be $script:GetSpaceByKey.Icon.Path
        }
    }

    Context 'ConvertTo-ConfluenceStorageFormat' {
        It 'converts content to storage format and can preserve wiki markup as text' {
            $result1 = 'Hi Pester!' | ConvertTo-ConfluenceStorageFormat
            $result2 = ConvertTo-ConfluenceStorageFormat -Content 'Hi Pester!'
            $result3 = ConvertTo-ConfluenceStorageFormat -Content 'Hi Pester!', 'Hi Pester!'
            $result4 = ConvertTo-ConfluenceStorageFormat -Content 'h1. *bold* !image.png!' -AsPlainText

            $result1 | Should -BeExactly '<p>Hi Pester!</p>'
            $result2 | Should -BeExactly '<p>Hi Pester!</p>'
            $result3 | Should -BeExactly @('<p>Hi Pester!</p>', '<p>Hi Pester!</p>')
            $result4 | Should -Match 'h1&#46;'
            $result4 | Should -Match '&#42;bold&#42;'
            $result4 | Should -Match '&#33;image&#46;png&#33;'
            $result4 | Should -Not -Match '<h1|<strong|<ac:image'
        }
    }

    Context 'Invoke-ConfluenceMethod' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:InvokeMethodSpaceResults = Invoke-ConfluenceMethod -Uri "$($script:Fixture.ApiUri)/space" -GetParameters @{ limit = 1 } -Credential $script:Fixture.Credential -ErrorAction Stop
                $script:InvokeMethodTypedSpaceResults = Invoke-ConfluenceMethod -Uri "$($script:Fixture.ApiUri)/space" -GetParameters @{ limit = 1 } -Credential $script:Fixture.Credential -OutputType ([ConfluencePS.Space]) -ErrorAction Stop
            }
        }

        It 'returns raw and typed results from direct API calls' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:InvokeMethodSpaceResults).Count | Should -BeGreaterThan 0
            @($script:InvokeMethodSpaceResults)[0].ID | Should -Not -BeNullOrEmpty
            @($script:InvokeMethodSpaceResults)[0].Key | Should -Not -BeNullOrEmpty
            @($script:InvokeMethodTypedSpaceResults).Count | Should -BeGreaterThan 0
            @($script:InvokeMethodTypedSpaceResults)[0] | Should -BeOfType [ConfluencePS.Space]
        }
    }

    Context 'ConvertTo-ConfluenceTable' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:TableInput = [PSCustomObject]@{
                    Name  = 'ConfluencePS'
                    Scope = 'IntegrationCoverage'
                }
                $script:TableMarkup = $script:TableInput | ConvertTo-ConfluenceTable
                $tableStorageMarkup = ConvertTo-ConfluenceStorageFormat -Content $script:TableMarkup
                $script:TablePage = New-ConfluenceIntegrationPage -Fixture $script:Fixture -SpaceKey $script:SpaceObjectKey -TitlePrefix 'Table Page' -Body $tableStorageMarkup
                $script:FetchedTablePage = Get-ConfluencePage -PageID $script:TablePage.ID -ErrorAction Stop
            }
        }

        It 'creates Confluence table markup that can be used in a real page' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            $script:TableMarkup | Should -Match '\|\| Name \|\| Scope \|\|'
            $script:TableMarkup | Should -Match '\| ConfluencePS \| IntegrationCoverage \|'
            $script:FetchedTablePage | Should -BeOfType [ConfluencePS.Page]
            $script:FetchedTablePage.Body | Should -Match 'ConfluencePS'
            $script:FetchedTablePage.Body | Should -Match 'IntegrationCoverage'
        }
    }

    Context 'Remove-ConfluenceSpace' {
        It 'removes a space by key and by pipeline' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            Remove-ConfluenceSpace -Key $script:SpaceObjectKey -Force -ErrorAction Stop
            $script:SpaceParameterKey | Remove-ConfluenceSpace -Force -ErrorAction Stop
            $script:Fixture.Spaces.Remove($script:SpaceObjectKey)
            $script:Fixture.Spaces.Remove($script:SpaceParameterKey)

            Start-Sleep -Seconds 20
            { Get-ConfluenceSpace -Key $script:SpaceObjectKey -ErrorAction Stop } | Should -Throw
            { Get-ConfluenceSpace -Key $script:SpaceParameterKey -ErrorAction Stop } | Should -Throw
        }
    }
}
