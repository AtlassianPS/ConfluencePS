function Set-TlsLevel {
    [CmdletBinding( SupportsShouldProcess = $false )]
    [System.Diagnostics.CodeAnalysis.SuppressMessage(
        "PSUseShouldProcessForStateChangingFunctions",
        "",
        Justification = "The function sets the state of the security protocol for using TLS1.2 and restores it to its original state.")]
    [System.Diagnostics.CodeAnalysis.SuppressMessage(
        "PSReviewUnusedParameter",
        "",
        Justification = "Unused parameters are used through ParameterSetName.")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Set')]
        [Switch]$Tls12,

        [Parameter(Mandatory = $true, ParameterSetName = 'Revert')]
        [Switch]$Revert
    )

    begin {
        switch ($PSCmdlet.ParameterSetName) {
            'Set' {
                $Script:OriginalTlsSettings = [Net.ServicePointManager]::SecurityProtocol
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            }
            'Revert' {
                if ($Script:OriginalTlsSettings) {
                    [Net.ServicePointManager]::SecurityProtocol = $Script:OriginalTlsSettings
                }
            }
        }
    }
}
