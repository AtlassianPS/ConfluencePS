#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.10" }

Describe 'Tools/update.dependencies.ps1' -Tag Unit {
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
                    (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'Tools/update.dependencies.ps1'))
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

    It 'delegates dependency updates to the shared standards updater with expected paths and switches' {
        $projectRoot = Get-RepositoryRoot
        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/0.1.6'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'update.dependencies.ps1'
        $capturePath = Join-Path -Path $TestDrive -ChildPath 'update-deps.json'
        $escapedCapturePath = $capturePath.Replace("'", "''")

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'update.dependencies.ps1') -Destination $scriptPath

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
function Update-AtlassianPSDependencyReference {
    [CmdletBinding()]
    param(
        [String]`$BuildRequirementsPath,
        [String]`$ManifestPath,
        [Switch]`$SkipBuildRequirement,
        [Switch]`$SkipManifestRequirement
    )

    [PSCustomObject]@{
        BuildRequirementsPath   = `$BuildRequirementsPath
        ManifestPath            = `$ManifestPath
        SkipBuildRequirement    = [Boolean]`$SkipBuildRequirement
        SkipManifestRequirement = [Boolean]`$SkipManifestRequirement
    } | ConvertTo-Json -Compress | Set-Content -LiteralPath '$escapedCapturePath'

    return [PSCustomObject]@{
        SkipBuildRequirement    = [Boolean]`$SkipBuildRequirement
        SkipManifestRequirement = [Boolean]`$SkipManifestRequirement
    }
}

Export-ModuleMember -Function Update-AtlassianPSDependencyReference
"@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '0.1.6'
    GUID              = 'f7f93cb9-f0ad-4744-8dff-36a92073d7d6'
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
            $result = & $scriptPath -SkipBuildRequirement -SkipManifestRequirement
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
        }

        $captured = Get-Content -LiteralPath $capturePath -Raw | ConvertFrom-Json

        $captured.BuildRequirementsPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'Tools/build.requirements.psd1')
        $captured.ManifestPath | Should -Be (Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS/ConfluencePS.psd1')
        $captured.SkipBuildRequirement | Should -BeTrue
        $captured.SkipManifestRequirement | Should -BeTrue
        $result.SkipBuildRequirement | Should -BeTrue
        $result.SkipManifestRequirement | Should -BeTrue
    }

    It 'honors -WhatIf and does not call the shared dependency updater' {
        $projectRoot = Get-RepositoryRoot
        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'update.dependencies.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'update.dependencies.ps1') -Destination $scriptPath

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

        Mock -CommandName Get-PSRepository -MockWith {
            [PSCustomObject]@{
                Name               = 'PSGallery'
                SourceLocation     = 'https://www.powershellgallery.com/api/v2/'
                InstallationPolicy = 'Trusted'
            }
        }
        Mock -CommandName Register-PSRepository -MockWith {}
        Mock -CommandName Install-Module -MockWith {}
        Mock -CommandName Import-Module -MockWith {}

        $result = & $scriptPath -WhatIf

        Assert-MockCalled -CommandName Install-Module -Exactly -Times 0 -Scope It
        $result.Skipped | Should -BeTrue
    }

    It 'fails with clear guidance when PSGallery is unavailable after registration attempt' {
        $projectRoot = Get-RepositoryRoot
        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'update.dependencies.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'update.dependencies.ps1') -Destination $scriptPath

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

    It 'fails fast when shared updater emits a non-terminating error' {
        $projectRoot = Get-RepositoryRoot
        $sourceToolsPath = Join-Path -Path $projectRoot -ChildPath 'Tools'
        $harnessRoot = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString())
        $toolsPath = Join-Path -Path $harnessRoot -ChildPath 'Tools'
        $modulePath = Join-Path -Path $harnessRoot -ChildPath 'ConfluencePS'
        $mockModulePath = Join-Path -Path $harnessRoot -ChildPath 'mockModules/AtlassianPS.Standards/0.1.6'
        $scriptPath = Join-Path -Path $toolsPath -ChildPath 'update.dependencies.ps1'

        $null = New-Item -Path $toolsPath -ItemType Directory -Force
        $null = New-Item -Path $modulePath -ItemType Directory -Force
        $null = New-Item -Path $mockModulePath -ItemType Directory -Force

        Copy-Item -LiteralPath (Join-Path -Path $sourceToolsPath -ChildPath 'update.dependencies.ps1') -Destination $scriptPath

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
function Update-AtlassianPSDependencyReference {
    [CmdletBinding()]
    param(
        [String]$BuildRequirementsPath,
        [String]$ManifestPath,
        [Switch]$SkipBuildRequirement,
        [Switch]$SkipManifestRequirement
    )

    Write-Error -Message "simulated updater failure"
}

Export-ModuleMember -Function Update-AtlassianPSDependencyReference
'@

        Set-Content -LiteralPath (Join-Path -Path $mockModulePath -ChildPath 'AtlassianPS.Standards.psd1') -Value @'
@{
    RootModule        = 'AtlassianPS.Standards.psm1'
    ModuleVersion     = '0.1.6'
    GUID              = '02692396-2036-4c3f-b8f1-e6ceea9eb89f'
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
            Assert-ThrowsMessage -ScriptBlock { & $scriptPath -SkipBuildRequirement -SkipManifestRequirement | Out-Null } -MessagePattern 'simulated updater failure'
        }
        finally {
            $env:PSModulePath = $originalModulePath
            Remove-Module -Name 'AtlassianPS.Standards' -Force -ErrorAction SilentlyContinue
        }
    }
}
