function ConvertTo-Attachment {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Attachment] )]
    param (
        # object to convert
        [Parameter( ValueFromPipeline = $true )]
        $InputObject
    )

    Process {
        foreach ($object in $InputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to Attachment"
            [ConfluencePS.Attachment](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = {
                            $ID = $_.id -replace 'att', ''
                            [convert]::ToInt32($ID, 10)
                        }
                    },
                    status,
                    title,
                    @{Name = "mediatype";  Expression = {
                            $_.extensions.mediaType
                        }
                    },
                    @{Name = "filesize";  Expression = {
                            [convert]::ToInt32($_.extensions.fileSize, 10)
                        }
                    },
                    @{Name = "comment";  Expression = {
                            $_.extensions.comment
                        }
                    },
                    @{Name = "spacekey"; Expression = {
                            $_._expandable.space -replace '^.*\/space\/', ''
                        }
                    },
                    @{Name = "pageid"; Expression = {
                            $_.container.id
                        }
                    },
                    @{Name = "version"; Expression = {
                            if ($_.version) {
                                ConvertTo-Version $_.version
                            }
                            else {$null}
                        }
                    },
                    @{Name = "URL"; Expression = {
                            $base = $_._links.base
                            if (!($base)) { $base = $_._links.self -replace '\/rest.*', '' }
                            if ($_._links.download) {
                                "{0}{1}" -f $base, $_._links.download
                            }
                            else {$null}
                        }
                    }
                ))
        }
    }
}
