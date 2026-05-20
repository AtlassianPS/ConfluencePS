#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.10" }

Describe 'Tools/setup.ps1' -Tag Unit {
    BeforeAll {
        function Get-RepositoryRoot {
            if (
                $env:BHProjectPath -and
                (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'ConfluencePS.build.ps1'))
            ) {
                return (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
            }

            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (
                    (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'ConfluencePS.build.ps1')) -and
                    (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'Tools/setup.ps1'))
                ) {
                    return $candidate
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            throw "Could not resolve repository root from '$PSScriptRoot'."
        }

        function Assert-ThrowsMessage {
            param(
                [Parameter(Mandatory)]
                [ScriptBlock]$ScriptBlock,

                [Parameter(Mandatory)]
                [String]$MessagePattern
            )

            $capturedError = $null
            try {
                & $ScriptBlock
            }
            catch {
                $capturedError = $_
            }

            $capturedError | Should -Not -BeNullOrEmpty
            $capturedError.Exception.Message | Should -Match $MessagePattern
        }
    }

    It 'delegates dependency install and analyzer settings sync to shared standards commands' {
        $projectRoot = Get-RepositoryRoot
        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/0.1.6'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'setup.ps1'
        $installCapturePath = Join-Path -Path $TestDrive -ChildPath 'setup-install.json'
        $syncCapturePath = Join-Path -Path $TestDrive -ChildPath 'setup-sync.txt'
        $escapedInstallCapturePath = $installCapturePath.Replace("'", "''")
        $escapedSyncCapturePath = $syncCapturePath.Replace("'", "''")

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'setup.ps1') -Destination $scriptPath

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "0.1.6" }
    @{ ModuleName = "InvokeBuild"; RequiredVersion = "5.14.23" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'ConfluencePS.psd1') -Value @'
@{
    RootModule      = 'ConfluencePS.psm1'
    ModuleVersion   = '2.5'
    RequiredModules = @()
}
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psm1') -Value @"
function Install-AtlassianPSDependencyRequirement {
    [CmdletBinding()]
    param(
        [String]`$BuildRequirementsPath,
        [String]`$ManifestPath
    )

    [PSCustomObject]@{
        BuildRequirementsPath = `$BuildRequirementsPath
        ManifestPath          = `$ManifestPath
    } | ConvertTo-Json -Compress | Set-Content -LiteralPath '$escapedInstallCapturePath'
}

function Sync-AtlassianPSScriptAnalyzerSettings {
    [CmdletBinding()]
    param(
        [String]`$DestinationPath
    )

    Set-Content -LiteralPath '$escapedSyncCapturePath' -Value `$DestinationPath
    return `$DestinationPath
}

Export-ModuleMember -Function Install-AtlassianPSDependencyRequirement, Sync-AtlassianPSScriptAnalyzerSettings
"@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '0.1.6'
    GUID              = '87eec220-b38f-4f70-bf4d-0cac17c9a3dd'
    FunctionsToExport = @('*')
}
'@

        Mock -CommandName Get-PSRepository -MockWith {
            [PSCustomObject]@{
                Name               = 'PSGallery'
                SourceLocation     = 'https://www.powershellgallery.com/api/v2/'
                InstallationPolicy = 'Trusted'
            }
        }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Get-PackageProvider -MockWith { [PSCustomObject]@{ Name = 'NuGet'; Version = [Version] '2.8.5.208' } }
        Mock -CommandName Install-PackageProvider -MockWith {}
        Mock -CommandName Set-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}

        $moduleSearchPath = Join-Path -Path $harnessRoot -ChildPath 'mockModules'
        $originalModulePath = $env:PSModulePath
        $env:PSModulePath = "$moduleSearchPath$([System.IO.Path]::PathSeparator)$originalModulePath"
        try {
            & $scriptPath | Out-Null
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
        }

        $capturedInstall = Get-Content -LiteralPath $installCapturePath -Raw | ConvertFrom-Json
        $capturedSyncPath = (Get-Content -LiteralPath $syncCapturePath -Raw).TrimEnd("`r", "`n")

        $capturedInstall.BuildRequirementsPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'Tools/build.requirements.psd1')
        $capturedInstall.ManifestPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS/ConfluencePS.psd1')
        $capturedSyncPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'PSScriptAnalyzerSettings.psd1')
    }

    It 'installs the required standards version from build.requirements when not present locally' {
        $projectRoot = Get-RepositoryRoot
        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/9.9.9'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'setup.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'setup.ps1') -Destination $scriptPath

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "9.9.9" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'ConfluencePS.psd1') -Value @'
@{
    RootModule      = 'ConfluencePS.psm1'
    ModuleVersion   = '2.5'
    RequiredModules = @()
}
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psm1') -Value @'
function Install-AtlassianPSDependencyRequirement {
    [CmdletBinding()]
    param(
        [String]$BuildRequirementsPath,
        [String]$ManifestPath
    )

    return [PSCustomObject]@{
        BuildRequirementsPath = $BuildRequirementsPath
        ManifestPath          = $ManifestPath
    }
}

function Sync-AtlassianPSScriptAnalyzerSettings {
    [CmdletBinding()]
    param(
        [String]$DestinationPath
    )

    return $DestinationPath
}

Export-ModuleMember -Function Install-AtlassianPSDependencyRequirement, Sync-AtlassianPSScriptAnalyzerSettings
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '9.9.9'
    GUID              = '4f0a5fe2-b109-4d78-a2b0-dff2e309e5fd'
    FunctionsToExport = @('*')
}
'@

        Mock -CommandName Get-PSRepository -MockWith {
            [PSCustomObject]@{
                Name               = 'PSGallery'
                SourceLocation     = 'https://www.powershellgallery.com/api/v2/'
                InstallationPolicy = 'Trusted'
            }
        }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Get-PackageProvider -MockWith { [PSCustomObject]@{ Name = 'NuGet'; Version = [Version] '2.8.5.208' } }
        Mock -CommandName Install-Module -MockWith {}

        $moduleSearchPath = Join-Path -Path $harnessRoot -ChildPath 'mockModules'
        $originalModulePath = $env:PSModulePath
        $env:PSModulePath = "$moduleSearchPath$([System.IO.Path]::PathSeparator)$originalModulePath"
        try {
            $result = & $scriptPath
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
        }

        Assert-MockCalled -CommandName Install-Module -Exactly -Times 1 -ParameterFilter {
            $Name -eq 'AtlassianPS.Standards' -and
            $RequiredVersion -eq '9.9.9' -and
            $Scope -eq 'CurrentUser' -and
            $Repository -eq 'PSGallery' -and
            [Boolean]$AllowClobber -and
            [Boolean]$Force
        }
        $result | Should -Not -BeNullOrEmpty
    }

    It 'fails with clear guidance when PSGallery is unavailable after registration attempt' {
        $projectRoot = Get-RepositoryRoot
        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'setup.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'setup.ps1') -Destination $scriptPath

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "0.1.6" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'ConfluencePS.psd1') -Value @'
@{
    RootModule      = 'ConfluencePS.psm1'
    ModuleVersion   = '2.5'
    RequiredModules = @()
}
'@

        Mock -CommandName Get-PSRepository -MockWith { $null }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}

        Assert-ThrowsMessage -ScriptBlock { & $scriptPath } -MessagePattern 'PSGallery repository is unavailable'
    }

    It 'fails fast when shared installer emits a non-terminating error' {
        $projectRoot = Get-RepositoryRoot
        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/0.1.6'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'setup.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'setup.ps1') -Destination $scriptPath

        Set-Content -LiteralPath (Join-Path -Path $toolsPath -ChildPath 'build.requirements.psd1') -Value @'
@(
    @{ ModuleName = "AtlassianPS.Standards"; RequiredVersion = "0.1.6" }
    @{ ModuleName = "InvokeBuild"; RequiredVersion = "5.14.23" }
)
'@

        Set-Content -LiteralPath (Join-Path -Path $modulePath -ChildPath 'ConfluencePS.psd1') -Value @'
@{
    RootModule      = 'ConfluencePS.psm1'
    ModuleVersion   = '2.5'
    RequiredModules = @()
}
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psm1') -Value @'
function Install-AtlassianPSDependencyRequirement {
    [CmdletBinding()]
    param(
        [String]$BuildRequirementsPath,
        [String]$ManifestPath
    )

    Write-Error -Message "simulated setup failure"
}

function Sync-AtlassianPSScriptAnalyzerSettings {
    [CmdletBinding()]
    param(
        [String]$DestinationPath
    )

    return $DestinationPath
}

Export-ModuleMember -Function Install-AtlassianPSDependencyRequirement, Sync-AtlassianPSScriptAnalyzerSettings
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '0.1.6'
    GUID              = '73dc51ab-a3ad-4f90-b04f-b091f67fcdb2'
    FunctionsToExport = @('*')
}
'@

        Mock -CommandName Get-PSRepository -MockWith {
            [PSCustomObject]@{
                Name               = 'PSGallery'
                SourceLocation     = 'https://www.powershellgallery.com/api/v2/'
                InstallationPolicy = 'Trusted'
            }
        }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Get-PackageProvider -MockWith { [PSCustomObject]@{ Name = 'NuGet'; Version = [Version] '2.8.5.208' } }
        Mock -CommandName Install-PackageProvider -MockWith {}
        Mock -CommandName Set-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}

        $moduleSearchPath = Join-Path -Path $harnessRoot -ChildPath 'mockModules'
        $originalModulePath = $env:PSModulePath
        $env:PSModulePath = "$moduleSearchPath$([System.IO.Path]::PathSeparator)$originalModulePath"
        try {
            Assert-ThrowsMessage -ScriptBlock { & $scriptPath | Out-Null } -MessagePattern 'simulated setup failure'
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
        }
    }
}
