function Invoke-WikiMethod {
    <#
    .SYNOPSIS
    Extracted invokation of the REST method to own function.
    #>
    [CmdletBinding()]
    [OutputType( [PSObject] )]
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
        [hashtable]$Headers,

        # GET Parameters
        [hashtable]$GetParameters,

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

    Process {
        # Validation of parameters
        if (($Method -in ("POST", "PUT")) -and (!($Body))) {
            $message = "The following parameters are required when using the ${Method} parameter: Body."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        if (!($Credential) -and ($script:Credential)) {
            # This allows for the Credential parameter to be used
            # and if missing, the Set-WikiInfo Credentials will be used
            $Credential = $script:Credential
            Write-Verbose "Using HTTP Basic authentication with username $($Credential.UserName)"
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
            'Content-Type' = 'application/json; charset=utf-8'
        }

        # Append GET parameters to URi
        if ($GetParameters) {
            Write-Debug "Using `$GetParameters: $($GetParameters | Out-String)"
            [string]$URI += (ConvertTo-GetParameter $GetParameters)
        }

        # set mandatory parameters
        $splatParameters = @{
            Uri = $URi
            Method = $Method
            Headers = $_headers
            UseBasicParsing = $true
            ErrorAction = 'SilentlyContinue'
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
            Write-Verbose "[Invoke-WikiMethod] Invoking method $Method to URI $URi"
            Write-Debug "[Invoke-WikiMethod] Invoke-WebRequest with: $($splatParameters | Out-String)"
            $webResponse = Invoke-WebRequest @splatParameters
        }
        catch {
            # Invoke-WebRequest is hard-coded to throw an exception if the Web request returns a 4xx or 5xx error.
            # This is the best workaround I can find to retrieve the actual results of the request.
            # This shall be fixed with PoSh v6: https://github.com/PowerShell/PowerShell/issues/2193
            Write-Verbose "[Invoke-WikiMethod] Failed to get an anser from the server"
            $webResponse = $_.Exception.Response
        }

        Write-Debug "[Invoke-WikiMethod] Executed WebRequest. Access `$webResponse to see details"

        if ($webResponse) {
            Write-Verbose "[Invoke-WikiMethod] Status code: $($webResponse.StatusCode)"

            if ($webResponse.StatusCode.value__ -ge 400) {
                Write-Warning "Conflunce returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

                # Retrieve body of HTTP response - this contains more useful information about exactly why the error occurred
                $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
                $responseBody = $readStream.ReadToEnd()
                $readStream.Close()

                Write-Verbose "[Invoke-WikiMethod] Retrieved body of HTTP response for more information about the error (`$responseBody)"
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
                    $result = ConvertFrom-Json -InputObject $webResponse.Content
                }
                else {
                    # No content, although statusCode < 400
                    # This could be wanted behavior of the API
                    Write-Verbose "[Invoke-WikiMethod] No content was returned from."
                }
            }

            if ($result.errors -ne $null) {
                Write-Verbose "[Invoke-WikiMethod] An error response was received from; resolving"
                # This could be handled nicely in an function such as:
                # ResolveError $result -WriteError
                Write-Error $($result.errors | Out-String)
            }
            else {
                # Dected if result is paginated
                if ($result._links.next) {
                    Write-Verbose "[Invoke-WikiMethod] Invoking pagination"

                    # Self-Invoke function for recursion
                    $parameters = @{
                        URi = "{0}{1}" -f $result._links.base, $result._links.next
                        Method = $Method
                    }
                    if ($Body) {$parameters["Body"] = $Body}
                    if ($Headers) {$parameters["Headers"] = $Headers}
                    if ($GetParameters) {$parameters["Get$GetParameters"] = $GetParameters}

                    # Append results
                    $result.results += (Invoke-WikiMethod @parameters)
                }

                # Extract results from array
                # This allows for harmonized handling of single or multiple results
                if (($result) -and ($result | Get-Member -Name results)) {
                    $result = $result | Select-Object -ExpandProperty results
                }

                if ($OutputType) {
                    # Results shall be casted to custom objects (see ValidateSet)
                    Write-Verbose "[Invoke-WikiMethod] Outputting results as $($OutputType.FullName)"
                    $convertFunction = "ConvertTo-Wiki$($OutputType.Name)"

                    # We need to test if there is 1+ result to convert
                    # If not, we would return an empty object
                    if (($result | Measure-Object).count -ge 1) {
                        foreach ($item in $result) {
                            # Use private function `ConvertTo-Wiki<ObjectName>` to cast objects
                            Write-Output ($item | & $convertFunction)
                        }
                    }
                }
                else {
                    # Return results as PSCustomObject
                    Write-Verbose "[Invoke-WikiMethod] Outputting results as PSCustomObject"
                    Write-Output $result
                }
            }
        }
        else {
            Write-Verbose "[Invoke-WikiMethod] No Web result object was returned from. This is unusual!"
        }
    }
}
