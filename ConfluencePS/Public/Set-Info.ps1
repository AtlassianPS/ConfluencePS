function Set-Info {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(
            HelpMessage = 'Example = https://brianbunke.atlassian.net/wiki (/wiki for Cloud instances)'
        )]
        [uri]$BaseURi,

        [PSCredential]$Credential,

        [string]$PersonalAccessToken,

        [UInt32]$PageSize,

        [switch]$PromptCredentials
    )

    BEGIN {

        function Add-ConfluenceDefaultParameter {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Command,

                [Parameter(Mandatory = $true)]
                [string]$Parameter,

                [Parameter(Mandatory = $true)]
                $Value
            )

            PROCESS {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Setting [$command : $parameter] = $value"

                # Needs to set both global and module scope for the private functions:
                # http://stackoverflow.com/questions/30427110/set-psdefaultparametersvalues-for-use-within-module-scope
                $PSDefaultParameterValues["${command}:${parameter}"] = $Value
                $global:PSDefaultParameterValues["${command}:${parameter}"] = $Value
            }
        }

        $moduleCommands = Get-Command -Module ConfluencePS

        if ($PromptCredentials) {
            $Credential = (Get-Credential)
        }
    }

    PROCESS {
        foreach ($command in $moduleCommands) {

            $parameter = "ApiUri"
            if ($BaseURi -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value ($BaseURi.AbsoluteUri.TrimEnd('/') + '/rest/api')
            }

            $parameter = "Credential"
            if ($Credential -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value $Credential
            }

            $parameter = "PersonalAccessToken"
            if ($PersonalAccessToken -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value $PersonalAccessToken
            }

            $parameter = "PageSize"
            if ($PageSize -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value $PageSize
            }
        }
    }
}
