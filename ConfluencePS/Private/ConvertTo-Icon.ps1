function ConvertTo-Icon {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place
    to select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Icon] )]
    param (
        # object to convert
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    Process {
        foreach ($object in $InputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to Icon"
            [ConfluencePS.Icon](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                Path,
                Width,
                Height,
                IsDefault
            ))
        }
    }
}
