function ConvertFrom-HTMLEncoded {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to decode
        [Parameter(
            Position = $true,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]$inputString
    )

    PROCESS {
        [System.Web.HttpUtility]::HtmlEncode($inputString)
    }
}
