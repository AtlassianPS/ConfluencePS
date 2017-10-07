function ConvertTo-CustomType {
    <#
    .SYNOPSIS
    Converts a PSCustomObject to a custom class

    .DESCRIPTION
    PowerShell v4 on Windows 8.1 seems to have trouble casting [PSCustomObject] to custom classes.

    This function is a workaround, as suggested on https://stackoverflow.com/q/38217736
    #>
    param(
        # Object to convert
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $InputObject,

        # Custom Type to cast to
        [Parameter(Mandatory = $true)]
        [Alias("As")]
        [String] $CustomType
    )

    Begin {
        function ConvertTo-HashTable {
            param(
                [Parameter(Mandatory = $true)]
                [Object]$InputObject
            )

            begin {
                $hash = @{}
                $InputObject.PSObject.properties | Foreach-Object {
                    $hash[$_.Name] = $_.Value
                }
                Write-Output $hash
            }
        }
    }

    Process {
        Write-Output ([System.Management.Automation.LanguagePrimitives]::ConvertTo((ConvertTo-HashTable $InputObject), $CustomType))
    }
}
