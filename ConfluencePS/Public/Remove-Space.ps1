function Remove-Space {
    [CmdletBinding(
        ConfirmImpact = 'High',
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

        # The key (short code) of the space to delete. Accepts multiple keys via pipeline input.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Key')]
        [string[]]$SpaceKey,

        # Forces the deletion of the space without prompting for confirmation.
        [switch]$Force

        # TODO: Probably an extra param later to loop checking the status & wait for completion?
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        if ($Force) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
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
                $response = Invoke-Method -Uri $URI -Method Delete -Credential $Credential

                # Successful response provides a "longtask" status link
                # (add additional code here later to check and/or wait for the status)
            }
        }
    }

    END {
        if ($Force) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
