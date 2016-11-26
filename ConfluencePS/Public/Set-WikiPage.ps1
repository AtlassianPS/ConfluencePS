function Set-WikiPage {
    <#
    .SYNOPSIS
    Edit an existing Confluence page.

    .DESCRIPTION
    For existing page(s): Edit page content, page title, and/or change parent page.
    Content needs to be in "Confluence storage format." Use -Convert if not preconditioned.

    .EXAMPLE
    Get-WikiPage -Title 'My First Page' -Expand | Set-WikiPage -Body 'Hello World!' -Convert
    Probably the easiest edit method, overwriting contents with a short sentence.
    Use Get-WikiPage -Expand to pipe in PageID & CurrentVersion.
    (See "Get-Help Get-WikiPage -Examples" for help with -Expand and >100 pages.)
    -Convert molds the sentence into a format Confluence will accept.

    .EXAMPLE
    Get-WikiPage -Title 'Lew Alcindor' -Limit 100 -Expand | Set-WikiPage -Title 'Kareem Abdul-Jabbar' -Verbose
    Change the page's name. Body remains the same, via piping the existing contents.
    Verbose flag active for additional screen output.

    .EXAMPLE
    Get-WikiPage -SpaceKey MATRIX | Set-WikiPage -Body 'Agent Smith' -Convert -WhatIf
    Overwrites the contents of all pages in the MATRIX space.
    WhatIf flag tells you how many pages would have been affected.

    .EXAMPLE
    Set-WikiPage -PageID 12345 -Title 'My Luggage Combo' -CurrentVersion 1 -Body '<p>Spaceballs</p>'
    An example of what needs to be known and specified to avoid:
    1) Piping in values required for the PUT method
    2) Calling Get-WikiPage mid-function to retrieve those same values
    3) Calling ConvertTo-WikiStorageFormat mid-function to condition the string

    .LINK
    Get-WikiPage

    .LINK
    ConvertTo-WikiStorageFormat

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
    param (
        # The ID of the page to edit. Accepts pipeline input by value/name. Mandatory.
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1,[int]::MaxValue)]
        [Alias('ID')]
        [int]$PageID,

        # Name of the page; existing or new value can be used.
        # Existing will be automatically supplied via Get-WikiPage if not manually included.
        # Accepts pipeline input by property name.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Title,

        # The current version of the page; will be incremented upon successful edit.
        # Will be automatically supplied via Get-WikiPage if not manually included.
        # Accepts pipeline input by property name.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1,[int]::MaxValue)]
        [int]$CurrentVersion,

        # The full contents of the updated body (existing contents will be overwritten).
        # If not yet in "storage format"--or you don't know what that is--also use -Convert.
        # Mandatory. Current content may be piped in for no cosmetic change, if changing title or parent.
        # Accepts pipeline input by property name.
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]$Body,

        # Optional switch flag for calling ConvertTo-WikiStorageFormat against your Body.
        [switch]$Convert,

        # Optionally define a new parent page. If unspecified, no change.
        # Accepts pipeline input by property name.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1,[int]::MaxValue)]
        [int]$ParentID
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
        
        # If -Convert is flagged, call ConvertTo-WikiStorageFormat against the -Body
        If ($Convert) {
            Write-Verbose '-Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-WikiStorageFormat -Content $Body
        }
    }

    PROCESS {
        # Title & Version must be specified in the PUT
        # If one or both are not found, use Get-WikiPage to capture them
        If ((!$CurrentVersion) -and (!$Title)) {
            Write-Verbose "Title and version unspecified. Calling Get-WikiPage w/ ID $PageID"
            $CurrentPage   = Get-WikiPage -PageID $PageID -Expand
            [int]$CurrentVersion  = $CurrentPage.Ver
            [string]$Title = $CurrentPage.Title
        } ElseIf (!$CurrentVersion) {
            Write-Verbose "Version unspecified. Calling Get-WikiPage w/ ID $PageID"
            [int]$CurrentVersion  = Get-WikiPage -PageID $PageID -Expand | Select -ExpandProperty Ver
        } ElseIf (!$Title) {
            Write-Verbose "Title unspecified. Calling Get-WikiPage w/ ID $PageID"
            [string]$Title = Get-WikiPage -PageID $PageID -Expand | Select -ExpandProperty Title
        }

        # The PUT wants new version, not current, so increment by one
        $CurrentVersion++

        $URI = $BaseURI + "/content/$PageID"

        If ($ParentID) {
            $Content = @{version   = @{number = $CurrentVersion}
                         title     = $Title
                         type      = 'page'
                         body      = @{storage = @{value          = $Body
                                                   representation = 'storage'
                                                  }
                                      }
                         ancestors = @{id = $ParentID}
                        # Using -Compress to make the -replace below easier
                        } | ConvertTo-Json -Compress
        
            # Ancestors requires [] brackets around its JSON values to work correctly
            # This is RegEx magic. If you're not familiar, regex101.com or similar sites
            $Content = $Content -replace '(\{\"id\"\:\d+\})','[$1]'
        } Else {
            $Content = @{version   = @{number = $CurrentVersion}
                         title     = $Title
                         type      = 'page'
                         body      = @{storage = @{value          = $Body
                                                   representation = 'storage'
                                                  }
                                      }
                        } | ConvertTo-Json
        }
                
        Write-Verbose "PUT (edit) to $URI"
        # -WhatIf wrapper
        If ($PSCmdlet.ShouldProcess("PageID $PageID, Body $Body")) {
            $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Body $Content -Method Put -ContentType 'application/json'

            # Hashing everything because I don't like the lower case property names from the REST call
            $Rest | Select @{n='ID';      e={$_.id}},
                           @{n='Key';     e={$_.space.key}},
                           @{n='Title';   e={$_.title}},
                           @{n='ParentID';e={$_.ancestors.id}}
        }

        # If multiple pages are being piped in, need to check for version each time
        $CurrentVersion = $null
    }
}
