#requires -Module PowerShellGet

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [Switch]$SkipBuildRequirement,

    [Parameter()]
    [Switch]$SkipManifestRequirement,

    [Parameter()]
    [Switch]$AllowMajorVersionUpgrade,

    [Parameter(DontShow = $true)]
    [ValidateSet('Desktop', 'Core')]
    [String]$RuntimePSEdition = $PSVersionTable.PSEdition,

    [Parameter(DontShow = $true)]
    [Switch]$ForceDesktopBootstrapRemediation
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
$buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
$manifestPath = Join-Path -Path $projectRoot -ChildPath 'ConfluencePS/ConfluencePS.psd1'

function Get-BuildRequirementsFromDataFile {
    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Path
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        throw "Unable to parse data file '$Path': $($parseErrors[0].Message)"
    }

    if (-not $ast.EndBlock -or $ast.EndBlock.Statements.Count -eq 0) {
        throw "Data file '$Path' does not contain a supported data expression."
    }

    $statement = $ast.EndBlock.Statements[0]
    if ($statement -isnot [System.Management.Automation.Language.PipelineAst]) {
        throw "Data file '$Path' does not contain a supported data expression."
    }

    $pipelineElement = $statement.PipelineElements[0]
    if ($pipelineElement -isnot [System.Management.Automation.Language.CommandExpressionAst]) {
        throw "Data file '$Path' does not contain a supported data expression."
    }

    return @($pipelineElement.Expression.SafeGetValue())
}

$buildRequirements = Import-PowerShellDataFile -Path $buildRequirementsPath
$standardsRequirement = $buildRequirements |
    Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
    Select-Object -First 1

if (-not $standardsRequirement -or -not $standardsRequirement.RequiredVersion) {
    $buildRequirements = Get-BuildRequirementsFromDataFile -Path $buildRequirementsPath
    $standardsRequirement = $buildRequirements |
        Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
        Select-Object -First 1
}

if (-not $standardsRequirement -or -not $standardsRequirement.RequiredVersion) {
    throw "Could not resolve AtlassianPS.Standards required version from '$buildRequirementsPath'."
}

$standardsVersion = [string] $standardsRequirement.RequiredVersion

if (-not $PSCmdlet.ShouldProcess($manifestPath, 'Update AtlassianPS dependency references')) {
    return [PSCustomObject]@{
        Skipped                 = $true
        BuildRequirementsPath   = $buildRequirementsPath
        ManifestPath            = $manifestPath
        SkipBuildRequirement    = [Boolean] $SkipBuildRequirement
        SkipManifestRequirement = [Boolean] $SkipManifestRequirement
    }
}

$isWindowsPowerShell = $RuntimePSEdition -eq 'Desktop'
if ($isWindowsPowerShell) {
    $nuGetProvider = Get-PackageProvider -Name 'NuGet' -ListAvailable -ErrorAction SilentlyContinue |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    $requiresNuGetBootstrap = (
        $ForceDesktopBootstrapRemediation -or
        (-not $nuGetProvider -or $nuGetProvider.Version -lt [Version] '2.8.5.201')
    )

    if ($requiresNuGetBootstrap) {
        Install-PackageProvider -Name 'NuGet' -MinimumVersion '2.8.5.201' -Scope CurrentUser -Force -ErrorAction Stop
    }

}

$psGalleryRepository = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
if (-not $psGalleryRepository) {
    try {
        Register-PSRepository -Default -ErrorAction Stop
    }
    catch {
        throw "PSGallery repository is unavailable. Register PSGallery or configure repository access, then rerun '$($MyInvocation.MyCommand.Path)'."
    }

    $psGalleryRepository = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
}

if (-not $psGalleryRepository) {
    throw "PSGallery repository is unavailable. Register PSGallery or configure repository access, then rerun '$($MyInvocation.MyCommand.Path)'."
}

if ($isWindowsPowerShell -and ($ForceDesktopBootstrapRemediation -or $psGalleryRepository.InstallationPolicy -ne 'Trusted')) {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
}

Install-Module -Name 'AtlassianPS.Standards' `
    -RequiredVersion $standardsVersion `
    -Scope CurrentUser `
    -Repository 'PSGallery' `
    -AllowClobber `
    -Force `
    -ErrorAction Stop

Import-Module -Name 'AtlassianPS.Standards' -RequiredVersion $standardsVersion -Force -ErrorAction Stop

$result = AtlassianPS.Standards\Update-AtlassianPSDependencyReference `
    -BuildRequirementsPath $buildRequirementsPath `
    -ManifestPath $manifestPath `
    -SkipBuildRequirement:$SkipBuildRequirement `
    -SkipManifestRequirement:$SkipManifestRequirement `
    -AllowMajorVersionUpgrade:$AllowMajorVersionUpgrade `
    -ErrorAction Stop

$result
