function Test-ShouldPreserveAuthorizationOnRedirect {
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter(Mandatory = $true)]
        [Uri]$Uri,

        [String]$OutFile,

        [PSCredential]$Credential,

        [String]$PersonalAccessToken
    )

    if (-not $OutFile) { return $false }
    if (-not $Credential) { return $false }

    if ($Uri.Scheme -ne 'https') { return $false }
    if ($Uri.AbsolutePath -match '/rest/api/content/\d+/child/attachment/\d+/download$') {
        return (Get-Command -Name 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.ContainsKey('PreserveAuthorizationOnRedirect')
    }
    if ($Uri.Host -notmatch '(^|\.)atlassian\.net$') { return $false }
    if ($Uri.AbsolutePath -notmatch '/download/attachments/') { return $false }

    (Get-Command -Name 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.ContainsKey('PreserveAuthorizationOnRedirect')
}
