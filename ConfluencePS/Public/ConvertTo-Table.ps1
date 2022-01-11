function ConvertTo-Table {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        $Content,

        [Switch]$Vertical,

        [Switch]$NoHeader
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $sb = [System.Text.StringBuilder]::new()

        $HeaderGenerated = $NoHeader
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # This ForEach needed if the content wasn't piped in
        $Content | ForEach-Object {
            if ($Vertical) {
                if ($HeaderGenerated) { $pipe = '|' }
                else { $pipe = '||' }

                # Put an empty row between multiple tables (objects)
                if ($Spacer) {
                    $null = $sb.AppendLine('')
                }

                $_.PSObject.Properties | ForEach-Object {
                    $row = ("$pipe {0} $pipe {1} |" -f $_.Name, $_.Value) -replace "\|\s\s", "| "
                    $null = $sb.AppendLine($row)
                }

                $Spacer = $true
            }
            else {
                # Header row enclosed by ||
                if (-not $HeaderGenerated) {
                    $null = $sb.AppendLine("|| {0} ||" -f ($_.PSObject.Properties.Name -join " || "))
                    $HeaderGenerated = $true
                }

                # All other rows enclosed by |
                $row = ("| " + ($_.PSObject.Properties.Value -join " | ") + " |") -replace "\|\s\s", "| "
                $null = $sb.AppendLine($row)
            }
        }
    }

    END {
        # Return the array as one large, multi-line string
        $sb.ToString()

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
