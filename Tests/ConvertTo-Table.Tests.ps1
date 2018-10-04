Describe 'ConvertTo-Table' -Tag 'unit' {
    Remove-Module ConfluencePS -Force
    Import-Module $PSScriptRoot\..\ConfluencePS\ConfluencePS.psd1

    Context 'Example 1' {
        $return = Get-Service | Select-Object Name,DisplayName,Status -First 10 | ConvertTo-ConfluenceTable
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
                $_ | Should -Not -Match '\|\|'
            }
        }

        It 'Returns an empty row at the end' {
            $array[11] | Should -BeNullOrEmpty
        }
    }

    # Not much for Example 2 to check

    Context 'Example 3' {
        $return = Get-Alias | Where-Object {$_.Name.Length -eq 1} | Select-Object CommandType,DisplayName | ConvertTo-ConfluenceTable -NoHeader
        $array = $return -split [Environment]::NewLine

        It 'Does not return a header row' {
            $array[0] | Should -Not -Match '\|\|'
        }
    }

    Context 'Example 4' {
        $return = [PSCustomObject]@{Name = 'Max'; Age = 123} | ConvertTo-ConfluenceTable -Vertical
        $array = $return -split [Environment]::NewLine

        It 'Out-String is called at the end of the function' {
            $return.Count | Should -Be 1
        }

        It 'Returns the correct number of rows' {
            $array.Count | Should -Be 3
        }

        It 'Returns a vertical table with a header column' {
            $array[0] | Should -BeExactly '||Name||Max|'
            $array[1] | Should -BeExactly '||Age||123|'
        }

        It 'Returns an empty row at the end' {
            $array[2] | Should -BeNullOrEmpty
        }
    }

    Context 'Example 5' {
        $return = Get-Alias | Where-Object {$_.Name.Length -eq 1} | Select-Object Name,Definition |
            ConvertTo-ConfluenceTable -Vertical -NoHeader
        $array = $return -split [Environment]::NewLine

        It 'Returns the correct number of rows' {
            # This assumes Get-Alias finds 4 one-character aliases
            $array.Count | Should -Be 12
        }

        It 'Returns a vertical table with no header column' {
            $array[0] | Should -BeExactly '|Name|%|'
            $array[1] | Should -BeExactly '|Definition|ForEach-Object|'
        }

        It 'Spaces objects into multiple vertical tables' {
            # We expect four two-line tables
            # So rows 3, 6, 9, and 12 should be empty
            $array[2,5,8,11] | ForEach-Object {$_ | Should -BeNullOrEmpty}
        }
    }
}
