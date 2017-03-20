﻿function Remove-WikiSpace {
    <#
    .SYNOPSIS
    Remove an existing Confluence space.

    .DESCRIPTION
    Delete an existing Confluence space, including child content.
    "The space is deleted in a long running task, so the space cannot be considered deleted when this resource returns."

    .EXAMPLE
    Remove-WikiSpace -Key XYZ -Confirm
    Delete a space with key XYZ (note that key != name). Confirm will prompt before deletion.

    .EXAMPLE
    Get-WikiSpace -Name ald | Remove-WikiSpace -Verbose -WhatIf
    Get spaces matching '*ald*' (like Reginald and Alderaan), piping them to be deleted.
    Would remove each space one by one with verbose output; -WhatIf flag active.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(SupportsShouldProcess = $true,
                   ConfirmImpact = 'Medium')]
    param (
        # The key (short code) of the space to delete. Accepts multiple keys via pipeline input.
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [string]$SpaceKey

        # Probably an extra param later to loop checking the status & wait for completion?
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        $URI = "$BaseURI/space/$SpaceKey"

        Write-Verbose "Sending delete request to $URI"
        If ($PSCmdlet.ShouldProcess("Space key $SpaceKey")) {
            $response = Invoke-WikiMethod -Uri $URI -Method Delete

            # Successful response provides a "longtask" status link
                # (add additional code here later to check and/or wait for the status)
        }
    }
}
