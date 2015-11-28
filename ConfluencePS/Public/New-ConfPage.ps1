function New-ConfPage {
    <#
    .SYNOPSIS
    Create a new page in your Confluence instance.

    .DESCRIPTION
    Create a new page in Confluence. Optionally include content in -Body.
    Content needs to be in "Confluence storage format;" see also -Convert.

    .PARAMETER Title
    Name of your new page.

    .PARAMETER ParentID
    The ID of the parent page. Accepts pipeline input by value/name.
    NOTE: This feature is not in the 5.8 REST API documentation, and should be considered experimental.

    .PARAMETER SpaceKey
    Key of the space where the new page should exist. Only needed if you don't utilize ParentID.

    .PARAMETER Body
    The contents of your new page. Accepts pipeline input by property name.

    .PARAMETER Convert
    Optional flag to call ConvertTo-ConfStorageFormat against your Body.

    .EXAMPLE
    New-ConfPage -Title 'Test New Page' -ParentID 123456 -Body '<p>Hello world</p>' -WhatIf
    Creates a new test page (as a child member of existing page 123456) with one line of page text.
    Automatically finds 123456 in space 'ABC' via Get-ConfPage and applies the key to the REST post.
    -WhatIf support, so the page will not actually be created.

    .EXAMPLE
    Get-ConfPage -Title 'Darth Vader' | New-ConfPage -Title 'Luke Skywalker' -Body $Body -Confirm
    Searches for pages named *Darth Vader*, pipes page ID and space key. New page is a child of existing page.
    Note that this can grab multiple pages via wildcard matching, potentially attempting multiple posts.
    You will be asked to confirm each creation. Choose wisely.

    .EXAMPLE
    New-ConfPage -Title 'Loner Page' -SpaceKey TEST -Body $Body -Convert -Verbose
    Creates a new page at the root of the specified space (no parent page). Verbose flag enabled.
    $Body is not yet in Confluence storage format ("XHTML-based"), and needs to be converted.

    .LINK
    Get-ConfPage

    .LINK
    ConvertTo-ConfStorageFormat

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
    param (
		[Parameter(Mandatory = $true)]
		[Alias('Name')]
		[string]$Title,

		[Parameter(ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
		[Alias('ID')]
        [int]$ParentID,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[Alias('Space','Key')]
		[string]$SpaceKey,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]$Body,

        [switch]$Convert
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Get-ConfInfo'
            Get-ConfInfo
        }
    }

    PROCESS {
        If (($ParentID) -and !($SpaceKey)) {
            Write-Verbose "SpaceKey not specified. Retrieving from Get-ConfPage -PageID $ParentID"
            $SpaceKey = Get-ConfPage -PageID $ParentID | Select -ExpandProperty Space
        }

        # If -Convert is flagged, call Convert-ConfStorageFormat against the -Body
        If ($Convert) {
            Write-Verbose '-Convert flag active; converting content to Confluence storage format'
            # $Body = Convert-ConfStorageFormat $Body
        }
        
        $URI = $BaseURI + '/content'

        $Content = @{type      = 'page'
                     title     = "$Title"
                     space     = @{key = "$SpaceKey"}
                     body      = @{storage = @{value          = "$Body"
                                               representation = 'storage'
                                              }
                                  }
                     # Ancestors is undocumented! May break in the future
                     # http://stackoverflow.com/questions/23523705/how-to-create-new-page-in-confluence-using-their-rest-api
                     # Using [ordered] (requires Posh v3) to ensure -replace below works as desired
                     ancestors = [ordered]@{id   = "$ParentID"
                                            type = 'page'
                                           }
                    # Using -Compress to make the -replace below easier
                    } | ConvertTo-Json -Compress
        
        # Ancestors requires [] brackets around its JSON values to work correctly
        $Content = $Content -replace '"ancestors":','"ancestors":[' -replace '"page"},','"page"}],'

        Write-Verbose "Posting to $URI"
        If ($PSCmdlet.ShouldProcess("Space $SpaceKey, Parent $ParentID")) {
            $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Body $Content -Method Post -ContentType 'application/json'

            # Hashing everything because I don't like the lower case property names from the REST call
            $Rest | Select @{n='ID';      e={$_.id}},
                           @{n='Key';     e={$_.space.key}},
                           @{n='Title';   e={$_.title}},
                           @{n='ParentID';e={$_.ancestors.id}}
        }
    }
}
