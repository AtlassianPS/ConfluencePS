function Remove-WikiLabel {
    <#
    .SYNOPSIS
    Remove a label from existing Confluence content.

    .DESCRIPTION
    Remove a single label from Confluence content.
    Does accept multiple pages piped via Get-WikiPage.
    Specifically tested against pages, but should work against all content IDs.

    .EXAMPLE
    Remove-WikiLabel -Label seven -PageID 123456 -Verbose -Confirm
    Would remove label "seven" from the page with ID 123456.
    Verbose and Confirm flags both active.

    .EXAMPLE
    Get-WikiLabelApplied -Label asdf -Limit 100 | Remove-WikiLabel -Label asdf -WhatIf
    Would remove the label "asdf" from all of your Confluence pages. -WhatIf flag supported.
    This may not remove everything if the max result limit for Get-WikiLabelApplied is reached.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact = 'Medium')]
    param (
        # A single content label to remove from one or more pages.
        [Parameter(Mandatory = $true)]
        [string]$Label,

        # The page ID to remove the label from. Accepts multiple IDs via pipeline input.
        [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1,[int]::MaxValue)]
        [Alias('ID')]
        [int]$PageID
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        $URI = "$BaseURI/content/$PageID/label?name=$Label"

        Write-Verbose "Sending delete request to $URI"
        If ($PSCmdlet.ShouldProcess("Label $Label, PageID $PageID")) {
            $response = Invoke-WikiMethod -Uri $URI -Method Delete

            # Successful response is empty. Adding verbose output
            If ($response -eq '') {
                Write-Verbose "Delete of label $Label on PageID $PageID successful."
            }
        }
    }
}
