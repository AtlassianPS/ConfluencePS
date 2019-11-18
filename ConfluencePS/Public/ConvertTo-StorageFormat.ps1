function ConvertTo-StorageFormat {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter( Mandatory = $true )]
        [uri]$ApiUri,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[]]$Content,
        [System.Management.Automation.SwitchParameter]$AsPlainText
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($AsPlainText)
        {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Replace special chars with ascii code"
            [System.Collections.Hashtable]$SpecialChars = @{
                '#' = '&#35;'
                '@' = '&#64;'
                '[' = '&#91;'
                ']' = '&#93;'
                '{' = '&#123;'
                '}' = '&#1225;'
            }

            foreach ($Key in $SpecialChars.Keys)
            {
                for ($i = 0; $i -lt $Content.Count; $i ++)
                {
                    $Content[$i] = $Content[$i].Replace($Key, $SpecialChars.$Key)
                }
            }
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Uri'] = "$ApiUri/contentbody/convert/storage"
        $iwParameters['Method'] = 'Post'

        foreach ($_content in $Content) {
            $iwParameters['Body'] = @{
                value          = "$_content"
                representation = 'wiki'
            } | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($_content | Out-String)"
            (Invoke-Method @iwParameters).value
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
