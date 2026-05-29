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
        [ConfluencePS.Attachment],
        [ConfluencePS.ServerInformation]
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute( "PSAvoidUsingEmptyCatchBlock", "" )]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [Uri]$Uri,

        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = "GET",

        [ValidateNotNullOrEmpty()]
        [String]$Body,

        [Switch]$RawBody,

        [Hashtable]$Headers,

        [Hashtable]$GetParameters,

        [String]$InFile,

        [String]$OutFile,

        [ValidateRange(0, [Int32]::MaxValue)]
        [Int32]$TimeoutSec = 100,

        [ValidateSet(
            [ConfluencePS.Page],
            [ConfluencePS.Space],
            [ConfluencePS.Label],
            [ConfluencePS.Icon],
            [ConfluencePS.Version],
            [ConfluencePS.User],
            [ConfluencePS.Attachment],
            [ConfluencePS.ServerInformation]
        )]
        [System.Type]$OutputType,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [String]
        $PersonalAccessToken,

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
        $convertFromJsonSupportsAsHashtable = (Get-Command -Name ConvertFrom-Json).Parameters.ContainsKey("AsHashtable")

        $splatParameters = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @("Uri", "Method", "InFile", "OutFile")
        $splatParameters['Headers'] = $_headers
        $splatParameters['ContentType'] = "application/json; charset=utf-8"
        $splatParameters['UseBasicParsing'] = $true
        $splatParameters['ErrorAction'] = 'Stop'
        $splatParameters['Verbose'] = $false     # Overwrites verbose output
        if (Test-ShouldPreserveAuthorizationOnRedirect -Uri $Uri -OutFile $OutFile -Credential $Credential -PersonalAccessToken $PersonalAccessToken) {
            $secureCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(
                    $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password)
                ))
            $splatParameters['Headers']['Authorization'] = "Basic $($secureCreds)"
            $null = $splatParameters.Remove('Credential')
        }
        if ($TimeoutSec -gt 0) {
            $splatParameters["TimeoutSec"] = $TimeoutSec
        }
        if (
            ($PSVersionTable.PSVersion.Major -ge 6) -and
            ($Uri.Scheme -eq "http") -and
            ($Credential -or $PersonalAccessToken) -and
            ($Uri.Host -in @("localhost", "127.0.0.1", "::1"))
        ) {
            $allowUnencryptedAuthentication = (
                @('1', 'true', 'yes') -contains "$($env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH)".Trim().ToLowerInvariant()
            ) -and (
                @('localhost', '127.0.0.1', '::1') -contains $Uri.Host
            )

            if ($allowUnencryptedAuthentication) {
                $splatParameters["AllowUnencryptedAuthentication"] = $true
            }
        }

        #add 'start' query parameter if Paging with Skip is being used
        if (($PSCmdlet.PagingParameters) -and ($PSCmdlet.PagingParameters.Skip)) {
            $GetParameters["start"] = $PSCmdlet.PagingParameters.Skip
        }
        $paginationGetParameters = $null
        if ($GetParameters) {
            $paginationGetParameters = $GetParameters.Clone()
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
        $webException = $null
        $retryCount = 0
        $maxRetries = 3
        $getResponseBody = {
            param($Response)

            if (-not $Response) {
                return $null
            }

            if ($Response.Content) {
                if ($Response.Content -is [string]) {
                    return [string]$Response.Content
                }

                if ($Response.Content -is [System.Net.Http.HttpContent]) {
                    try {
                        return $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                    }
                    catch {
                    }
                }

                if ($Response.Content.PSObject.Methods.Name -contains "ReadAsStringAsync") {
                    try {
                        return $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                    }
                    catch {
                    }
                }
            }

            if (($Response | Get-Member -Name "RawContentStream") -and $Response.RawContentStream) {
                try {
                    return [Text.Encoding]::UTF8.GetString($Response.RawContentStream.ToArray())
                }
                catch {
                }
            }

            if ($Response | Get-Member -Name "GetResponseStream") {
                try {
                    $readStream = New-Object -TypeName System.IO.StreamReader -ArgumentList ($Response.GetResponseStream())
                    $body = $readStream.ReadToEnd()
                    $readStream.Close()
                    return $body
                }
                catch {
                }
            }

            return $null
        }

        do {
            $responseBody = $null

            try {
                $webResponse = Invoke-WebRequest @splatParameters
                $webException = $null
            }
            catch {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Failed to get an answer from the server"
                $webException = $_
                if ($webException.ErrorDetails) {
                    # In PowerShellCore (v6+), the response body is available as string
                    $responseBody = $webException.ErrorDetails.Message
                }
                $webResponse = $webException.Exception.Response

                if (-not $webResponse) {
                    throw $webException
                }

                if (-not $responseBody) {
                    $responseBody = & $getResponseBody $webResponse
                }
            }

            # Test response Headers if Confluence requires a CAPTCHA
            Test-Captcha -InputObject $webResponse

            $shouldRetry = Test-ServerResponse -InputObject $webResponse -Method $Method -RetryCount $retryCount -MaxRetries $maxRetries
            if ($shouldRetry) {
                $retryCount++
            }
        }
        while ($shouldRetry)

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Executed WebRequest. Access `$webResponse to see details"

        if ($webResponse) {
            # In PowerShellCore (v6+) the StatusCode of an exception is somewhere else
            if (-not ($statusCode = $webResponse.StatusCode)) {
                $statusCode = $webresponse.Exception.Response.StatusCode
            }
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Status code: $($statusCode)"

            if ($statusCode.value__ -ge 400) {
                Write-Warning "Confluence returned HTTP error $($statusCode.value__) - $($statusCode)"

                if (-not $responseBody) {
                    $responseBody = & $getResponseBody $webResponse
                }

                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Retrieved body of HTTP response for more information about the error (`$responseBody)"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Got the following error as `$responseBody"

                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    ([System.ArgumentException]"Invalid Server Response"),
                    "InvalidResponse.Status$($statusCode.value__)",
                    [System.Management.Automation.ErrorCategory]::InvalidResult,
                    $responseBody
                )

                $errorMessages = @()
                try {
                    $convertFromJsonParameters = @{
                        InputObject = $responseBody
                        ErrorAction = 'Stop'
                    }
                    if ($convertFromJsonSupportsAsHashtable) {
                        $convertFromJsonParameters['AsHashtable'] = $true
                    }

                    $responseObject = ConvertFrom-Json @convertFromJsonParameters
                    if ($responseObject.message) {
                        $errorMessages += [string]$responseObject.message
                    }
                    if ($responseObject.errorMessages) {
                        $errorMessages += @($responseObject.errorMessages | ForEach-Object { [string]$_ })
                    }
                    if ($responseObject.errors) {
                        if ($responseObject.errors -is [hashtable]) {
                            $errorMessages += @($responseObject.errors.Values | ForEach-Object { [string]$_ })
                        }
                        elseif (($responseObject.errors -is [System.Management.Automation.PSObject]) -and ($responseObject.errors -isnot [string])) {
                            $errorMessages += @($responseObject.errors.PSObject.Properties | ForEach-Object { [string]$_.Value })
                        }
                        else {
                            $errorMessages += @($responseObject.errors | ForEach-Object { [string]$_ })
                        }
                    }
                }
                catch {
                    # Fall back to raw response body below.
                }

                if ($errorMessages.Count -eq 0) {
                    if ($responseBody) {
                        $errorMessages = @([string]$responseBody)
                    }
                    else {
                        $errorMessages = @("An unknown error occurred.")
                    }
                }

                $errorItem.ErrorDetails = [System.Management.Automation.ErrorDetails]::new(($errorMessages -join [Environment]::NewLine))
                $Caller.WriteError($errorItem)
            }
            else {
                if ($webResponse.Content) {
                    try {
                        # API returned a Content: lets work with it
                        $jsonResponseBody = [Text.Encoding]::UTF8.GetString($webResponse.RawContentStream.ToArray())
                        $convertFromJsonParameters = @{
                            InputObject = $jsonResponseBody
                            ErrorAction = 'Stop'
                        }
                        try {
                            $response = ConvertFrom-Json @convertFromJsonParameters
                        }
                        catch {
                            if (-not $convertFromJsonSupportsAsHashtable) {
                                throw
                            }

                            # Confluence occasionally sends duplicate keys that differ only by case.
                            $convertFromJsonParameters['AsHashtable'] = $true
                            $response = ConvertFrom-Json @convertFromJsonParameters
                        }

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
                            $hasResults = $false
                            if ($response -is [System.Collections.IDictionary]) {
                                $hasResults = $response.Contains("results")
                            }
                            elseif (($response) -and ($response | Get-Member -Name results)) {
                                $hasResults = $true
                            }
                            if ($hasResults) {
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

                                $parameters = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @("Method", "Headers", "OutputType", "TimeoutSec")
                                $parameters['Uri'] = "{0}{1}" -f $response._links.base, $response._links.next
                                if ($paginationGetParameters) {
                                    $parameters['GetParameters'] = $paginationGetParameters
                                    $nextUriBuilder = [System.UriBuilder]$parameters['Uri']
                                    $nextQueryParameters = [System.Web.HttpUtility]::ParseQueryString($nextUriBuilder.Query)
                                    foreach ($key in $paginationGetParameters.Keys) {
                                        if ($nextQueryParameters.AllKeys -notcontains $key) {
                                            $nextQueryParameters[[string]$key] = [string]$paginationGetParameters[$key]
                                        }
                                    }
                                    $nextUriBuilder.Query = $nextQueryParameters.ToString()
                                    $parameters['Uri'] = $nextUriBuilder.Uri
                                }

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
