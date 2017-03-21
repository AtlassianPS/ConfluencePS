function ConvertFrom-URLEncoded {
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
        [System.Web.HttpUtility]::UrlDecode($inputString)
    }
}
