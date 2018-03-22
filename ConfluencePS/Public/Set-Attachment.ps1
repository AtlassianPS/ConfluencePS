function Set-Attachment {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.Attachment])]
    param (
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Attachment]$Attachment,

        # Path of the file to upload and attach
        [Parameter( Mandatory )]
        [ValidateScript(
            {
                if (-not (Test-Path $_ -PathType Leaf)) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"File not found"),
                        'ParameterValue.FileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $_
                    )
                    $errorItem.ErrorDetails = "No file could be found with the provided path '$_'."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [String]$FilePath
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$apiURi/content/{0}/child/attachment/{1}/data"
    }

    PROCESS {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $parameter = @{
            URI        = $resourceApi -f $Attachment.PageID, $Attachment.ID
            Method     = "POST"
            InFile     = $FilePath
            Credential = $Credential
            OutputType = [ConfluencePS.Attachment]
            Verbose    = $false
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking Set Attachment Method with `$parameter"
        if ($PSCmdlet.ShouldProcess($Attachment.PageID, "Updating attachment '$($Attachment.Title)'.")) {
            Invoke-Method @parameter
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
