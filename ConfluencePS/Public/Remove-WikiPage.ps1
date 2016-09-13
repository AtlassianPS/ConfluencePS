function Remove-WikiPage {
    <#
    .SYNOPSIS
    Trash an existing Confluence page.

    .DESCRIPTION
    Delete existing Confluence content by page ID.
    This trashes most content, but will permanently delete "un-trashable" content.
    Untested against non-page content, but probably works anyway.

    .EXAMPLE
    Get-WikiSpace -Key SESAME | Get-WikiPage -Title Oscar | Remove-WikiPage -Confirm
    Send Oscar to the trash. Each matching page will ask you to confirm the deletion.

    .EXAMPLE
    Get-WikiLabelApplied -Label outdated -Limit 100 | Remove-WikiPage -Verbose -WhatIf
    Find the first 100 content results that are labeled "outdated."
    Would remove each page one by one with verbose output; -WhatIf flag active.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
    param (
        # The page ID to delete. Accepts multiple IDs via pipeline input.
        [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
        [Alias('ID')]
        [ValidateRange(1,[int]::MaxValue)]
        [int]$PageID
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        $URI = $BaseURI + "/content/$PageID"

        Write-Verbose "Sending delete request to $URI"
        If ($PSCmdlet.ShouldProcess("PageID $PageID")) {
            $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Delete

            # Successful response is empty. Adding verbose output
            If ($Rest -eq '') {
                Write-Verbose "Delete of PageID $PageID successful."
            }
        }
    }
}
