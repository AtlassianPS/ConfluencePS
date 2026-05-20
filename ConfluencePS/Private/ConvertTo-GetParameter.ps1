function ConvertTo-GetParameter {
    <#
    .SYNOPSIS
    Generate the GET parameter string for an URL from a hashtable
    #>
    [CmdletBinding()]
    param (
        [Parameter( Position = 0, Mandatory = $true, ValueFromPipeline = $true )]
        [hashtable]$InputObject
    )

    BEGIN {
        [string]$parameters = "?"
    }

    PROCESS {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Making HTTP get parameter string out of a hashtable"
        foreach ($key in $InputObject.Keys) {
            $encodedKey = ConvertTo-URLEncoded -InputString ([string]$key)
            $encodedValue = if ($null -eq $InputObject[$key]) {
                ""
            }
            else {
                ConvertTo-URLEncoded -InputString ([string]$InputObject[$key])
            }

            $parameters += "$encodedKey=$encodedValue&"
        }
    }

    END {
        $parameters -replace ".$"
    }
}
