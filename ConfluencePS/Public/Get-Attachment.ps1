function Get-Attachment {
    [CmdletBinding( SupportsPaging = $true )]
    [OutputType([ConfluencePS.Attachment])]
    param (
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [Int[]]$PageID,

        [String]$FileNameFilter,

        [String]$MediaTypeFilter,

        [ValidateRange(1, [int]::MaxValue)]
        [Int]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $resourceApi = "$apiURi/content/{0}/child/attachment"
    }

    PROCESS {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        foreach ($_PageID in $PageID) {
            $iwParameters = @{
                Uri           = $resourceApi -f $_PageID
                Method        = 'Get'
                GetParameters = @{
                    expand = "version"
                    limit  = $PageSize
                }
                OutputType    = [ConfluencePS.Attachment]
                Credential    = $Credential
            }

            if ($FileNameFilter) {
                $iwParameters["GetParameters"]["filename"] = $FileNameFilter
            }

            if ($MediaTypeFilter) {
                $iwParameters["GetParameters"]["mediaType"] = $MediaTypeFilter
            }

            # Paging
            ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
            }

            Invoke-Method @iwParameters
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
