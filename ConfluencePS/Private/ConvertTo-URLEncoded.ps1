function ConvertTo-URLEncoded {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to encode
        [Parameter(
            Position = $true,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]$inputString
    )

    PROCESS {
        [System.Web.HttpUtility]::UrlEncode($inputString)
    }
}
