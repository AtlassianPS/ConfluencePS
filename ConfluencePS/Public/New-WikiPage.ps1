function New-WikiPage {
    <#
    .SYNOPSIS
    Create a new page in your Confluence instance.

    .DESCRIPTION
    Create a new page in Confluence. Optionally include content in -Body.
    Content needs to be in "Confluence storage format;" see also -Convert.

    .EXAMPLE
    New-WikiPage -Title "My new fance Page" -Body "<h1>My Title</h1><p>The body of my fancy new page.</p>"
    Creates a new page with a given title and body content (in "confluence's storeage format").
    The information of the created page is returned to the console.


    .EXAMPLE
    New-WikiPage -Title 'Test New Page' -ParentID 123456 -Body 'Hello world' -Convert -WhatIf
    Creates a new page as a child member of existing page 123456 with one line of page text.
    The Body defined is converted to Storage fromat by the "-Convert" parameter

    .EXAMPLE
    New-WikiPage -Title "Luke Skywalker" -Parent (Get-WikiPage -title "Darth Vader" -SpaceKey "STARWARS")
    Creates a new page with an empty body as a child page of the "Parent Page" in the "space" page.

    .EXAMPLE
    [ConfluencePS.Page]@{Title="My Title";Space=[ConfluencePS.Space]@{Key="ABC"}} | New-WikiPage -ApiURi "https://myserver.com/wiki" -Credential $cred
    Creates a new page "My Title" in the space "ABC" with an empty body.

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
        # The URi of the API interface.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

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

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"

        $URI = "$apiURi/content"

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
            Invoke-WikiMethod -Uri $URI -Body $Content -Method Post -Credential $Credential -OutputType ([ConfluencePS.Page])
        }
    }
}
