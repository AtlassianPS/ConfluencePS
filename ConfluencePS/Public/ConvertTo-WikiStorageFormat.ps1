function ConvertTo-WikiStorageFormat {
    <#
    .SYNOPSIS
    Convert your content to Confluence's storage format.

    .DESCRIPTION
    To properly create/edit pages, content should be in the proper "XHTML-based" format.
    Invokes a POST call to convert from a "wiki" representation, receiving a "storage" response.
    https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html

    .EXAMPLE
    $Body = ConvertTo-WikiStorageFormat -Content 'Hello world!'
    Stores the returned value '<p>Hello world!</p>' in $Body for use in New-WikiPage/Set-WikiPage/etc.

    .EXAMPLE
    Get-Date -Format s | ConvertTo-WikiStorageFormat
    Returns the current date/time in sortable format, and converts via pipeline input.

    .EXAMPLE
    New-WikiPage -Title 'Loner Page' -SpaceKey TEST -Body $Body -Convert -Verbose
    Creates a new page at the root of the specified space (no parent page). Verbose flag enabled.
    Need to invoke ConvertTo-WikiStorageFormat on $Body to prep it for page creation.

    .LINK
    New-WikiPage

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding()]
    param (
        # A string (in plain text and/or wiki markup) to be converted to storage format.
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [string]$Content
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        $URI = "$BaseURI/contentbody/convert/storage"

        $Body = @{
            value = "$Content"
            representation = 'wiki'
        } | ConvertTo-Json

        $response = Invoke-WikiMethod -Uri $URI -Body $Body -Method Post
        $response.value
    }
}
