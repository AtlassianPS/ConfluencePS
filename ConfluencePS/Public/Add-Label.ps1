function Add-Label {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.ContentLabelSet])]
    param (
        [Parameter( Mandatory = $true )]
        [uri]$ApiUri,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

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

        $resourceApi = "$ApiUri/content/{0}/label"
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
            $Label = $Label.Labels
        }

        # Test if Label is String[]
        [String[]]$_label = $Label
        $_label = $_label | Where-Object {$_ -ne "ConfluencePS.Label"}
        if ($_label) {
            [String[]]$Label = $_label
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

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Post'
        $iwParameters['OutputType'] = [ConfluencePS.Label]

        # Extract name if an Object is provided
        if (($Label -is [ConfluencePS.Label]) -or $Label -is [ConfluencePS.Label[]]) {
            $Label = $Label | Select-Object -ExpandProperty Name
        }

        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePS.Page]) {
                $InputObject = $_
            }
            elseif ($_ -is [ConfluencePS.ContentLabelSet]) {
                $InputObject = $_.Page
            }
            else {
                $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"
                $InputObject = Get-Page -PageID $_page @authAndApiUri
            }

            $iwParameters["Uri"] = $resourceApi -f $_page
            $iwParameters["Body"] = ($Label | Foreach-Object {@{prefix = 'global'; name = $_}}) | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($iwParameters["Body"] | Out-String)"
            if ($PSCmdlet.ShouldProcess("Label $Label, PageID $_page")) {
                $output = [ConfluencePS.ContentLabelSet]@{ Page = $InputObject }
                $output.Labels += (Invoke-Method @iwParameters)
                $output
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
