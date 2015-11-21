function Get-ConfPage {
    <#
    .SYNOPSIS
    Retrieve a listing of pages in your Confluence instance.

    .DESCRIPTION
    Fetch Confluence pages, optionally filtering by Name/Space/ID.

    Piped output into other cmdlets is generally tested and supported.

    .PARAMETER Name
    Filter results by name. Supports wildcard matching on partial names.

    .PARAMETER PageID
    Filter results by page ID.

    .PARAMETER SpaceKey
    Filter results by key.

    .EXAMPLE
    Get-ConfSpace
    List all pages in your Confluence instance. Runs Get-ConfInfo first if instance info unknown.

    .EXAMPLE
    Get-ConfSpace -Title Confluence
    Get all pages with the word Confluence in the title.

    .EXAMPLE
    Get-ConfSpace -Name Demo | Get-ConfPage
    Get all spaces with a name like *demo*, and then list all pages from those spaces.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
        [Alias('Name')]
        [string]$Title,

        [string]$PageID,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Space','Key')]
        [string]$SpaceKey
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Get-ConfInfo'
            Get-ConfInfo
        }
    }

    PROCESS {
        $URI = $BaseURI + '/content'

        # Fetch our content
        If ($PageID) {
            $URI = $URI + "/$PageID"
            Write-Verbose "Fetching info from $URI"
            $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get
        } ElseIf ($SpaceKey) {
            $URI = $URI + "?spaceKey=$SpaceKey"
            Write-Verbose "Fetching info from $URI"
            $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get
        } Else {
            $URI = $URI + '?type=page'
            Write-Verbose "Fetching info from $URI"
            $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get
        }

        # Display results depending on the call we made
        # Hashing everything because I don't like the lower case property names from the REST call
        If ($PageID) {
            Write-Verbose "Showing -PageID $PageID results"
            $Rest | Select @{n='ID';e={$_.id}},
                           @{n='Title';e={$_.title}},
                           @{n='Space';e={$_.space.key}}
        } ElseIf ($Title) {
            Write-Verbose "Showing -Title $Title results"
            $Rest | Select -ExpandProperty Results | Where {$_.Title -like "*$Title*"} | Sort Title |
                Select @{n='ID';e={$_.id}},
                       @{n='Title';e={$_.title}},
                       @{n='Space';e={$_._expandable.space -replace '/rest/api/space/',''}}
        } Else {
            Write-Verbose "Showing results"
            $Rest | Select -ExpandProperty Results | Sort Title |
                Select @{n='ID';e={$_.id}},
                       @{n='Title';e={$_.title}},
                       @{n='Space';e={$_._expandable.space -replace '/rest/api/space/',''}}
        }
    }
}
