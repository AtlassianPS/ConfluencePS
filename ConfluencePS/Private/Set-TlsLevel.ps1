function Set-TlsLevel {
    [CmdletBinding( SupportsShouldProcess = $false )]
    [System.Diagnostics.CodeAnalysis.SuppressMessage(
        "PSUseShouldProcessForStateChangingFunctions",
        "",
        Justification = "The function sets the state of the security protocol for using TLS1.2 and restores it to its original state.")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Set')]
        [Switch]$Tls12,

        [Parameter(Mandatory = $true, ParameterSetName = 'Revert')]
        [Switch]$Revert
    )

    begin {
        switch ($true) {
            $Tls12 {
                $Script:OriginalTlsSettings = [Net.ServicePointManager]::SecurityProtocol
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            }
            $Revert {
                if ($Script:OriginalTlsSettings) {
                    [Net.ServicePointManager]::SecurityProtocol = $Script:OriginalTlsSettings
                }
            }
        }
    }
}
