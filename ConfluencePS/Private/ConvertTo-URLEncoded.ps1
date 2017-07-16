function ConvertTo-URLEncoded {
    <#
    .SYNOPSIS
    Encode a string into URL (eg: %20 instead of " ")
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # String to encode
        [Parameter( Position = 0, Mandatory = $true, ValueFromPipeline = $true )]
        [string]$InputString
    )

    PROCESS {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Encoding string to URL"
        [System.Web.HttpUtility]::UrlEncode($InputString)
    }
}
