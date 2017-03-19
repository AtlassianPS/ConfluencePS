function New-WikiSpace {
    <#
    .SYNOPSIS
    Create a new blank space in your Confluence instance.

    .DESCRIPTION
    Create a new blank space. Key and Name mandatory, Description recommended.

    .EXAMPLE
    New-WikiSpace -Key 'TEST' -Name 'Test Space'
    Create the new blank space. Runs Set-WikiInfo first if instance info unknown.

    .EXAMPLE
    New-WikiSpace -Key 'TEST' -Name 'Test Space' -Description 'New blank space via REST API' -Verbose
    Create the new blank space with the optional description and verbose output.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='Medium')]
    param (
        # Specify the short key to be used in the space URI.
        [Parameter(Mandatory = $true)]
        [Alias('SpaceKey')]
        [string]$Key,

        # Specify the space's name.
        [Parameter(Mandatory = $true)]
        [string]$Name,

        # A short description of the new space.
        [string]$Description
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        $URI = "$BaseURI/space"

        $Body = @{
            key         = "$Key"
            name        = "$Name"
            description = @{
                plain = @{
                    value          = "$Description"
                    representation = 'plain'
                }
            }
        } | ConvertTo-Json

        Write-Verbose "Posting to $URI"
        If ($PSCmdlet.ShouldProcess("$Key $Name")) {
            Invoke-WikiMethod -Uri $URI -Body $Body -Method Post
        }
    }
}
