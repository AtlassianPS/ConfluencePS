function Get-Label {
    [CmdletBinding(
        SupportsPaging = $true
    )]
    [OutputType([ConfluencePS.ContentLabelSet])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-ConfluenceInfo.
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
        [int[]]$PageID,

        # Maximimum number of results to fetch per call.
        # This setting can be tuned to get better performance according to the load on the server.
        # Warning: too high of a PageSize can cause a timeout on the request.
        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
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

        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePS.Page]) {
                $InputObject = $_
            }
            else {
                $InputObject = Get-Page -PageID $_page -ApiURi $apiURi -Credential $Credential
            }

            $URI = "$apiURi/content/{0}/label" -f $_page
            If ($PageSize) { $GETparameters = @{limit = $PageSize}
            }

            $output = New-Object -TypeName ConfluencePS.ContentLabelSet -Property @{
                Page = $InputObject
            }

            $output.Labels += (Invoke-Method -Uri $URI -Method Get -Credential $Credential -GetParameters $GETparameters -OutputType ([ConfluencePS.Label]))
            $output
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
