﻿function Get-Page {
    <#
    .SYNOPSIS
    Retrieve a listing of pages in your Confluence instance.

    .DESCRIPTION
    Fetch Confluence pages, optionally filtering by Name/Space/ID.
    Piped output into other cmdlets is generally tested and supported.

    .PARAMETER Skip
    Controls how many things will be skipped before starting output. Defaults to 0.

    .PARAMETER First
    Currently not supported.
    Indicates how many items to return. Defaults to 100.

    .PARAMETER IncludeTotalCount
    Causes an extra output of the total count at the beginning.
    Note this is actually a uInt64, but with a custom string representation.

    .EXAMPLE
    Get-ConfluencePage -ApiURi "https://myserver.com/wiki" -Credential $cred | Select-Object ID, Title -first 500 | Sort-Object Title
    List the first 500 pages found in your Confluence instance.
    Returns only each page's ID and Title, sorting results alphabetically by Title.

    .EXAMPLE
    Get-ConfluencePage -Title Confluence -SpaceKey "ABC" -PageSize 100
    Get all pages with the word Confluence in the title in the 'ABC' sapce. The calls
    to the server are limited to 100 pages per call.

    .EXAMPLE
    Get-ConfluenceSpace -Name Demo | Get-ConfluencePage
    Get all spaces with a name like *demo*, and then list pages from each returned space.

    .EXAMPLE
    $FinalCountdown = Get-ConfluencePage -PageID 54321
    Store the page's ID, Title, Space Key, Version, and Body for use later in your script.

    .EXAMPLE
    $WhereIsShe = Get-ConfluencePage -Title 'Rachel' | Get-ConfluencePage
    Search Batman's 1000 pages for Rachel in order to find the correct page ID(s).
    Search again, this time piping in the page ID(s), to also capture version and body from the expanded results.
    Store them in a variable for later use (e.g. Set-ConfluencePage).

    .EXAMPLE
    $meetingPages = Get-ConfluencePage -Label "meeting-notes" -SpaceKey PROJ1
    Captures all the meeting note pages in the Proj1 Space.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
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