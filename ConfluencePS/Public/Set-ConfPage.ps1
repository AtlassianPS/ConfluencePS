function Set-ConfPage {
    <#
    .SYNOPSIS
    Edit an existing Confluence page.

    .DESCRIPTION
    For existing page(s): Edit page content, page title, and/or change parent page.
    Content needs to be in "Confluence storage format." Use -Convert if not preconditioned.

    .PARAMETER PageID
    The ID of the page to edit. Accepts pipeline input by value/name. Mandatory.

    .PARAMETER Title
    Name of the page; existing or new value can be used.
    Existing will be automatically supplied via Get-ConfPage if not manually included.
    Accepts pipeline input by property name.

    .PARAMETER CurrentVersion
    The current version of the page; will be incremented upon successful edit.
    Will be automatically supplied via Get-ConfPage if not manually included.
    Accepts pipeline input by property name.

    .PARAMETER Body
    The full contents of the updated body (existing contents will be overwritten).
    If not yet in "storage format"--or you don't know what that is--also use -Convert.
    Mandatory. Current content may be piped in for no cosmetic change, if changing title or parent.
    Accepts pipeline input by property name.
    
    .PARAMETER Convert
    Optional switch flag for calling ConvertTo-ConfStorageFormat against your Body.

    .PARAMETER ParentID
    Optionally define a new parent page. If unspecified, no change.
    Accepts pipeline input by property name.

    .EXAMPLE
    Get-ConfPage -Title 'My First Page' -Expand | Set-ConfPage -Body 'Hello World!' -Convert
    Probably the easiest edit method, overwriting contents with a short sentence.
    Use Get-ConfPage -Expand to pipe in PageID & CurrentVersion.
    (See "Get-Help Get-ConfPage -Examples" for help with -Expand and >100 pages.)
    -Convert molds the sentence into a format Confluence will accept.

    .EXAMPLE
    Get-ConfPage -Title 'Lew Alcindor' -Limit 100 -Expand | Set-ConfPage -Title 'Kareem Abdul-Jabbar' -Verbose
    Change the page's name. Body remains the same, via piping the existing contents.
    Verbose flag active for additional screen output.

    .EXAMPLE
    Get-ConfPage -SpaceKey MATRIX | Set-ConfPage -Body 'Agent Smith' -Convert -WhatIf
    Overwrites the contents of all pages in the MATRIX space.
    WhatIf flag tells you how many pages would have been affected.

    .EXAMPLE
    Set-ConfPage -PageID 12345 -Title 'My Luggage Combo' -CurrentVersion 1 -Body '<p>Spaceballs</p>'
    An example of what needs to be known and specified to avoid:
    1) Piping in values required for the PUT method
    2) Calling Get-ConfPage mid-function to retrieve those same values
    3) Calling ConvertTo-ConfStorageFormat mid-function to condition the string

    .LINK
    Get-ConfPage

    .LINK
    ConvertTo-ConfStorageFormat

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
    param (
		[Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
		[Alias('ID')]
        [int]$PageID,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]$Title,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[int]$CurrentVersion,

		[Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
		[string]$Body,

        [switch]$Convert,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$ParentID
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-ConfInfo'
            Set-ConfInfo
        }
        
        # If -Convert is flagged, call ConvertTo-ConfStorageFormat against the -Body
        If ($Convert) {
            Write-Verbose '-Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-ConfStorageFormat -Content $Body
        }
    }

    PROCESS {
        # Title & Version must be specified in the PUT
        # If one or both are not found, use Get-ConfPage to capture them
        If ((!$CurrentVersion) -and (!$Title)) {
            Write-Verbose "Title and version unspecified. Calling Get-ConfPage w/ ID $PageID"
            $CurrentPage   = Get-ConfPage -PageID $PageID -Expand
            [int]$CurrentVersion  = $CurrentPage.Ver
            [string]$Title = $CurrentPage.Title
        } ElseIf (!$CurrentVersion) {
            Write-Verbose "Version unspecified. Calling Get-ConfPage w/ ID $PageID"
            [int]$CurrentVersion  = Get-ConfPage -PageID $PageID -Expand | Select -ExpandProperty Ver
        } ElseIf (!$Title) {
            Write-Verbose "Title unspecified. Calling Get-ConfPage w/ ID $PageID"
            [string]$Title = Get-ConfPage -PageID $PageID -Expand | Select -ExpandProperty Title
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
