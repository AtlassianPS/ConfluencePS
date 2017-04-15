﻿function Get-WikiChildPage {
    <#
    .SYNOPSIS
    For a given wiki page, list all child wiki pages.

    .DESCRIPTION
    Pipeline input of ParentID is accepted.

    This API method only returns the immediate children (results are not recursive).

    .EXAMPLE
    Get-WikiChildPage -ParentID 1234 | Select-Object ID, Title | Sort-Object Title
    For the wiki page with ID 1234, get all pages immediately beneath it.
    Returns only each page's ID and Title, sorting results alphabetically by Title.

    .EXAMPLE
    Get-WikiPage -Title 'Genghis Khan' | Get-WikiChildPage -Limit 500
    Find the Genghis Khan wiki page and pipe the results.
    Get only the first 500 children beneath that page.

    .EXAMPLE
    Get-WikiChildPage -ParentID 9999 -Expand -Limit 100
    For each child page found, expand the results to also include properties
    like Body and Version (Ver). Typically, using -Expand will not return
    more than 100 results, even if -Limit is set to a higher value.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(DefaultParameterSetName = "byID")]
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
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = "byID"
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int]$PageID,

        # Find child pages by Page Object
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = "byObject"
        )]
        [ConfluencePS.Page]$InputObject,

        # Get all child pages recursively
        [switch]$Recurse,

        # Defaults to 25 max results; can be modified here.
        # Numbers above 100 may not be honored if -Expand is used.
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize
    )

    BEGIN {
        $depthLevel = "child"
    }

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($PsCmdlet.ParameterSetName -eq "byObject") {
            $PageID = $InputObject.ID
        }
        if ($Recurse) {$depthLevel = "descendant"} # depth = ALL
        $URI = "$apiURi/content/{0}/{1}/page" -f $PageID, $depthLevel

        # URI prep based on specified parameters
        $GETparameters = @{expand = "space,version,body.storage,ancestors"}
        If ($PageSize) { $GETparameters["limit"] = $PageSize }

        Write-Verbose "Fetching data from $URI"
        Invoke-WikiMethod -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Page])
    }
}
