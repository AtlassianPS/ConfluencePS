#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:projectRoot = Resolve-ProjectRoot
    $script:modulePrefix = (Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue).DefaultCommandPrefix
}

Describe "Help tests" -Tag "Documentation", "Build" {
    BeforeAll {
        Import-Module $moduleToTest -Force -ErrorAction Stop
    }

    BeforeDiscovery {
        ${/} = [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)

        $script:isRunningInReleaseFolder = $moduleToTest -match "${/}Release${/}"
        if (-not $isRunningInReleaseFolder) {
            Write-Warning "Tests are being run outside of the 'Release' folder. Some tests may be skipped."
        }

        $script:publicFunctions = (Get-ChildItem "$projectRoot/ConfluencePS/Public/*.ps1").BaseName

        $commandToDocNameMap = @{}
        foreach ($functionName in $publicFunctions) {
            $exportedName = $functionName -replace "\-", "-$modulePrefix"
            $commandToDocNameMap[$exportedName] = $functionName
        }

        Import-Module $moduleToTest -Force -ErrorAction Stop
        $script:commands = Get-Command -Module ConfluencePS -CommandType Cmdlet, Function |
            Where-Object { $_.Name -in $commandToDocNameMap.Keys } |
            ForEach-Object {
                @{
                    Command     = $_
                    CommandName = $_.Name
                    DocName     = $commandToDocNameMap[$_.Name]
                }
            }

        $script:defaultParams = @(
            'Verbose'
            'Debug'
            'ErrorAction'
            'WarningAction'
            'InformationAction'
            'ErrorVariable'
            'WarningVariable'
            'InformationVariable'
            'OutVariable'
            'OutBuffer'
            'PipelineVariable'
            'ProgressAction'
            'WhatIf'
            'Confirm'
        )
    }

    Describe "Public Functions" {
        Context "Command <_.CommandName>" -ForEach $commands {
            BeforeDiscovery {
                if ($isRunningInReleaseFolder) {
                    $cmd = $_.Command
                    $isDontShow = {
                        param($name)
                        $paramAttr = $cmd.Parameters[$name].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
                        return ($paramAttr.DontShow -contains $true)
                    }
                    $script:parameters = $cmd.Parameters.Keys | Where-Object { $_ -notin $defaultParams -and -not (& $isDontShow $_) }
                }
                else {
                    $script:parameters = @()
                }
            }
            BeforeAll {
                $script:command = $_.Command
                $script:docName = $_.DocName
                $script:help = if ($isRunningInReleaseFolder) { Get-Help $command.Name -ErrorAction Stop }
            }

            Context "Markdown file for <_.CommandName>" {
                BeforeAll {
                    $script:markdownFile = Resolve-Path "$projectRoot/docs/en-US/commands/$docName.md" -ErrorAction Stop
                }

                It "is described in a markdown file" {
                    $markdownFile | Should -Not -BeNullOrEmpty
                    Test-Path $markdownFile | Should -Be $true
                }

                It "does not have Comment-Based Help" {
                    $command.Definition | Should -Not -BeNullOrEmpty
                    $pattern = [regex]::Escape(".EXAMPLE")

                    $command.Definition | Should -Not -Match "^\s*$pattern"
                }

                It "has no platyPS template artifacts" {
                    $markdownFile | Should -Not -BeNullOrEmpty
                    $markdownFile | Should -Not -FileContentMatch '\{\{.*?\}\}'
                }

                It "has a valid online version" {
                    $pattern = [regex]::Escape("https://atlassianps.org/docs/ConfluencePS/commands/$docName/")

                    $markdownFile | Should -FileContentMatch $pattern
                }

                It "defines the frontmatter for the homepage" {
                    $markdownFile | Should -Not -BeNullOrEmpty
                    $markdownFile | Should -FileContentMatch "Module Name: ConfluencePS"
                    $markdownFile | Should -FileContentMatchExactly "layout: documentation"
                    $markdownFile | Should -FileContentMatch "permalink: /docs/ConfluencePS/commands/$docName/"
                }
            }

            Context "Help for <_.CommandName>" -Skip:(-not $isRunningInReleaseFolder) {
                It "has a synopsis" {
                    $help.Synopsis | Should -Not -BeNullOrEmpty
                }

                It "has a syntax" {
                    $help.syntax | Should -Not -BeNullOrEmpty
                }

                It "has a description" {
                    $help.Description.Text -join '' | Should -Not -BeNullOrEmpty
                }

                It "has examples" {
                    ($help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
                }

                It "has desciptions for all examples" {
                    foreach ($example in ($help.Examples.Example)) {
                        $example.remarks.Text | Should -Not -BeNullOrEmpty
                    }
                }

                It "has at least as many examples as ParameterSets" {
                    ($help.Examples.Example | Measure-Object).Count | Should -BeGreaterOrEqual $command.ParameterSets.Count
                }

                It "has a link to the 'Online Version'" {
                    [Uri]$onlineLink = ($help.relatedLinks.navigationLink | Where-Object { $_.linkText -match "^Online Version:?$" }).Uri

                    $onlineLink.Authority | Should -Be "atlassianps.org"
                    $onlineLink.Scheme | Should -Be "https"
                    $onlineLink.PathAndQuery | Should -Be "/docs/ConfluencePS/commands/$docName/"
                }

                It "has a valid HelpUri" -Skip {
                    $command.HelpUri | Should -Not -BeNullOrEmpty
                    $pattern = [regex]::Escape("https://atlassianps.org/docs/ConfluencePS/commands/$docName")

                    $command.HelpUri | Should -Match $pattern
                }
            }

            Context "Parameter for <_.CommandName>" -Skip:(-not $isRunningInReleaseFolder) {
                Context "Parameter: <_>" -ForEach $parameters {
                    BeforeAll {
                        $script:parameterName = $_
                        $script:parameterCode = $command.Parameters[$parameterName]
                        $script:parameterHelp = $help.Parameters.Parameter | Where-Object Name -eq $parameterName
                    }

                    It "has a description" {
                        $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
                    }

                    It "has a mandatory flag" {
                        $isMandatory = $parameterCode.ParameterSets.Values.IsMandatory -contains "True"

                        $command | Should -HaveParameter $parameterName -Mandatory:$isMandatory
                        $parameterHelp.Required | Should -BeLike $isMandatory.ToString()
                    }

                    It "matches the type of the parameter in code and help" {
                        $codeType = $parameterCode.ParameterType.Name
                        if ($codeType -eq "Object" -or $codeType -eq "Object[]") {
                            $psTypeAttr = $parameterCode.Attributes | Where-Object { $_ -is [System.Management.Automation.PSTypeNameAttribute] } | Select-Object -First 1
                            if ($psTypeAttr) {
                                $codeType = $psTypeAttr.PSTypeName
                                if ($parameterCode.ParameterType.IsArray -and $codeType -notmatch '\[\]$') {
                                    $codeType += '[]'
                                }
                            }
                        }
                        $helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
                        if ($helpType -eq "PSCustomObject") { $helpType = "PSObject" }
                        if ($helpType -eq "Switch") { $helpType = "SwitchParameter" }

                        $helpType | Should -Be $codeType
                    }
                }

                It "does not have parameters that are not in the code" {
                    $parameter = @()
                    if ($help.Parameters | Get-Member -Name Parameter) {
                        $parameter = $help.Parameters.Parameter.Name | Sort-Object -Unique
                    }

                    foreach ($helpParm in $parameter) {
                        $command.Parameters.Keys | Should -Contain $helpParm
                    }
                }

                It "documents every public parameter exposed by the code" {
                    $documented = @()
                    if ($help.Parameters | Get-Member -Name Parameter) {
                        $documented = @($help.Parameters.Parameter.Name)
                    }

                    foreach ($paramName in $command.Parameters.Keys) {
                        if ($paramName -in $defaultParams) { continue }
                        $paramAttr = $command.Parameters[$paramName].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
                        if ($paramAttr.DontShow -contains $true) { continue }

                        $documented | Should -Contain $paramName -Because "every public parameter must be documented in docs/en-US/commands/$docName.md (or marked [Parameter(DontShow)] if it is internal)"
                    }
                }
            }
        }
    }
}
