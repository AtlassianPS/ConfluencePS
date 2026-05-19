function Test-ServerResponse {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [PSObject]$InputObject,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        [Int32]$RetryCount = 0,

        [Int32]$MaxRetries = 3
    )

    process {
        if (-not $InputObject -or -not $InputObject.StatusCode) {
            return
        }

        $statusCode = [int]$InputObject.StatusCode
        if ($statusCode -notin @(429, 503)) {
            return
        }

        if ($RetryCount -ge $MaxRetries) {
            return
        }

        $idempotentMethods = @(
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Get
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Head
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Put
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Delete
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Options
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Trace
        )
        if ($Method -notin $idempotentMethods) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Not retrying non-idempotent method '$Method'."
            return
        }

        $retryAfter = 0
        $hasRetryAfterHeader = $false
        $retryAfterHeader = $null

        if ($InputObject.PSObject.Properties.Name -contains "Headers" -and $InputObject.Headers) {
            $headers = $InputObject.Headers

            if ($headers -is [System.Collections.IDictionary]) {
                if ($headers.Contains("Retry-After")) {
                    $hasRetryAfterHeader = $true
                    $retryAfterHeader = [string]$headers["Retry-After"]
                }
            }
            else {
                if (($headers.PSObject.Properties.Name -contains "RetryAfter") -and $headers.RetryAfter) {
                    $hasRetryAfterHeader = $true
                    if ($headers.RetryAfter.Delta) {
                        $retryAfter = [Math]::Ceiling($headers.RetryAfter.Delta.TotalSeconds)
                    }
                    elseif ($headers.RetryAfter.Date) {
                        $retryAfter = [Math]::Ceiling(($headers.RetryAfter.Date.Value.ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalSeconds)
                    }
                }

                if (-not $hasRetryAfterHeader -and ($headers.PSObject.Methods.Name -contains "TryGetValues")) {
                    $headerValues = [string[]]@()
                    if ($headers.TryGetValues("Retry-After", [ref]$headerValues) -and $headerValues.Count -gt 0) {
                        $hasRetryAfterHeader = $true
                        $retryAfterHeader = [string]$headerValues[0]
                    }
                }
            }
        }

        if ($hasRetryAfterHeader -and $retryAfter -le 0 -and $retryAfterHeader) {
            $retryAfterSeconds = 0
            if ([Int32]::TryParse($retryAfterHeader, [ref]$retryAfterSeconds)) {
                $retryAfter = $retryAfterSeconds
            }
            else {
                $retryAt = [DateTimeOffset]::MinValue
                if ([DateTimeOffset]::TryParse($retryAfterHeader, [ref]$retryAt)) {
                    $retryAfter = [Math]::Ceiling(($retryAt.ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalSeconds)
                }
            }
        }

        if ($hasRetryAfterHeader -and $retryAfter -gt 0) {
            # Respect server-provided Retry-After as a minimum wait value.
            $retryDelay = [double]$retryAfter
        }
        else {
            $retryAfter = [Math]::Pow(2, $RetryCount + 1) * 10

            $maxRetryDelay = 60
            $jitter = Get-Random -Minimum 0.5 -Maximum 1.0
            $retryDelay = [Math]::Min($maxRetryDelay, $retryAfter) * $jitter
        }

        $statusName = switch ($statusCode) {
            429 { "Too Many Requests" }
            503 { "Service Unavailable" }
            default { "Recoverable Error" }
        }

        Write-Warning "[$($MyInvocation.MyCommand.Name)] $statusName (HTTP $statusCode). Retrying in $([Math]::Round($retryDelay, 1)) seconds (attempt $($RetryCount + 1) of $MaxRetries)."
        Start-Sleep -Seconds $retryDelay
        return $true
    }
}
