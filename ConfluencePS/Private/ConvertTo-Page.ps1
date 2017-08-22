function ConvertTo-Page {
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
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to Page"
            ($object | Select-Object `
                id,
                status,
                title,
                @{Name = "space"; Expression = {
                        if ($_.space) {
                            ConvertTo-Space $_.space
                        }
                        else {$null}
                    }
                },
                @{Name = "version"; Expression = {
                        if ($_.version) {
                            ConvertTo-Version $_.version
                        }
                        else {$null}
                    }
                },
                @{Name = "body"; Expression = {$_.body.storage.value}},
                @{Name = "ancestors"; Expression = {
                        if ($_.ancestors) {
                            ConvertTo-PageAncestor $_.ancestors
                        }
                        else {$null}
                    }
                },
                @{Name = "URL"; Expression = {
                        if ($_._links.webui) {
                            "{0}{1}" -f $_._links.base, $_._links.webui
                        }
                        else {$null}
                    }
                },
                @{Name = "ShortURL"; Expression = {
                        if ($_._links.tinyui) {
                            "{0}{1}" -f $_._links.base, $_._links.tinyui
                        }
                        else {$null}
                    }
                }
            ) -as [ConfluencePS.Page]
        }
    }
}
