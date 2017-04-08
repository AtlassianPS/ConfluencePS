function ConvertTo-HTMLEncoded {
    <#
    .SYNOPSIS
    Encode a string into HTML (eg: &gt; instead of >)
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to encode
        [Parameter( Position = $true, Mandatory = $true, ValueFromPipeline = $true )]
        [string]$inputString
    )

    PROCESS {
        [System.Web.HttpUtility]::HtmlEncode($inputString)
    }
}
