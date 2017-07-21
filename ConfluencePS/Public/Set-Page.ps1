﻿function Set-Page {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
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

        # The ID of the page to edit
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int]$PageID,

        # Name of the page; existing or new value can be used.
        # Existing will be automatically supplied via Get-ConfluencePage if not manually included.
        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        # The full contents of the updated body (existing contents will be overwritten).
        # If not yet in "storage format"--or you don't know what that is--also use -Convert.
        [Parameter(ParameterSetName = 'byParameters')]
        [string]$Body,

        # Optional switch flag for calling ConvertTo-ConfluenceStorageFormat against your Body.
        [Parameter(ParameterSetName = 'byParameters')]
        [switch]$Convert,

        # Optionally define a new parent page. If unspecified, no change.
        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ParentID,
        # Optionally define a new parent page. If unspecified, no change.
        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Page]$Parent
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$apiURi/content/{0}"

        # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
        If ($Convert) {
            Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-StorageFormat -Content $Body -ApiURi $apiURi -Credential $Credential
        }
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Uri        = ""
            Method     = 'Put'
            Body       = ""
            OutputType = [ConfluencePS.Page]
            Credential = $Credential
        }
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
                $originalPage = Get-Page -PageID $PageID -ApiURi $apiURi -Credential $Credential

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
