function Set-Page {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
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
        [PSCredential]$PersonalAccessToken,

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
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64]$PageID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(ParameterSetName = 'byParameters')]
        [string]$Body,

        [Parameter(ParameterSetName = 'byParameters')]
        [switch]$Convert,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$ParentID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Page]$Parent
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content/{0}"

        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"
        # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
        if ($Convert) {
            Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
        }
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Put'
        $iwParameters['OutputType'] = [ConfluencePS.Page]

        $Content = [PSObject]@{
            type      = "page"
            title     = ""
            body      = [PSObject]@{
                storage = [PSObject]@{
                    value          = ""
                    representation = 'storage'
                }
            }
            version   = [PSObject]@{
                number = 0
            }
            ancestors = @()
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byObject" {
                $iwParameters["Uri"] = $resourceApi -f $InputObject.ID
                $Content.version.number = ++$InputObject.Version.Number
                $Content.title = $InputObject.Title
                $Content.body.storage.value = $InputObject.Body
                # if ($InputObject.Ancestors) {
                # $Content["ancestors"] += @( $InputObject.Ancestors | Foreach-Object { @{ id = $_.ID } } )
                # }
            }
            "byParameters" {
                $iwParameters["Uri"] = $resourceApi -f $PageID
                $originalPage = Get-Page -PageID $PageID @authAndApiUri

                if (($Parent -is [ConfluencePS.Page]) -and ($Parent.ID)) {
                    $ParentID = $Parent.ID
                }

                $Content.version.number = ++$originalPage.Version.Number
                if ($Title) { $Content.title = $Title }
                else { $Content.title = $originalPage.Title }
                # $Body might be empty
                if ($PSBoundParameters.Keys -contains "Body") {
                    $Content.body.storage.value = $Body
                }
                else {
                    $Content.body.storage.value = $originalPage.Body
                }
                # Ancestors is undocumented! May break in the future
                # http://stackoverflow.com/questions/23523705/how-to-create-new-page-in-confluence-using-their-rest-api
                if ($ParentID) {
                    $Content.ancestors = @( @{ id = $ParentID } )
                }
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("Page $($Content.title)")) {
            Invoke-Method @iwParameters
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
