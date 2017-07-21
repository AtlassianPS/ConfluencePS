function New-Page {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byParameters'
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

        # Page Object
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byObject'
        )]
        [ConfluencePS.Page]$InputObject,

        # Name of your new page.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [Alias('Name')]
        [string]$Title,

        # The ID of the parent page.
        # NOTE: This feature is not in the 5.8 REST API documentation, and should be considered experimental.
        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ParentID,
        # Page Object of the parent page.
        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Page]$Parent,

        # Key of the space where the new page should exist. Only needed if you don't utilize ParentID.
        [Parameter(ParameterSetName = 'byParameters')]
        [string]$SpaceKey,
        # Space Object in which to create the new page.
        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Space]$Space,

        # The contents of your new page. Accepts pipeline input by property name.
        [Parameter(ParameterSetName = 'byParameters')]
        [string]$Body,

        # Optional flag to call ConvertTo-ConfluenceStorageFormat against your Body.
        [Parameter(ParameterSetName = 'byParameters')]
        [switch]$Convert
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$apiURi/content"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Uri        = $resourceApi
            Method     = 'Post'
            Body       = ""
            OutputType = [ConfluencePS.Page]
            Credential = $Credential
        }
        $Content = [PSObject]@{
            type      = "page"
            space     = [PSObject]@{ key = ""}
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
                    $Content.ancestors += @( $InputObject.Ancestors | Foreach-Object { @{ id = $_.ID } } )
                }
            }
            "byParameters" {
                if (($Parent -is [ConfluencePS.Page]) -and ($Parent.ID)) {
                    $ParentID = $Parent.ID
                }
                if (($Space -is [ConfluencePS.Space]) -and ($Space.Key)) {
                    $SpaceKey = $Space.Key
                }

                If (($ParentID) -and !($SpaceKey)) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] SpaceKey not specified. Retrieving from Get-ConfluencePage -PageID $ParentID"
                    $SpaceKey = (Get-Page -PageID $ParentID -ApiURi $apiURi -Credential $Credential).Space.Key
                }

                # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
                If ($Convert) {
                    Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
                    $Body = ConvertTo-StorageFormat -Content $Body -ApiURi $apiURi -Credential $Credential
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
