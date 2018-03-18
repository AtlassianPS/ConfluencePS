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

        $boundary = [System.Guid]::NewGuid().ToString()
        $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
        foreach ($file in $FilePath) {
            $fileName = Split-Path -Path $file -Leaf
            $readFile = Get-Content -Path $file -Encoding Byte
            $fileEnc = $enc.GetString($readFile)
            $bodyLines += @'
--{0}
Content-Disposition: form-data; name="file"; filename="{1}"
Content-Type: application/octet-stream

{2}

'@ -f $boundary, $fileName, $fileEnc
        }
        $bodyLines += "--{0}--`n`n" -f $boundary

        $headers = @{
            'X-Atlassian-Token' = 'nocheck'
            'Content-Type'      = "multipart/form-data; boundary=$boundary"
        }

        $parameter = @{
            URI        = $resourceApi -f $PageID
            Method     = "POST"
            Body       = $bodyLines
            Headers    = $headers
            RawBody    = $true
            Credential = $Credential
            OutputType = [ConfluencePS.Attachment]
            Verbose    = $false
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking Add Attachment Method with `$parameter"
        if ($PSCmdlet.ShouldProcess($PageID, "Adding attachment(s) '$($FilePath)'.")) {
            Invoke-Method @parameter
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
