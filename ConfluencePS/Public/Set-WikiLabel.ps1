function Set-WikiLabel {
    <#
    .SYNOPSIS
    Sets the label for an existing Confluence content.

    .DESCRIPTION
    Sets the label for Confluence content.
    All previous labels will be removed in the process.

    .EXAMPLE
    Set-WikiLabel -ApiURi "https://myserver.com/wiki" -Credential $cred -Label seven -PageID 123456 -Verbose -Confirm
    Would remove any label previously assigned to the page with ID 123456 and would add the label "seven"
    Verbose and Confirm flags both active.

    .EXAMPLE
    Get-WikiPage -SpaceKey "ABC" | Set-WikiLabel -Label "asdf","qwer" -WhatIf
    Would remove all labels and adds "asdf" and "qwer" to all pages in the ABC space.

    .LINK
    https://github.com/brianbunke/ConfluencePS
    #>
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.ContentLabelSet])]
    param (
        # The URi of the API interface.
        # Value can be set persistently with Set-WikiInfo.
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        # Confluence's credentials for authentication.
        # Value can be set persistently with Set-WikiInfo.
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

        # Label names to add to the content.
        [Parameter(Mandatory = $true)]
        [string[]]$Label
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [int])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePS.Page]) {
                $InputObject = $_
            }
            else {
                $InputObject = Get-WikiPage -PageID $_page
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Removing all previous labels"
            Remove-WikiLabel -PageID $_page | Out-Null

            $URI = "$apiURi/content/{0}/label" -f $_page

            $Content = $Label | Foreach-Object {@{prefix = 'global'; name = $_}} | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
            If ($PSCmdlet.ShouldProcess("Label $Label, PageID $_page")) {
                $output = New-Object -TypeName ConfluencePS.ContentLabelSet
                $output.Page = $InputObject
                $output.Labels += (Invoke-WikiMethod -Uri $URI -Body $Content -Method Post -Credential $Credential -OutputType ([ConfluencePS.Label]))
                $output
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
