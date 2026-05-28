function ConvertTo-ServerInformation {
    [CmdletBinding()]
    [OutputType([ConfluencePS.ServerInformation])]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSObject[]]$InputObject
    )

    PROCESS {
        foreach ($object in $InputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to ServerInformation"

            $deploymentType = if ($object.cloudId) { 'Cloud' } elseif ($object.deploymentType) { $object.deploymentType } else { 'DataCenter' }
            $hash = @{
                DeploymentType  = $deploymentType
                CloudId         = $object.cloudId
                CommitHash      = $object.commitHash
                Edition         = $object.edition
                SiteTitle       = $object.siteTitle
                DefaultLocale   = $object.defaultLocale
                DefaultTimeZone = $object.defaultTimeZone
                MicrosPerimeter = $object.microsPerimeter
                Version         = $object.version
            }

            if ($object.baseUrl) { $hash.BaseUrl = [Uri]$object.baseUrl }
            if ($object.fallbackBaseUrl) { $hash.FallbackBaseUrl = [Uri]$object.fallbackBaseUrl }
            if ($object.buildNumber) { $hash.BuildNumber = [Int32]$object.buildNumber }
            if ($object.buildDate) { $hash.BuildDate = [DateTime]$object.buildDate }
            if ($object.serverTime) { $hash.ServerTime = [DateTime]$object.serverTime }

            [ConfluencePS.ServerInformation]$hash
        }
    }
}
