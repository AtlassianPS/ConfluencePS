function Remove-Attachment {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true
    )]
    [OutputType([Bool])]
    param (
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Attachment]$Attachment
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$apiURi/content/{0}"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Uri        = ""
            Method     = 'Delete'
            Credential = $Credential
        }

        foreach ($_attachment in $Attachment) {
            $iwParameters["Uri"] = $resourceApi -f $_attachment.ID

            If ($PSCmdlet.ShouldProcess("Attachment $($_attachment.ID), PageID $($_attachment.PageID)")) {
                Invoke-Method @iwParameters
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
