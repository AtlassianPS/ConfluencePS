#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'AtlassianPS.Standards version consistency' -Tag Unit {
    BeforeAll {
        $script:ExpectedStandardsSha = '6fe5d05db84cdd10c9e4284e235a8f359c9537ad'

        function Get-RepositoryRoot {
            if (
                $env:BHProjectPath -and
                (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'ConfluencePS.build.ps1'))
            ) {
                return (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
            }

            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (
                    (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'ConfluencePS.build.ps1')) -and
                    (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'Tools/build.requirements.psd1'))
                ) {
                    return $candidate
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            throw "Could not resolve repository root from '$PSScriptRoot'."
        }

        function Get-StandardsVersion {
            param([Parameter(Mandatory)][String]$ProjectRoot)

            $buildRequirementsPath = Join-Path -Path $ProjectRoot -ChildPath 'Tools/build.requirements.psd1'
            $buildRequirements = Import-PowerShellDataFile -Path $buildRequirementsPath
            $standardsRequirement = $buildRequirements |
                Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
                Select-Object -First 1

            if (-not $standardsRequirement -or -not $standardsRequirement.RequiredVersion) {
                throw "Could not resolve AtlassianPS.Standards required version from '$buildRequirementsPath'."
            }

            return [string] $standardsRequirement.RequiredVersion
        }
    }

    It 'keeps workflow Standards action pins aligned with build.requirements' {
        $projectRoot = Get-RepositoryRoot
        $standardsVersion = Get-StandardsVersion -ProjectRoot $projectRoot

        $workflowPaths = Get-ChildItem -Path (Join-Path -Path $projectRoot -ChildPath '.github/workflows') -File -Filter '*.yml' |
            Select-Object -ExpandProperty FullName

        $standardsActionReferences = foreach ($workflowPath in $workflowPaths) {
            $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
            [regex]::Matches(
                $workflowContent,
                'AtlassianPS/AtlassianPS\.Standards/\.github/actions/[^@\s]+@(?<ref>[^\s#]+)(?:\s+#\s+v(?<version>[0-9]+\.[0-9]+\.[0-9]+))?'
            ) | ForEach-Object {
                [PSCustomObject]@{
                    WorkflowPath = $workflowPath
                    Ref          = $_.Groups['ref'].Value
                    Version      = $_.Groups['version'].Value
                }
            }
        }

        @($standardsActionReferences).Count | Should -BeGreaterThan 0
        @($standardsActionReferences | Where-Object { $_.Ref -notmatch '^[0-9a-f]{40}$' }).Count | Should -Be 0
        @($standardsActionReferences | Where-Object { [string]::IsNullOrWhiteSpace($_.Version) }).Count | Should -Be 0
        ($standardsActionReferences | Select-Object -ExpandProperty Version -Unique) | Should -Be @($standardsVersion)
        ($standardsActionReferences | Select-Object -ExpandProperty Ref -Unique) | Should -Be @($script:ExpectedStandardsSha)
    }

    It 'uses the shared Standards release tag resolver action' {
        $projectRoot = Get-RepositoryRoot
        $releaseWorkflowContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath '.github/workflows/release.yml') -Raw

        $releaseWorkflowContent | Should -Match "AtlassianPS/AtlassianPS\.Standards/\.github/actions/resolve-release-tag@$script:ExpectedStandardsSha"
        $releaseWorkflowContent | Should -Not -Match 'git\s+rev-list|Resolve-ReleaseTag|release_sha="\$\(git'
    }

    It 'builds changelog release notes before publishing and reuses them for GitHub releases' {
        $projectRoot = Get-RepositoryRoot
        $releaseWorkflowContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath '.github/workflows/release.yml') -Raw

        $releaseWorkflowContent | Should -Match "AtlassianPS/AtlassianPS\.Standards/\.github/actions/build-release-notes@$script:ExpectedStandardsSha"
        $releaseWorkflowContent | Should -Match 'body_path:\s+\$\{\{\s*steps\.release_notes\.outputs\.release_notes_path\s*\}\}'
        $releaseWorkflowContent | Should -Match 'build-release-notes[\s\S]+Publish module'
        $releaseWorkflowContent | Should -Not -Match 'changelog-to-release|changelog\.configuration\.json|steps\.changelog\.outputs\.body|Set-Content|Out-File|release-notes\.md'
        Test-Path -LiteralPath (Join-Path -Path $projectRoot -ChildPath '.github/changelog.configuration.json') | Should -BeFalse
    }

    It 'keeps published manifest release notes sourced from the changelog' {
        $projectRoot = Get-RepositoryRoot
        $buildScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'ConfluencePS.build.ps1') -Raw

        $buildScriptContent | Should -Match 'Get-AtlassianPSReleaseNotesFromChangelog[\s\S]+CHANGELOG\.md'
        $buildScriptContent | Should -Match 'Set-AtlassianPSModuleManifestVersion[\s\S]+-ReleaseNotes\s+\$releaseNotes'
        $buildScriptContent | Should -Not -Match 'function\s+Get-.*ReleaseNotesFromChangelog|Metadata\\Update-Metadata[\s\S]+PropertyName\s+"ReleaseNotes"|Get-Content[\s\S]+CHANGELOG\.md[\s\S]+Set-Content'
    }

    It 'uses Standards package validation for CI publish dry-runs' {
        $projectRoot = Get-RepositoryRoot
        $buildScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'ConfluencePS.build.ps1') -Raw
        $ciWorkflowContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath '.github/workflows/ci.yml') -Raw

        $buildScriptContent | Should -Match 'Task\s+TestPublish\s+Build,\s+Package'
        $buildScriptContent | Should -Match 'New-AtlassianPSModulePackage'
        $buildScriptContent | Should -Match 'Test-AtlassianPSModulePackage'
        $buildScriptContent | Should -Not -Match 'Task\s+SignCode|Task\s+UpdateHomepage|Compress-Archive'
        $ciWorkflowContent | Should -Match 'Invoke-Build -Task Clean, TestPublish'
        $ciWorkflowContent | Should -Match 'rhysd/actionlint@[0-9a-f]{40}\s+#\s+v[0-9]+\.[0-9]+\.[0-9]+'
        $ciWorkflowContent | Should -Match 'dorny/paths-filter@[0-9a-f]{40}\s+#\s+v[0-9]+'
    }

    It 'uses the future release changelog format required by the blueprint' {
        $projectRoot = Get-RepositoryRoot
        $changelogContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'CHANGELOG.md') -Raw

        $changelogContent | Should -Match '(?m)^## v[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)? - \d{4}-\d{2}-\d{2}$'
    }

    It 'reads AtlassianPS.Standards version from build.requirements in tool scripts' {
        $projectRoot = Get-RepositoryRoot

        $setupScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tools/setup.ps1') -Raw
        $updateScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tools/update.dependencies.ps1') -Raw
        $buildScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'ConfluencePS.build.ps1') -Raw

        $setupScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $setupScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $setupScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'

        $updateScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $updateScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $updateScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'
        $updateScriptContent | Should -Match '\$PSCmdlet\.ShouldProcess\('
        $updateScriptContent | Should -Match 'AtlassianPS\.Standards\\Update-AtlassianPSDependencyReference'

        $buildScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $buildScriptContent | Should -Match '-RequiredVersion\s+\$standardsRequirement\.RequiredVersion'
        $buildScriptContent | Should -Not -Match "AtlassianPS\.Standards.*RequiredVersion\s+'[0-9]+\.[0-9]+\.[0-9]+'"
    }
}
