function Remove-WikiPage {
    <#
    .SYNOPSIS
    Trash an existing Confluence page.

    .DESCRIPTION
    Delete existing Confluence content by page ID.
    This trashes most content, but will permanently delete "un-trashable" content.
    Untested against non-page content, but probably works anyway.

    .EXAMPLE
    Get-WikiPage -Title Oscar | Remove-WikiPage -Confirm
    Send Oscar to the trash. Each matching page will ask you to confirm the deletion.

    .EXAMPLE
    Remove-WikiPage -ApiURi "https://myserver.com/wiki" -Credential $cred -PageID 12345,12346 -Verbose -WhatIf
    Simulates the removal of two specifc pages.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([Bool])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # The page ID to delete. Accepts multiple IDs via pipeline input.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID
    )

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"
        if (($_) -and ($_ -isnot [ConfluencePS.Page])) {
            if (!$Force) {
                Write-Warning "The Object in the pipe is not a Page"
            }
        }

        foreach ($_page in $PageID) {
            $URI = "$apiURi/content/{0}" -f $_page

            Write-Verbose "Sending delete request to $URI"
            If ($PSCmdlet.ShouldProcess("PageID $_page")) {
                Invoke-WikiMethod -Uri $URI -Method Delete -Credential $Credential
            }
        }

    }
}
