#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.3.1" }

Describe 'ConvertTo-Table' -Tag Unit {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    Context "Sanity checking" {
        $command = Get-Command -Name ConvertTo-ConfluenceTable

        It "has a [System.Object] -Content parameter" {
            $command.Parameters.ContainsKey("Content")
            $command.Parameters["Content"].ParameterType | Should -Be "System.Object"
        }
        It "has a [Switch] -Vertical parameter" {
            $command.Parameters.ContainsKey("Vertical")
            $command.Parameters["Vertical"].ParameterType | Should -Be "Switch"
        }
        It "has a [Switch] -NoHeader parameter" {
            $command.Parameters.ContainsKey("NoHeader")
            $command.Parameters["NoHeader"].ParameterType | Should -Be "Switch"
        }
    }

    Context "Behavior checking" {

        #region Mocking
        Mock Get-Service {
            [PSCustomObject]@{
                Name = "AppMgmt"
                DisplayName = "Application Management"
                Status = "Running"
            }
            [PSCustomObject]@{
                Name = "BITS"
                DisplayName = "Background Intelligent Transfer Service"
                Status = "Running"
            }
            [PSCustomObject]@{
                Name = "Dhcp"
                DisplayName = "DHCP Client"
                Status = "Running"
            }
            [PSCustomObject]@{
                Name = "DsmSvc"
                DisplayName = "Device Setup Manager"
                Status = "Running"
            }
            [PSCustomObject]@{
                Name = "EFS"
                DisplayName = "Encrypting File System (EFS)"
                Status = "Running"
            }
            [PSCustomObject]@{
                Name = "lmhosts"
                DisplayName = "TCP/IP NetBIOS Helper"
                Status = "Running"
            }
            [PSCustomObject]@{
                Name = "MSDTC"
                DisplayName = "Distributed Transaction Coordinator"
                Status = "Stopped"
            }
            [PSCustomObject]@{
                Name = "NlaSvc"
                DisplayName = "Network Location Awareness"
                Status = "Stopped"
            }
            [PSCustomObject]@{
                Name = "PolicyAgent"
                DisplayName = "IPsec Policy Agent"
                Status = "Stopped"
            }
            [PSCustomObject]@{
                Name = "SessionEnv"
                DisplayName = "Remote Desktop Configuration"
                Status = "Stopped"
            }
        }
        #endregion Mocking

        It "creates a table with a header row" {
            $table = ConvertTo-ConfluenceTable -Content (Get-Service)
            $row = $table -split [Environment]::NewLine

            $row.Count | Should -Be 12
            $row[0] | Should -BeExactly '|| Name || DisplayName || Status ||'
            $row[1..10] | ForEach-Object {
                $_ | Should -Match '^| [\w\s]+? | [\w\s]+? | [\w\s]+? |$'
                $_ | Should -Not -Match '\|\|'
                $_ | Should -Not -Match '\|\s\s+\|'
            }
            $row[11] | Should -BeNullOrEmpty
        }

        It "creates an empty table with header row" {
            $table = ConvertTo-ConfluenceTable ([PSCustomObject]@{ Name = $null; DisplayName = $null; Status = $null })
            $row = $table -split [Environment]::NewLine

            $row.Count | Should -Be 3
            $row[0] | Should -BeExactly '|| Name || DisplayName || Status ||'
            $row[1] | Should -BeExactly '| | | |'
            $row[2] | Should -BeNullOrEmpty
        }

        It "creates a table without a header row" {
            $table = ConvertTo-ConfluenceTable (Get-Service) -NoHeader
            $row = $table -split [Environment]::NewLine

            $row.Count | Should -Be 11
            $row[0..9] | ForEach-Object {
                $_ | Should -Match '^| [\w\s]+? | [\w\s]+? | [\w\s]+? |$'
                $_ | Should -Not -Match '\|\|'
                $_ | Should -Not -Match '\|\s\s+\|'
            }
            $row[10] | Should -BeNullOrEmpty
        }

        It "creates a vertical table with a header column" {
            $table = ConvertTo-ConfluenceTable ([PSCustomObject]@{ Name = "winlogon"; DisplayName = "Windows logon"; Status = "Running" }) -Vertical
            $row = $table -split [Environment]::NewLine

            $row.Count | Should -Be 4
            $row[0..3] | ForEach-Object {
                $_ | Should -Match '^|| [\w\s]+ || [\w\s]+ |$'
                $_ | Should -Not -Match '\|\|$'
                $_ | Should -Not -Match '\|\s\s+\|'
            }
            $row[4] | Should -BeNullOrEmpty
        }

        It "creates an empty vertical table with a header column" {
            $table = ConvertTo-ConfluenceTable ([PSCustomObject]@{ Name = $null; DisplayName = $null; Status = $null }) -Vertical
            $row = $table -split [Environment]::NewLine

            $row.Count | Should -Be 4
            $row[0..3] | ForEach-Object {
                $_ | Should -Match '^|| [\w\s]+? || |$'
                $_ | Should -Not -Match '\|\|$'
                $_ | Should -Not -Match '\|\s\s+\|'
            }
            $row[4] | Should -BeNullOrEmpty
        }

        It "creates a vertical table without a header column" {
            $table = ConvertTo-ConfluenceTable ([PSCustomObject]@{ Name = "winlogon"; DisplayName = "Windows logon"; Status = "Running" }) -Vertical -NoHeader
            $row = $table -split [Environment]::NewLine

            $row.Count | Should -Be 4
            $row[0..3] | ForEach-Object {
                $_ | Should -Match '^| [\w\s]+? | [\w\s]+? |$'
                $_ | Should -Not -Match '\|\|$'
                $_ | Should -Not -Match '\|\s\s+\|'
            }
            $row[4] | Should -BeNullOrEmpty
        }

        It "creates an empty vertical table without a header column" {
            $table = ConvertTo-ConfluenceTable ([PSCustomObject]@{ Name = $null; DisplayName = $null; Status = $null }) -Vertical -NoHeader
            $row = $table -split [Environment]::NewLine

            $row.Count | Should -Be 4
            $row[0..3] | ForEach-Object {
                $_ | Should -Match '^| [\w\s]+? | |$'
                $_ | Should -Not -Match '\|\|$'
                $_ | Should -Not -Match '\|\s\s+\|'
            }
            $row[4] | Should -BeNullOrEmpty
        }

        It "returns a single string object" {
            $table = ConvertTo-ConfluenceTable (Get-Service)
            $row = $table -split [Environment]::NewLine

            $table.Count | Should -Be 1
            $row.Count | Should -BeGreaterThan 1
        }
    }
}
