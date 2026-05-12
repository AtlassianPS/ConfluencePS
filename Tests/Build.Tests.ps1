#requires -modules Metadata
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.10" }

Describe "Validation of build environment" -Tag Unit {

    BeforeAll {
        . "$PSScriptRoot/Helpers/TestTools.ps1"
        $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
        $script:isBuild = $PSScriptRoot -like "*$([System.IO.Path]::DirectorySeparatorChar)Release$([System.IO.Path]::DirectorySeparatorChar)*"
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    $changelogFile = if ($script:isBuild) {
        "$env:BHBuildOutput/$env:BHProjectName/CHANGELOG.md"
    }
    else {
        "$env:BHProjectPath/CHANGELOG.md"
    }

    Context "CHANGELOG" {

        foreach ($line in (Get-Content $changelogFile)) {
            if ($line -match "(?:##|\<h2.*?\>)\s*\[(?<Version>(\d+\.?){1,2})\]") {
                $changelogVersion = $matches.Version
                break
            }
        }

        It "has a changelog file" {
            $changelogFile | Should -Exist
        }

        It "has a valid version in the changelog" {
            $changelogVersion            | Should -Not -BeNullOrEmpty
            [Version]($changelogVersion)  | Should -BeOfType [Version]
        }

        It "has a version changelog that matches the manifest version" {
            (Metadata\Import-Metadata -Path $env:BHManifestToTest).ModuleVersion | Should -BeLike "$changelogVersion*"
        }
    }
}
