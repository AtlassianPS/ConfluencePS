function Get-Space {
    <#
    .SYNOPSIS
    Retrieve a listing of spaces in your Confluence instance.

    .DESCRIPTION
    Fetch all Confluence spaces, optionally filtering by Name/Key/ID.
    Input for all parameters is not case sensitive.
    Piped output into other cmdlets is generally tested and supported.

    .EXAMPLE
    Get-ConfluenceSpace -ApiURi "https://myserver.com/wiki" -Credential $cred
    Display the info of all spaces on the server.

    .EXAMPLE
    Get-ConfluenceSpace -SpaceKey NASA
    Display the info of the space with key "NASA".

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding()]
    [OutputType([ConfluencePS.Space])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # Filter results by key. Supports wildcard matching on partial input.
        [Parameter(
            Position = 0
        )]
        [Alias('Key')]
        [string[]]$SpaceKey,

        # Maximimum number of results to fetch per call.
        # This setting can be tuned to get better performance according to the load on the server.
        # Warning: too high of a PageSize can cause a timeout on the request.
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $resourceURI = "$apiURi/space"
        $GETparameters += @{expand = "description.plain,icon,homepage,metadata.labels"}
        If ($PageSize) { $GETparameters["limit"] = $PageSize }

        if ($SpaceKey) {
            foreach ($_space in $SpaceKey) {
                $URI = "$resourceURI/{0}" -f $_space

                Invoke-Method -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Space])
            }
        }
        else {
            $URI = $resourceURI

            Invoke-Method -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Space])
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
