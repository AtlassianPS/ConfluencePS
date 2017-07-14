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
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method = "GET",

        # Body of the request
        [ValidateNotNullOrEmpty()]
        [string]$Body,

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
        [PSCredential]$Credential
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        # Validation of parameters
        if (($Method -in ("POST", "PUT")) -and (!($Body))) {
            $message = "The following parameters are required when using the ${Method} parameter: Body."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # pass input to local variable
        # this allows to use the PSBoundParameters for recursion
        $_headers = $Headers

        # Add Basic Authentication to Header
        $SecureCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(
                $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password)
            ))
        $_headers += @{
            "Authorization" = "Basic $($SecureCreds)"
            'Content-Type'  = 'application/json; charset=utf-8'
        }
    }

    Process {
        # Append GET parameters to URi
        if (($PSCmdlet.PagingParameters) -and ($PSCmdlet.PagingParameters.Skip)) {
            $GetParameters["start"] = $PSCmdlet.PagingParameters.Skip
        }
        if ($GetParameters -and ($URi -notlike "*\?*")) {
            Write-Debug "Using `$GetParameters: $($GetParameters | Out-String)"
            [string]$URI += (ConvertTo-GetParameter $GetParameters)
            # Prevent recursive appends
            $GetParameters = $null
        }

        # set mandatory parameters
        $splatParameters = @{
            Uri             = $URi
            Method          = $Method
            Headers         = $_headers
            UseBasicParsing = $true
            ErrorAction     = 'SilentlyContinue'
        }

        # set optional parameters
        # http://stackoverflow.com/questions/15290185/invoke-webrequest-issue-with-special-characters-in-json
        if ($Body) {$splatParameters["Body"] = [System.Text.Encoding]::UTF8.GetBytes($Body)}

        # load DefaultParameters for Invoke-WebRequest
        # as the global PSDefaultParameterValues is not used
        # TODO: find out why PSJira doesn't need this
        $script:PSDefaultParameterValues = $global:PSDefaultParameterValues

        # Invoke the API
        try {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking method $Method to URI $URi"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoke-WebRequest with: $($splatParameters | Out-String)"
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
            else {
                if ($webResponse.Content) {
                    # API returned a Content: lets work wit it
                    $response = ConvertFrom-Json -InputObject $webResponse.Content

                    if ($response.errors -ne $null) {
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
                                URi    = "{0}{1}" -f $response._links.base, $response._links.next
                                Method = $Method
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
