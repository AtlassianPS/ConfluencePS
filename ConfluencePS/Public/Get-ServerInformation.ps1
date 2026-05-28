function Get-ServerInformation {
    [CmdletBinding()]
    [OutputType([ConfluencePS.ServerInformation])]
    param (
        [Parameter(Mandatory = $true)]
        [Uri]$ApiUri,

        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [String]
        $PersonalAccessToken,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['Uri'] = "$($ApiUri.AbsoluteUri.TrimEnd('/'))/settings/systemInfo"
        $iwParameters['OutputType'] = [ConfluencePS.ServerInformation]

        $serverInformation = Invoke-Method @iwParameters -ErrorAction Stop
        if ($serverInformation) {
            $serverInformation
        }
        else {
            [ConfluencePS.ServerInformation]@{ DeploymentType = 'DataCenter' }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
