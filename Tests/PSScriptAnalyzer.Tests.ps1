#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }
#requires -modules PSScriptAnalyzer

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    $script:analysisPath = Split-Path $moduleToTest -Parent
    $analysisRoot = Split-Path $analysisPath -Parent
    $script:settingsPath = Join-Path $analysisRoot 'PSScriptAnalyzerSettings.psd1'

    $script:scripts = Get-ChildItem $analysisPath -Include *.ps1, *.psm1 -Recurse
}

Describe "PSScriptAnalyzer Tests" -Tag Unit {
    BeforeAll {
        $params = @{
            Path          = $analysisPath
            Settings      = $settingsPath
            Severity      = @('Error', 'Warning')
            Recurse       = $true
            Verbose       = $false
            ErrorVariable = 'ErrorVariable'
            ErrorAction   = 'SilentlyContinue'
        }
        $script:scriptWarnings = Invoke-ScriptAnalyzer @params
        $script:analyzerErrors = $ErrorVariable
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    }

    Context "<_>" -ForEach $scripts {
        BeforeAll {
            $script:file = $_
            $script:relPath = $file.FullName.Replace($analysisPath, '') -replace '^\\', ''

            $script:rules = $scriptWarnings |
                Where-Object { $_.ScriptPath -like $file.FullName } |
                Select-Object -ExpandProperty RuleName -Unique

            $script:exceptions = $null
            if ($analyzerErrors) {
                $script:exceptions = $analyzerErrors.Exception.Message |
                    Where-Object { $_ -match [regex]::Escape($file.FullName) }
            }
        }

        It "reports rule compliance for $relPath" {
            foreach ($rule in $rules) {
                $badLines = $scriptWarnings |
                    Where-Object { $_.ScriptPath -like $file.FullName -and $_.RuleName -like $rule } |
                    Select-Object -ExpandProperty Line
                $badLines | Should -Be $null
            }
        }

        It "has no parse errors for $relPath" {
            foreach ($exception in $exceptions) {
                $exception | Should -BeNullOrEmpty
            }
        }
    }
}
