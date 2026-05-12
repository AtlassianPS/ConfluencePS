#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.10" }

Describe "General project validation" -Tag Unit {

    BeforeAll {
        . "$PSScriptRoot/Helpers/TestTools.ps1"
        $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    It "passes Test-ModuleManifest" {
        { Test-ModuleManifest -Path $env:BHManifestToTest -ErrorAction Stop } | Should -Not -Throw
    }

    It "module '$env:BHProjectName' can import cleanly" {
        { Import-Module $env:BHManifestToTest } | Should Not Throw
    }

    It "module '$env:BHProjectName' exports functions" {
        Import-Module $env:BHManifestToTest

        (Get-Command -Module $env:BHProjectName | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "module uses the correct root module" {
        Get-Metadata -Path $env:BHManifestToTest -PropertyName RootModule | Should -Be 'ConfluencePS.psm1'
    }

    It "module uses the correct guid" {
        Get-Metadata -Path $env:BHManifestToTest -PropertyName Guid | Should -Be '20d32089-48ef-464d-ba73-6ada240e26b3'
    }

    It "module uses a valid version" {
        [Version](Get-Metadata -Path $env:BHManifestToTest -PropertyName ModuleVersion) | Should -Not -BeNullOrEmpty
        [Version](Get-Metadata -Path $env:BHManifestToTest -PropertyName ModuleVersion) | Should -BeOfType [Version]
    }

    It "module is imported with default prefix" {
        $prefix = Get-Metadata -Path $env:BHManifestToTest -PropertyName DefaultCommandPrefix

        Import-Module $env:BHManifestToTest -Force -ErrorAction Stop
        (Get-Command -Module $env:BHProjectName).Name | ForEach-Object {
            $_ | Should -Match "\-$prefix"
        }
    }

    It "module is imported with custom prefix" {
        $prefix = "Wiki"

        Import-Module $env:BHManifestToTest -Prefix $prefix -Force -ErrorAction Stop
        (Get-Command -Module $env:BHProjectName).Name | ForEach-Object {
            $_ | Should -Match "\-$prefix"
        }
    }
}
