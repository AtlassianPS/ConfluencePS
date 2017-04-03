function Add-GetParameter {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [hashtable]$InputObject
    )

    begin {
        [string]$parameters = "?"
    }

    process {
        foreach ($key in $InputObject.Keys) {
            $parameters += "$key=$($InputObject[$key])&"
        }
    }

    end {
        $parameters -replace ".$"
    }
}
