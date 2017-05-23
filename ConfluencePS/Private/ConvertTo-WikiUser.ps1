function ConvertTo-WikiUser {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.User] )]
    param (
        # object to convert
        [Parameter( Mandatory = $true, ValueFromPipeline = $true )]
        $inputObject
    )

    Process {
        foreach ($object in $inputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to User"
            ($object | Select-Object `
                username,
                userKey,
                @{Name = "profilePicture"; Expression = {$_.profilePicture | ConvertTo-WikiIcon}},
                displayname
            ) -as [ConfluencePS.User]
        }
    }
}
