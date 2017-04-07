﻿function New-WikiLabel {
    <#
    .SYNOPSIS
    Add a new global label to an existing Confluence page.

    .DESCRIPTION
    Add one or more labels to one or more Confluence pages. Label can be brand new.

    .EXAMPLE
    New-WikiLabel -Label alpha,bravo,charlie -PageID 123456 -Verbose
    Apply the labels alpha, bravo, and charlie to the page with ID 123456. Verbose output.

    .EXAMPLE
    Get-WikiPage -SpaceKey SRV | New-WikiLabel -Label servers -WhatIf
    Would apply the label "servers" to all pages in the space with key SRV. -WhatIf flag supported.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.Label])]
    param (
        # The page ID to apply the label to. Accepts multiple IDs via pipeline input.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

        # One or more labels to be added. Currently supports labels of prefix "global."
        [Parameter(Mandatory = $true)]
        [string[]]$Label
    )

    BEGIN {
        If (!($Credential) -or !($BaseURI)) {
            Write-Warning 'Confluence instance info not yet defined in this session. Calling Set-WikiInfo'
            Set-WikiInfo
        }
    }

    PROCESS {
        Write-Debug "ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "PSBoundParameters: $($PSBoundParameters | Out-String)"
        if (($_) -and ($_ -isnot [ConfluencePS.Page])) {
            if (!$Force) {
                Write-Warning "The Object in the pipe is not a Page"
            }
        }

        foreach ($_page in $PageID) {
            $URI = "$BaseURI/content/{0}/label" -f $_page

            $Content = $Label | Foreach-Object {@{prefix = 'global'; name = $_}} | ConvertTo-Json

            Write-Verbose "Posting to $URI"
            Write-Verbose "Content: $($Content | Out-String)"
            If ($PSCmdlet.ShouldProcess("Label $Label, PageID $PageID")) {
                $response = Invoke-WikiMethod -Uri $URI -Body $Content -Method Post

                if ($response | Get-Member -Name results) {
                    # Extract from array
                    $response = $response | Select-Object -ExpandProperty results
                }
                if (($response | Measure-Object).count -ge 1) {
                    foreach ($item in $response) {
                        $item | ConvertTo-WikiLabel
                    }
                }
            }
        }
    }
}
