function Get-ConfLabelApplied {
    <#
    .SYNOPSIS
    Search for a label and get results of where it has been applied.

    .DESCRIPTION
    View pages, blogposts, etc. with the specified label. Optionally filter by space.
    Leverages the Confluence Query Language against the /search resource.

    .PARAMETER Label
    Name the label to filter by.
    Currently accepts only one label; input is not case sensitive.

    .PARAMETER SpaceKey
    Optionally filter results by space key. Accepts pipeline input.

    .PARAMETER Limit
    Defaults to 25 max results; can be modified here.

    .EXAMPLE
    Get-ConfLabelApplied -Label blue -Limit 50 -Verbose
    Search all content for anything with the "blue" label.
    Results returned will be 50 instead of 25. Verbose flag active.

    .EXAMPLE
    Get-ConfSpace -Name Nintendo | Get-ConfLabelApplied -Label Mario
    For each space matching the name *Nintendo*, find content labeled "Mario."
    This method pipes the key of the matching space(s) into the -SpaceKey parameter.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
        [string]$Label,

		[Parameter(ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Key')]
        [string]$SpaceKey,

        [int]$Limit
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Get-ConfInfo'
            Get-ConfInfo
        }
    }

    PROCESS {
        $URI = $BaseURI + "/content/search"

        Write-Verbose 'Building URI based on parameters selected'
        If (($SpaceKey) -and ($Limit)) {
            $URI = $URI + "?cql=space=$SpaceKey%20AND%20label=$Label&limit=$Limit"
        } ElseIf ($SpaceKey) {
            $URI = $URI + "?cql=space=$SpaceKey%20AND%20label=$Label"
        } ElseIf ($Limit) {
            $URI = $URI + "?cql=label=$Label&limit=$Limit"
        } Else {
            $URI = $URI + "?cql=label=$Label"
        }

        Write-Verbose "Fetching info from $URI"
        $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Method Get | Select -ExpandProperty Results

        # Hashing everything because I don't like the lower case property names from the REST call
        $Rest | Sort Title | Select @{n='ID';    e={$_.id}},
                                    @{n='Title'; e={$_.title}},
                                    @{n='Type';  e={$_.type}}
    }
}
