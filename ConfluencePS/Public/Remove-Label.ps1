function Remove-Label {
    <#
    .SYNOPSIS
    Remove a label from existing Confluence content.

    .DESCRIPTION
    Remove a single label from Confluence content.
    Does accept multiple pages piped via Get-ConfluencePage.
    Specifically tested against pages, but should work against all content IDs.

    .EXAMPLE
    Remove-ConfluenceLabel -ApiURi "https://myserver.com/wiki" -Credential $cred -Label seven -PageID 123456 -Verbose -Confirm
    Would remove label "seven" from the page with ID 123456.
    Verbose and Confirm flags both active.

    .EXAMPLE
    Get-ConfluencePage -SpaceKey "ABC" | Remove-ConfluenceLabel -Label asdf -WhatIf
    Would remove the label "asdf" from all pages in the ABC space.

    .EXAMPLE
    (Get-ConfluenceSpace "ABC").Homepage | Remove-ConfluenceLabel
    Removes all labels from the homepage of the ABC space.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([Bool])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-ConfluenceInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # The page ID to remove the label from. Accepts multiple IDs via pipeline input.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

        # A single content label to remove from one or more pages.
        [Parameter()]
        [string[]]$Label
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$apiURi/content/{0}/label?name={1}"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        $iwParameters = @{
            Uri        = ""
            Method     = 'Delete'
            Credential = $Credential
        }

        foreach ($_page in $PageID) {
            $_labels = $Label
            if (!$_labels) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Collecting all Labels for page $_page"
                $allLabels = Get-Label -PageID $_page -ApiURi $apiURi -Credential $Credential
                if ($allLabels.Labels) {
                    $_labels = $allLabels.Labels | Select -ExpandProperty Name
                }
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Labels to remove: `$_labels"

            foreach ($_label in $_labels) {
                $iwParameters["Uri"] = $resourceApi -f $_page, $_label

                If ($PSCmdlet.ShouldProcess("Label $_label, PageID $_page")) {
                    Invoke-Method @iwParameters
                }
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
