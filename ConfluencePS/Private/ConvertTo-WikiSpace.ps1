function ConvertTo-WikiSpace {
    # Extracted the conversion to private function in order to have a single place to
    # select the properties to use when casting to custom object type
    [CmdletBinding()]
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
            ($object | Select-Object id, key, name, description, icon, type) -as [ConfluencePS.Space]
        }
    }
}
