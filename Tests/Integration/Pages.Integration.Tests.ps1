#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

Describe 'Page integration tests' -Tag Integration, Cloud, DataCenter {
    BeforeAll {
        . "$PSScriptRoot/Helpers/ConfluenceIntegrationFixture.ps1"
        $script:Fixture = New-ConfluenceIntegrationFixture

        if ($script:Fixture.IsConfigured) {
            $script:RawContent = 'Hi Pester!'
            $script:FormattedContent = '<p>Hi Pester!</p>'
            $script:PageSet = New-ConfluenceIntegrationPageSet -Fixture $script:Fixture -SpaceNamePrefix 'ConfluencePS Pages' -Body $script:FormattedContent
            $script:SpaceKey = $script:PageSet.Space.Key
        }
    }

    AfterAll {
        if ($script:Fixture) {
            Remove-ConfluenceIntegrationFixture -Fixture $script:Fixture
        }
    }

    Context 'New-ConfluencePage' {
        It 'creates pages from pipeline, parameters, object input, and parent object input' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            $script:PageSet.Page1 | Should -BeOfType [ConfluencePS.Page]
            $script:PageSet.Page2 | Should -BeOfType [ConfluencePS.Page]
            $script:PageSet.Page3 | Should -BeOfType [ConfluencePS.Page]
            $script:PageSet.Page4 | Should -BeOfType [ConfluencePS.Page]
            $script:PageSet.Page1.ID | Should -BeOfType [UInt64]
            $script:PageSet.Page2.ID | Should -BeOfType [UInt64]
            $script:PageSet.Page1.Space.Key | Should -BeExactly $script:SpaceKey
            $script:PageSet.Page2.Space.Key | Should -BeExactly $script:SpaceKey
            $script:PageSet.Page3.Space.Key | Should -BeExactly $script:SpaceKey
            $script:PageSet.Page4.Space.Key | Should -BeExactly $script:SpaceKey
            $script:PageSet.Page1.Ancestors.ID | Should -BeExactly $script:PageSet.HomePage.ID
            $script:PageSet.Page2.Ancestors | Should -BeNullOrEmpty
            $script:PageSet.Page3.Ancestors.ID | Should -BeExactly $script:PageSet.HomePage.ID
            $script:PageSet.Page4.Ancestors.ID | Should -BeExactly $script:PageSet.HomePage.ID
            $script:PageSet.Page1.URL | Should -Not -BeNullOrEmpty
            $script:PageSet.Page1.ShortURL | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ConfluencePage' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:SearchLabel = "search$($script:PageSet.Suffix)".ToLowerInvariant()
                $script:PageSet.HomePage | Add-ConfluenceLabel -Label $script:SearchLabel -ErrorAction Stop | Out-Null

                $script:GetByTitle = Get-ConfluencePage -Title $script:PageSet.Page3.Title.ToLowerInvariant() -SpaceKey $script:SpaceKey -PageSize 200 -ErrorAction SilentlyContinue
                $script:GetByExactTitle = Get-ConfluencePage -Title $script:PageSet.Page2.Title -SpaceKey $script:SpaceKey -ErrorAction SilentlyContinue
                $script:GetByPartialTitle = Get-ConfluencePage -Title 'orphan' -SpaceKey $script:SpaceKey -ErrorAction SilentlyContinue
                $script:GetByWildcardTitle = Get-ConfluencePage -Title '*orphan*' -SpaceKey $script:SpaceKey -ErrorAction SilentlyContinue
                $script:GetByID1 = Get-ConfluencePage -PageID $script:GetByTitle.ID -ErrorAction SilentlyContinue
                $script:GetByID2 = Get-ConfluencePage -PageID $script:GetByExactTitle.ID -ErrorAction SilentlyContinue
                $script:GetByQuery = @()
                $script:GetByLabel = @()
                $query = "id in ($($script:GetByID1.ID), $($script:GetByID2.ID))"
                $maxSearchRetries = if ($script:Fixture.Environment.IsCloud) { 24 } else { 6 }
                for ($retry = 0; $retry -lt $maxSearchRetries; $retry++) {
                    $script:GetByLabel = Get-ConfluencePage -Label $script:SearchLabel -SpaceKey $script:SpaceKey -ErrorAction SilentlyContinue
                    $script:GetByQuery = Get-ConfluencePage -Query $query -ErrorAction SilentlyContinue
                    if ((@($script:GetByLabel).Count -ge 1) -and (@($script:GetByQuery).Count -eq 2)) { break }
                    Start-Sleep -Seconds 5
                }

                $script:GetByLabelCanBeAsserted = (@($script:GetByLabel).Count -ge 1) -or (-not $script:Fixture.Environment.IsCloud)
                $script:GetByQueryCanBeAsserted = (@($script:GetByQuery).Count -eq 2) -or (-not $script:Fixture.Environment.IsCloud)
                $script:GetAllBySpaceKey = Get-ConfluencePage -SpaceKey $script:SpaceKey -ErrorAction SilentlyContinue | Sort-Object ID
                $script:GetBySpaceObject = Get-ConfluencePage -Space (Get-ConfluenceSpace -SpaceKey $script:SpaceKey) -ErrorAction SilentlyContinue
                $script:GetByPipedSpace = Get-ConfluenceSpace -SpaceKey $script:SpaceKey | Get-ConfluencePage -ErrorAction SilentlyContinue
                $script:GetPagedBySpace = Get-ConfluencePage -SpaceKey $script:SpaceKey -PageSize 1 -ErrorAction SilentlyContinue
            }
        }

        It 'gets pages by title, wildcard, ID, label, query, space object, and pipeline' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:GetByTitle).Count | Should -Be 1
            @($script:GetByExactTitle).Count | Should -Be 1
            @($script:GetByPartialTitle).Count | Should -Be 0
            @($script:GetByWildcardTitle).Count | Should -Be 1
            @($script:GetByID1).Count | Should -Be 1
            @($script:GetByID2).Count | Should -Be 1
            @($script:GetAllBySpaceKey).Count | Should -Be 5
            @($script:GetBySpaceObject).Count | Should -Be 5
            @($script:GetByPipedSpace).Count | Should -Be 5
            @($script:GetPagedBySpace).Count | Should -Be 5
            if ($script:GetByLabelCanBeAsserted) { @($script:GetByLabel).Count | Should -Be 1 }
            if ($script:GetByQueryCanBeAsserted) { @($script:GetByQuery).Count | Should -Be 2 }
            @($script:GetPagedBySpace | Where-Object { $_.Space.Key -ne $script:SpaceKey }).Count | Should -Be 0
        }

        It 'returns typed pages with expected identity, body, and string values' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            . "$env:BHProjectPath/$env:BHProjectName/Private/ConvertFrom-HTMLEncoded.ps1"

            $script:GetByTitle | Should -BeOfType [ConfluencePS.Page]
            $script:GetByTitle.ID | Should -BeOfType [UInt64]
            $script:GetByTitle.Title | Should -BeExactly $script:PageSet.Page3.Title
            $script:GetByTitle.Space.Key | Should -BeExactly $script:SpaceKey
            $script:GetByID1.ID | Should -Be $script:GetByTitle.ID
            $script:GetAllBySpaceKey.ID | Should -Contain $script:GetByID1.ID
            ConvertFrom-HTMLEncoded $script:GetByID1.Body | Should -BeExactly $script:FormattedContent
            $script:GetByTitle.URL | Should -Not -BeNullOrEmpty
            $script:GetByTitle.ShortURL | Should -Not -BeNullOrEmpty
            $script:GetByTitle.Version.ToString() | Should -Be $script:GetByTitle.Version.Number.ToString()
            $script:GetByTitle.Space.ToString() | Should -Be ("[{0}] {1}" -f $script:GetByTitle.Space.Key, $script:GetByTitle.Space.Name)
        }
    }

    Context 'Set-ConfluencePage' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:Page5, $script:Page6, $script:Page7, $script:Page8, $script:Page9 = ('Page 5', 'Page 6', 'Page 7', 'Page 8', 'Page 9' | New-ConfluencePage -SpaceKey $script:SpaceKey -Body '<p>Lorem ipsum</p>' -ErrorAction Stop)
                foreach ($page in @($script:Page5, $script:Page6, $script:Page7, $script:Page8, $script:Page9)) { $null = $script:Fixture.Pages.Add($page.ID) }

                $script:AllPages = Get-ConfluencePage -SpaceKey $script:SpaceKey | Where-Object { $_.Title -notlike '*Home' }
                $script:NewTitle6 = 'Renamed Page 6'
                $script:NewTitle7 = 'Renamed Page 7'
                $script:NewVersionMessage9 = 'Updated body content'
                $script:NewContent1 = '<h1>Bulk Change</h1><p>Changed all bodies in this space at once</p>'
                $script:NewContent2 = '<h1>Set Body by property</h1>'
                $script:NewContent3 = '<p>Updated</p>'
                $script:NewContent9 = '<h1>Bulk Change</h1><p>Changed all bodies in this space at once</p><p>Updated body for version message test</p>'

                $script:AllChangedPages = $script:AllPages | ForEach-Object {
                    $_.Body = $script:NewContent1
                    $_
                } | Set-ConfluencePage -ErrorAction Stop
                $script:SetPage1 = $script:PageSet.Page1.ID | Set-ConfluencePage -Body $script:NewContent1 -ErrorAction Stop
                $script:SetPage2 = $script:PageSet.Page2.ID | Set-ConfluencePage -Body $script:NewContent2 -ErrorAction Stop
                $script:SetPage3 = $script:PageSet.Page3.ID | Set-ConfluencePage -Body '...' -ErrorAction Stop
                for ($retry = 0; $retry -lt 12; $retry++) {
                    $currentPage3 = Get-ConfluencePage -PageID $script:PageSet.Page3.ID -ErrorAction Stop
                    if ($currentPage3.Version.Number -ge $script:SetPage3.Version.Number) { break }
                    Start-Sleep -Seconds 5
                }
                $script:SetPage3 = $script:PageSet.Page3.ID | Set-ConfluencePage -Body 'Updated' -Convert -ErrorAction Stop
                $script:SetPage4 = Set-ConfluencePage -PageID $script:PageSet.Page4.ID -Parent $script:SetPage3 -ErrorAction Stop
                $script:SetPage5 = Set-ConfluencePage -PageID $script:Page5.ID -ParentID $script:PageSet.Page4.ID -ErrorAction Stop
                $script:SetPage6 = $script:Page6.ID | Set-ConfluencePage -Title $script:NewTitle6 -ErrorAction Stop
                $script:SetPage7 = $script:AllChangedPages | Where-Object { $_.ID -eq $script:Page7.ID } | ForEach-Object {
                    $_.Title = $script:NewTitle7
                    $_
                } | Set-ConfluencePage -ErrorAction Stop
                $script:SetPage8 = Set-ConfluencePage -PageID $script:Page8.ID -Body '' -ErrorAction Stop
                $script:SetPage9 = $script:AllChangedPages | Where-Object { $_.ID -eq $script:Page9.ID } | ForEach-Object {
                    $_.Body = $script:NewContent9
                    $_.Version.Message = $script:NewVersionMessage9
                    $_
                } | Set-ConfluencePage -ErrorAction Stop
            }
        }

        It 'updates page bodies, titles, parents, version messages, and converted content' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            @($script:AllChangedPages).Count | Should -Be 9
            $script:SetPage1 | Should -BeOfType [ConfluencePS.Page]
            $script:SetPage2 | Should -BeOfType [ConfluencePS.Page]
            $script:SetPage3 | Should -BeOfType [ConfluencePS.Page]
            $script:SetPage4 | Should -BeOfType [ConfluencePS.Page]
            $script:SetPage5 | Should -BeOfType [ConfluencePS.Page]
            $script:SetPage6.Title | Should -BeExactly $script:NewTitle6
            $script:SetPage7.Title | Should -BeExactly $script:NewTitle7
            $script:SetPage9.Version.Message | Should -BeExactly $script:NewVersionMessage9
            $script:SetPage2.Body | Should -BeExactly $script:NewContent2
            $script:SetPage3.Body | Should -BeExactly $script:NewContent3
            $script:SetPage8.Body | Should -BeExactly ''
            $script:SetPage9.Body | Should -BeExactly $script:NewContent9
            $script:SetPage1.Version.Number | Should -BeExactly 2
            $script:SetPage2.Version.Number | Should -BeExactly 3
            $script:SetPage3.Version.Number | Should -BeExactly 4
        }

        It 'updates and preserves expected page hierarchy' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            $script:SetPage1.Ancestors.ID | Should -BeExactly $script:PageSet.HomePage.ID
            $script:SetPage2.Ancestors | Should -BeNullOrEmpty
            $script:SetPage3.Ancestors.ID | Should -BeExactly $script:PageSet.HomePage.ID
            $script:SetPage4.Ancestors.ID | Should -BeExactly @($script:PageSet.HomePage.ID, $script:SetPage3.ID)
            $script:SetPage5.Ancestors.ID | Should -BeExactly @($script:PageSet.HomePage.ID, $script:SetPage3.ID, $script:PageSet.Page4.ID)
        }
    }

    Context 'Get-ConfluenceChildPage' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:ChildPages = @()
                $script:DescendantPages = @()
                $script:LastChildPageError = $null
                for ($retry = 0; $retry -lt 12; $retry++) {
                    try {
                        $script:ChildPages = $script:PageSet.HomePage | Get-ConfluenceChildPage -ErrorAction Stop
                        $script:DescendantPages = $script:PageSet.HomePage | Get-ConfluenceChildPage -Recurse -ErrorAction Stop
                        $script:LastChildPageError = $null
                        break
                    }
                    catch {
                        $script:LastChildPageError = $_
                        Start-Sleep -Seconds 5
                    }
                }
            }
        }

        It 'gets direct children and recursive descendants' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }
            if ($script:LastChildPageError) { throw $script:LastChildPageError }

            @($script:ChildPages).Count | Should -Be 2
            @($script:DescendantPages).Count | Should -Be 4
            $script:ChildPages | Should -BeOfType [ConfluencePS.Page]
            $script:DescendantPages | Should -BeOfType [ConfluencePS.Page]
        }
    }

    Context 'Remove-ConfluencePage' {
        BeforeAll {
            if ($script:Fixture.IsConfigured) {
                $script:DeletedPage = New-ConfluenceIntegrationPage -Fixture $script:Fixture -SpaceKey $script:SpaceKey -TitlePrefix 'Deleted Page'
                $script:DeletedPageLabel = "deleted$($script:PageSet.Suffix)".ToLowerInvariant()
                $script:DeletedPage | Add-ConfluenceLabel -Label $script:DeletedPageLabel -ErrorAction Stop | Out-Null
                $maxSearchRetries = if ($script:Fixture.Environment.IsCloud) { 24 } else { 6 }
                $script:DeletedPageByLabelBefore = @()
                for ($retry = 0; $retry -lt $maxSearchRetries; $retry++) {
                    $script:DeletedPageByLabelBefore = Get-ConfluencePage -Label $script:DeletedPageLabel -SpaceKey $script:SpaceKey -ErrorAction SilentlyContinue
                    if (@($script:DeletedPageByLabelBefore).ID -contains $script:DeletedPage.ID) { break }
                    Start-Sleep -Seconds 5
                }
                $script:PagesBeforeDelete = Get-ConfluencePage -SpaceKey $script:SpaceKey -ErrorAction Stop

                Remove-ConfluencePage -PageID $script:DeletedPage.ID -Confirm:$false -ErrorAction Stop
                $script:Fixture.Pages.Remove($script:DeletedPage.ID)
                $script:DeletedPageByLabelAfter = @()
                for ($retry = 0; $retry -lt $maxSearchRetries; $retry++) {
                    $script:DeletedPageByLabelAfter = Get-ConfluencePage -Label $script:DeletedPageLabel -SpaceKey $script:SpaceKey -ErrorAction SilentlyContinue
                    if (@($script:DeletedPageByLabelAfter).ID -notcontains $script:DeletedPage.ID) { break }
                    Start-Sleep -Seconds 5
                }
                if (-not $script:Fixture.Environment.IsCloud) {
                    $script:DeletedPageByLabelWithStatus = Get-ConfluencePage -Label $script:DeletedPageLabel -SpaceKey $script:SpaceKey -Status trashed -ErrorAction SilentlyContinue
                }
            }
        }

        It 'removes a page and excludes it from normal label searches' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }

            $script:PagesBeforeDelete | Should -Not -BeNullOrEmpty
            if (-not $script:Fixture.Environment.IsCloud) {
                @($script:DeletedPageByLabelBefore).ID | Should -Contain $script:DeletedPage.ID
            }
            @($script:DeletedPageByLabelAfter).ID | Should -Not -Contain $script:DeletedPage.ID
        }

        It 'returns the trashed labeled page on Data Center when status is requested' {
            if (-not (Assert-ConfluenceIntegrationFixtureReady -Fixture $script:Fixture)) { return }
            if ($script:Fixture.Environment.IsCloud) {
                Set-ItResult -Skipped -Because 'Confluence Cloud content search does not return trashed labeled pages.'
                return
            }

            @($script:DeletedPageByLabelWithStatus).ID | Should -Contain $script:DeletedPage.ID
        }
    }
}
