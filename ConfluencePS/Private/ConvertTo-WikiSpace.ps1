function ConvertTo-WikiSpace {
    # Extracted the conversion to private function in order to have a single place to
    # select the properties to use when casting to custom object type
    [CmdletBinding()]
    [OutputType(
        [ConfluencePS.Space]
    )]
    param (
        # object to convert
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        $inputObject
    )

    Process {
        foreach ($object in $inputObject) {
            # TODO: Add homepage
            ($object | Select-Object id,
                                     key,
                                     name,
                                     @{Name = "description"; Expression = {$_.description.plain.value}},
                                     icon,
                                     type
            ) -as [ConfluencePS.Space]
        }
    }
}
