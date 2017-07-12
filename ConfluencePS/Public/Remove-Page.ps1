function Remove-Page {
    <#
    .SYNOPSIS
    Trash an existing Confluence page.

    .DESCRIPTION
    Delete existing Confluence content by page ID.
    This trashes most content, but will permanently delete "un-trashable" content.
    Untested against non-page content, but probably works anyway.

    .EXAMPLE
    Get-ConfluencePage -Title Oscar | Remove-ConfluencePage -Confirm
    Send Oscar to the trash. Each matching page will ask you to confirm the deletion.

    .EXAMPLE
    Remove-ConfluencePage -ApiURi "https://myserver.com/wiki" -Credential $cred -PageID 12345,12346 -Verbose -WhatIf
    Simulates the removal of two specifc pages.

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
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-ConfluenceInfo.
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

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        foreach ($_page in $PageID) {
            $URI = "$apiURi/content/{0}" -f $_page

            If ($PSCmdlet.ShouldProcess("PageID $_page")) {
                Invoke-Method -Uri $URI -Method Delete -Credential $Credential
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
