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
        $GETparameters += @{expand = "description.plain,icon,homepage,metadata.labels"}
        If ($Limit) { $GETparameters["limit"] = $Limit }

        Write-Debug "Using `$GETparameters: $($GETparameters | Out-String)"
        $URI += (Add-GetParameter $GETparameters)

        Write-Verbose "Fetching data from $URI"
        $response = Invoke-WikiMethod -Uri $URI -Method Get
        Write-Debug "`$response: $($response | Out-String)"

        Write-Verbose "Processing results"
        if ($response | Get-Member -Name results) {
            # extract from array
            $response = $response | Select-Object -ExpandProperty results
        }
        if (($response | Measure-Object).count -ge 1) {
            foreach ($item in $response) {
                $item | ConvertTo-WikiSpace
            }
        }
    }
}
