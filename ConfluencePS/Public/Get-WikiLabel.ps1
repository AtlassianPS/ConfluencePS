function Get-WikiLabel {
    <#
    .SYNOPSIS
    Returns the list of labels.

    .DESCRIPTION
    View all labels applied to a content.

    .EXAMPLE
    Get-WikiLabel -PageID 123456 -PageSize 500 -ApiURi "https://myserver.com/wiki" -Credential $cred
    Lists the labels applied to page 123456.
    This also increases the size of the result's page from 25 to 500.

    .EXAMPLE
    Get-WikiPage -SpaceKey NASA | Get-WikiLabel -Verbose
    Get all pages that exist in NASA space (literally?).
    Search all of those pages (piped to -PageID) for all of their active labels.
    Verbose flag would be good here to keep track of the request.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding()]
    [OutputType([ConfluencePS.Label])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # List the PageID number to check for labels. Accepts piped input.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int]$PageID,

        # Maximimum number of results to fetch per call.
        # This setting can be tuned to get better performance according to the load on the server.
        # Warning: too high of a PageSize can cause a timeout on the request.
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize = 25
    )

    BEGIN {
        $result = @()
    }

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        if (!($_)) {
            $InputObject = Get-WikiPage -PageID $PageID
        }
        else {
            $InputObject = $_
        }

        Write-Verbose "Processing request for PageID $PageID"
        $URI = "$apiURi/content/{0}/label" -f $PageID

        If ($PageSize) { $GETparameters = @{limit = $PageSize} }

        $output = New-Object -TypeName ConfluencePS.ContentLabelSet -Property @{
            Page = $InputObject
        }

        Write-Verbose "Fetching info from $URI"
        $output.Labels += (Invoke-WikiMethod -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Label]))
        $output
    }
}
