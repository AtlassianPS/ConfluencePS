function Remove-WikiLabel {
    <#
    .SYNOPSIS
    Remove a label from existing Confluence content.

    .DESCRIPTION
    Remove a single label from Confluence content.
    Does accept multiple pages piped via Get-WikiPage.
    Specifically tested against pages, but should work against all content IDs.

    .EXAMPLE
    Remove-WikiLabel -ApiURi "https://myserver.com/wiki" -Credential $cred -Label seven -PageID 123456 -Verbose -Confirm
    Would remove label "seven" from the page with ID 123456.
    Verbose and Confirm flags both active.

    .EXAMPLE
    Get-WikiPage -SpaceKey "ABC" | Remove-WikiLabel -Label asdf -WhatIf
    Would remove the label "asdf" from all pages in the ABC space.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true
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

        # The page ID to remove the label from. Accepts multiple IDs via pipeline input.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

        # A single content label to remove from one or more pages.
        [Parameter(Mandatory = $true)]
        [string[]]$Label,

        # Run command without showing warning messages
        [switch]$Force
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
            foreach ($_label in $Label) {
                $URI = "$BaseURI/content/{0}/label?name={1}" -f $_page, $_label

                Write-Verbose "Sending delete request to $URI"
                If ($PSCmdlet.ShouldProcess("Label $_label, PageID $_page")) {
                    Invoke-WikiMethod -Uri $URI -Method Delete -Credential $Credential
                }
            }
        }
    }
}
