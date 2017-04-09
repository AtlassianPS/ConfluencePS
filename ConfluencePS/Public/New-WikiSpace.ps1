function New-WikiSpace {
    <#
    .SYNOPSIS
    Create a new blank space in your Confluence instance.

    .DESCRIPTION
    Create a new blank space. Key and Name mandatory, Description recommended.

    .EXAMPLE
    [ConfluencePS.Space]@{key="TEST";Name="Test Space"} | New-WikiSpace -ApiURi "https://myserver.com/wiki" -Credential $cred
    Create the new blank space. Runs Set-WikiInfo first if instance info unknown.

    .EXAMPLE
    New-WikiSpace -Key 'TEST' -Name 'Test Space' -Description 'New blank space via REST API' -Verbose
    Create the new blank space with the optional description and verbose output.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = "byObject"
    )]
    [OutputType([ConfluencePS.Space])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # Space Object
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byObject",
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Space]$InputObject,

        # Specify the short key to be used in the space URI.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byProperties"
        )]
        [Alias('Key')]
        [string]$SpaceKey,

        # Specify the space's name.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byProperties"
        )]
        [string]$Name,

        # A short description of the new space.
        [Parameter(
            ParameterSetName = "byProperties"
        )]
        [string]$Description
    )

    PROCESS {
        $URI = "$apiURi/space"

        if ($PsCmdlet.ParameterSetName -eq "byObject") {
            $SpaceKey = $InputObject.Key
            $Name = $InputObject.Name
            $Description = $InputObject.Description
        }

        $Body = @{
            key = $SpaceKey
            name = $Name
            description = @{
                plain = @{
                    value = $Description
                    representation = 'plain'
                }
            }
        } | ConvertTo-Json

        Write-Verbose "Posting to $URI"
        If ($PSCmdlet.ShouldProcess("$SpaceKey $Name")) {
            Invoke-WikiMethod -Uri $URI -Body $Body -Method Post -Credential $Credential -OutputType ([ConfluencePS.Space])
        }
    }
}
