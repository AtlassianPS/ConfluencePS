function ConvertFrom-HTMLEncoded {
    <#
    .SYNOPSIS
    Decode a HTML encoded string
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to decode
        [Parameter( Position = 0, Mandatory = $true, ValueFromPipeline = $true )]
        [string]$inputString
    )

    PROCESS {
        [System.Web.HttpUtility]::HtmlEncode($inputString)
    }
}
