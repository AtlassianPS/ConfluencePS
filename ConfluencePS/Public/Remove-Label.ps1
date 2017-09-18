function Remove-Label {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([Bool])]
    param (
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

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
                    $_labels = $allLabels.Labels | Select-Object -ExpandProperty Name
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
