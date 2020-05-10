function Set-TlsLevel {
    [CmdletBinding( SupportsShouldProcess = $false )]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Set')]
        [Switch]$Tls12,

        [Parameter(Mandatory = $true, ParameterSetName = 'Revert')]
        [Switch]$Revert
    )

    begin {
        switch ($PSCmdlet.ParameterSetName) {
            "Set" {
                $null = $Tls12 #Test usinf parameter
                $Script:OriginalTlsSettings = [Net.ServicePointManager]::SecurityProtocol
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            }
            "Revert" {
                if ($Script:OriginalTlsSettings) {
                    $null = $Revert #Test usinf parameter
                    [Net.ServicePointManager]::SecurityProtocol = $Script:OriginalTlsSettings
                }
            }
        }
    }
}
