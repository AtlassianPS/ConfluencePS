function Get-WikiPageLabel {
    <#
    .SYNOPSIS
    Returns the list of labels on a page.

    .DESCRIPTION
    View all labels applied to a page (specified by PageID).
    Currently accepts multiple pages only via piped input.

    .EXAMPLE
    Get-WikiPageLabel -PageID 123456 -Limit 500
    Lists the labels applied to page 123456.
    This also increases the result limit from 200 to 500, in case you love to label.

    .EXAMPLE
    Get-WikiPage -SpaceKey NASA | Get-WikiPageLabel -Verbose
    Get all pages that exist in NASA space (literally?).
    Search all of those pages (piped to -PageID) for all of their active labels.
    Verbose flag would be good here to keep track of the request.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding()]
    [OutputType([ConfluencePS.Label])]
    param (
        # List the PageID number to check for labels. Accepts piped input.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int]$PageID,

        # Maximimum number of results to fetch per call.
        # This setting can be tuned to get better performance according to the load on the server.
        # Warning: too high of a PageSize can cause a timeout on the request.
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize = 25
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"
        if (($_) -and ($_ -isnot [ConfluencePS.Page])) {
            if (!$Force) {
                Write-Warning "The Object in the pipe is not a Page"
            }
        }

        Write-Verbose "Processing request for PageID $PageID"
        $URI = "$BaseURI/content/$PageID/label"

        If ($PageSize) {
            $URI = $URI + "?limit=$PageSize"
        }

        Write-Verbose "Fetching info from $URI"
        Invoke-WikiMethod -Uri $URI -Method Get -OutputType ([ConfluencePS.Label])
    }
}
