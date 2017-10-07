function ConvertTo-Version {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Version] )]
    param (
        # object to convert
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    Process {
        foreach ($object in $InputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to Version"
            ConvertTo-CustomType -InputObject ($object | Select-Object `
                @{Name = "by"; Expression = { ConvertTo-User $_.by }},
                when,
                friendlyWhen,
                number,
                message,
                minoredit
            ) -as ([ConfluencePS.Version])
        }
    }
}
