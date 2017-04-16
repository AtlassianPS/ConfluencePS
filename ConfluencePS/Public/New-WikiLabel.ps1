﻿function New-WikiLabel {
    <#
    .SYNOPSIS
    Add a new global label to an existing Confluence page.

    .DESCRIPTION
    Add one or more labels to one or more Confluence pages. Label can be brand new.

    .EXAMPLE
    New-WikiLabel -ApiURi "https://myserver.com/wiki" -Credential $cred -Label alpha,bravo,charlie -PageID 123456 -Verbose
    Apply the labels alpha, bravo, and charlie to the page with ID 123456. Verbose output.

    .EXAMPLE
    Get-WikiPage -SpaceKey SRV | New-WikiLabel -Label servers -WhatIf
    Would apply the label "servers" to all pages in the space with key SRV. -WhatIf flag supported.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byLabelName'
    )]
    [OutputType([ConfluencePS.Label])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        # The page ID to apply the label to. Accepts multiple IDs via pipeline input.
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

        # One or more labels to be added. Currently supports labels of prefix "global."
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byLabelName'
        )]
        [string[]]$Label,

        # Labels from a ContentLabelSet.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'byLabelSet'
        )]
        [ConfluencePS.ContentLabelSet]$Labels
    )

    DynamicParam {
        if (!($Page)) {
            $paramDictionary["PageID"] | Out-String | Write-Host
        }
    }

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"
        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int] -or $_ -is [ConfluencePS.ContentLabelSet])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        if ($Labels) {
            $Label = $Labels.Labels | Select -ExpandProperty Name
        }

        foreach ($_page in $PageID) {
            $URI = "$apiURi/content/{0}/label" -f $_page

            $Content = $Label | Foreach-Object {@{prefix = 'global'; name = $_}} | ConvertTo-Json

            Write-Verbose "Posting to $URI"
            Write-Verbose "Content: $($Content | Out-String)"
            If ($PSCmdlet.ShouldProcess("Label $Label, PageID $PageID")) {
                Invoke-WikiMethod -Uri $URI -Body $Content -Method Post -Credential $Credential -OutputType ([ConfluencePS.Label])
            }
        }
    }
}
