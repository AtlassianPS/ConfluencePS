function Get-WikiChildPage {
    <#
    .SYNOPSIS
    For a given wiki page, list all child wiki pages.

    .DESCRIPTION
    Pipeline input of ParentID is accepted.

    This API method only returns the immediate children (results are not recursive).

    .PARAMETER Skip
    Controls how many things will be skipped before starting output. Defaults to 0.

    .PARAMETER First
    Currently not supported.
    Indicates how many items to return. Defaults to 100.

    .PARAMETER IncludeTotalCount
    Causes an extra output of the total count at the beginning.
    Note this is actually a uInt64, but with a custom string representation.

    .EXAMPLE
    Get-WikiChildPage -ParentID 1234 | Select-Object ID, Title | Sort-Object Title
    For the wiki page with ID 1234, get all pages immediately beneath it.
    Returns only each page's ID and Title, sorting results alphabetically by Title.

    .EXAMPLE
    Get-WikiPage -Title 'Genghis Khan' | Get-WikiChildPage -Limit 500
    Find the Genghis Khan wiki page and pipe the results.
    Get only the first 500 children beneath that page.

    .EXAMPLE
    Get-WikiChildPage -ParentID 9999 -Expand -Limit 100
    For each child page found, expand the results to also include properties
    like Body and Version (Ver). Typically, using -Expand will not return
    more than 100 results, even if -Limit is set to a higher value.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byID"
    )]
    [OutputType([ConfluencePS.Page])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # Filter results by page ID.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "byID"
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int]$PageID,

        # Get all child pages recursively
        [switch]$Recurse,

        # Defaults to 25 max results; can be modified here.
        # Numbers above 100 may not be honored if -Expand is used.
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $depthLevel = "child"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $script:PSDefaultParameterValues["Invoke-WikiMethod:$_"] = $PSCmdlet.PagingParameters.$_
        }

        if ($PsCmdlet.ParameterSetName -eq "byObject") {
            $PageID = $InputObject.ID
        }
        if ($Recurse) {$depthLevel = "descendant"} # depth = ALL

        $URI = "$apiURi/content/{0}/{1}/page" -f $PageID, $depthLevel
        $GETparameters = @{expand = "space,version,body.storage,ancestors"}
        If ($PageSize) { $GETparameters["limit"] = $PageSize }

        Invoke-WikiMethod -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Page])
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
