function Get-ConfInfo {
    <#
    .SYNOPSIS
    Gather URI/auth info for use in this session's REST API requests.

    .DESCRIPTION
    Anonymous access to the Confluence REST API is disabled by default.
    Unless manually enabled, you will need to pass authorization in all interactions.

    If you have a better suggestion for how to handle this, please reach out on GitHub!

    .PARAMETER BaseURI
    Address of your base Confluence install. For Atlassian On-Demand instances, include /wiki.

    .PARAMETER Username
    The username you use to log in to Confluence.

    .PARAMETER Password
    The password you use to log in to Confluence.

    .EXAMPLE
    Get-ConfInfo -BaseURI 'https://brianbunke.atlassian.net/wiki' -Username admin -Password uncrackable
    Declare Confluence home address and credentials. Stored in script-scope variables $BaseURI and $Header
    
    .LINK
    https://github.com/brianbunke/ConfluencePS

    .LINK
    http://stackoverflow.com/questions/27951561/use-invoke-webrequest-with-a-username-and-password-for-basic-authentication-on-t
    #>
	[CmdletBinding()]
	param (
	    [Parameter( Mandatory   = $true,
                    HelpMessage = 'Example = https://brianbunke.atlassian.net/wiki (/wiki for On-Demand instances)')]
	    [ValidateNotNullorEmpty()]
        [Uri]$BaseURI = 'https://brianbunke.atlassian.net/wiki',

	    [Parameter(Mandatory = $true)]
	    [ValidateNotNullorEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $true)]
	    [ValidateNotNullorEmpty()]
        [string]$Password
    )

    PROCESS {
        # Append the /rest/api to our URI
        # Save as script-level variable for further use in the current session
        $script:BaseURI = $BaseURI.AbsoluteUri.TrimEnd('/') + '/rest/api'

        $Pair = "${Username}:${Password}"

        # Encode the string to the RFC2045-MIME variant of Base64, except not limited to 76 char/line.
        $Bytes = [System.Text.Encoding]::ASCII.GetBytes($Pair)
        $Base64 = [System.Convert]::ToBase64String($Bytes)

        # Create the Auth value as the method, a space, and then the encoded pair Method Base64String
        $BasicAuthValue = "Basic $Base64"

        # Create the header hashtable to pass your basic auth
        # Save as script-level variable for further use in the current session
        $script:Header = @{ Authorization = $BasicAuthValue }
    }
}
