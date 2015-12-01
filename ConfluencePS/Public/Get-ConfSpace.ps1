function Get-ConfSpace {
    <#
    .SYNOPSIS
    Retrieve a listing of spaces in your Confluence instance.

    .DESCRIPTION
    Fetch all Confluence spaces, optionally filtering by Name/Key/ID.
    Input for all parameters is not case sensitive.
    Piped output into other cmdlets is generally tested and supported.

    .PARAMETER Name
    Filter results by name. Supports wildcard matching on partial input.

    .PARAMETER Key
    Filter results by key. Supports wildcard matching on partial input.

    .PARAMETER ID
    Filter results by ID.

    .PARAMETER Limit
    Defaults to 25 max results; can be modified here.

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

        [int]$ID,

        [int]$Limit
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-ConfInfo'
            Set-ConfInfo
        }
    }

    PROCESS {
        $URI = $BaseURI + '/space'

        If ($Limit) {
            $URI = $URI + "?limit=$Limit"
        }

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
