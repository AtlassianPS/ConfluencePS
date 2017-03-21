function Get-WikiPage {
    <#
    .SYNOPSIS
    Retrieve a listing of pages in your Confluence instance.

    .DESCRIPTION
    Fetch Confluence pages, optionally filtering by Name/Space/ID.
    Piped output into other cmdlets is generally tested and supported.

    .EXAMPLE
    Get-WikiPage -Title Confluence -Limit 100
    Get all pages with the word Confluence in the title. Title is not case sensitive.
    Among only the first 100 pages found, returns all results matching *confluence*.

    .EXAMPLE
    Get-WikiPage -Limit 500 | Select-Object ID, Title | Sort-Object Title
    List the first 500 pages found in your Confluence instance.
    Returns only each page's ID and Title, sorting results alphabetically by Title.

    .EXAMPLE
    Get-WikiSpace -Name Demo | Get-WikiPage
    Get all spaces with a name like *demo*, and then list pages from each returned space.

    .EXAMPLE
    $FinalCountdown = Get-WikiPage -PageID 54321 -Expand
    Store the page's ID, Title, Space Key, Version, and Body for use later in your script.

    .EXAMPLE
    $WhereIsShe = Get-WikiPage -Title 'Rachel' -Limit 1000 | Get-WikiPage -Expand
    Search Batman's 1000 pages for Rachel in order to find the correct page ID(s).
    Search again, this time piping in the page ID(s), to also capture version and body from the expanded results.
    Store them in a variable for later use (e.g. Set-WikiPage).

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
        # Filter results by name. Supports wildcard matching on partial names.
        # Filtering happens via Where-Object (after the REST call) for case insensitivity.
        [Alias('Name')]
        [string]$Title,

        # Filter results by page ID.
        # Best option if you already know the ID, as it bypasses result limit problems.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1,[int]::MaxValue)]
        [Alias('ID')]
        [int]$PageID,

        # Filter results by key. Currently, this parameter is case sensitive.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [string]$SpaceKey,

        # Defaults to 25 max results; can be modified here.
        # Numbers above 100 may not be honored if -Expand is used.
        [ValidateRange(1,[int]::MaxValue)]
        [int]$Limit,

        # Additionally returns expanded results for each page (body, version, etc.).
        # May negatively affect -Limit, client/server performance, and network bandwidth.
        [switch]$Expand
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        $URI = "$BaseURI/content"

        # URI prep based on specified parameters
        If ($PageID) {
            If ($Expand) {
                $URI = $URI + "/$PageID/?expand=body.view,version"
            } Else {
                $URI = $URI + "/$PageID"
            }
        } ElseIf ($SpaceKey) {
            If ($Expand) {
                $URI = $URI + "?type=page&spaceKey=$SpaceKey&expand=body.view,version"
            } Else {
                $URI = $URI + "?type=page&spaceKey=$SpaceKey"
            }
        } Else {
            If ($Expand) {
                $URI = $URI + '?type=page&expand=body.view,version'
            } Else {
                $URI = $URI + '?type=page'
            }
        }

        # Append the Limit parameter to the URI
        If ($Limit) {
            If ($PageID) {
                # Not supported/needed on this resource
            } Else {
                # Will always have ?type=page, so this will always be & instead of ?
                $URI = $URI + "&limit=$Limit"
            }
        }

        Write-Verbose "GET call from $URI"
        $response = Invoke-WikiMethod -Uri $URI -Method Get

        # Display results depending on the call we made
        # Hashing everything because I don't like the lower case property names from the REST call
        If ($PageID) {
            Write-Verbose "Showing -PageID $PageID results"
            If ($Expand) {
                $response | Select @{n='ID';    e={$_.id}},
                               @{n='Title'; e={$_.title}},
                               @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}},
                               @{n='Ver';   e={$_.version.number}},
                               @{n='Body';  e={$_.body.view.value}}
            } Else {
                $response | Select @{n='ID';    e={$_.id}},
                               @{n='Title'; e={$_.title}},
                               @{n='Space'; e={$_.space.key}}
            }
        } ElseIf ($Title) {
            Write-Verbose "Showing -Title $Title results"
            If ($Expand) {
                $response | Select -ExpandProperty Results | Where {$_.Title -like "*$Title*"} |
                    Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}},
                           @{n='Ver';   e={$_.version.number}},
                           @{n='Body';  e={$_.body.view.value}}
            } Else {
                $response | Select -ExpandProperty Results | Where {$_.Title -like "*$Title*"} |
                    Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}}
            }
        } Else {
            Write-Verbose "Showing results"
            If ($Expand) {
                $response | Select -ExpandProperty Results |
                    Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}},
                           @{n='Ver';   e={$_.version.number}},
                           @{n='Body';  e={$_.body.view.value}}
            } Else {
                $response | Select -ExpandProperty Results |
                    Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}}
            }
        }
    }
}
