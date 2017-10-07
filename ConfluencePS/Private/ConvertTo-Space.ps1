function ConvertTo-Space {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Space] )]
    param (
        # object to convert
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    Process {
        foreach ($object in $InputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to Space"
            ConvertTo-CustomType -InputObject ($object | Select-Object `
                id,
                key,
                name,
                @{Name = "description"; Expression = {$_.description.plain.value}},
                icon,
                type,
                @{Name = "Homepage"; Expression = {
                    if ($_.homepage -is [PSCustomObject]) {
                            ConvertTo-Page $_.homepage
                    } else {$null} # homepage might be a string
                }}
            ) -as ([ConfluencePS.Space])
        }
    }
}
