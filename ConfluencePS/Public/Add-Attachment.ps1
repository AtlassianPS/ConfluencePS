function Add-Attachment {
    [CmdletBinding( SupportsShouldProcess )]
    [OutputType([ConfluencePS.Attachment])]
    param(
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int]$PageID,

        # Path of the file to upload and attach
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
        [Alias('InFile', 'FullName', 'Path')]
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

        foreach ($file in $FilePath) {
            $fileName = Split-Path -Path $file -Leaf
            $readFile = [System.IO.File]::ReadAllBytes($file)
            $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
            $fileEnc = $enc.GetString($readFile)
            $boundary = [System.Guid]::NewGuid().ToString()
            $mimeType = [System.Web.MimeMapping]::GetMimeMapping($file)
            if ($mimeType) { $ContentType = $mimeType }
            else { $ContentType = "application/octet-stream" }

            $bodyLines = @'
--{0}
Content-Disposition: form-data; name="file"; filename="{1}"
Content-Type: {2}

{3}
--{0}--

'@ -f $boundary, $fileName, $mimeType, $fileEnc

            $headers = @{
                'X-Atlassian-Token' = 'nocheck'
                'Content-Type'      = "multipart/form-data; boundary=`"$boundary`""
            }

            $parameter = @{
                URI        = $resourceApi -f $PageID
                Method     = "PUT"
                Body       = $bodyLines
                Headers    = $headers
                RawBody    = $true
                Credential = $Credential
                OutputType = [ConfluencePS.Attachment]
                Verbose    = $false
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($PageID, "Adding attachment '$($fileName)'.")) {
                Invoke-Method @parameter

                if ($PassThru) {
                    Write-Output (ConvertTo-Attachment -InputObject $rawResult)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
