function Invoke-Method {
    [CmdletBinding(SupportsPaging = $true)]
    [OutputType(
        [PSObject],
        [ConfluencePS.Page],
        [ConfluencePS.Space],
        [ConfluencePS.Label],
        [ConfluencePS.Icon],
        [ConfluencePS.Version],
        [ConfluencePS.User],
        [ConfluencePS.Attachment]
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute( "PSAvoidUsingEmptyCatchBlock", "" )]
    param (
        [Parameter(Mandatory = $true)]
        [Uri]$Uri,

        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = "GET",

        [ValidateNotNullOrEmpty()]
        [String]$Body,

        [Switch]$RawBody,

        [Hashtable]$Headers,

        [Hashtable]$GetParameters,

        [String]$InFile,

        [String]$OutFile,

        [ValidateSet(
            [ConfluencePS.Page],
            [ConfluencePS.Space],
            [ConfluencePS.Label],
            [ConfluencePS.Icon],
            [ConfluencePS.Version],
            [ConfluencePS.User],
            [ConfluencePS.Attachment]
        )]
        [System.Type]$OutputType,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        $Caller = $PSCmdlet
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        Set-TlsLevel -Tls12

        # Sanitize double slash `//`
        # Happens when the BaseUri is the domain name
        # [Uri]"http://google.com" vs [Uri]"http://google.com/foo"
        $Uri = $Uri -replace '(?<!:)\/\/', '/'

        # pass input to local variable
        # this allows to use the PSBoundParameters for recursion
        $_headers = @{   # Set any default headers
            "Accept"         = "application/json"
            "Accept-Charset" = "utf-8"
        }
        $Headers.Keys.foreach( { $_headers[$_] = $Headers[$_] })
    }

    Process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # load DefaultParameters for Invoke-WebRequest
        # as the global PSDefaultParameterValues is not used
        $PSDefaultParameterValues = $global:PSDefaultParameterValues

        $splatParameters = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @("Uri", "Method", "InFile", "OutFile")
        $splatParameters['Headers']         = $_headers
        $splatParameters['ContentType']     = "application/json; charset=utf-8"
        $splatParameters['UseBasicParsing'] = $true
        $splatParameters['ErrorAction']     = 'Stop'
        $splatParameters['Verbose']         = $false     # Overwrites verbose output

        #add 'start' query parameter if Paging with Skip is being used
        if (($PSCmdlet.PagingParameters) -and ($PSCmdlet.PagingParameters.Skip)) {
            $GetParameters["start"] = $PSCmdlet.PagingParameters.Skip
        }
        # Append GET parameters to Uri, aka query Parameters
        if ($GetParameters -and ($Uri.Query -eq "")) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Using `$GetParameters: $($GetParameters | Out-String)"
            $splatParameters['Uri'] = [uri]"$Uri$(ConvertTo-GetParameter $GetParameters)"
            # Prevent recursive appends
            $PSBoundParameters.Remove('GetParameters') | Out-Null
            $GetParameters = $null
        }

        if ($_headers.ContainsKey("Content-Type")) {
            $splatParameters["ContentType"] = $_headers["Content-Type"]
            $_headers.Remove("Content-Type")
            $splatParameters["Headers"] = $_headers
        }

        if ($Body) {
            if ($RawBody) {
                $splatParameters["Body"] = $Body
            }
            else {
                # Encode Body to preserve special chars
                # http://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json
                $splatParameters["Body"] = [System.Text.Encoding]::UTF8.GetBytes($Body)
            }
        }

        # Invoke the API
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking method $Method to URI $URi"
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoke-WebRequest with: $(([PSCustomObject]$splatParameters) | Out-String)"
        try {
            $webResponse = Invoke-WebRequest @splatParameters
        }
        catch {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to get an answer from the server"
            $webResponse = $_
            if ($webResponse.ErrorDetails) {
                # In PowerShellCore (v6+), the response body is available as string
                $responseBody = $webResponse.ErrorDetails.Message
            }
            else {
                $webResponse = $webResponse.Exception.Response
            }
        }

        # Test response Headers if Confluence requires a CAPTCHA
        Test-Captcha -InputObject $webResponse

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Executed WebRequest. Access `$webResponse to see details"

        if ($webResponse) {
            # In PowerShellCore (v6+) the StatusCode of an exception is somewhere else
            if (-not ($statusCode = $webResponse.StatusCode)) {
                $statusCode = $webresponse.Exception.Response.StatusCode
            }
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Status code: $($statusCode)"

            if ($statusCode.value__ -ge 400) {
                Write-Warning "Confluence returned HTTP error $($statusCode.value__) - $($statusCode)"

                if ((!($responseBody)) -and ($webResponse | Get-Member -Name "GetResponseStream")) {
                    # Retrieve body of HTTP response - this contains more useful information about exactly why the error occurred
                    $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
                    $responseBody = $readStream.ReadToEnd()
                    $readStream.Close()
                }

                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Retrieved body of HTTP response for more information about the error (`$responseBody)"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Got the following error as `$responseBody"

                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    ([System.ArgumentException]"Invalid Server Response"),
                    "InvalidResponse.Status$($statusCode.value__)",
                    [System.Management.Automation.ErrorCategory]::InvalidResult,
                    $responseBody
                )

                try {
                    $responseObject = ConvertFrom-Json -InputObject $responseBody -ErrorAction Stop
                    if ($responseObject.message) {
                        $errorItem.ErrorDetails = $responseObject.message
                    }
                    else {
                        $errorItem.ErrorDetails = "An unknown error ocurred."
                    }

                }
                catch {
                    $errorItem.ErrorDetails = "An unknown error ocurred."
                }

                $Caller.WriteError($errorItem)
            }
            else {
                if ($webResponse.Content) {
                    try {
                        # API returned a Content: lets work with it
                        $response = ConvertFrom-Json ([Text.Encoding]::UTF8.GetString($webResponse.RawContentStream.ToArray()))

                        if ($null -ne $response.errors) {
                            Write-Verbose "[$($MyInvocation.MyCommand.Name)] An error response was received from; resolving"
                            # This could be handled nicely in an function such as:
                            # ResolveError $response -WriteError
                            Write-Error $($response.errors | Out-String)
                        }
                        else {
                            if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
                                [double]$Accuracy = 0.0
                                $PSCmdlet.PagingParameters.NewTotalCount($response.size, $Accuracy)
                            }
                            # None paginated results / first page of pagination
                            $result = $response
                            if (($response) -and ($response | Get-Member -Name results)) {
                                $result = $response.results
                            }
                            if ($OutputType) {
                                # Results shall be casted to custom objects (see ValidateSet)
                                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Outputting results as $($OutputType.FullName)"
                                $converter = "ConvertTo-$($OutputType.Name)"
                                $result | & $converter
                            }
                            else {
                                $result
                            }

                            # Detect if result is paginated
                            if ($response._links.next) {
                                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking pagination"

                                # Remove Parameters that don't need propagation
                                $script:PSDefaultParameterValues.Remove("$($MyInvocation.MyCommand.Name):GetParameters")
                                $script:PSDefaultParameterValues.Remove("$($MyInvocation.MyCommand.Name):IncludeTotalCount")

                                $parameters = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @("Method", "Headers", "OutputType")
                                $parameters['Uri'] = "{0}{1}" -f $response._links.base, $response._links.next

                                Write-Verbose "NEXT PAGE: $($parameters["Uri"])"

                                Invoke-Method @parameters
                            }
                        }
                    }
                    catch {
                        throw $_
                    }
                }
                else {
                    # No content, although statusCode < 400
                    # This could be wanted behavior of the API
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] No content was returned from."
                }
            }
        }
        else {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] No Web result object was returned from. This is unusual!"
        }
    }

    END {
        Set-TlsLevel -Revert

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
