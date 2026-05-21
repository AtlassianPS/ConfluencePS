#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-ChildPage" -Tag 'Unit' {
        BeforeAll {
            function New-TestPage {
                param(
                    [UInt64]$ID
                )

                $page = [ConfluencePS.Page]::new()
                $page.ID = $ID
                $page
            }
        }

        It "uses descendant endpoint directly for recursive queries" {
            Mock Invoke-Method -ModuleName ConfluencePS {
                New-TestPage -ID 11
            }

            $null = Get-ChildPage -ApiUri "https://example.com/wiki/rest/api" -PageID 10 -Recurse -Skip 2 -First 3 -IncludeTotalCount

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "https://example.com/wiki/rest/api/content/10/descendant/page" -and
                $Skip -eq 2 -and
                $First -eq 3 -and
                $IncludeTotalCount
            }
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 0 -Scope It -ParameterFilter {
                $Uri -like "https://example.com/wiki/rest/api/content/*/child/page"
            }
        }

        It "falls back to iterative child traversal and applies paging globally when descendant endpoint fails" {
            Mock Invoke-Method -ModuleName ConfluencePS {
                param(
                    [string]$Uri
                )

                switch ($Uri) {
                    "https://example.com/wiki/rest/api/content/10/descendant/page" {
                        throw [System.ArgumentException]::new("Invalid Server Response")
                    }
                    "https://example.com/wiki/rest/api/content/10/child/page" {
                        @((New-TestPage -ID 11), (New-TestPage -ID 12))
                    }
                    "https://example.com/wiki/rest/api/content/11/child/page" {
                        @(New-TestPage -ID 13)
                    }
                    "https://example.com/wiki/rest/api/content/12/child/page" {
                        @()
                    }
                    "https://example.com/wiki/rest/api/content/13/child/page" {
                        @()
                    }
                    default {
                        throw "Unexpected URI: $Uri"
                    }
                }
            }

            $result = @(Get-ChildPage -ApiUri "https://example.com/wiki/rest/api" -PageID 10 -Recurse -Skip 1 -First 2)

            $result.ID | Should -Be @(12, 13)
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "https://example.com/wiki/rest/api/content/10/descendant/page"
            }
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 4 -Scope It -ParameterFilter {
                $Uri -like "https://example.com/wiki/rest/api/content/*/child/page" -and
                (-not $PSBoundParameters.ContainsKey("Skip")) -and
                (-not $PSBoundParameters.ContainsKey("First")) -and
                (-not $PSBoundParameters.ContainsKey("IncludeTotalCount"))
            }
        }

        It "rethrows non-recoverable descendant endpoint errors" {
            Mock Invoke-Method -ModuleName ConfluencePS {
                throw [System.ArgumentException]::new("Not a recoverable error")
            }

            {
                Get-ChildPage -ApiUri "https://example.com/wiki/rest/api" -PageID 10 -Recurse -ErrorAction Stop
            } | Should -Throw "Not a recoverable error"

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "https://example.com/wiki/rest/api/content/10/descendant/page"
            }
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 0 -Scope It -ParameterFilter {
                $Uri -like "https://example.com/wiki/rest/api/content/*/child/page"
            }
        }
    }
}
