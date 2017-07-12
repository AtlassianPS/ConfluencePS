# Test .psd1, .psm1, general module structure, and function availability

Get-Module ConfluencePS | Remove-Module -Force
Import-Module "$PSScriptRoot\..\ConfluencePS" -Force

Describe 'Check module files for breaking changes' {
    $ModuleRoot = "$PSScriptRoot\..\ConfluencePS"
    $PublicFiles = (Get-ChildItem "$ModuleRoot\Public").BaseName
    $ExportedFunctions = $PublicFiles | ForEach-Object {$_ -replace "\-(\w)", "-Confluence`$1"}

    It 'Contains expected helper files and directories' {
        "$ModuleRoot\en-US\about_ConfluencePS.help.txt" | Should Exist
        "$ModuleRoot\Public" | Should Exist
        "$ModuleRoot\..\appveyor.yml" | Should Exist
        "$ModuleRoot\..\LICENSE" | Should Exist
        "$ModuleRoot\..\README.md" | Should Exist
    }

    Context 'Verify .psd1 module file' {
        It 'Has a valid .psd1 module manifest' {
            {Test-ModuleManifest -Path "$ModuleRoot\ConfluencePS.psd1" -ErrorAction Stop -WarningAction SilentlyContinue} | Should Not Throw
        }

        $manifest = Test-ModuleManifest -Path "$ModuleRoot\ConfluencePS.psd1" -ErrorAction Stop

        It 'Static .psd1 values have not changed' {
            $manifest.RootModule | Should BeExactly 'ConfluencePS.psm1'
            $manifest.Name | Should BeExactly 'ConfluencePS'
            $manifest.Version -as [Version] | Should BeGreaterThan '0.9.9'
            $manifest.Guid | Should BeExactly '20d32089-48ef-464d-ba73-6ada240e26b3'
            $manifest.Author | Should BeExactly 'Brian Bunke'
            $manifest.CompanyName | Should BeExactly 'Community'
            $manifest.Copyright | Should BeExactly 'MIT License'
            $manifest.Description | Should BeOfType String
            $manifest.PowerShellVersion | Should Be '3.0'
            $manifest.ExportedFunctions.Values.Name | Should BeExactly $ExportedFunctions

            $manifest.PrivateData.PSData.Tags | Should BeExactly @('confluence','wiki','atlassian')
            $manifest.PrivateData.PSData.LicenseUri | Should BeExactly 'https://github.com/brianbunke/ConfluencePS/blob/master/LICENSE'
            $manifest.PrivateData.PSData.ProjectUri | Should BeExactly 'https://github.com/brianbunke/ConfluencePS'
        }

        It 'Exports all functions within the Public folder' {
            (Get-Command -Module ConfluencePS).Name | Should BeExactly $ExportedFunctions
        }
    }

    <#
    # InModuleScope helps test private functions
    InModuleScope ConfluencePS {
        # Run unit tests for all private functions here
        # Instead of breaking out into individual files like the public functions
        Context 'Contains expected private functions' {
            It 'Private-Function behaves normally' {
            }

            # (Any additional private functions as It tests here)
        } #Context private
    } #InModuleScope
    #>
} #Describe
