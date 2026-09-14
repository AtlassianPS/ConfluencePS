#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    Import-Module $moduleToTest -Global -Force -ErrorAction Stop
    $modulePrefix = (Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue).Prefix
    $modulePath = Split-Path -Path $moduleToTest -Parent
    $publicFunctionsPath = Join-Path -Path $modulePath -ChildPath "Public"
    $publicFunctions = if (Test-Path -Path $publicFunctionsPath) {
        (Get-ChildItem "$publicFunctionsPath/*.ps1").BaseName
    }
    else {
        (Import-PowerShellDataFile -Path $moduleToTest).FunctionsToExport
    }
    $publicCommandNames = $publicFunctions |
        ForEach-Object { $_ -replace '\-', "-$modulePrefix" }
    $script:commands = Get-Command -Module ConfluencePS -CommandType Cmdlet, Function |
        Where-Object { $_.Name -in $publicCommandNames }
}

Describe "Validation of example codes in the documentation" -Tag Documentation, NotImplemented {
    Describe "Examples" {
        Describe "Examples for <_.Name>" -ForEach $commands {
            BeforeAll {
                $script:command = $_
                $script:help = Get-Help $command
            }

            # TODO:
            It "should have examples implemented as tests" -Skip {
                $true | Should -Be $true
            }
        }
    }
}
