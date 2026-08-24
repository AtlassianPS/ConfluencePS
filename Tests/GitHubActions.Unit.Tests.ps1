#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'GitHub Actions release contract' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/Helpers/TestTools.ps1"
        $script:projectRoot = Resolve-ProjectRoot
        $workflowRoot = Join-Path $script:projectRoot '.github/workflows'
        $script:ci = Get-Content (Join-Path $workflowRoot 'ci.yml') -Raw
        $script:continuousRelease = Get-Content (Join-Path $workflowRoot 'continuous_release.yml') -Raw
        $script:releaseIntent = Get-Content (Join-Path $workflowRoot 'release_intent.yml') -Raw
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
        $script:releaseIntent | Should -Match 'AtlassianPS/AtlassianPS\.Standards/\.github/actions/validate-release-intent@'
        $script:releaseIntent | Should -Match '(?m)^\s+pull-requests:\s+read\r?$'
        $script:releaseIntent | Should -Match '(?m)^\s+issues:\s+write\r?$'
        $script:releaseIntent | Should -Not -Match 'actions/checkout@|contents:\s+write|pull_request\.head|github\.head_ref'
    }

    It 'builds and verifies the release candidate without publishing credentials' {
        $script:ci | Should -Match 'AtlassianPS/AtlassianPS\.Standards/\.github/actions/build-release-notes@'
        $script:ci | Should -Match 'Invoke-Build -Task SetVersion'
        $script:ci | Should -Match 'Invoke-Build -Task VerifyReleaseArtifact'
        $script:ci | Should -Match 'name:\s+Release'
        $script:ci | Should -Not -Match 'PSGALLERY_API_KEY|ATLASSIANPS_RELEASE_APP|HOMEPAGE_PAT'
    }

    It 'delegates release orchestration to the immutable Standards workflow' {
        $script:continuousRelease | Should -Match 'uses:\s+AtlassianPS/AtlassianPS\.Standards/\.github/workflows/module_release\.yml@[0-9a-f]{40}'
        $script:continuousRelease | Should -Match 'module-name:\s+ConfluencePS'
        $script:continuousRelease | Should -Match 'release-impact:\s+\$\{\{\s*inputs\.release_impact\s*\}\}'
        $script:continuousRelease | Should -Match 'secrets:\s+inherit'
        $script:continuousRelease | Should -Not -Match '(?m)^  (prepare|publish):|Publish-Module|create-github-app-token|actions/download-artifact'
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
    }
}
