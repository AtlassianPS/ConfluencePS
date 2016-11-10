function Get-WikiChildPages {
    <#
    .SYNOPSIS
    Retrieve a listing of child pages in your Confluence instance by their parent page.

    .DESCRIPTION
    Fetch Confluence child pages by parent page id.

    .EXAMPLE
    Get-WikiChildPages -ParentID 1234
    Get all child pages that parent page with id 3625 contains.

    .EXAMPLE
    Get-WikiChildPages -ParentID 1234 -Limit 500 | Select-Object ID, Title | Sort-Object Title
    List the first 500 child pages found under your Confluence parent page.
    Returns only each page's ID and Title, sorting results alphabetically by Title.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
        # Filter results by page ID.
        [Parameter(Mandatory=$true)]
        [ValidateRange(1,[int]::MaxValue)]
        [int]$ParentID,

        # Defaults to 25 max results; can be modified here.        
        [ValidateRange(1,[int]::MaxValue)]
        [int]$Limit
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        
        # URI prep based on specified parameters
        $URI = $BaseURI + "/content/$ParentID/child/page"

        # Append the Limit parameter to the URI
        If ($Limit) {
                # Will always have ?type=page, so this will always be & instead of ?
                $URI = $URI + "?limit=$Limit" 
        }
        
        Write-Verbose "GET call from $URI"
        $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get

        # Display results
        # Hashing everything because I don't like the lower case property names from the REST call
        $Rest | Select -ExpandProperty Results |
                    Select @{n='ID';    e={$_.id}},
                           @{n='Title'; e={$_.title}},
                           @{n='Space'; e={$_._expandable.space -replace '/rest/api/space/',''}}
    }
}
