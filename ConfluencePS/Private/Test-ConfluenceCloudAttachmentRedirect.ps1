function Test-ConfluenceCloudAttachmentRedirect {
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter(Mandatory = $true)]
        [Uri]$Uri
    )

    # Cloud attachment downloads redirect to Atlassian media hosts and need auth preserved.
    ($Uri.Scheme -eq 'https') -and
    ($Uri.Host -match '(^|\.)atlassian\.net$') -and
    ($Uri.AbsolutePath -match '/download/attachments/')
}
