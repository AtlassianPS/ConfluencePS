function Add-Attachment {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.Attachment])]
    param(
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [Int]$PageID,

        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
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
        [Alias('InFile', 'FullName', 'Path', 'PSPath')]
        [String[]]
        $FilePath
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$apiURi/content/{0}/child/attachment"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $parameter = @{
            URI        = $resourceApi -f $PageID
            Method     = "POST"
            Credential = $Credential
            OutputType = [ConfluencePS.Attachment]
            Verbose    = $false
        }
        foreach ($file in $FilePath) {
            $parameter["InFile"] = $file

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking Add Attachment Method with `$parameter"
            if ($PSCmdlet.ShouldProcess($PageID, "Adding attachment(s) '$($file)'.")) {
                Invoke-Method @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
