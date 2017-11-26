function Invoke-Method {
    <#
    .SYNOPSIS
    Extracted invokation of the REST method to own function.
    #>
    [CmdletBinding(SupportsPaging = $true)]
    [OutputType(
        [PSObject],
        [ConfluencePS.Page],
        [ConfluencePS.Space],
        [ConfluencePS.Label],
        [ConfluencePS.Icon],
        [ConfluencePS.Version],
        [ConfluencePS.User]
    )]
    param (
        # REST API to invoke
        [Parameter(Mandatory = $true)]
        [Uri]$URi,

        # Method of the invokation
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = "GET",

        # Body of the request
        [ValidateNotNullOrEmpty()]
        [String]$Body,

        # Do not encode the body
        [Switch]$RawBody,

        # Additional headers
        [Hashtable]$Headers,

        # GET Parameters
        [Hashtable]$GetParameters,

        # Type of object to which the output will be casted to
        [ValidateSet(
            [ConfluencePS.Page],
            [ConfluencePS.Space],
            [ConfluencePS.Label],
            [ConfluencePS.Icon],
            [ConfluencePS.Version],
            [ConfluencePS.User]
        )]
        [System.Type]$OutputType,

        # Authentication credentials
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential,

        $Caller = $PSCmdlet
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        # Validation of parameters
        if (($Method -in ("POST", "PUT")) -and (!($Body))) {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.ArgumentException]"Invalid Parameter"),
                'ParameterProperties.IncorrectType',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Method
            )
            $errorItem.ErrorDetails = "The following parameters are required when using the $Method parameter: Body."
            $Caller.ThrowTerminatingError($errorItem)
        }

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

        # Append GET parameters to URi
        if (($PSCmdlet.PagingParameters) -and ($PSCmdlet.PagingParameters.Skip)) {
            $GetParameters["start"] = $PSCmdlet.PagingParameters.Skip
        }
        if ($GetParameters -and ($URi -notlike "*\?*")) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Using `$GetParameters: $($GetParameters | Out-String)"
            [Uri]$URI = "$Uri$(ConvertTo-GetParameter $GetParameters)"
            # Prevent recursive appends
            $GetParameters = $null
        }

        # set mandatory parameters
        $splatParameters = @{
            Uri             = $URi
            Method          = $Method
            Headers         = $_headers
            ContentType     = "application/json; charset=utf-8"
            UseBasicParsing = $true
            Credential      = $Credential
            ErrorAction     = "Stop"
            Verbose         = $false     # Overwrites verbose output
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
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking method $Method to URI $URi"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoke-WebRequest with: $(([PSCustomObject]$splatParameters) | Out-String)"
            $webResponse = Invoke-WebRequest @splatParameters
        }
        catch {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to get an answer from the server"
            $webResponse = $_
            if ($webResponse.ErrorDetails) {
                # In PowerShellCore (v6+), the response body is available as string
                $responseBody = $webResponse.ErrorDetails.Message
            }
            $webResponse = $webResponse.Exception.Response
        }

        # Test response Headers if Confluence requires a CAPTCHA
        Test-Captcha -InputObject $webResponse

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Executed WebRequest. Access `$webResponse to see details"

        if ($webResponse) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Status code: $($webResponse.StatusCode)"

            if ($webResponse.StatusCode.value__ -ge 400) {
                Write-Warning "Confluence returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

                if ((!($responseBody)) -and ($webResponse | Get-Member -Name "GetResponseStream")) {
                    # Retrieve body of HTTP response - this contains more useful information about exactly why the error occurred
                    $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
                    $responseBody = $readStream.ReadToEnd()
                    $readStream.Close()
                }

                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Retrieved body of HTTP response for more information about the error (`$responseBody)"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Got the following error as `$responseBody"
                # try {
                    $responseObject = ConvertFrom-Json -InputObject $responseBody -ErrorAction Stop

                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Invalid Parameter"),
                        'ParameterProperties.IncorrectType',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $Method
                    )
                    $errorItem.ErrorDetails = $responseObject.message
                    $Caller.ThrowTerminatingError($errorItem)
                # }
                # catch {
                    # $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    #     ([System.ArgumentException]"Invalid Parameter"),
                    #     'ParameterProperties.IncorrectType',
                    #     [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    #     $Method
                    # )
                    # $errorItem.ErrorDetails = $responseBody.message
                    # $Caller.WriteError($errorItem)
                # }
            }
            else {
                if ($webResponse.Content) {
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

                            # Self-Invoke function for recursion
                            $parameters = @{
                                URi        = "{0}{1}" -f $response._links.base, $response._links.next
                                Method     = $Method
                                Credential = $Credential
                            }
                            if ($Body) {$parameters["Body"] = $Body}
                            if ($Headers) {$parameters["Headers"] = $Headers}
                            if ($OutputType) {$parameters["OutputType"] = $OutputType}

                            Write-Verbose "NEXT PAGE: $($parameters["URi"])"

                            Invoke-Method @parameters
                        }
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
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
