Describe 'ConvertTo-Table' -Tag 'unit' {
    Remove-Module ConfluencePS -Force
    Import-Module $PSScriptRoot\..\ConfluencePS\ConfluencePS.psd1

    Context 'Example 1' {
        $return = Get-Service | Select Name,DisplayName,Status -First 10 | ConvertTo-ConfluenceTable
        $array = $return -split [Environment]::NewLine

        It 'Out-String is called at the end of the function' {
            $return.Count | Should -Be 1
        }

        It 'Returns the correct number of rows' {
            $array.Count | Should -Be 12
        }

        It 'Returns a header row first' {
            $array[0] | Should -BeExactly '||Name||DisplayName||Status||'
        }

        It 'Wraps other rows with table formatting' {
            $array[1..10] | ForEach-Object {
                $_ | Should -Match '^\|.*?\|.*?\|Running|Stopped\|'
            }
        }

        It 'Returns an empty row at the end' {
            $array[11] | Should -BeNullOrEmpty
        }
    }

    # Not much for Example 2 to check

    Context 'Example 3' {
        $return = Get-Alias | Where {$_.Name.Length -eq 1} | Select CommandType,DisplayName | ConvertTo-ConfluenceTable -NoHeader
        $array = $return -split [Environment]::NewLine

        It 'Does not return a header row' {
            $array[0] | Should -Not -Match '\|\|'
        }
    }
}
