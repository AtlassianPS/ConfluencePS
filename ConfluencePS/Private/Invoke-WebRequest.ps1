function Invoke-WebRequest {
    # For Version up to 5.1
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=217035')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingConvertToSecureStringWithPlainText",
        "",
        Justification = "Converting received plaintext token to SecureString"
    )]
    param(
        [switch]
        ${UseBasicParsing},

        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [uri]
        ${Uri},

        [Microsoft.PowerShell.Commands.WebRequestSession]
        ${WebSession},

        [Alias('SV')]
        [string]
        ${SessionVariable},

        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential},

        [switch]
        ${UseDefaultCredentials},

        [ValidateNotNullOrEmpty()]
        [string]
        ${CertificateThumbprint},

        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        ${Certificate},

        [string]
        ${UserAgent},

        [switch]
        ${DisableKeepAlive},

        [ValidateRange(0, 2147483647)]
        [int]
        ${TimeoutSec},

        [System.Collections.IDictionary]
        ${Headers},

        [ValidateRange(0, 2147483647)]
        [int]
        ${MaximumRedirection},

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        ${Method},

        [uri]
        ${Proxy},

        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        ${ProxyCredential},

        [switch]
        ${ProxyUseDefaultCredentials},

        [Parameter(ValueFromPipeline = $true)]
        [System.Object]
        ${Body},

        [string]
        ${ContentType},

        [ValidateSet('chunked', 'compress', 'deflate', 'gzip', 'identity')]
        [string]
        ${TransferEncoding},

        [string]
        ${InFile},

        [string]
        ${OutFile},

        [switch]
        ${PassThru})

    begin {
        if ($Credential) {
            $SecureCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(
                    $('{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password)
                ))
            $Headers["Authorization"] = "Basic $($SecureCreds)"
            $null = $PSBoundParameters.Remove("Credential")
        }

        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Invoke-WebRequest', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Invoke-WebRequest
    .ForwardHelpCategory Cmdlet

    #>
}

if ($PSVersionTable.PSVersion.Major -ge 6) {
    function Invoke-WebRequest {
        #require -Version 6
        [CmdletBinding(DefaultParameterSetName = 'StandardMethod', HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=217035')]
        param(
            [switch]
            ${UseBasicParsing},

            [Parameter(Mandatory = $true, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [uri]
            ${Uri},

            [Microsoft.PowerShell.Commands.WebRequestSession]
            ${WebSession},

            [Alias('SV')]
            [string]
            ${SessionVariable},

            [switch]
            ${AllowUnencryptedAuthentication},

            [Microsoft.PowerShell.Commands.WebAuthenticationType]
            ${Authentication},

            [pscredential]
            [System.Management.Automation.CredentialAttribute()]
            ${Credential},

            [switch]
            ${UseDefaultCredentials},

            [ValidateNotNullOrEmpty()]
            [string]
            ${CertificateThumbprint},

            [ValidateNotNull()]
            [X509Certificate]
            ${Certificate},

            [switch]
            ${SkipCertificateCheck},

            [Microsoft.PowerShell.Commands.WebSslProtocol]
            ${SslProtocol},

            [securestring]
            ${Token},

            [string]
            ${UserAgent},

            [switch]
            ${DisableKeepAlive},

            [ValidateRange(0, 2147483647)]
            [int]
            ${TimeoutSec},

            [System.Collections.IDictionary]
            ${Headers},

            [ValidateRange(0, 2147483647)]
            [int]
            ${MaximumRedirection},

            [Parameter(ParameterSetName = 'StandardMethod')]
            [Parameter(ParameterSetName = 'StandardMethodNoProxy')]
            [Microsoft.PowerShell.Commands.WebRequestMethod]
            ${Method},

            [Parameter(ParameterSetName = 'CustomMethod', Mandatory = $true)]
            [Parameter(ParameterSetName = 'CustomMethodNoProxy', Mandatory = $true)]
            [Alias('CM')]
            [ValidateNotNullOrEmpty()]
            [string]
            ${CustomMethod},

            [Parameter(ParameterSetName = 'CustomMethodNoProxy', Mandatory = $true)]
            [Parameter(ParameterSetName = 'StandardMethodNoProxy', Mandatory = $true)]
            [switch]
            ${NoProxy},

            [Parameter(ParameterSetName = 'StandardMethod')]
            [Parameter(ParameterSetName = 'CustomMethod')]
            [uri]
            ${Proxy},

            [Parameter(ParameterSetName = 'StandardMethod')]
            [Parameter(ParameterSetName = 'CustomMethod')]
            [pscredential]
            [System.Management.Automation.CredentialAttribute()]
            ${ProxyCredential},

            [Parameter(ParameterSetName = 'StandardMethod')]
            [Parameter(ParameterSetName = 'CustomMethod')]
            [switch]
            ${ProxyUseDefaultCredentials},

            [Parameter(ValueFromPipeline = $true)]
            [System.Object]
            ${Body},

            [string]
            ${ContentType},

            [ValidateSet('chunked', 'compress', 'deflate', 'gzip', 'identity')]
            [string]
            ${TransferEncoding},

            [string]
            ${InFile},

            [string]
            ${OutFile},

            [switch]
            ${PassThru},

            [switch]
            ${PreserveAuthorizationOnRedirect},

            [switch]
            ${SkipHeaderValidation})

        begin {
            if ($Credential -and (-not ($Authentication))) {
                $PSBoundParameters["Authentication"] = "Basic"
            }
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                    $PSBoundParameters['OutBuffer'] = 1
                }
                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Invoke-WebRequest', [System.Management.Automation.CommandTypes]::Cmdlet)
                $scriptCmd = {& $wrappedCmd @PSBoundParameters }
                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)
            }
            catch {
                throw
            }
        }

        process {
            try {
                $steppablePipeline.Process($_)
            }
            catch {
                throw
            }
        }

        end {
            try {
                $steppablePipeline.End()
            }
            catch {
                throw
            }
        }
        <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Invoke-WebRequest
    .ForwardHelpCategory Cmdlet

    #>
    }
}
