function ConvertTo-StorageFormat {
    <#
    .SYNOPSIS
    Convert your content to Confluence's storage format.

    .DESCRIPTION
    To properly create/edit pages, content should be in the proper "XHTML-based" format.
    Invokes a POST call to convert from a "wiki" representation, receiving a "storage" response.
    https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html

    .EXAMPLE
    $Body = ConvertTo-ConfluenceStorageFormat -Content 'Hello world!'
    Stores the returned value '<p>Hello world!</p>' in $Body for use in New-ConfluencePage/Set-ConfluencePage/etc.

    .EXAMPLE
    Get-Date -Format s | ConvertTo-ConfluenceStorageFormat -ApiURi "https://myserver.com/wiki" -Credential $cred
    Returns the current date/time in sortable format, and converts via pipeline input.

    .EXAMPLE
    New-ConfluencePage -Title 'Loner Page' -SpaceKey TEST -Body $Body -Convert -Verbose
    Creates a new page at the root of the specified space (no parent page). Verbose flag enabled.
    Need to invoke ConvertTo-ConfluenceStorageFormat on $Body to prep it for page creation.

    .LINK
    New-ConfluencePage

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding()]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # A string (in plain text and/or wiki markup) to be converted to storage format.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]$Content
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Uri        = "$apiURi/contentbody/convert/storage"
            Method     = 'Post'
            Body       = @{
                value          = "$Content"
                representation = 'wiki'
            } | ConvertTo-Json
            Credential = $Credential
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        (Invoke-Method @iwParameters).value
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
