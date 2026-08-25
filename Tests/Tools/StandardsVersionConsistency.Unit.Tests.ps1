#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

Describe 'AtlassianPS.Standards version consistency' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/TestTools.ps1"
        $script:projectRoot = Resolve-ProjectRoot
        $script:standardsActionSha = '8a75c583308d27526f29d7aaef1d1ba67c059103'

        $requirements = Import-PowerShellDataFile -Path (Join-Path $script:projectRoot 'Tools/build.requirements.psd1')
        $standardsRequirement = $requirements |
            Where-Object ModuleName -EQ 'AtlassianPS.Standards' |
            Select-Object -First 1
        $script:standardsVersion = [string]$standardsRequirement.RequiredVersion
    }

    It 'pins every Standards workflow dependency to the released build dependency' {
        $workflowRoot = Join-Path $script:projectRoot '.github/workflows'
        $matches = foreach ($workflow in Get-ChildItem $workflowRoot -Filter '*.yml') {
            $content = Get-Content -LiteralPath $workflow.FullName -Raw
            [regex]::Matches(
                $content,
                'AtlassianPS/AtlassianPS\.Standards/\.github/(?:actions/[^\s@]+|workflows/module_release\.yml)@(?<sha>[0-9a-f]{40})\s+#\s+v(?<version>\d+\.\d+\.\d+)'
            )
        }

        @($matches).Count | Should -BeGreaterThan 0
        @($matches | ForEach-Object { $_.Groups['sha'].Value } | Select-Object -Unique) |
            Should -Be @($script:standardsActionSha)
        @($matches | ForEach-Object { $_.Groups['version'].Value } | Select-Object -Unique) |
            Should -Be @($script:standardsVersion)
    }

    It 'reads the Standards version from build.requirements in build and dependency tools' {
        $setupScript = Get-Content (Join-Path $script:projectRoot 'Tools/setup.ps1') -Raw
        $updateScript = Get-Content (Join-Path $script:projectRoot 'Tools/update.dependencies.ps1') -Raw
        $buildScript = Get-Content (Join-Path $script:projectRoot 'ConfluencePS.build.ps1') -Raw

        $setupScript | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $setupScript | Should -Match '-RequiredVersion\s+\$standardsVersion'
        $updateScript | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $updateScript | Should -Match 'AtlassianPS\.Standards\\Update-AtlassianPSDependencyReference'
        $buildScript | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $buildScript | Should -Match '-RequiredVersion\s+\$standardsRequirement\.RequiredVersion'
    }
}
