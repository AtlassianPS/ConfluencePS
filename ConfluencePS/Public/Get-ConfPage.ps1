﻿function Get-ConfPage {
    <#
    .SYNOPSIS
    Retrieve a listing of pages in your Confluence instance.

    .DESCRIPTION
    Fetch Confluence pages, optionally filtering by Name/Space/ID.
    Piped output into other cmdlets is generally tested and supported.

    .PARAMETER Title
    Filter results by name. Supports wildcard matching on partial names.
    Filtering happens via Where-Object (after the REST call) for case insensitivity.

    .PARAMETER PageID
    Filter results by page ID.
    Best option if you already know the ID, as it bypasses result limit problems.

    .PARAMETER SpaceKey
    Filter results by key. Currently, this parameter is case sensitive.

    .PARAMETER Limit
    Defaults to 25 max results; can be modified here.
    Numbers above 100 may not be honored if -Expand is used.

    .PARAMETER Expand
    Additionally returns expanded results for each page (body, version, etc.).
    May negatively affect -Limit, client/server performance, and network bandwidth.

    .EXAMPLE
    Get-ConfPage -Title Confluence -Limit 100
    Get all pages with the word Confluence in the title. Title is not case sensitive.
    Among only the first 100 pages found, returns all results matching *confluence*.

    .EXAMPLE
    Get-ConfPage -Limit 500 | Select-Object ID, Title | Sort-Object Title
    List the first 500 pages found in your Confluence instance.
    Returns only each page's ID and Title, sorting results alphabetically by Title.

    .EXAMPLE
    Get-ConfSpace -Name Demo | Get-ConfPage
    Get all spaces with a name like *demo*, and then list pages from each returned space.

    .EXAMPLE
    $FinalCountdown = Get-ConfPage -PageID 54321 -Expand
    Store the page's ID, Title, Space Key, Version, and Body for use later in your script.

    .EXAMPLE
    $WhereIsShe = Get-ConfPage -Title 'Rachel' -Limit 1000 | Select-Object ID | Get-ConfPage -Expand
    Search Batman's 1000 pages for Rachel in order to find the correct page ID(s).
    Search again, this time piping in the page ID(s), to also capture version and body from the expanded results.
    Store them in a variable for later use (e.g. Set-ConfPage).

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
        [Alias('Name')]
        [string]$Title,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('ID')]
        [int]$PageID,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Space','Key')]
        [string]$SpaceKey,

        [int]$Limit,

        [switch]$Expand
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-ConfInfo'
            Set-ConfInfo
        }
    }

    PROCESS {
        $URI = $BaseURI + '/content'

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
        $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get

        # Display results depending on the call we made
        # Hashing everything because I don't like the lower case property names from the REST call
        If ($PageID) {
            Write-Verbose "Showing -PageID $PageID results"
            If ($Expand) {
                $Rest | Select @{n='ID';    e={$_.id}},
                               @{n='Title'; e={$_.title}},
                               @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}},
                               @{n='Ver';   e={$_.version.number}},
                               @{n='Body';  e={$_.body.view.value}}
            } Else {
                $Rest | Select @{n='ID';    e={$_.id}},
                               @{n='Title'; e={$_.title}},
                               @{n='Space'; e={$_.space.key}}
            }
        } ElseIf ($Title) {
            Write-Verbose "Showing -Title $Title results"
            If ($Expand) {
                $Rest | Select -ExpandProperty Results | Where {$_.Title -like "*$Title*"} |
                    Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}},
                           @{n='Ver';   e={$_.version.number}},
                           @{n='Body';  e={$_.body.view.value}}
            } Else {
                $Rest | Select -ExpandProperty Results | Where {$_.Title -like "*$Title*"} |
                    Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}}
            }
        } Else {
            Write-Verbose "Showing results"
            If ($Expand) {
                $Rest | Select -ExpandProperty Results |
                    Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}},
                           @{n='Ver';   e={$_.version.number}},
                           @{n='Body';  e={$_.body.view.value}}
            } Else {
                $Rest | Select -ExpandProperty Results |
                    Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}}
            }
        }
    }
}
