function ConvertTo-WikiPage {
    # Extracted the conversion to private function in order to have a single place to
    # select the properties to use when casting to custom object type
    [CmdletBinding()]
    [OutputType(
        [ConfluencePS.Page]
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
            # TODO: Add URL
            # TODO: Add Version
            ($object | Select-Object id,
                                     status,
                                     title,
                                     @{Name = "space"; Expression = {$_.space | ConvertTo-WikiSpace}},
                                     @{Name = "version"; Expression = {$_.version | ConvertTo-WikiVersion}},
                                     @{Name = "body"; Expression = {$_.body.storage.value}}
            ) -as [ConfluencePS.Page]
        }
    }
}
