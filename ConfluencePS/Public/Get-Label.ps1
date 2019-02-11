function Get-Label {
    [CmdletBinding(
        SupportsPaging = $true
    )]
    [OutputType([ConfluencePS.ContentLabelSet])]
    param (
        [Parameter( Mandatory = $true )]
        [uri]$ApiUri,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content/{0}/label"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method']        = 'Get'
        $iwParameters['GetParameters'] = @{
                                            limit  = $PageSize
                                         }
        $iwParameters['OutputType']    = [ConfluencePS.Label]

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePS.Page]) {
                $InputObject = $_
            }
            else {
                $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"
                $InputObject = Get-Page -PageID $_page @authAndApiUri
            }
            $iwParameters["Uri"] = $resourceApi -f $_page
            $output = New-Object -TypeName ConfluencePS.ContentLabelSet
            $output.Page = $InputObject
            $output.Labels += (Invoke-Method @iwParameters)
            $output
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
