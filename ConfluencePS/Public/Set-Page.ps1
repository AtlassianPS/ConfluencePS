function Set-Page {
    <#
    .SYNOPSIS
    Edit an existing Confluence page.

    .DESCRIPTION
    For existing page(s): Edit page content, page title, and/or change parent page.
    Content needs to be in "Confluence storage format." Use -Convert if not preconditioned.

    .EXAMPLE
    Get-ConfluencePage -Title 'My First Page' -Expand | Set-ConfluencePage -Body 'Hello World!' -Convert
    Probably the easiest edit method, overwriting contents with a short sentence.
    Use Get-ConfluencePage -Expand to pipe in PageID & CurrentVersion.
    (See "Get-Help Get-ConfluencePage -Examples" for help with -Expand and >100 pages.)
    -Convert molds the sentence into a format Confluence will accept.

    .EXAMPLE
    Get-ConfluencePage -Title 'Lew Alcindor' -Limit 100 -Expand | Set-ConfluencePage -Title 'Kareem Abdul-Jabbar' -Verbose
    Change the page's name. Body remains the same, via piping the existing contents.
    Verbose flag active for additional screen output.

    .EXAMPLE
    Get-ConfluencePage -SpaceKey MATRIX | Set-ConfluencePage -Body 'Agent Smith' -Convert -WhatIf
    Overwrites the contents of all pages in the MATRIX space.
    WhatIf flag tells you how many pages would have been affected.

    .EXAMPLE
    Set-ConfluencePage -PageID 12345 -Title 'My Luggage Combo' -CurrentVersion 1 -Body '<p>Spaceballs</p>'
    An example of what needs to be known and specified to avoid:
    1) Piping in values required for the PUT method
    2) Calling Get-ConfluencePage mid-function to retrieve those same values
    3) Calling ConvertTo-ConfluenceStorageFormat mid-function to condition the string

    .LINK
    Get-ConfluencePage

    .LINK
    ConvertTo-ConfluenceStorageFormat

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
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

        # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
        If ($Convert) {
            Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-StorageFormat -Content $Body -ApiURi $apiURi -Credential $Credential
        }
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PsCmdlet.ParameterSetName) {
            "byObject" {
                $URI = "$apiURi/content/{0}" -f $InputObject.ID

                $Content = @{
                    version = @{ number = ++$InputObject.Version.Number }
                    title = $InputObject.Title
                    type = 'page'
                    body = @{
                        storage = @{
                            value = $InputObject.Body
                            representation = 'storage'
                        }
                    }
                    # ancestors = @()
                }
                # Ancestors is undocumented! May break in the future
                # http://stackoverflow.com/questions/23523705/how-to-create-new-page-in-confluence-using-their-rest-api
                # if ($InputObject.Ancestors) {
                # $Content["ancestors"] += @( $InputObject.Ancestors | Foreach-Object { @{ id = $_.ID } } )
                # }
            }
            "byParameters" {
                $URI = "$apiURi/content/{0}" -f $PageID
                $originalPage = Get-Page -PageID $PageID -ApiURi $apiURi -Credential $Credential

                if (($Parent -is [ConfluencePS.Page]) -and ($Parent.ID)) {
                    $ParentID = $Parent.ID
                }

                $Content = @{
                    version = @{ number = ++$originalPage.Version.Number }
                    type = 'page'
                }
                if ($Title) {
                    $Content["title"] = $Title
                }
                else {
                    $Content["title"] = $originalPage.Title
                }
                # $Body might be empty
                if ($PSBoundParameters.Keys -contains "Body") {
                    $Content["body"] = @{ storage = @{ value = $Body; representation = 'storage' }}
                }
                else {
                    $Content["body"] = @{ storage = @{ value = $originalPage.Body; representation = 'storage' }}
                }
                # Ancestors is undocumented! May break in the future
                # http://stackoverflow.com/questions/23523705/how-to-create-new-page-in-confluence-using-their-rest-api
                if ($ParentID) {
                    $Content["ancestors"] = @( @{ id = $ParentID } )
                }
            }
        }

        $Content = $Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("Space $SpaceKey, Parent $ParentID")) {
            Invoke-Method -Uri $URI -Body $Content -Method Put -Credential $Credential -OutputType ([ConfluencePS.Page])
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
