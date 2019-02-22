function Copy-CommonParameter
{
    <#
    .SYNOPSIS
    This is a helper function to assist in creating a hashtable for splatting parameters to inner function calls.

    .DESCRIPTION
    This command copies all of the keys of a hashtable to a new hashtable if the key name matches the DefaultParameter
    or the AdditionalParameter values. This function is designed to help select only function parameters that have been
    set, so they can be passed to inner functions if and only if they have been set.

    .EXAMPLE
    PS C:\> Copy-CommonParameter -InputObject $PSBoundParameters

    Returns a hashtable that contains all of the bound default parameters.

    .EXAMPLE
    PS C:\> Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"

    Returns a hashtable that contains all of the bound default parameters and the "ApiUri" parameter.
    #>
    [CmdletBinding( SupportsShouldProcess = $false )]
    [OutputType(
        [hashtable]
    )]
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
