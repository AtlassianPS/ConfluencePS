function Test-Captcha {
    [CmdletBinding()]
    param(
        # Response of Invoke-WebRequest
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [PSObject]$InputObject
    )

    begin {
        $tokenRequiresCaptcha = "AUTHENTICATION_DENIED"
        $headerRequiresCaptcha = "X-Seraph-LoginReason"
    }

    process {
        if ($InputObject.Headers -and $InputObject.Headers[$headerRequiresCaptcha]) {
            if ( ($InputObject.Headers[$headerRequiresCaptcha] -split ",") -contains $tokenRequiresCaptcha ) {
                Write-Warning "Confluence requires you to log on to the website before continuing for security reasons."
            }
        }
    }

    end {
    }
}
