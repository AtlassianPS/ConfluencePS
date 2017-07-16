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
        [string]$InputString
    )

    PROCESS {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Decoding string from HTML"
        [System.Web.HttpUtility]::HtmlEncode($InputString)
    }
}
