#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Validation of build environment" -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/Helpers/TestTools.ps1"

        $script:moduleToTest = Initialize-TestEnvironment
        $script:moduleRoot = Resolve-ProjectRoot
    }

    Context "Compiled module" {
        It "has a UTF-8 BOM on the compiled .psm1" {
            $modulePath = Split-Path $moduleToTest -Parent
            $psm1Path = Join-Path $modulePath "$((Get-Item $modulePath).Name).psm1"
            $bytes = [System.IO.File]::ReadAllBytes($psm1Path)
            $bytes.Count | Should -BeGreaterThan 3
            $bytes[0] | Should -Be 0xEF
            $bytes[1] | Should -Be 0xBB
            $bytes[2] | Should -Be 0xBF
        }
    }

    Context "CHANGELOG" {
        BeforeAll {
            $changelogFile = "$moduleRoot/CHANGELOG.md"

            if (-not (Test-Path $changelogFile)) {
                throw "CHANGELOG.md file not found in the module root directory."
            }

            $script:changelogVersion = $null
            foreach ($line in (Get-Content $changelogFile)) {
                if ($line -match "(?:##|\<h2.*?\>)\s*\[?(?<Version>\d+(?:\.\d+){1,2})\]?(\-(?<Prerelease>(?:alpha|beta|rc)\d*))?") {
                    $changelogVersion = $matches.Version
                    break
                }
            }
        }

        It "has a changelog file" {
            $changelogFile | Should -Exist
        }

        It "has a valid version in the changelog" {
            $changelogVersion             | Should -Not -BeNullOrEmpty
            [Version]($changelogVersion)  | Should -BeOfType [Version]
        }

        It "has a version changelog that matches the manifest version" {
            Metadata\Get-Metadata -Path $moduleToTest -PropertyName ModuleVersion | Should -BeLike "$changelogVersion*"
        }
    }
}
