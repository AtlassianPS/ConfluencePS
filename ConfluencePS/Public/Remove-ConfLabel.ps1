function Remove-ConfLabel {
    <#
    .SYNOPSIS
    Remove a label from existing Confluence content.

    .DESCRIPTION
    Remove a single label from Confluence content.
    Does accept multiple pages piped via Get-ConfPage.
    Specifically tested against pages, but should work against all content IDs.

    .PARAMETER Label
    A single content label to remove from one or more pages.

    .PARAMETER PageID
    The page ID to remove the label from. Accepts multiple IDs via pipeline input.

    .EXAMPLE
    Remove-ConfLabel -Label 7890 -PageID 123456 -Verbose -Confirm
    Would remove label "7890" from the page with ID 123456.
    Verbose and Confirm flags both active.

    .EXAMPLE
    Get-ConfLabelApplied -Label asdf -Limit 100 | Remove-ConfLabel -Label asdf -WhatIf
    Would remove the label "asdf" from all of your Confluence pages. -WhatIf flag supported.
    This may not remove everything if the max result limit for Get-ConfLabelApplied is reached.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
    param (
		[Parameter(Mandatory = $true)]
        [string]$Label,

		[Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
		[Alias('ID')]
        [int]$PageID
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-ConfInfo'
            Set-ConfInfo
        }
    }

    PROCESS {
        $URI = $BaseURI + "/content/$PageID/label?name=$Label"

        Write-Verbose "Sending delete request to $URI"
        If ($PSCmdlet.ShouldProcess("Label $Label, PageID $PageID")) {
            $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Delete

            # Successful response is empty. Adding verbose output
            If ($Rest -eq '') {
                Write-Verbose "Delete of label $Label on PageID $PageID successful."
            }
        }
    }
}
