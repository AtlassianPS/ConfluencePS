#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

param()

Describe 'Page integration tests' -Tag Integration, Cloud, DataCenter {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
        $script:fixture = New-ConfluenceIntegrationFixture

        if ($script:fixture.IsConfigured) {
            $script:rawContent = 'Hi Pester!'
            $script:formattedContent = '<p>Hi Pester!</p>'
            $script:pageSet = New-ConfluenceIntegrationPageSet -Fixture $script:fixture -SpaceNamePrefix 'ConfluencePS Pages' -Body $script:formattedContent
            $script:spaceKey = $script:pageSet.Space.Key
        }
    }

    AfterAll {
        if ($script:fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:fixture
        }
    }

    Context 'New-ConfluencePage' {
        It 'creates pages from pipeline, parameters, object input, and parent object input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            $script:pageSet.Page1 | Should -BeOfType [ConfluencePS.Page]
            $script:pageSet.Page2 | Should -BeOfType [ConfluencePS.Page]
            $script:pageSet.Page3 | Should -BeOfType [ConfluencePS.Page]
            $script:pageSet.Page4 | Should -BeOfType [ConfluencePS.Page]
            $script:pageSet.Page1.ID | Should -BeOfType [UInt64]
            $script:pageSet.Page2.ID | Should -BeOfType [UInt64]
            $script:pageSet.Page1.Space.Key | Should -BeExactly $script:spaceKey
            $script:pageSet.Page2.Space.Key | Should -BeExactly $script:spaceKey
            $script:pageSet.Page3.Space.Key | Should -BeExactly $script:spaceKey
            $script:pageSet.Page4.Space.Key | Should -BeExactly $script:spaceKey
            $script:pageSet.Page1.Ancestors.ID | Should -BeExactly $script:pageSet.HomePage.ID
            $script:pageSet.Page2.Ancestors | Should -BeNullOrEmpty
            $script:pageSet.Page3.Ancestors.ID | Should -BeExactly $script:pageSet.HomePage.ID
            $script:pageSet.Page4.Ancestors.ID | Should -BeExactly $script:pageSet.HomePage.ID
            $script:pageSet.Page1.URL | Should -Not -BeNullOrEmpty
            $script:pageSet.Page1.ShortURL | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ConfluencePage' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:searchLabel = "search$($script:pageSet.Suffix)".ToLowerInvariant()
                $script:pageSet.HomePage | Add-ConfluenceLabel -Label $script:searchLabel -ErrorAction Stop | Out-Null

                $script:getByTitle = Get-ConfluencePage -Title $script:pageSet.Page3.Title.ToLowerInvariant() -SpaceKey $script:spaceKey -PageSize 200 -ErrorAction SilentlyContinue
                $script:getByExactTitle = Get-ConfluencePage -Title $script:pageSet.Page2.Title -SpaceKey $script:spaceKey -ErrorAction SilentlyContinue
                $script:getByPartialTitle = Get-ConfluencePage -Title 'orphan' -SpaceKey $script:spaceKey -ErrorAction SilentlyContinue
                $script:getByWildcardTitle = Get-ConfluencePage -Title '*orphan*' -SpaceKey $script:spaceKey -ErrorAction SilentlyContinue
                $script:getByID1 = Get-ConfluencePage -PageID $script:getByTitle.ID -ErrorAction SilentlyContinue
                $script:getByID2 = Get-ConfluencePage -PageID $script:getByExactTitle.ID -ErrorAction SilentlyContinue
                $script:getByQuery = @()
                $script:getByLabel = @()
                $query = "id in ($($script:getByID1.ID), $($script:getByID2.ID))"
                $maxSearchRetries = if ($script:fixture.Environment.IsCloud) { 24 } else { 6 }
                for ($retry = 0; $retry -lt $maxSearchRetries; $retry++) {
                    $script:getByLabel = Get-ConfluencePage -Label $script:searchLabel -SpaceKey $script:spaceKey -ErrorAction SilentlyContinue
                    $script:getByQuery = Get-ConfluencePage -Query $query -ErrorAction SilentlyContinue
                    if ((@($script:getByLabel).Count -ge 1) -and (@($script:getByQuery).Count -eq 2)) { break }
                    Start-Sleep -Seconds 5
                }

                $script:getByLabelCanBeAsserted = (@($script:getByLabel).Count -ge 1) -or (-not $script:fixture.Environment.IsCloud)
                $script:getByQueryCanBeAsserted = (@($script:getByQuery).Count -eq 2) -or (-not $script:fixture.Environment.IsCloud)
                $script:getAllBySpaceKey = Get-ConfluencePage -SpaceKey $script:spaceKey -ErrorAction SilentlyContinue | Sort-Object ID
                $script:getBySpaceObject = Get-ConfluencePage -Space (Get-ConfluenceSpace -SpaceKey $script:spaceKey) -ErrorAction SilentlyContinue
                $script:getByPipedSpace = Get-ConfluenceSpace -SpaceKey $script:spaceKey | Get-ConfluencePage -ErrorAction SilentlyContinue
                $script:getPagedBySpace = Get-ConfluencePage -SpaceKey $script:spaceKey -PageSize 1 -ErrorAction SilentlyContinue
            }
        }

        It 'gets pages by title, wildcard, ID, label, query, space object, and pipeline' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:getByTitle).Count | Should -Be 1
            @($script:getByExactTitle).Count | Should -Be 1
            @($script:getByPartialTitle).Count | Should -Be 0
            @($script:getByWildcardTitle).Count | Should -Be 1
            @($script:getByID1).Count | Should -Be 1
            @($script:getByID2).Count | Should -Be 1
            @($script:getAllBySpaceKey).Count | Should -Be 5
            @($script:getBySpaceObject).Count | Should -Be 5
            @($script:getByPipedSpace).Count | Should -Be 5
            @($script:getPagedBySpace).Count | Should -Be 5
            if ($script:getByLabelCanBeAsserted) { @($script:getByLabel).Count | Should -Be 1 }
            if ($script:getByQueryCanBeAsserted) { @($script:getByQuery).Count | Should -Be 2 }
            @($script:getPagedBySpace | Where-Object { $_.Space.Key -ne $script:spaceKey }).Count | Should -Be 0
        }

        It 'returns typed pages with expected identity, body, and string values' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            . "$env:BHProjectPath/$env:BHProjectName/Private/ConvertFrom-HTMLEncoded.ps1"

            $script:getByTitle | Should -BeOfType [ConfluencePS.Page]
            $script:getByTitle.ID | Should -BeOfType [UInt64]
            $script:getByTitle.Title | Should -BeExactly $script:pageSet.Page3.Title
            $script:getByTitle.Space.Key | Should -BeExactly $script:spaceKey
            $script:getByID1.ID | Should -Be $script:getByTitle.ID
            $script:getAllBySpaceKey.ID | Should -Contain $script:getByID1.ID
            ConvertFrom-HTMLEncoded $script:getByID1.Body | Should -BeExactly $script:formattedContent
            $script:getByTitle.URL | Should -Not -BeNullOrEmpty
            $script:getByTitle.ShortURL | Should -Not -BeNullOrEmpty
            $script:getByTitle.Version.ToString() | Should -Be $script:getByTitle.Version.Number.ToString()
            $script:getByTitle.Space.ToString() | Should -Be ("[{0}] {1}" -f $script:getByTitle.Space.Key, $script:getByTitle.Space.Name)
        }
    }

    Context 'Set-ConfluencePage' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:page5, $script:page6, $script:page7, $script:page8, $script:page9 = ('Page 5', 'Page 6', 'Page 7', 'Page 8', 'Page 9' | New-ConfluencePage -SpaceKey $script:spaceKey -Body '<p>Lorem ipsum</p>' -ErrorAction Stop)
                foreach ($page in @($script:page5, $script:page6, $script:page7, $script:page8, $script:page9)) { $null = $script:fixture.Pages.Add($page.ID) }

                $script:allPages = Get-ConfluencePage -SpaceKey $script:spaceKey | Where-Object { $_.Title -notlike '*Home' }
                $script:newTitle6 = 'Renamed Page 6'
                $script:newTitle7 = 'Renamed Page 7'
                $script:newVersionMessage9 = 'Updated body content'
                $script:newContent1 = '<h1>Bulk Change</h1><p>Changed all bodies in this space at once</p>'
                $script:newContent2 = '<h1>Set Body by property</h1>'
                $script:newContent3 = '<p>Updated</p>'
                $script:newContent9 = '<h1>Bulk Change</h1><p>Changed all bodies in this space at once</p><p>Updated body for version message test</p>'

                $script:allChangedPages = $script:allPages | ForEach-Object {
                    $_.Body = $script:newContent1
                    $_
                } | Set-ConfluencePage -ErrorAction Stop
                $script:setPage1 = $script:pageSet.Page1.ID | Set-ConfluencePage -Body $script:newContent1 -ErrorAction Stop
                $script:setPage2 = $script:pageSet.Page2.ID | Set-ConfluencePage -Body $script:newContent2 -ErrorAction Stop
                $script:setPage3 = $script:pageSet.Page3.ID | Set-ConfluencePage -Body '...' -ErrorAction Stop
                for ($retry = 0; $retry -lt 12; $retry++) {
                    $currentPage3 = Get-ConfluencePage -PageID $script:pageSet.Page3.ID -ErrorAction Stop
                    if ($currentPage3.Version.Number -ge $script:setPage3.Version.Number) { break }
                    Start-Sleep -Seconds 5
                }
                $script:setPage3 = $script:pageSet.Page3.ID | Set-ConfluencePage -Body 'Updated' -Convert -ErrorAction Stop
                $script:setPage4 = Set-ConfluencePage -PageID $script:pageSet.Page4.ID -Parent $script:setPage3 -ErrorAction Stop
                $script:setPage5 = Set-ConfluencePage -PageID $script:page5.ID -ParentID $script:pageSet.Page4.ID -ErrorAction Stop
                $script:setPage6 = $script:page6.ID | Set-ConfluencePage -Title $script:newTitle6 -ErrorAction Stop
                $script:setPage7 = $script:allChangedPages | Where-Object { $_.ID -eq $script:page7.ID } | ForEach-Object {
                    $_.Title = $script:newTitle7
                    $_
                } | Set-ConfluencePage -ErrorAction Stop
                $script:setPage8 = Set-ConfluencePage -PageID $script:page8.ID -Body '' -ErrorAction Stop
                $script:setPage9 = $script:allChangedPages | Where-Object { $_.ID -eq $script:page9.ID } | ForEach-Object {
                    $_.Body = $script:newContent9
                    $_.Version.Message = $script:newVersionMessage9
                    $_
                } | Set-ConfluencePage -ErrorAction Stop
            }
        }

        It 'updates page bodies, titles, parents, version messages, and converted content' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            @($script:allChangedPages).Count | Should -Be 9
            $script:setPage1 | Should -BeOfType [ConfluencePS.Page]
            $script:setPage2 | Should -BeOfType [ConfluencePS.Page]
            $script:setPage3 | Should -BeOfType [ConfluencePS.Page]
            $script:setPage4 | Should -BeOfType [ConfluencePS.Page]
            $script:setPage5 | Should -BeOfType [ConfluencePS.Page]
            $script:setPage6.Title | Should -BeExactly $script:newTitle6
            $script:setPage7.Title | Should -BeExactly $script:newTitle7
            $script:setPage9.Version.Message | Should -BeExactly $script:newVersionMessage9
            $script:setPage2.Body | Should -BeExactly $script:newContent2
            $script:setPage3.Body | Should -BeExactly $script:newContent3
            $script:setPage8.Body | Should -BeExactly ''
            $script:setPage9.Body | Should -BeExactly $script:newContent9
            $script:setPage1.Version.Number | Should -BeExactly 2
            $script:setPage2.Version.Number | Should -BeExactly 3
            $script:setPage3.Version.Number | Should -BeExactly 4
        }

        It 'updates and preserves expected page hierarchy' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            $script:setPage1.Ancestors.ID | Should -BeExactly $script:pageSet.HomePage.ID
            $script:setPage2.Ancestors | Should -BeNullOrEmpty
            $script:setPage3.Ancestors.ID | Should -BeExactly $script:pageSet.HomePage.ID
            $script:setPage4.Ancestors.ID | Should -BeExactly @($script:pageSet.HomePage.ID, $script:setPage3.ID)
            $script:setPage5.Ancestors.ID | Should -BeExactly @($script:pageSet.HomePage.ID, $script:setPage3.ID, $script:pageSet.Page4.ID)
        }
    }

    Context 'Get-ConfluenceChildPage' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:childPages = @()
                $script:descendantPages = @()
                $script:lastChildPageError = $null
                for ($retry = 0; $retry -lt 12; $retry++) {
                    try {
                        $script:childPages = $script:pageSet.HomePage | Get-ConfluenceChildPage -ErrorAction Stop
                        $script:descendantPages = $script:pageSet.HomePage | Get-ConfluenceChildPage -Recurse -ErrorAction Stop
                        $script:lastChildPageError = $null
                        break
                    }
                    catch {
                        $script:lastChildPageError = $_
                        Start-Sleep -Seconds 5
                    }
                }
            }
        }

        It 'gets direct children and recursive descendants' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }
            if ($script:lastChildPageError) { throw $script:lastChildPageError }

            @($script:childPages).Count | Should -Be 2
            @($script:descendantPages).Count | Should -Be 4
            $script:childPages | Should -BeOfType [ConfluencePS.Page]
            $script:descendantPages | Should -BeOfType [ConfluencePS.Page]
        }
    }

    Context 'Remove-ConfluencePage' {
        BeforeAll {
            if ($script:fixture.IsConfigured) {
                $script:deletedPage = New-ConfluenceIntegrationPage -Fixture $script:fixture -SpaceKey $script:spaceKey -TitlePrefix 'Deleted Page'
                $script:deletedPageLabel = "deleted$($script:pageSet.Suffix)".ToLowerInvariant()
                $script:deletedPage | Add-ConfluenceLabel -Label $script:deletedPageLabel -ErrorAction Stop | Out-Null
                $maxSearchRetries = if ($script:fixture.Environment.IsCloud) { 24 } else { 6 }
                $script:deletedPageByLabelBefore = @()
                for ($retry = 0; $retry -lt $maxSearchRetries; $retry++) {
                    $script:deletedPageByLabelBefore = Get-ConfluencePage -Label $script:deletedPageLabel -SpaceKey $script:spaceKey -ErrorAction SilentlyContinue
                    if (@($script:deletedPageByLabelBefore).ID -contains $script:deletedPage.ID) { break }
                    Start-Sleep -Seconds 5
                }
                $script:pagesBeforeDelete = Get-ConfluencePage -SpaceKey $script:spaceKey -ErrorAction Stop

                Remove-ConfluencePage -PageID $script:deletedPage.ID -Confirm:$false -ErrorAction Stop
                $script:fixture.Pages.Remove($script:deletedPage.ID)
                $script:deletedPageByLabelAfter = @()
                for ($retry = 0; $retry -lt $maxSearchRetries; $retry++) {
                    $script:deletedPageByLabelAfter = Get-ConfluencePage -Label $script:deletedPageLabel -SpaceKey $script:spaceKey -ErrorAction SilentlyContinue
                    if (@($script:deletedPageByLabelAfter).ID -notcontains $script:deletedPage.ID) { break }
                    Start-Sleep -Seconds 5
                }
                if (-not $script:fixture.Environment.IsCloud) {
                    $script:deletedPageByLabelWithStatus = Get-ConfluencePage -Label $script:deletedPageLabel -SpaceKey $script:spaceKey -Status trashed -ErrorAction SilentlyContinue
                }
            }
        }

        It 'removes a page and excludes it from normal label searches' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }

            $script:pagesBeforeDelete | Should -Not -BeNullOrEmpty
            if (-not $script:fixture.Environment.IsCloud) {
                @($script:deletedPageByLabelBefore).ID | Should -Contain $script:deletedPage.ID
            }
            @($script:deletedPageByLabelAfter).ID | Should -Not -Contain $script:deletedPage.ID
        }

        It 'returns the trashed labeled page on Data Center when status is requested' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:fixture)) { return }
            if ($script:fixture.Environment.IsCloud) {
                Set-ItResult -Skipped -Because 'Confluence Cloud content search does not return trashed labeled pages.'
                return
            }

            @($script:deletedPageByLabelWithStatus).ID | Should -Contain $script:deletedPage.ID
        }
    }
}
