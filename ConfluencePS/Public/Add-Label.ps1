function Add-Label {
    <#
    .SYNOPSIS
    Add a new global label to an existing Confluence page.

    .DESCRIPTION
    Add one or more labels to one or more Confluence pages. Label can be brand new.

    .EXAMPLE
    Add-Label -ApiURi "https://myserver.com/wiki" -Credential $cred -Label alpha,bravo,charlie -PageID 123456 -Verbose
    Apply the labels alpha, bravo, and charlie to the page with ID 123456. Verbose output.

    .EXAMPLE
    Get-Page -SpaceKey SRV | Add-Label -Label servers -WhatIf
    Would apply the label "servers" to all pages in the space with key SRV. -WhatIf flag supported.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.ContentLabelSet])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-Info.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-Info.
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
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('Labels')]
        $Label
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Validade input object from Pipeline
        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int] -or $_ -is [ConfluencePS.ContentLabelSet])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # The parameter "Label" has no type declared. Because of this, a piped object of
        # type "ConfluencePS.ContentLabelSet" will be assigned to "Label". Lets fix this:
        if ($_ -and $Label -is [ConfluencePS.ContentLabelSet]) {
            $Label  = $Label.Labels
        }

        # Allow only for Label to be a [String[]] or [ConfluencePS.Label[]]
        $allowedLabelTypes = @(
            "System.String"
            "System.String[]"
            "ConfluencePS.Label"
            "ConfluencePS.Label[]"
        )
        if ($Label.GetType().FullName -notin $allowedLabelTypes) {
            $message = "Parameter 'Label' is not a Label or a String. It is $($Label.gettype().FullName)"
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # Extract name if an Object is provided
        if (($Label -is [ConfluencePS.Label]) -or $Label -is [ConfluencePS.Label[]]) {
            $Label = $Label | Select -ExpandProperty Name
        }

        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePS.Page]) {
                $InputObject = $_
            }
            elseif ($_ -is [ConfluencePS.ContentLabelSet]) {
                $InputObject = $_.Page
            }
            else {
                $InputObject = Get-Page -PageID $_page -ApiURi $apiURi -Credential $Credential
            }

            $URI = "$apiURi/content/{0}/label" -f $_page

            $Content = $Label | Foreach-Object {@{prefix = 'global'; name = $_}} | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
            If ($PSCmdlet.ShouldProcess("Label $Label, PageID $_page")) {
                $output = New-Object -TypeName ConfluencePS.ContentLabelSet
                $output.Page = $InputObject
                $output.Labels += (Invoke-Method -Uri $URI -Body $Content -Method Post -Credential $Credential -OutputType ([ConfluencePS.Label]))
                $output
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
