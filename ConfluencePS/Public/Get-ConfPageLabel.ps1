function Get-ConfPageLabel {
    <#
    .SYNOPSIS
    Returns the list of labels on a page.

    .DESCRIPTION
    View all labels applied to a page (specified by PageID).
    Currently accepts multiple pages only via piped input.

    .PARAMETER PageID
    List the PageID number to check for labels. Accepts piped input.

    .PARAMETER Limit
    Defaults to 200 max results; can be modified here.

    .EXAMPLE
    Get-ConfPageLabel -PageID 123456 -Limit 500
    Lists the labels applied to page 123456.
    This also increases the result limit from 200 to 500, in case you love to label.

    .EXAMPLE
    Get-ConfPage -SpaceKey NASA | Get-ConfPageLabel -Verbose
    Get all pages that exist in NASA space (literally?).
    Search all of those pages (piped to -PageID) for all of their active labels.
    Verbose flag would be good here to keep track of the request.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('ID')]
        [int]$PageID,

        [int]$Limit
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-ConfInfo'
            Set-ConfInfo
        }
    }

    PROCESS {
        Write-Verbose "Processing request for PageID $PageID"
        $URI = $BaseURI + "/content/$PageID/label"

        If ($Limit) {
            $URI = $URI + "?limit=$Limit"
        }

        Write-Verbose "Fetching info from $URI"
        $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get | Select -ExpandProperty Results

        # Hashing everything because I don't like the lower case property names from the REST call
        $Rest | Sort Name | Select @{n='LabelID'; e={$_.id}},
                                   @{n='Label';   e={$_.name}},
                                   @{n='Prefix';  e={$_.prefix}},
                                   @{n='PageID';  e={$PageID}}
    }
}
