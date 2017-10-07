function ConvertTo-PageAncestor {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Page] )]
    param (
        # object to convert
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    Process {
        foreach ($object in $InputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to Page (Ancestor)"
            ConvertTo-CustomType -InputObject ($object | Select-Object `
                id,
                status,
                title
            ) -as ([ConfluencePS.Page])
        }
    }
}
