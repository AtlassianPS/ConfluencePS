function Get-WikiSpace {
    <#
    .SYNOPSIS
    Retrieve a listing of spaces in your Confluence instance.

    .DESCRIPTION
    Fetch all Confluence spaces, optionally filtering by Name/Key/ID.
    Input for all parameters is not case sensitive.
    Piped output into other cmdlets is generally tested and supported.

    .EXAMPLE
    Get-WikiSpace -ID 123456
    Display the info of the space with ID 123456.

    .EXAMPLE
    Get-WikiSpace -Name test
    Display all spaces containing 'test' in the name.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
        # Filter results by key. Supports wildcard matching on partial input.
        [Alias('Key')]
        [string]$SpaceKey,

        # Defaults to 25 max results; can be modified here.
        [ValidateRange(1,[int]::MaxValue)]
        [int]$Limit
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        $URI = "$BaseURI/space"

        if ($SpaceKey) {
            $URI += "/$SpaceKey"
        }

        If ($Limit) {
            $URI += "?limit=$Limit"
        }

        Write-Verbose "Fetching info from $URI"
        $response = Invoke-WikiMethod -Uri $URI -Method Get

        if ($response.Results) {
            $response.Results | Select @{n='Key';     e={$_.key}},
                                      @{n='Name';    e={$_.name}},
                                      @{n='SpaceID'; e={$_.id}},
                                      @{n='Type';    e={$_.type}}
        }
        else {
            $response | Select @{n='Key';     e={$_.key}},
                               @{n='Name';    e={$_.name}},
                               @{n='SpaceID'; e={$_.id}},
                               @{n='Type';    e={$_.type}}
        }

    }
}
