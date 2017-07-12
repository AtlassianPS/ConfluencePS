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
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        $inputObject
    )

    Process {
        foreach ($object in $inputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to Icon"
            ($object | Select-Object `
                Path,
                Width,
                Height,
                IsDefault
            ) -as [ConfluencePS.Icon]
        }
    }
}
