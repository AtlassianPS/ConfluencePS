function Get-AttachmentFile {
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter( Mandatory = $true )]
        [uri]$ApiUri,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [PSCredential]$PersonalAccessToken,

        [Parameter( Mandatory = $false )]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Attachment[]]$Attachment,

        [ValidateScript(
            {
                if (-not (Test-Path $_)) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Path not found"),
                        'ParameterValue.FileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $_
                    )
                    $errorItem.ErrorDetails = "Invalid path '$_'."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [String]$Path
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Attachment])) {
            $message = "The Object in the pipe is not an Attachment."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'

        foreach ($_Attachment in $Attachment) {
            $iwParameters['Uri'] = $_Attachment.URL
            $iwParameters['Headers'] = @{"Accept" = $_Attachment.MediaType }
            $iwParameters['OutFile'] = if ($Path) { Join-Path -Path $Path -ChildPath $_Attachment.Filename } else { $_Attachment.Filename }

            $result = Invoke-Method @iwParameters
            (-not $result)
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
