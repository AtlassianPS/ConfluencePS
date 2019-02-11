function New-Space {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = "byObject"
    )]
    [OutputType([ConfluencePS.Space])]
    param (
        [Parameter( Mandatory = $true )]
        [uri]$ApiUri,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byObject",
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Space]$InputObject,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byProperties"
        )]
        [Alias('Key')]
        [string]$SpaceKey,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byProperties"
        )]
        [string]$Name,

        [Parameter(
            ParameterSetName = "byProperties"
        )]
        [string]$Description
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/space"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($PsCmdlet.ParameterSetName -eq "byObject") {
            $SpaceKey = $InputObject.Key
            $Name = $InputObject.Name
            $Description = $InputObject.Description
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Uri']           = $resourceApi
        $iwParameters['Method']        = 'Post'
        $iwParameters['OutputType']    = [ConfluencePS.Space]

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
