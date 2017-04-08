function Remove-WikiSpace {
    <#
    .SYNOPSIS
    Remove an existing Confluence space.

    .DESCRIPTION
    Delete an existing Confluence space, including child content.
    "The space is deleted in a long running task, so the space cannot be considered deleted when this resource returns."

    .EXAMPLE
    Remove-WikiSpace -Key ABC,XYZ -Confirm
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
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"
        if (($_) -and ($_ -isnot [ConfluencePS.Space])) {
            if (!$Force) {
                Write-Warning "The Object in the pipe is not a Page"
            }
        }

        foreach ($_space in $SpaceKey) {
            $URI = "$BaseURI/space/{0}" -f $_space

            Write-Verbose "Sending delete request to $URI"
            If ($PSCmdlet.ShouldProcess("Space key $_space")) {
                $response = Invoke-WikiMethod -Uri $URI -Method Delete

                # Successful response provides a "longtask" status link
                # (add additional code here later to check and/or wait for the status)
            }
        }
    }
}
