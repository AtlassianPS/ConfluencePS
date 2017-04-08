function ConvertTo-WikiPage {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Page] )]
    param (
        # object to convert
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        $inputObject
    )

    Process {
        foreach ($object in $inputObject) {
            ($object | Select-Object `
                id,
                status,
                title,
                @{Name = "space"; Expression = {
                    if ($_.space) {
                        $_.space | ConvertTo-WikiSpace
                    } else {$null}
                }},
                @{Name = "version"; Expression = {
                    if ($_.version) {
                        $_.version | ConvertTo-WikiVersion
                    } else {$null}
                }},
                @{Name = "body"; Expression = {$_.body.storage.value}},
                @{Name = "ancestors"; Expression = {
                    if ($_.ancestors) {
                        $_.ancestors | ConvertTo-WikiPageAncestor
                    }
                    else {$null}
                }},
                @{Name = "URL"; Expression = {
                    if ($_._links.webui) {
                        "{0}{1}" -f $_._links.base, $_._links.webui
                    }
                    else {$null}
                }},
                @{Name = "ShortURL"; Expression = {
                    if ($_._links.tinyui) {
                        "{0}{1}" -f $_._links.base, $_._links.tinyui
                    } else {$null}
                }}
            ) -as [ConfluencePS.Page]
        }
    }
}
