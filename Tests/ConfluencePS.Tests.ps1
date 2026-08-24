#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.9.0"; MaximumVersion = "5.9.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "General project validation" -Tag Unit {
    BeforeAll {
        Remove-Module ConfluencePS -ErrorAction SilentlyContinue

        $script:manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue
    }
    AfterEach {
        Remove-Module ConfluencePS -ErrorAction SilentlyContinue
    }

    It "passes Test-ModuleManifest" {
        { Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop } | Should -Not -Throw
    }

    It "module 'ConfluencePS' can import cleanly" {
        { Import-Module $moduleToTest } | Should -Not -Throw
    }

    It "module 'ConfluencePS' exports functions" {
        Import-Module $moduleToTest

        (Get-Command -Module ConfluencePS -CommandType Function | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "module uses the correct root module" {
        $manifest.RootModule | Should -Be 'ConfluencePS.psm1'
    }

    It "module uses the correct guid" {
        $manifest.Guid | Should -Be '20d32089-48ef-464d-ba73-6ada240e26b3'
    }

    It "module uses a valid version" {
        $manifest.Version | Should -Not -BeNullOrEmpty
        [Version]($manifest.Version) | Should -BeOfType [Version]
    }

    It "module is imported with default prefix" {
        $prefix = $manifest.DefaultCommandPrefix

        Import-Module $moduleToTest -Force -ErrorAction Stop
        (Get-Command -Module ConfluencePS -CommandType Function).Name | ForEach-Object {
            $_ | Should -Match "\-$prefix"
        }
    }

    It "module is imported with custom prefix" {
        $prefix = "Wiki"

        Import-Module $moduleToTest -Prefix $prefix -Force -ErrorAction Stop
        (Get-Command -Module ConfluencePS -CommandType Function).Name | ForEach-Object {
            $_ | Should -Match "\-$prefix"
        }
    }
}
