function New-Page {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byParameters'
    )]
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
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byObject'
        )]
        [ConfluencePS.Page]$InputObject,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [Alias('Name')]
        [string]$Title,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$ParentID,
        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Page]$Parent,

        [Parameter(ParameterSetName = 'byParameters')]
        [string]$SpaceKey,
        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Space]$Space,

        [Parameter(ParameterSetName = 'byParameters')]
        [string]$Body,

        [Parameter(ParameterSetName = 'byParameters')]
        [switch]$Convert
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content"

        #this is the splat hashtable that passes the auth and uri to calls but not Invoke-Method, i.e. Get-Page
        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Uri'] = $resourceApi
        $iwParameters['Method'] = 'Post'
        $iwParameters['OutputType'] = [ConfluencePS.Page]

        $Content = [PSObject]@{
            type      = "page"
            space     = [PSObject]@{ key = "" }
            title     = ""
            body      = [PSObject]@{
                storage = [PSObject]@{
                    representation = 'storage'
                }
            }
            ancestors = @()
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byObject" {
                $Content.title = $InputObject.Title
                $Content.space.key = $InputObject.Space.Key
                $Content.body.storage.value = $InputObject.Body
                if ($InputObject.Ancestors) {
                    $Content.ancestors += @( $InputObject.Ancestors | ForEach-Object { @{ id = $_.ID } } )
                }
            }
            "byParameters" {
                if (($Parent -is [ConfluencePS.Page]) -and ($Parent.ID)) {
                    $ParentID = $Parent.ID
                }
                if (($Space -is [ConfluencePS.Space]) -and ($Space.Key)) {
                    $SpaceKey = $Space.Key
                }

                if (($ParentID) -and !($SpaceKey)) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] SpaceKey not specified. Retrieving from Get-ConfluencePage -PageID $ParentID"
                    $SpaceKey = (Get-Page -PageID $ParentID @authAndApiUri).Space.Key
                }

                # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
                if ($Convert) {
                    Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
                    $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
                }

                $Content.title = $Title
                $Content.space = @{ key = $SpaceKey }
                $Content.body.storage.value = $Body
                if ($ParentID) {
                    $Content.ancestors = @( @{ id = $ParentID } )
                }
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("Space $($Content.space.key)")) {
            Invoke-Method @iwParameters
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
