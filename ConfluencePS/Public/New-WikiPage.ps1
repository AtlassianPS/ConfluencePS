function New-WikiPage {
    <#
    .SYNOPSIS
    Create a new page in your Confluence instance.

    .DESCRIPTION
    Create a new page in Confluence. Optionally include content in -Body.
    Content needs to be in "Confluence storage format;" see also -Convert.

    .EXAMPLE
    New-WikiPage -Title 'Test New Page' -ParentID 123456 -Body '<p>Hello world</p>' -WhatIf
    Creates a new test page (as a child member of existing page 123456) with one line of page text.
    Automatically finds 123456 in space 'ABC' via Get-WikiPage and applies the key to the REST post.
    -WhatIf support, so the page will not actually be created.

    .EXAMPLE
    Get-WikiPage -Title 'Darth Vader' | New-WikiPage -Title 'Luke Skywalker' -Body $Body -Confirm
    Searches for pages named *Darth Vader*, pipes page ID and space key. New page is a child of existing page.
    Note that this can grab multiple pages via wildcard matching, potentially attempting multiple posts.
    You will be asked to confirm each creation. Choose wisely.

    .EXAMPLE
    New-WikiPage -Title 'Loner Page' -SpaceKey TEST -Body $Body -Convert -Verbose
    Creates a new page at the root of the specified space (no parent page). Verbose flag enabled.
    $Body is not yet in Confluence storage format ("XHTML-based"), and needs to be converted.

    .LINK
    Get-WikiPage

    .LINK
    ConvertTo-WikiStorageFormat

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([ConfluencePS.Page])]
    param (
        # Name of your new page.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Alias('Name')]
        [string]$Title,

        # The ID of the parent page. Accepts pipeline input by value/name.
        # NOTE: This feature is not in the 5.8 REST API documentation, and should be considered experimental.
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ParentID,

        # Key of the space where the new page should exist. Only needed if you don't utilize ParentID.
        [string]$SpaceKey,

        # The contents of your new page. Accepts pipeline input by property name.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Body,

        # Optional flag to call ConvertTo-WikiStorageFormat against your Body.
        [switch]$Convert
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"

        If (($ParentID) -and !($SpaceKey)) {
            Write-Verbose "SpaceKey not specified. Retrieving from Get-WikiPage -PageID $Parent"
            $SpaceKey = (Get-WikiPage -PageID $ParentID).Space.Key
        }

        # If -Convert is flagged, call ConvertTo-WikiStorageFormat against the -Body
        If ($Convert) {
            Write-Verbose '-Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-WikiStorageFormat -Content $Body
        }

        $URI = "$BaseURI/content"

        $Content = @{
            type = "page"
            title = $Title
            space = @{key = $SpaceKey}
            body = @{
                storage = @{
                    value = $Body
                    representation = 'storage'
                }
            }
        }
        # Ancestors is undocumented! May break in the future
        # http://stackoverflow.com/questions/23523705/how-to-create-new-page-in-confluence-using-their-rest-api
        if ($ParentID) {
            $Content["ancestors"] = @( @{ id = $ParentID } )
        }
        $Content = $Content | ConvertTo-Json

        Write-Verbose "Posting to $URI"
        Write-Verbose "Content: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("Space $SpaceKey, Parent $ParentID")) {
            $response = Invoke-WikiMethod -Uri $URI -Body $Content -Method Post
            if ($response) { $response | ConvertTo-WikiPage }
        }
    }
}
