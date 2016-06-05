function ConvertTo-WikiTable {
    <#
    .SYNOPSIS
    Convert your content to Confluence's wiki markup table format.

    .DESCRIPTION
    Formats input as a table with a horizontal header row.
    This wiki formatting is an intermediate step, and would still need ConvertTo-WikiStorageFormat called against it.
    This work is performed locally, and does not perform a REST call.

    .NOTES
    Basically stolen verbatim from thomykay's PoshConfluence SOAP API module. See link below.

    .PARAMETER Content
    Object array you would like to see displayed as a table on a wiki page.

    .PARAMETER NoHeader
    Ignore the property names, and just have a table of values with no header row highlighting.

    .EXAMPLE
    $Services = Get-Service | Select Name,DisplayName,Status -First 10 | ConvertTo-WikiTable
    List the first ten services on your computer, convert to a Confluence table, and store in $Services for future use.

    .EXAMPLE
    Get-Alias | Where {$_.Name.Length -eq 1} | Select CommandType,DisplayName | ConvertTo-WikiTable -NoHeader
    Make a table of all the one-character PowerShell aliases, and don't include the header row.

    .LINK
    https://github.com/brianbunke/ConfluencePS

    .LINK
    https://github.com/thomykay/PoshConfluence
    #>
    [CmdletBinding()]
    param (
		[Parameter(Mandatory=$true, ValueFromPipeline = $true)]
		$Content,

        [switch]$NoHeader
    )

    BEGIN {
    }

    PROCESS {
        If ($NoHeader) {
            $HeaderGenerated = $true
        }

        # This ForEach needed if the content wasn't piped in
        $Content | ForEach-Object {
            # First row enclosed by ||, all other rows by |
            If (!$HeaderGenerated) {
		        $_.PSObject.Properties | ForEach-Object -Begin {$Header = ""} -Process {$Header += "||$($_.Name)"} -End {$Header += "||"}
                $Header
                $HeaderGenerated = $true
            }
		    $_.PSObject.Properties | ForEach-Object -Begin {$Row = ""} -Process {$Row += "|$($_.Value)"} -End {$Row += "|"}
            $Row
        }
    }
}
