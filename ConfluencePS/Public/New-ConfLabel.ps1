function New-ConfLabel {
    <#
    .SYNOPSIS
    Add a new global label to an existing Confluence page.

    .DESCRIPTION
    Add one or more labels to one or more Confluence pages. Label can be brand new.

    .PARAMETER Label
    One or more labels to be added. Currently supports labels of prefix "global."

    .PARAMETER PageID
    The page ID to apply the label to. Accepts multiple IDs via pipeline input.

    .EXAMPLE
    New-ConfLabel -Label alpha,bravo,charlie -PageID 123456 -Verbose
    Apply the labels alpha, bravo, and charlie to the page with ID 123456. Verbose output.

    .EXAMPLE
    Get-ConfPage -SpaceKey SRV | New-ConfLabel -Label servers -WhatIf
    Would apply the label "servers" to all pages in the space with key SRV. -WhatIf flag supported.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
    param (
		[Parameter(Mandatory = $true)]
        [string[]]$Label,

		[Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
		[Alias('ID')]
        [int]$PageID
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Get-ConfInfo'
            Get-ConfInfo
        }
    }

    PROCESS {
        
        # Set both of these for use inside the ForEach
        $Int = 0
        $Body = @()
        
        ForEach ($SingleLabel in $Label) {
            # If not the first loop, add a comma to separate previous
            If ($Int -gt 0) {
                $Body += ','
            }

            $Body += @{prefix = 'global'
                       name   = "$SingleLabel"
                      } | ConvertTo-Json -Compress

            $Int++
        }

        $Body = '[' + $Body + ']'

        $URI = $BaseURI + "/content/$PageID/label"

        Write-Verbose "Posting to $URI"
        If ($PSCmdlet.ShouldProcess("Label $Label, PageID $PageID")) {
            $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Body $Body -Method Post -ContentType 'application/json'

            # Hashing everything because I don't like the lower case property names from the REST call
            ForEach ($Result in $Rest.results) {
                $Result | Select @{n='Label';   e={$_.name}},
                                 @{n='LabelID'; e={$_.id}},
                                 @{n='Prefix';  e={$_.prefix}},
                                 @{n='PageID';  e={$PageID}}
            }
        }
    }
}
