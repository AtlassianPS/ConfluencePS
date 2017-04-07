function ConvertTo-WikiSpace {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Space] )]
    param (
        # object to convert
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        $inputObject
    )

    Process {
        foreach ($object in $inputObject) {
            ($object | Select-Object `
                id,
                key,
                name,
                @{Name = "description"; Expression = {$_.description.plain.value}},
                icon,
                type,
                @{Name = "Homepage"; Expression = {
                    if ($_.homepage -is [PSCustomObject]) {
                            $_.homepage | ConvertTo-WikiPage
                    } else {$null} # homepage might be a string
                }}
            ) -as [ConfluencePS.Space]
        }
    }
}
