function Get-WikiPage {
    <#
    .SYNOPSIS
    Retrieve a listing of pages in your Confluence instance.

    .DESCRIPTION
    Fetch Confluence pages, optionally filtering by Name/Space/ID.
    Piped output into other cmdlets is generally tested and supported.

    .EXAMPLE
    Get-WikiPage -Title Confluence -Limit 100
    Get all pages with the word Confluence in the title. Title is not case sensitive.
    Among only the first 100 pages found, returns all results matching *confluence*.

    .EXAMPLE
    Get-WikiPage -Limit 500 | Select-Object ID, Title | Sort-Object Title
    List the first 500 pages found in your Confluence instance.
    Returns only each page's ID and Title, sorting results alphabetically by Title.

    .EXAMPLE
    Get-WikiSpace -Name Demo | Get-WikiPage
    Get all spaces with a name like *demo*, and then list pages from each returned space.

    .EXAMPLE
    $FinalCountdown = Get-WikiPage -PageID 54321 -Expand
    Store the page's ID, Title, Space Key, Version, and Body for use later in your script.

    .EXAMPLE
    $WhereIsShe = Get-WikiPage -Title 'Rachel' -Limit 1000 | Get-WikiPage -Expand
    Search Batman's 1000 pages for Rachel in order to find the correct page ID(s).
    Search again, this time piping in the page ID(s), to also capture version and body from the expanded results.
    Store them in a variable for later use (e.g. Set-WikiPage).

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(DefaultParameterSetName = "byId")]
    [OutputType([ConfluencePS.Page])]
    param (
        # Filter results by page ID.
        # Best option if you already know the ID, as it bypasses result limit problems.
        [Parameter(
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
        [Alias('Key')]
        [string]$SpaceKey,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = "bySpaceObject"
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ParameterSetName = "byTitle"
        )]
        [ConfluencePS.Space]$Space,

        # Defaults to 25 max results; can be modified here.
        # Numbers above 100 may not be honored if -Expand is used.
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Limit, # TODO: pagination

        # Additionally returns expanded results for each page (body, version, etc.).
        # May negatively affect -Limit, client/server performance, and network bandwidth.
        [switch]$Expand
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }

        # collect all results to process in END block
        $results = @()

        $contentRoot = "$BaseURI/content" # base url for this resouce
    }

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"

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

                    Write-Debug "Using `$GETparameters: $($GETparameters | Out-String)"
                    $URI += (Add-GetParameter $GETparameters)

                    Write-Verbose "Fetching data from $URI"
                    $response = Invoke-WikiMethod -Uri $URI -Method Get
                    Write-Debug "`$response: $($response | Out-String)"
                    $results += $response
                }
                break
            }
            "byTitle" {
                if ($SpaceKey) { $GETparameters["spaceKey"] = $SpaceKey }
                $GETparameters["title"] = $Title
            }
            "bySpace" {
                $GETparameters["spaceKey"] = $SpaceKey
            }
            "(bySpace|byTitle)" {
                $GETparameters["type"] = "page"
                If ($Limit) { $GETparameters["limit"] = $Limit }

                Write-Debug "Using `$GETparameters: $($GETparameters | Out-String)"
                $URI += (Add-GetParameter $GETparameters)

                Write-Verbose "Fetching data from $URI"
                $response = Invoke-WikiMethod -Uri $URI -Method Get
                Write-Debug "`$response: $($response | Out-String)"
                # Collect results to process in END block
                $results += $response
            }
        }
    }

    End {
        Write-Verbose "Processing results"
        foreach ($result in $results) {
            if ($result.results) {
                # Extract from array
                $result = $result | Select-Object -ExpandProperty results
            }
            foreach ($item in $result) {
                $item | ConvertTo-WikiPage
            }
        }
    }
}
