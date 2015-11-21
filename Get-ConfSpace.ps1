function Get-ConfSpace {
    <#
    .SYNOPSIS
    Retrieve a listing of spaces in your Confluence instance.

    .DESCRIPTION
    Fetch all Confluence spaces, optionally filtering by Name/Key/ID.

    Piped output into other cmdlets is generally tested and supported.

    .PARAMETER Name
    Filter results by name. Supports wildcard matching on partial names.

    .PARAMETER Key
    Filter results by key. Supports wildcard matching on partial names.

    .PARAMETER ID
    Filter results by ID.

    .EXAMPLE
    Get-ConfSpace -ID 123456
    Display the info of the space with ID 123456.

    .EXAMPLE
    Get-ConfSpace -Name test
    Display all spaces containing 'test' in the name.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
        [string]$Name,

        [Alias('SpaceKey')]
        [string]$Key,

        [string]$ID
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Get-ConfInfo'
            Get-ConfInfo
        }
    }

    PROCESS {
        $URI = $BaseURI + '/space'

        Write-Verbose "Fetching info from $URI"
        $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get | Select -ExpandProperty Results | Select Key,Name,ID,Type

        If ($ID) {
            $Rest | Where {$_.ID -eq $ID}
        } ElseIf ($Key) {
            $Rest | Where {$_.Key -like "*$Key*"} | Sort Key
        } ElseIf ($Name) {
            $Rest | Where {$_.Name -like "*$Name*"} | Sort Key
        } Else {
            $Rest
        }
    }
}
