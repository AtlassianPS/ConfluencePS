function Copy-CommonParameter
{
    [CmdletBinding( SupportsShouldProcess = $false )]
    [OutputType(
        [hashtable]
    )]
    #[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [hashtable]$InputObject,

        [Parameter(Mandatory = $false)]
        [string[]]$AdditionalParameter,

        [Parameter(Mandatory = $false)]
        [string[]]$DefaultParameter = @("Credential", "Certificate")
    )

    [hashtable]$ht = @{}
    foreach($key in $InputObject.Keys)
    {
        if ($key -in ($DefaultParameter + $AdditionalParameter))
        {
            $ht[$key] = $InputObject[$key]
        }
    }

    return $ht
}
