function Get-WikiChildPage {
    <#
    .SYNOPSIS
    For a given wiki page, list all child wiki pages.

    .DESCRIPTION
    Pipeline input of ParentID is accepted.
    
    This API method only returns the immediate children (results are not recursive).

    .EXAMPLE
    Get-WikiChildPage -ParentID 1234 | Select-Object ID, Title | Sort-Object Title
    For the wiki page with ID 1234, get all pages immediately beneath it.
    Returns only each page's ID and Title, sorting results alphabetically by Title.

    .EXAMPLE
    Get-WikiPage -Title 'Genghis Khan' | Get-WikiChildPage -Limit 500
    Find the Genghis Khan wiki page and pipe the results.
    Get only the first 500 children beneath that page.

    .EXAMPLE
    Get-WikiChildPage -ParentID 9999 -Expand -Limit 100
    For each child page found, expand the results to also include properties
    like Body and Version (Ver). Typically, using -Expand will not return
    more than 100 results, even if -Limit is set to a higher value.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
        # Filter results by page ID.
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1,[int]::MaxValue)]
        [Alias('ID')]
        [int]$ParentID,

        # Defaults to 25 max results; can be modified here.        
        # Numbers above 100 may not be honored if -Expand is used.
        [ValidateRange(1,[int]::MaxValue)]
        [int]$Limit,

        # Additionally returns expanded results for each page (body, version, etc.).
        # May negatively affect -Limit, client/server performance, and network bandwidth.
        [switch]$Expand
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        $URI = $BaseURI + "/content/$ParentID/child/page"

        # URI prep based on specified parameters
        If ($Expand -and $Limit) {
            $URI = $URI + "?expand=body.view,version&limit=$Limit"
        } ElseIf ($Expand) {
            $URI = $URI + '?expand=body.view,version'
        } ElseIf ($Limit) {
            $URI = $URI + "?limit=$Limit"
        }
        
        Write-Verbose "GET call from $URI"
        $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get

        # Display results
        # Hashing everything because I don't like the lower case property names from the REST call
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
    } #Process
} #Function
