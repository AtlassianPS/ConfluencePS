function Get-WikiPage {
    <#
    .SYNOPSIS
    Retrieve a listing of pages in your Confluence instance.

    .DESCRIPTION
    Fetch Confluence pages, optionally filtering by Name/Space/ID.
    Piped output into other cmdlets is generally tested and supported.

    .EXAMPLE
    Get-WikiPage -ApiURi "https://myserver.com/wiki" -Credential $cred | Select-Object ID, Title -first 500 | Sort-Object Title
    List the first 500 pages found in your Confluence instance.
    Returns only each page's ID and Title, sorting results alphabetically by Title.

    .EXAMPLE
    Get-WikiPage -Title Confluence -SpaceKey "ABC" -PageSize 100
    Get all pages with the word Confluence in the title in the 'ABC' sapce. The calls
    to the server are limited to 100 pages per call.

    .EXAMPLE
    Get-WikiSpace -Name Demo | Get-WikiPage
    Get all spaces with a name like *demo*, and then list pages from each returned space.

    .EXAMPLE
    $FinalCountdown = Get-WikiPage -PageID 54321
    Store the page's ID, Title, Space Key, Version, and Body for use later in your script.

    .EXAMPLE
    $WhereIsShe = Get-WikiPage -Title 'Rachel' | Get-WikiPage
    Search Batman's 1000 pages for Rachel in order to find the correct page ID(s).
    Search again, this time piping in the page ID(s), to also capture version and body from the expanded results.
    Store them in a variable for later use (e.g. Set-WikiPage).

    .EXAMPLE
    $meetingPages = Get-WikiPage -Label "meeting-notes" -SpaceKey PROJ1
    Captures all the meeting note pages in the Proj1 Space.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(DefaultParameterSetName = "byId")]
    [OutputType([ConfluencePS.Page])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # Filter results by page ID.
        # Best option if you already know the ID, as it bypasses result limit problems.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "byId",
            ValueFromPipeline = $true
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

        # Base url for this resouce
        $contentRoot = "$apiURi/content"
    }

    PROCESS {
        if ($PSBoundParameters['Debug']) { $DebugPreference = 'Continue' }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"
        $DebugPreference = $_debugPreference

        $URI = $contentRoot

        if ($Space -is [ConfluencePS.Space] -and ($Space.Key)) {
            $SpaceKey = $Space.Key
        }

        # URI prep based on specified parameters
        $GETparameters = @{expand = "space,version,body.storage,ancestors"}
        switch -regex ($PsCmdlet.ParameterSetName) {
            "byId" {
                foreach ($_pageID in $PageID) {
                    $URI = "$contentRoot/$_pageID"

                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Fetching data from $URI"
                    Invoke-WikiMethod -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Page])
                }
                break
            }
            "(bySpace|byTitle)" {
                $GETparameters["type"] = "page"
                if ($Title) { $GETparameters["title"] = $Title }
                if ($SpaceKey) { $GETparameters["spaceKey"] = $SpaceKey }
                If ($PageSize) { $GETparameters["limit"] = $PageSize }

                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Fetching data from $URI"
                Invoke-WikiMethod -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Page])
                break
            }
            "byLabel" {
                $URI = "$contentRoot/search"

                $CQLparameters = @("type=page", "label=$Label")
                if ($SpaceKey) {$CQLparameters += "space=$SpaceKey"}

                $cqlQuery = ConvertTo-URLEncoded ($CQLparameters -join (" AND "))

                $GETparameters["cql"] = $cqlQuery
                If ($PageSize) { $GETparameters["limit"] = $PageSize }

                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Fetching data from $URI"
                Invoke-WikiMethod -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Page])
                break
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
