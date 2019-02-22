function Get-ChildPage {
    [CmdletBinding( SupportsPaging = $true )]
    [OutputType([ConfluencePS.Page])]
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
        [int]$PageID,

        [switch]$Recurse,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        #Fix: See fix statement below. These two fix statements are tied together
        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        #Fix: This doesn't get called since there are no parameter sets for this function. It must be
        #copy paste from another function. This function doesn't really accept ConfluencePS.Page objects, it only
        #works due to powershell grabbing the 'ID' from ConfluencePS.Page using the
        #'ValueFromPipelineByPropertyName = $true' and '[Alias('ID')]' on the PageID Parameter.
        if ($PsCmdlet.ParameterSetName -eq "byObject") {
            $PageID = $InputObject.ID
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Uri'] = if ($Recurse.IsPresent) {"$ApiUri/content/{0}/descendant/page" -f $PageID} else {"$ApiUri/content/{0}/child/page" -f $PageID}
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{
            expand = "space,version,body.storage,ancestors"
            limit  = $PageSize
        }
        $iwParameters['OutputType'] = [ConfluencePS.Page]

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        Invoke-Method @iwParameters
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
