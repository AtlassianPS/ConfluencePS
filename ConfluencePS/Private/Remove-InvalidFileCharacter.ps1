function Remove-InvalidFileCharacter {
    <#
    .SYNOPSIS
    Replace any invalid filename characters from a string with underscores
    #>
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType( [String] )]
    param (
        # string to process
        [Parameter( ValueFromPipeline = $true )]
        [String]$InputString
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        $InvalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
        $RegExInvalid = "[{0}]" -f [RegEx]::Escape($InvalidChars)
    }
    Process {
        foreach ($_string in $InputString) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Removing invalid characters"
            $_string -replace $RegExInvalid, '_'
        }
    }
}
