function ConvertFrom-URLEncoded {
    <#
    .SYNOPSIS
    Decode a URL encoded string
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to decode
        [Parameter( Position = 0, Mandatory = $true, ValueFromPipeline = $true )]
        [string]$InputString
    )

    PROCESS {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Decoding string from URL"
        [System.Web.HttpUtility]::UrlDecode($InputString)
    }
}
