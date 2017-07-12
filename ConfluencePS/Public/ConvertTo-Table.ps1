function ConvertTo-Table {
    <#
    .SYNOPSIS
    Convert your content to Confluence's wiki markup table format.

    .DESCRIPTION
    Formats input as a table with a horizontal header row.
    This wiki formatting is an intermediate step, and would still need ConvertTo-ConfluenceStorageFormat called against it.
    This work is performed locally, and does not perform a REST call.

    .NOTES
    Basically stolen verbatim from thomykay's PoshConfluence SOAP API module. See link below.

    .EXAMPLE
    Get-Service | Select Name,DisplayName,Status -First 10 | ConvertTo-ConfluenceTable
    List the first ten services on your computer, and convert to a table in Confluence markup format.

    .EXAMPLE
    $SvcTable = Get-Service | Select Name,Status -First 10 | ConvertTo-ConfluenceTable | ConvertTo-ConfluenceStorageFormat
    Following Example 1, convert the table from wiki markup format into storage format.
    Store the results in variable $SvcTable for a later New-ConfluencePage/Set-ConfluencePage command.

    .EXAMPLE
    Get-Alias | Where {$_.Name.Length -eq 1} | Select CommandType,DisplayName | ConvertTo-ConfluenceTable -NoHeader
    Make a table of all the one-character PowerShell aliases, and don't include the header row.

    .OUTPUTS
    System.String

    .LINK
    https://github.com/brianbunke/ConfluencePS

    .LINK
    https://github.com/thomykay/PoshConfluence
    #>
    [CmdletBinding()]
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
