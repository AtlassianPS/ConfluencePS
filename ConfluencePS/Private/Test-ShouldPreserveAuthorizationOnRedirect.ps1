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
    if ($Uri.Host -notmatch '(^|\.)atlassian\.net$') { return $false }
    if (
        ($Uri.AbsolutePath -notmatch '/download/attachments/') -and
        ($Uri.AbsolutePath -notmatch '/rest/api/content/\d+/child/attachment/\d+/download$')
    ) { return $false }

    (Get-Command -Name 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.ContainsKey('PreserveAuthorizationOnRedirect')
}
