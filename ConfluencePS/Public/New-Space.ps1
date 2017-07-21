function New-Space {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = "byObject"
    )]
    [OutputType([ConfluencePS.Space])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-ConfluenceInfo.
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

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$apiURi/space"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($PsCmdlet.ParameterSetName -eq "byObject") {
            $SpaceKey = $InputObject.Key
            $Name = $InputObject.Name
            $Description = $InputObject.Description
        }

        $iwParameters = @{
            Uri        = $resourceApi
            Method     = 'Post'
            Body       = ""
            OutputType = [ConfluencePS.Space]
            Credential = $Credential
        }
        $Body = @{
            key         = $SpaceKey
            name        = $Name
            description = @{
                plain = @{
                    value          = $Description
                    representation = 'plain'
                }
            }
        }

        $iwParameters["Body"] = $Body | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Body | Out-String)"
        If ($PSCmdlet.ShouldProcess("$SpaceKey $Name")) {
            Invoke-Method @iwParameters
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
