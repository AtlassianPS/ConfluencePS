function Get-ChildPage {
    [CmdletBinding( SupportsPaging = $true )]
    [OutputType([ConfluencePS.Page])]
    param (
        [Parameter( Mandatory = $true )]
        [Uri]$ApiUri,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [String]
        $PersonalAccessToken,

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
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64]$PageID,

        [Switch]$Recurse,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25,

        [Switch]$ExcludePageBody
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        #Fix: See fix statement below. These two fix statements are tied together
        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [UInt64])) {
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

        $baseGetParameters = @{
            expand = "space,version,body.storage,ancestors"
            limit  = $PageSize
        }
        if ($ExcludePageBody) {
            $baseGetParameters.expand = "space,version,ancestors"
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = $baseGetParameters
        $iwParameters['OutputType'] = [ConfluencePS.Page]

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        if (-not $Recurse.IsPresent) {
            $iwParameters['Uri'] = "$ApiUri/content/{0}/child/page" -f $PageID
            Invoke-Method @iwParameters
            return
        }

        # Prefer the native descendant endpoint to preserve paging semantics and minimize API calls.
        $iwParameters['Uri'] = "$ApiUri/content/{0}/descendant/page" -f $PageID
        try {
            Invoke-Method @iwParameters
            return
        }
        catch {
            $isRecoverableServerResponse = $false
            if (($_.FullyQualifiedErrorId -match 'InvalidResponse\.Status(500|502|503|504)') -or
                (($_.Exception -is [System.ArgumentException]) -and ($_.Exception.Message -eq 'Invalid Server Response'))) {
                $isRecoverableServerResponse = $true
            }

            if (-not $isRecoverableServerResponse) {
                throw
            }

            Write-Warning "Confluence descendant endpoint is unstable; falling back to iterative child-page traversal."
        }

        # Fallback: breadth-first traversal via child/page, then apply paging globally.
        $fallbackParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $fallbackParameters['Method'] = 'Get'
        $fallbackParameters['GetParameters'] = $baseGetParameters
        $fallbackParameters['OutputType'] = [ConfluencePS.Page]
        $fallbackParameters.Remove('IncludeTotalCount') | Out-Null
        $fallbackParameters.Remove('First') | Out-Null
        $fallbackParameters.Remove('Skip') | Out-Null

        $allPages = New-Object System.Collections.Generic.List[ConfluencePS.Page]
        $visitedPageIds = New-Object System.Collections.Generic.HashSet[UInt64]
        $pagesToVisit = New-Object System.Collections.Generic.Queue[UInt64]
        $pagesToVisit.Enqueue($PageID)

        while ($pagesToVisit.Count -gt 0) {
            $currentPageId = $pagesToVisit.Dequeue()
            $fallbackParameters['Uri'] = "$ApiUri/content/{0}/child/page" -f $currentPageId
            $childPages = @(Invoke-Method @fallbackParameters)

            foreach ($childPage in $childPages) {
                if ((-not $childPage) -or (-not $visitedPageIds.Add($childPage.ID))) {
                    continue
                }

                $allPages.Add($childPage)
                $pagesToVisit.Enqueue($childPage.ID)
            }
        }

        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
            [double]$accuracy = 0.0
            $PSCmdlet.PagingParameters.NewTotalCount($allPages.Count, $accuracy)
        }

        $pagedResults = @($allPages)
        if ($PSBoundParameters.ContainsKey('Skip')) {
            $pagedResults = @($pagedResults | Select-Object -Skip $PSCmdlet.PagingParameters.Skip)
        }
        if ($PSBoundParameters.ContainsKey('First')) {
            $pagedResults = @($pagedResults | Select-Object -First $PSCmdlet.PagingParameters.First)
        }

        $pagedResults
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
