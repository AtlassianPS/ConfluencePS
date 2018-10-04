function ConvertTo-Table {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        $Content,

        [switch]$NoHeader
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $RowArray = New-Object System.Collections.Generic.List[string]
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        If ($NoHeader) {
            $HeaderGenerated = $true
        }

        # This ForEach needed if the content wasn't piped in
        $Content | ForEach-Object {
            # Header row enclosed by ||
            If ($null -eq $HeaderGenerated) {
                $_.PSObject.Properties | ForEach-Object `
                    -Begin   {$Header = ""} `
                    -Process {$Header += "||$($_.Name)"} `
                    -End     {$Header += "||"}
                [void]$RowArray.Add($Header)
                $HeaderGenerated = $true
            }

            # All other rows enclosed by |
            $_.PSObject.Properties | ForEach-Object `
                -Begin   {$Row = ""} `
                -Process {
                    if ($_.value) {$Row += "|$($_.Value)"}
                    else          {$Row += "| "}
                } `
                -End     {$Row += "|"}
            [void]$RowArray.Add($Row) | Out-Null
        }
    }

    END {
        # Return the array as one large, multi-line string
        $RowArray | Out-String

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
