function Get-Attachment {
    [CmdletBinding( SupportsPaging = $true )]
    [OutputType([ConfluencePS.Attachment])]
    param (
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

        [String]$FileNameFilter,

        [String]$MediaTypeFilter,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
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
                Uri           = "$apiURi/content/{0}/child/attachment" -f $_PageID
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
                $iwParameters["GetParameters"]["mediatype"] = $MediaTypeFilter
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
