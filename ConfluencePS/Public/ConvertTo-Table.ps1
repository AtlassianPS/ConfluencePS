function ConvertTo-Table {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
    param (
        # Object array you would like to see displayed as a table on a wiki page.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        $Content,

        # Ignore the property names, and just have a table of values with no header row highlighting.
        [switch]$NoHeader
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RowArray = New-Object System.Collections.ArrayList
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        If ($NoHeader) {
            $HeaderGenerated = $true
        }

        # This ForEach needed if the content wasn't piped in
        $Content | ForEach-Object {
            # First row enclosed by ||, all other rows by |
            If (!$HeaderGenerated) {
                $_.PSObject.Properties |
                    ForEach-Object -Begin {$Header = ""} `
                    -Process {$Header += "||$($_.Name)"} `
                    -End {$Header += "||"}
                $RowArray.Add($Header) | Out-Null
                $HeaderGenerated = $true
            }
            $_.PSObject.Properties |
                ForEach-Object -Begin {$Row = ""} `
                -Process {$Row += "|$($_.Value)"} `
                -End {$Row += "|"}
            $RowArray.Add($Row) | Out-Null
        }
    }

    END {
        $RowArray | Out-String

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ened"
    }
}
