function Get-ConfPage {
    <#
    .SYNOPSIS
    Retrieve a listing of pages in your Confluence instance.

    .DESCRIPTION
    Fetch Confluence pages, optionally filtering by Name/Space/ID.
    Piped output into other cmdlets is generally tested and supported.

    .PARAMETER Title
    Filter results by name. Supports wildcard matching on partial names.

    .PARAMETER PageID
    Filter results by page ID.

    .PARAMETER SpaceKey
    Filter results by key. Currently, this parameter is case sensitive.

    .PARAMETER Limit
    Defaults to 25 max results; can be modified here.

    .EXAMPLE
    Get-ConfPage -Limit 100
    List all pages in your Confluence instance. Runs Set-ConfInfo first if instance info unknown.
    Increases default result limit from 25 to the first 100 pages found.

    .EXAMPLE
    Get-ConfPage -Title Confluence
    Get all pages with the word Confluence in the title. Title is not case sensitive.

    .EXAMPLE
    Get-ConfSpace -Name Demo | Get-ConfPage
    Get all spaces with a name like *demo*, and then list all pages from each returned space.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
        [Alias('Name')]
        [string]$Title,

        [int]$PageID,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Space','Key')]
        [string]$SpaceKey,

        [int]$Limit
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
            $URI = $URI + "/$PageID/?expand=body.view,version"
        } ElseIf ($SpaceKey) {
            $URI = $URI + "?type=page&spaceKey=$SpaceKey&expand=body.view,version"
        } Else {
            $URI = $URI + '?type=page&expand=body.view,version'
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

        Write-Verbose "Fetching info from $URI"
        $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get

        # Display results depending on the call we made
        # Hashing everything because I don't like the lower case property names from the REST call
        If ($PageID) {
            Write-Verbose "Showing -PageID $PageID results"
            $Rest | Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}},
                           @{n='Ver';   e={$_.version.number}},
                           @{n='Body';  e={$_.body.view.value}}
        } ElseIf ($Title) {
            Write-Verbose "Showing -Title $Title results"
            $Rest | Select -ExpandProperty Results | Where {$_.Title -like "*$Title*"} | Sort Title |
                Select @{n='ID';    e={$_.id}},
                       @{n='Title'; e={$_.title}},
                       @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}},
                       @{n='Ver';   e={$_.version.number}},
                       @{n='Body';  e={$_.body.view.value}}
        } Else {
            Write-Verbose "Showing results"
            $Rest | Select -ExpandProperty Results | Sort Title |
                Select @{n='ID';    e={$_.id}},
                       @{n='Title'; e={$_.title}},
                       @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}},
                       @{n='Ver';   e={$_.version.number}},
                       @{n='Body';  e={$_.body.view.value}}
        }
    }
}
