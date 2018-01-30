function Get-AttachmentFile {
    [CmdletBinding()]
    [OutputType([Bool])]
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
        $Attachment,

        [String]$OutFile
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Attachment])) {
            $message = "The Object in the pipe is not an Attachment."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        if (-not($OutFile)) {
            $OutFile = "{0}"
        }

        # Basic Authentication hash
        $SecureCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(
                $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password)
            ))

        foreach ($_Attachment in $Attachment) {
            $_OutFile = [string]::Format($OutFile, $_Attachment.Title, $_Attachment.ID, $_Attachment.SpaceKey, $_Attachment.PageID, $_Attachment.Version.Number)

            # set mandatory parameters
            $splatParameters = @{
                Uri             = $_Attachment.URL
                Method          = 'Get'
                Headers         = @{"Accept" = $_Attachment.MediaType
                                    "Authorization" = "Basic $($SecureCreds)"}
                ContentType     = $_Attachment.MediaType
                UseBasicParsing = $true
                OutFile         = $_OutFile
                ErrorAction     = "Stop"
            }

            # load DefaultParameters for Invoke-WebRequest
            # as the global PSDefaultParameterValues is not used
            # TODO: find out why PSJira doesn't need this
            $script:PSDefaultParameterValues = $global:PSDefaultParameterValues

            # Invoke the API
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking method Get to URI $Attachment.URL"
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoke-WebRequest with: $(([PSCustomObject]$splatParameters) | Out-String)"
            try {
                $webResponse = Invoke-WebRequest @splatParameters
            }
            catch {
                # Invoke-WebRequest is hard-coded to throw an exception if the Web request returns a 4xx or 5xx error.
                # This is the best workaround I can find to retrieve the actual results of the request.
                # This shall be fixed with PoSh v6: https://github.com/PowerShell/PowerShell/issues/2193
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to get an answer from the server"
                $webResponse = $_.Exception.Response
            }


            Write-Debug "[$($MyInvocation.MyCommand.Name)] Executed WebRequest. Access `$webResponse to see details"
            if ($webResponse) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Status code: $($webResponse.StatusCode)"

                if ($webResponse.StatusCode.value__ -ge 400) {
                    Write-Warning "Confluence returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

                    # Retrieve body of HTTP response - this contains more useful information about exactly why the error occurred
                    $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
                    $responseBody = $readStream.ReadToEnd()
                    $readStream.Close()

                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Retrieved body of HTTP response for more information about the error (`$responseBody)"
                    try {
                        $responseObject = ConvertFrom-Json -InputObject $responseBody -ErrorAction Stop
                        if ($responseObject.message) {
                            Write-Error $responseObject.message
                        }
                        else {throw}
                    }
                    catch {
                        Write-Error $responseBody
                    }
                }
            }
       }
       $True
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
