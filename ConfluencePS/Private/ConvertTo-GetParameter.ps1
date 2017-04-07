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
        foreach ($key in $InputObject.Keys) {
            $parameters += "$key=$($InputObject[$key])&"
        }
    }

    END {
        $parameters -replace ".$"
    }
}
