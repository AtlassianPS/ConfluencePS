#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

param()

Describe 'Public cmdlet unit coverage baseline' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/../../Helpers/TestTools.ps1"

        $projectRoot = Resolve-ProjectRoot
        $script:publicPath = Join-Path $projectRoot 'ConfluencePS/Public'
        $script:baselinePath = Join-Path $PSScriptRoot 'PublicCmdletUnitCoverageBaseline.psd1'
        $script:baseline = Import-PowerShellDataFile -Path $script:baselinePath
        $script:publicCmdlets = Get-ChildItem -Path $script:publicPath -Filter '*.ps1' -File |
            Select-Object -ExpandProperty BaseName |
            Sort-Object
        $script:baselineCmdlets = @($script:baseline.PublicCmdlets.Keys | Sort-Object)
    }

    It 'includes every public cmdlet in the baseline' {
        $script:baselineCmdlets | Should -Be $script:publicCmdlets
    }

    It 'has test files for public cmdlets marked covered' {
        $coveredCmdlets = @(
            foreach ($cmdletName in $script:baselineCmdlets) {
                if ($script:baseline.PublicCmdlets[$cmdletName].Covered) {
                    $cmdletName
                }
            }
        )

        foreach ($cmdletName in $coveredCmdlets) {
            Join-Path $PSScriptRoot "$cmdletName.Unit.Tests.ps1" | Should -Exist
        }
    }
}
