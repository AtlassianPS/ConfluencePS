function Get-ChildPage {
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byID"
    )]
    [OutputType([ConfluencePS.Page])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-ConfluenceInfo.
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

        Invoke-Method -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Page])
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
