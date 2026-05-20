#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.10" }

Describe 'AtlassianPS.Standards version consistency' -Tag Unit {
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

    It 'keeps workflow setup action pins aligned with build.requirements' {
        $projectRoot = Get-RepositoryRoot

        $buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
        $buildRequirements = Import-PowerShellDataFile -Path $buildRequirementsPath
        $standardsRequirement = $buildRequirements |
            Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
            Select-Object -First 1
        $standardsVersion = [string] $standardsRequirement.RequiredVersion

        $workflowPaths = Get-ChildItem -Path (Join-Path -Path $projectRoot -ChildPath '.github/workflows') -File -Filter '*.yml' |
            Select-Object -ExpandProperty FullName

        $workflowActionMatches = foreach ($workflowPath in $workflowPaths) {
            $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
            [regex]::Matches(
                $workflowContent,
                "AtlassianPS/AtlassianPS\.Standards/\.github/actions/setup-powershell@(?<sha>[0-9a-f]{40})\s+#\s+v(?<version>[0-9]+\.[0-9]+\.[0-9]+)"
            ) | ForEach-Object {
                [PSCustomObject]@{
                    WorkflowPath = $workflowPath
                    Sha          = $_.Groups['sha'].Value
                    Version      = $_.Groups['version'].Value
                }
            }
        }

        @($workflowActionMatches).Count | Should -BeGreaterThan 0

        $matchedVersions = @($workflowActionMatches | Select-Object -ExpandProperty Version -Unique)
        $matchedVersions.Count | Should -Be 1
        $matchedVersions[0] | Should -Be $standardsVersion

        @($workflowActionMatches | Select-Object -ExpandProperty Sha -Unique).Count | Should -Be 1
    }

    It 'reads AtlassianPS.Standards version from build.requirements in tool scripts' {
        $projectRoot = Get-RepositoryRoot

        $setupScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tools/setup.ps1') -Raw
        $updateScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tools/update.dependencies.ps1') -Raw

        $setupScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $setupScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $setupScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'

        $updateScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $updateScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $updateScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'
        $updateScriptContent | Should -Match '\$PSCmdlet\.ShouldProcess\('
        $updateScriptContent | Should -Match 'AtlassianPS\.Standards\\Update-AtlassianPSDependencyReference'
    }
}
