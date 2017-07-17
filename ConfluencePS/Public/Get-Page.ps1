function Get-Page {
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byId"
    )]
    [OutputType([ConfluencePS.Page])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [URi]$ApiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # Filter results by page ID.
        # Best option if you already know the ID, as it bypasses result limit problems.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "byId",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

        # Filter results by name.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byTitle"
        )]
        [Alias('Name')]
        [string]$Title,

        # Filter results by key. Currently, this parameter is case sensitive.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "bySpace"
        )]
        [Parameter(
            ParameterSetName = "byTitle"
        )]
        [Parameter(
            ParameterSetName = "byLabel"
        )]
        [Alias('Key')]
        [string]$SpaceKey,

        # Filter results by space object(s), typically from the pipeline
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = "bySpaceObject"
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ParameterSetName = "byTitle"
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ParameterSetName = "byLabel"
        )]
        [ConfluencePS.Space]$Space,

        # Label(s) to use as search criteria to find pages
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byLabel"
        )]
        [string[]]$Label,

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

        if ($Space -is [ConfluencePS.Space] -and ($Space.Key)) {
            $SpaceKey = $Space.Key
        }

        $resourceURI = "$apiURi/content"
        $GETparameters = @{expand = "space,version,body.storage,ancestors"}

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $script:PSDefaultParameterValues["Invoke-WikiMethod:$_"] = $PSCmdlet.PagingParameters.$_
        }

        switch -regex ($PsCmdlet.ParameterSetName) {
            "byId" {
                foreach ($_pageID in $PageID) {
                    $URI = "$resourceURI/{0}" -f $_pageID

                    Invoke-Method -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Page])
                }
                break
            }
            "(bySpace|byTitle)" {
                $URI = "$resourceURI"
                $GETparameters["type"] = "page"
                if ($Title) { $GETparameters["title"] = $Title }
                if ($SpaceKey) { $GETparameters["spaceKey"] = $SpaceKey }
                If ($PageSize) { $GETparameters["limit"] = $PageSize }

                Invoke-Method -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Page])
                break
            }
            "byLabel" {
                $URI = "$resourceURI/search"

                $CQLparameters = @("type=page", "label=$Label")
                if ($SpaceKey) {$CQLparameters += "space=$SpaceKey"}
                $cqlQuery = ConvertTo-URLEncoded ($CQLparameters -join (" AND "))

                $GETparameters["cql"] = $cqlQuery
                If ($PageSize) { $GETparameters["limit"] = $PageSize }

                Invoke-Method -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Page])
                break
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
