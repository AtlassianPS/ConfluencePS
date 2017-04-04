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
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'byParameters'
    )]
    [OutputType([ConfluencePS.Page])]
    param (
        # Page Object
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byObject'
        )]
        [ConfluencePS.Page]$InputObject,

        # Name of your new page.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [Alias('Name')]
        [string]$Title,

        # The ID of the parent page.
        # NOTE: This feature is not in the 5.8 REST API documentation, and should be considered experimental.
        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ParentID,
        # Page Object of the parent page.
        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Page]$Parent,

        # Key of the space where the new page should exist. Only needed if you don't utilize ParentID.
        [Parameter(ParameterSetName = 'byParameters')]
        [string]$SpaceKey,
        # Space Object in which to create the new page.
        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Space]$Space,

        # The contents of your new page. Accepts pipeline input by property name.
        [Parameter(ParameterSetName = 'byParameters')]
        [string]$Body,

        # Optional flag to call ConvertTo-WikiStorageFormat against your Body.
        [Parameter(ParameterSetName = 'byParameters')]
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

        $URI = "$BaseURI/content"

        switch ($PsCmdlet.ParameterSetName) {
            "byObject" {
                Write-Verbose "Using Page Object as input"
                Write-Debug "using object: $($InputObject | Out-String)"
                $Content = @{
                    type = "page"
                    title = $InputObject.Title
                    space = @{key = $InputObject.Space.Key}
                    body = @{
                        storage = @{
                            value = $InputObject.Body
                            representation = 'storage'
                        }
                    }
                    ancestors = @()
                }
                # Ancestors is undocumented! May break in the future
                # http://stackoverflow.com/questions/23523705/how-to-create-new-page-in-confluence-using-their-rest-api
                if ($InputObject.Ancestors) {
                    $Content["ancestors"] += @( $InputObject.Ancestors | Foreach-Object { @{ id = $_.ID } } )
                }
            }
            "byParameters" {
                Write-Verbose "Using attributes as input"
                if (($Parent -is [ConfluencePS.Page]) -and ($Parent.ID)) {
                    $ParentID = $Parent.ID
                }
                if (($Space -is [ConfluencePS.Space]) -and ($Space.Key)) {
                    $SpaceKey = $Space.Key
                }

                If (($ParentID) -and !($SpaceKey)) {
                    Write-Verbose "SpaceKey not specified. Retrieving from Get-WikiPage -PageID $ParentID"
                    $SpaceKey = (Get-WikiPage -PageID $ParentID).Space.Key
                }

                # If -Convert is flagged, call ConvertTo-WikiStorageFormat against the -Body
                If ($Convert) {
                    Write-Verbose '-Convert flag active; converting content to Confluence storage format'
                    $Body = ConvertTo-WikiStorageFormat -Content $Body
                }

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
            }
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
