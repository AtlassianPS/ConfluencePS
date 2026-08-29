#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

Describe 'GitHub Actions release contract' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/Helpers/TestTools.ps1"
        $script:projectRoot = Resolve-ProjectRoot
        $workflowRoot = Join-Path $script:projectRoot '.github/workflows'
        $script:ci = Get-Content (Join-Path $workflowRoot 'ci.yml') -Raw
        $script:continuousRelease = Get-Content (Join-Path $workflowRoot 'continuous_release.yml') -Raw
        $script:integrationTests = Get-Content (Join-Path $workflowRoot 'integration_tests.yml') -Raw
        $script:releaseIntent = Get-Content (Join-Path $workflowRoot 'release_intent.yml') -Raw
        $requirements = Import-PowerShellDataFile (Join-Path $script:projectRoot 'Tools/build.requirements.psd1')
        $standardsRequirement = $requirements | Where-Object ModuleName -EQ 'AtlassianPS.Standards' | Select-Object -First 1
        $script:standardsVersionPattern = [regex]::Escape([String]$standardsRequirement.RequiredVersion)
    }

    It 'pins every external action to a full commit SHA' {
        foreach ($workflow in Get-ChildItem (Join-Path $script:projectRoot '.github/workflows') -Filter '*.yml') {
            $content = Get-Content -LiteralPath $workflow.FullName -Raw
            $actionReferences = [regex]::Matches($content, '(?m)^\s*(?:-\s+)?uses:\s+(?<action>[^@\s]+)@(?<ref>[^\s#]+)')

            foreach ($reference in $actionReferences) {
                $reference.Groups['ref'].Value | Should -Match '^[0-9a-f]{40}$' -Because $workflow.Name
            }
        }
    }

    It 'validates release intent without checking out contributor code' {
        $script:releaseIntent | Should -Match '(?m)^\s+pull_request_target:'
        $script:releaseIntent | Should -Not -Match '(?m)types:\s*\[[^\]]*\bedited\b'
        $script:releaseIntent | Should -Match '(?m)types:\s*\[[^\]]*\bsynchronize\b'
        $script:releaseIntent | Should -Match '(?m)types:\s*\[[^\]]*\blabeled\b'
        $script:releaseIntent | Should -Match '(?m)types:\s*\[[^\]]*\bunlabeled\b'
        $script:releaseIntent | Should -Match 'AtlassianPS/AtlassianPS\.Standards/\.github/actions/validate-release-intent@'
        $script:releaseIntent | Should -Match '(?m)^\s+pull-requests:\s+read\r?$'
        $script:releaseIntent | Should -Match '(?m)^\s+issues:\s+write\r?$'
        $script:releaseIntent | Should -Not -Match 'actions/checkout@|contents:\s+write|pull_request\.head|github\.head_ref'
    }

    It 'delegates CI to the immutable Standards workflow' {
        $script:ci | Should -Match "AtlassianPS/AtlassianPS\.Standards/\.github/workflows/module_ci\.yml@[0-9a-f]{40}\s+#\s+v$script:standardsVersionPattern"
        $script:ci | Should -Match 'smoke-profile:\s+confluence'
        $script:ci | Should -Match 'exclude-documentation-tests:\s+true'
        $script:ci | Should -Match '(?ms)ci-required:.*?name:\s+CI Result.*?needs:\s+module-ci'
        $script:ci | Should -Not -Match 'actions/checkout@|Invoke-Build|upload-artifact@'
    }

    It 'delegates release orchestration to the immutable Standards workflow' {
        $script:continuousRelease | Should -Match '(?ms)workflow_run:.*?branches:\s*\[master\]'
        $script:continuousRelease | Should -Match 'uses:\s+AtlassianPS/AtlassianPS\.Standards/\.github/workflows/module_release\.yml@[0-9a-f]{40}'
        $script:continuousRelease | Should -Match 'module-name:\s+ConfluencePS'
        $script:continuousRelease | Should -Match 'release-impact:\s+\$\{\{\s*inputs\.release_impact\s*\}\}'
        $script:continuousRelease | Should -Match 'secrets:\s+inherit'
        $script:continuousRelease | Should -Not -Match '(?m)^  (prepare|publish):|Publish-Module|create-github-app-token|actions/download-artifact'
    }

    It 'runs full integration tests weekly and on demand' {
        $script:integrationTests | Should -Match 'cron:\s*"0 5 \* \* 0"'
        $script:integrationTests | Should -Match 'workflow_dispatch:'
    }

    It 'retains integration diagnostics briefly and uploads container logs on demand' {
        ([regex]::Matches($script:integrationTests, 'retention-days:\s+14')).Count | Should -Be 2
        ([regex]::Matches($script:integrationTests, 'retention-days:\s+7')).Count | Should -Be 1
        $script:integrationTests | Should -Match '(?ms)debug:.*?type:\s+boolean'
        ([regex]::Matches($script:integrationTests, "failure\(\) \|\| inputs\.debug \|\| runner\.debug == '1'")).Count | Should -Be 2
    }

    It 'removes the legacy tag-triggered release path' {
        Test-Path (Join-Path $script:projectRoot '.github/workflows/release.yml') | Should -BeFalse
        $script:continuousRelease | Should -Not -Match '(?m)^\s+tags:'
    }

    It 'keeps source metadata and build responsibilities focused' {
        $manifest = Get-Content (Join-Path $script:projectRoot 'ConfluencePS/ConfluencePS.psd1') -Raw
        $buildScript = Get-Content (Join-Path $script:projectRoot 'ConfluencePS.build.ps1') -Raw

        $manifest | Should -Match "ReleaseNotes\s*=\s*''"
        $buildScript | Should -Match 'Task SetSourceVersion'
        $buildScript | Should -Match 'Task VerifyReleaseArtifact'
        $buildScript | Should -Not -Match '(?m)^Task Publish\b|PSGalleryAPIKey'
    }

    It 'labels future Dependabot updates as non-releasing changes' {
        $dependabot = Get-Content (Join-Path $script:projectRoot '.github/dependabot.yml') -Raw

        $dependabot | Should -Match '(?m)^\s+- dependencies\r?$'
        $dependabot | Should -Match '(?m)^\s+- github_actions\r?$'
        $dependabot | Should -Match '(?m)^\s+- "release:none"\r?$'
        $dependabot | Should -Match 'ignore:[\s\S]+dependency-name:\s*"AtlassianPS/AtlassianPS\.Standards\*"'
    }
}
