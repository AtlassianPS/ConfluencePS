#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

Describe 'Space integration tests' -Tag Integration, Cloud, DataCenter {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
        $script:fixture = New-ConfluenceIntegrationFixture
    }

    AfterAll {
        if ($script:fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:fixture
        }
    }

    Context 'Set-ConfluenceInfo' {
        It 'stores default credential and API URI values for Confluence commands' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            Set-ConfluenceInfo -BaseUri $script:fixture.Environment.CloudUrl -Credential $script:fixture.Credential

            $global:PSDefaultParameterValues['Get-ConfluencePage:Credential'] | Should -BeOfType [PSCredential]
            $global:PSDefaultParameterValues['Get-ConfluencePage:ApiUri'] | Should -BeOfType [String]
            $global:PSDefaultParameterValues['Get-ConfluencePage:ApiUri'] | Should -Match '^https?://.*/rest/api$'
        }
    }

    Context 'New-ConfluenceSpace' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:spaceObjectKey = New-ConfluenceIntegrationSpaceKey
                $script:spaceParameterKey = New-ConfluenceIntegrationSpaceKey
                $script:spaceObjectName = New-ConfluenceIntegrationResourceName -Prefix 'Space Object'
                $script:spaceParameterName = New-ConfluenceIntegrationResourceName -Prefix 'Space Parameters'
                $script:spaceDescription = '<p>A disposable integration test space</p>'
                $spaceObject = [ConfluencePS.Space]@{
                    Key         = $script:spaceObjectKey
                    Name        = $script:spaceObjectName
                    Description = $script:spaceDescription
                }

                $script:spaceAlreadyExisted = $false
                try {
                    $null = Get-ConfluenceSpace -SpaceKey $script:spaceObjectKey -ErrorAction Stop
                    $script:spaceAlreadyExisted = $true
                }
                catch {
                }

                $script:newSpaceFromObject = $spaceObject | New-ConfluenceSpace -ErrorAction Stop
                $script:newSpaceFromParameters = New-ConfluenceSpace -Key $script:spaceParameterKey -Name $script:spaceParameterName -Description $script:spaceDescription -ErrorAction Stop
                $null = $script:fixture.Spaces.Add($script:newSpaceFromObject.Key)
                $null = $script:fixture.Spaces.Add($script:newSpaceFromParameters.Key)
            }
        }

        It 'creates new spaces from object and parameter input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            $script:spaceAlreadyExisted | Should -Be $false
            $script:newSpaceFromObject | Should -BeOfType [ConfluencePS.Space]
            $script:newSpaceFromParameters | Should -BeOfType [ConfluencePS.Space]
            $script:newSpaceFromObject.ID | Should -BeOfType [UInt64]
            $script:newSpaceFromParameters.ID | Should -BeOfType [UInt64]
            $script:newSpaceFromObject.Key | Should -BeExactly $script:spaceObjectKey
            $script:newSpaceFromParameters.Key | Should -BeExactly $script:spaceParameterKey
            $script:newSpaceFromObject.Name | Should -BeExactly $script:spaceObjectName
            $script:newSpaceFromParameters.Name | Should -BeExactly $script:spaceParameterName
            $script:newSpaceFromObject.Homepage | Should -BeOfType [ConfluencePS.Page]
            $script:newSpaceFromParameters.Homepage | Should -BeOfType [ConfluencePS.Page]
        }
    }

    Context 'Get-ConfluenceSpace' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:getAllSpaces = Get-ConfluenceSpace -ErrorAction Stop
                $script:getSpaceByKey = Get-ConfluenceSpace -Key $script:spaceObjectKey -ErrorAction Stop
                $script:getSpaceByPipeline = $script:spaceParameterKey | Get-ConfluenceSpace -ErrorAction Stop
                $script:getSpacesByArray = Get-ConfluenceSpace @($script:spaceObjectKey, $script:spaceParameterKey) -ErrorAction Stop
            }
        }

        It 'gets spaces by key, pipeline, and multiple keys' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:getAllSpaces).Count | Should -BeGreaterOrEqual 2
            @($script:getSpaceByKey).Count | Should -Be 1
            @($script:getSpaceByPipeline).Count | Should -Be 1
            @($script:getSpacesByArray).Count | Should -Be 2
            $script:getSpaceByKey | Should -BeOfType [ConfluencePS.Space]
            $script:getSpaceByKey.Key | Should -BeExactly $script:spaceObjectKey
            $script:getSpaceByPipeline.Key | Should -BeExactly $script:spaceParameterKey
            $script:getSpacesByArray.Key | Should -BeExactly @($script:spaceObjectKey, $script:spaceParameterKey)
            $script:getSpaceByKey.Icon | Should -BeOfType [ConfluencePS.Icon]
            $script:getSpaceByKey.Homepage | Should -BeOfType [ConfluencePS.Page]
            $script:getSpaceByKey.Icon.ToString() | Should -Be $script:getSpaceByKey.Icon.Path
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
            if ($script:fixture.IsConfigured) {
                $script:invokeMethodSpaceResults = Invoke-ConfluenceMethod -Uri "$($script:fixture.ApiUri)/space" -GetParameters @{ limit = 1 } -Credential $script:fixture.Credential -ErrorAction Stop
                $script:invokeMethodTypedSpaceResults = Invoke-ConfluenceMethod -Uri "$($script:fixture.ApiUri)/space" -GetParameters @{ limit = 1 } -Credential $script:fixture.Credential -OutputType ([ConfluencePS.Space]) -ErrorAction Stop
            }
        }

        It 'returns raw and typed results from direct API calls' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:invokeMethodSpaceResults).Count | Should -BeGreaterThan 0
            @($script:invokeMethodSpaceResults)[0].ID | Should -Not -BeNullOrEmpty
            @($script:invokeMethodSpaceResults)[0].Key | Should -Not -BeNullOrEmpty
            @($script:invokeMethodTypedSpaceResults).Count | Should -BeGreaterThan 0
            @($script:invokeMethodTypedSpaceResults)[0] | Should -BeOfType [ConfluencePS.Space]
        }
    }

    Context 'ConvertTo-ConfluenceTable' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:tableInput = [PSCustomObject]@{
                    Name  = 'ConfluencePS'
                    Scope = 'IntegrationCoverage'
                }
                $script:tableMarkup = $script:tableInput | ConvertTo-ConfluenceTable
                $tableStorageMarkup = ConvertTo-ConfluenceStorageFormat -Content $script:tableMarkup
                $script:tablePage = New-ConfluenceIntegrationPage -Fixture $script:fixture -SpaceKey $script:spaceObjectKey -TitlePrefix 'Table Page' -Body $tableStorageMarkup
                $script:fetchedTablePage = Get-ConfluencePage -PageID $script:tablePage.ID -ErrorAction Stop
            }
        }

        It 'creates Confluence table markup that can be used in a real page' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            $script:tableMarkup | Should -Match '\|\| Name \|\| Scope \|\|'
            $script:tableMarkup | Should -Match '\| ConfluencePS \| IntegrationCoverage \|'
            $script:fetchedTablePage | Should -BeOfType [ConfluencePS.Page]
            $script:fetchedTablePage.Body | Should -Match 'ConfluencePS'
            $script:fetchedTablePage.Body | Should -Match 'IntegrationCoverage'
        }
    }

    Context 'Remove-ConfluenceSpace' {
        It 'removes a space by key and by pipeline' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            Remove-ConfluenceSpace -Key $script:spaceObjectKey -Force -ErrorAction Stop
            $script:spaceParameterKey | Remove-ConfluenceSpace -Force -ErrorAction Stop
            $script:fixture.Spaces.Remove($script:spaceObjectKey)
            $script:fixture.Spaces.Remove($script:spaceParameterKey)

            Start-Sleep -Seconds 20
            { Get-ConfluenceSpace -Key $script:spaceObjectKey -ErrorAction Stop } | Should -Throw
            { Get-ConfluenceSpace -Key $script:spaceParameterKey -ErrorAction Stop } | Should -Throw
        }
    }
}
