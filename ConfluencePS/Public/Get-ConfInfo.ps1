function Get-ConfInfo {
    <#
    .SYNOPSIS
    Gather URI/auth info for use in this session's REST API requests.

    .DESCRIPTION
    Anonymous access to the Confluence REST API is disabled by default.
    Unless manually enabled, you will need to pass authorization in all interactions.
    (If you have a better suggestion for how to handle this, please reach out on GitHub!)

    .PARAMETER BaseURI
    Address of your base Confluence install. For Atlassian On-Demand instances, include /wiki.

    .PARAMETER Credential
    The username/password combo you use to log in to Confluence.

    .EXAMPLE
    Get-ConfInfo -BaseURI 'https://brianbunke.atlassian.net/wiki'
    Declare your base install; be prompted for username and password.
    Stored in script-scope variables $BaseURI and $Header.
    
    .LINK
    https://github.com/brianbunke/ConfluencePS

    .LINK
    http://stackoverflow.com/questions/27951561/use-invoke-webrequest-with-a-username-and-password-for-basic-authentication-on-t

    .LINK
    http://www.dexterposh.com/2015/01/powershell-rest-api-basic-cms-cmsurl.html
    #>
	[CmdletBinding()]
	param (
	    [Parameter(HelpMessage = 'Example = https://brianbunke.atlassian.net/wiki (/wiki for On-Demand instances)')]
	    [ValidateNotNullorEmpty()]
        [Uri]$BaseURI = 'https://brianbunke.atlassian.net/wiki',

	    [ValidateNotNullorEmpty()]
        $Credential = (Get-Credential)
    )

    PROCESS {
        # Append the common /rest/api to the URI
        # Save as script-level variable for further use in the current session
        $script:BaseURI = $BaseURI.AbsoluteUri.TrimEnd('/') + '/rest/api'

        # Format as user:pass, call the .NET GetBytes method, convert it to Base64
        $SecureCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password)))

        # Create the header hashtable to pass your basic auth
        # Save as script-level variable for further use in the current session
        $script:Header = @{ Authorization = "Basic $($SecureCreds)" }
    }
}
