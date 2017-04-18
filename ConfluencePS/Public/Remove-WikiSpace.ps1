function Remove-WikiSpace {
    <#
    .SYNOPSIS
    Remove an existing Confluence space.

    .DESCRIPTION
    Delete an existing Confluence space, including child content.
    "The space is deleted in a long running task, so the space cannot be considered deleted when this resource returns."

    .EXAMPLE
    Remove-WikiSpace -ApiURi "https://myserver.com/wiki" -Credential $cred -Key ABC,XYZ -Confirm
    Delete the space with key ABC and with key XYZ (note that key != name). Confirm will prompt before deletion.

    .EXAMPLE
    Get-WikiSpace | Where {$_.Name -like "*old"} | Remove-WikiSpace -Verbose -WhatIf
    Get all spaces ending in 'old' and simulate the deletion of them.
    Would simulate the removal of each space one by one with verbose output; -WhatIf flag active.

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

        # The key (short code) of the space to delete. Accepts multiple keys via pipeline input.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [string[]]$SpaceKey

        # TODO: Probably an extra param later to loop checking the status & wait for completion?
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Space] -or $_ -is [string])) {
            $message = "The Object in the pipe is not a Space."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        foreach ($_space in $SpaceKey) {
            $URI = "$apiURi/space/{0}" -f $_space

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Sending delete request to $URI"
            If ($PSCmdlet.ShouldProcess("Space key $_space")) {
                $response = Invoke-WikiMethod -Uri $URI -Method Delete -Credential $Credential

                # Successful response provides a "longtask" status link
                # (add additional code here later to check and/or wait for the status)
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
