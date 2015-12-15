function ConvertTo-ConfStorageFormat {
    <#
    .SYNOPSIS
    Convert your content to Confluence's storage format.

    .DESCRIPTION
    To properly create/edit pages, content should be in the proper "XHTML-based" format.
    Invokes a POST call to convert from a "wiki" representation, receiving a "storage" response.
    https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html

    .PARAMETER Content
    A string (in plain text and/or wiki markup) to be converted to storage format.

    .EXAMPLE
    $Body = ConvertTo-ConfStorageFormat -Content 'Hello world!'
    Stores the returned value '<p>Hello world!</p>' in $Body for use in New-ConfPage/Set-ConfPage/etc.

    .EXAMPLE
    Get-Date -Format s | ConvertTo-ConfStorageFormat
    Returns the current date/time in sortable format, and converts via pipeline input.

    .EXAMPLE
    New-ConfPage -Title 'Loner Page' -SpaceKey TEST -Body $Body -Convert -Verbose
    Creates a new page at the root of the specified space (no parent page). Verbose flag enabled.
    Need to invoke ConvertTo-ConfStorageFormat on $Body to prep it for page creation.

    .LINK
    New-ConfPage

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding()]
    param (
		[Parameter(Mandatory=$true, ValueFromPipeline = $true)]
		[string]$Content
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-ConfInfo'
            Set-ConfInfo
        }
    }

    PROCESS {
        $URI = $BaseURI + '/contentbody/convert/storage'

        $Body = @{value          = "$Content"
                  representation = 'wiki'
                 } | ConvertTo-Json

        $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Body $Body -Method Post -ContentType 'application/json'

        $Rest.value
    }
}
