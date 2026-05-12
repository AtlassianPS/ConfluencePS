#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.10" }

Describe "Validation of example codes in the documentation" -Tag Documentation, NotImplemented {

    BeforeAll {
        . "$PSScriptRoot/Helpers/TestTools.ps1"
        $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
        $script:isBuild = $PSScriptRoot -like "*$([System.IO.Path]::DirectorySeparatorChar)Release$([System.IO.Path]::DirectorySeparatorChar)*"
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    Assert-True $script:isBuild "Examples can only be tested in the build environment. Please run `Invoke-Build -Task Build`."

    $functions = Get-Command -Module $env:BHProjectName | Get-Help
    foreach ($function in $functions) {
        Context "Examples of $($function.Name)" {


        }
    }
}
