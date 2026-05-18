#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:moduleRoot = Resolve-ProjectRoot

    Import-Module $moduleToTest -Force -ErrorAction Stop
}

Describe "General project validation" -Tag Unit {
    BeforeDiscovery {
        $script:module = Get-Module 'ConfluencePS'

        $script:publicFunctionFiles = (Get-ChildItem "$moduleRoot/ConfluencePS/Public/*.ps1").BaseName
        $script:privateFunctionFiles = (Get-ChildItem "$moduleRoot/ConfluencePS/Private/*.ps1").BaseName
        $script:expectedPublicExportNames = @($publicFunctionFiles | ForEach-Object { $_ -replace "\-", "-$($module.Prefix)" })

        # Source manifests use wildcard exports. Trust the module's actual resolved
        # exports from import-time instead of static manifest metadata.
        $script:exportedFunctionNames = @($script:module.ExportedFunctions.Keys)
    }

    Describe "Public functions" {
        Context "Function <_>" -ForEach $publicFunctionFiles {
            BeforeAll {
                $script:functionName = $_
                $script:expectedExportName = $functionName -replace "\-", "-$($module.Prefix)"
            }

            It "is exported" {
                $exportedFunctionNames | Should -Contain $expectedExportName
            }
        }
    }

    Describe "Private functions" {
        It "has private functions" {
            $privateFunctionFiles.Count | Should -BeGreaterThan 0
        }

        Context "Function <_>" -ForEach $privateFunctionFiles {
            BeforeAll {
                $script:functionName = $_
            }

            It "is loaded in the module" {
                $commandInModule = $module.Invoke({
                        param($name)
                        Get-Command -Name $name -CommandType Function -ErrorAction SilentlyContinue |
                            Where-Object { $_.ModuleName -eq 'ConfluencePS' }
                    }, $functionName)

                $commandInModule | Should -Not -BeNullOrEmpty -Because "private function '$functionName' should be loaded"
            }

            It "is not exported" {
                $exportedFunctionNames | Should -Not -Contain $functionName
            }
        }
    }

    Describe "Project stucture" {
        It "only exports functions from the Public folder" {
            foreach ($exportedFunctionName in $exportedFunctionNames) {
                $expectedPublicExportNames | Should -Contain $exportedFunctionName -Because "exported function '$exportedFunctionName' should have a corresponding file in ConfluencePS/Public/"
            }
        }
    }
}
