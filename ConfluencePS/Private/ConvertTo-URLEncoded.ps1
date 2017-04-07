function ConvertTo-URLEncoded {
    <#
    .SYNOPSIS
    Encode a string into URL (eg: %20 instead of " ")
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to encode
        [Parameter( Position = $true, Mandatory = $true, ValueFromPipeline = $true )]
        [string]$inputString
    )

    PROCESS {
        [System.Web.HttpUtility]::UrlEncode($inputString)
    }
}
