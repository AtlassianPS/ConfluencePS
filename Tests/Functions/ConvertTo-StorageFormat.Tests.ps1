#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "ConvertTo-StorageFormat" -Tag 'Unit' {
        BeforeEach {
            $script:lastRequestBody = $null
            Mock Invoke-Method -ModuleName ConfluencePS {
                param(
                    [string]$Body
                )

                $script:lastRequestBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                [PSCustomObject]@{ value = '<p>converted</p>' }
            }
        }

        It "has an AsPlainText switch parameter" {
            $command = Get-Command -Name ConvertTo-StorageFormat

            $command.Parameters.ContainsKey("AsPlainText") | Should -BeTrue
            $command.Parameters["AsPlainText"].ParameterType | Should -Be ([switch])
        }

        It "passes wiki content through unchanged by default" {
            $result = ConvertTo-StorageFormat -ApiUri "https://example.com/wiki/rest/api" -Content '# @ [{]}'

            $result | Should -Be '<p>converted</p>'
            $script:lastRequestBody.value | Should -Be '# @ [{]}'
            $script:lastRequestBody.representation | Should -Be 'wiki'
        }

        It "entity-encodes wiki markup before wiki-to-storage conversion" {
            $null = ConvertTo-StorageFormat -ApiUri "https://example.com/wiki/rest/api" -Content 'h1. *bold* _italic_ !image.png! ||cell|| # @ [{]} <script>' -AsPlainText

            $script:lastRequestBody.value | Should -Be 'h1&#46; &#42;bold&#42; &#95;italic&#95; &#33;image&#46;png&#33; &#124;&#124;cell&#124;&#124; &#35; &#64; &#91;&#123;&#93;&#125; &#60;script&#62;'
            $script:lastRequestBody.representation | Should -Be 'wiki'
        }
    }
}
