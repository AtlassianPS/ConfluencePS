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

        # Authentication credentials
        [PSCredential]$Credential
    )

    Process {
        # Validation
        if (($Method -in ("POST", "PUT")) -and (!($Body))) {
            Throw "Missing request body"
        }
        if (!($Credential) -and ($script:Credential)) {
            # This allows for the Credential parameter to be used
            # and if missing, the Set-WikiInfo Credentials will be used
            $Credential = $script:Credential
            Write-Verbose "Using HTTP Basic authentication with username $($Credential.UserName)"
        }

        $SecureCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(
            $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password)
        ))
        $Headers += @{
            "Authorization" = "Basic $($SecureCreds)"
            'Content-Type' = 'application/json; charset=utf-8'
        }

        # set mandatory parameters
        $splatParameters = @{
            Uri = $URi
            Method = $Method
            Headers = $Headers
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
            Write-Verbose "[Invoke-WikiMethod] Invoking method $Method to URI $URI"
            Write-Debug "[Invoke-WikiMethod] invoke-WebRequest with: $($splatParameters | Out-String)"
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

            if ($webResponse.StatusCode.value__ -gt 399) {
                Write-Warning "Conflunce returned HTTP error $($webResponse.StatusCode.value__) - $($webResponse.StatusCode)"

                # Retrieve body of HTTP response - this contains more useful information about exactly why the error
                # occurred
                $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($webResponse.GetResponseStream())
                $responseBody = $readStream.ReadToEnd()
                $readStream.Close()

                Write-Verbose "[Invoke-WikiMethod] Retrieved body of HTTP response for more information about the error (`$responseBody)"
                try {
                    $responseObject = ConvertFrom-Json -InputObject $responseBody -ErrorAction Stop
                    if ($responseObject.message) {
                        Write-Error $responseObject.message
                    } else {throw}
                }
                catch {
                    Write-Error $responseBody
                }
            }
            else {
                if ($webResponse.Content) {
                    $result = ConvertFrom-Json -InputObject $webResponse.Content
                }
                else {
                    Write-Verbose "[Invoke-WikiMethod] No content was returned from."
                }
            }

            if ($result.errors -ne $null) {
                Write-Verbose "[Invoke-WikiMethod] An error response was received from; resolving"
                # ResolveError $result -WriteError
                Write-Error $($result.errors | Out-String)
            }
            else {
                Write-Verbose "[Invoke-WikiMethod] Outputting results from"
                Write-Output $result
            }
        }
        else {
            Write-Verbose "[Invoke-WikiMethod] No Web result object was returned from. This is unusual!"
            Write-Warning "[Invoke-WikiMethod] No Web result object was returned from. This is unusual!"
        }
    }
}
