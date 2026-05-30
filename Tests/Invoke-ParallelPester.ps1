<#
.SYNOPSIS
    Runs Pester integration tests in parallel on PowerShell 7+ or sequentially on Windows PowerShell 5.1.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Interactive test runner with colored console output')]
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ProjectRoot,

    [Parameter()]
    [string[]]$Path = './Tests/Integration/',

    [Parameter()]
    [int]$ThrottleLimit = 1,

    [Parameter()]
    [string[]]$Tag,

    [Parameter()]
    [string[]]$ExcludeTag,

    [Parameter()]
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string]$Output = 'Normal',

    [Parameter()]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$canParallel = $PSVersionTable.PSVersion.Major -ge 7
if (-not $canParallel) {
    Write-Warning 'PowerShell 5.1 detected: running tests sequentially. Use PowerShell 7+ for parallel execution.'
}

if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).ProviderPath
$tempResultsDir = Join-Path ([System.IO.Path]::GetTempPath()) "ConfluencePS-TestResults-$(Get-Date -Format 'yyyyMMddHHmmss')"
if ($OutputPath -and $PSCmdlet.ShouldProcess($tempResultsDir, 'Create temporary results directory')) {
    $null = New-Item -ItemType Directory -Path $tempResultsDir -Force
}

$testFiles = @()
foreach ($p in $Path) {
    $resolvedPath = Resolve-Path $p -ErrorAction SilentlyContinue
    if ($resolvedPath) {
        if (Test-Path $resolvedPath -PathType Container) {
            $testFiles += Get-ChildItem -Path $resolvedPath -Filter '*.Tests.ps1' -File
        }
        else {
            $testFiles += Get-Item $resolvedPath
        }
    }
}

if ($testFiles.Count -eq 0) {
    Write-Warning "No test files found in: $Path"
    return
}

$executionMode = if ($canParallel) { "ThrottleLimit=$ThrottleLimit" } else { 'sequential (PS 5.1)' }
Write-Host "Running $($testFiles.Count) test files ($executionMode)" -ForegroundColor Cyan
Write-Host ''

$startTime = Get-Date
$results = @()
$generateXml = [bool]$OutputPath
$helpersPath = Join-Path $PSScriptRoot 'Helpers/IntegrationTestTools.ps1'

$runTestBodyText = @'
param($testFile, $projectRoot, $tagFilter, $excludeTagFilter, $outputVerbosity, $tempResultsDir, $generateXml, $helpersPath)

try {
    function Get-PesterTestInBlock {
        param($Block)

        foreach ($test in $Block.Tests) { $test }
        foreach ($childBlock in $Block.Blocks) { Get-PesterTestInBlock -Block $childBlock }
    }

    if (Test-Path $helpersPath) {
        . $helpersPath
        Read-DotEnvFile -Path (Join-Path $projectRoot '.env')
    }

    Import-Module Pester -MinimumVersion 5.0 -Force
    Set-Location $projectRoot

    $config = New-PesterConfiguration
    $config.Run.Path = $testFile.FullName
    $config.Run.PassThru = $true
    $config.Output.Verbosity = $outputVerbosity

    if ($generateXml -and $tempResultsDir) {
        $config.TestResult.Enabled = $true
        $config.TestResult.OutputFormat = 'NUnitXml'
        $config.TestResult.OutputPath = Join-Path $tempResultsDir "$($testFile.BaseName).xml"
    }

    if ($tagFilter) { $config.Filter.Tag = $tagFilter }
    if ($excludeTagFilter) { $config.Filter.ExcludeTag = $excludeTagFilter }

    $result = Invoke-Pester -Configuration $config

    $failedTests = @()
    $skippedTests = @()
    $allTests = foreach ($container in $result.Containers) {
        foreach ($block in $container.Blocks) { Get-PesterTestInBlock -Block $block }
    }

    foreach ($test in $allTests) {
        if ($test.Result -eq 'Failed') {
            $failedTests += [PSCustomObject]@{
                Name         = if ($test.ExpandedPath) { $test.ExpandedPath } else { $test.Name }
                ErrorMessage = if ($test.ErrorRecord) { $test.ErrorRecord[0].Exception.Message } else { 'Unknown error' }
            }
        }
        if ($test.Result -eq 'Skipped') {
            $skippedTests += [PSCustomObject]@{
                Name   = if ($test.ExpandedPath) { $test.ExpandedPath } else { $test.Name }
                Reason = if ($test.ErrorRecord) { ($test.ErrorRecord | ForEach-Object { $_.Exception.Message }) -join '; ' } else { 'No skip reason reported' }
            }
        }
    }

    [PSCustomObject]@{
        File         = $testFile.Name
        Passed       = $result.PassedCount
        Failed       = $result.FailedCount
        Skipped      = $result.SkippedCount
        Duration     = $result.Duration
        Success      = $result.FailedCount -eq 0
        FailedTests  = $failedTests
        SkippedTests = $skippedTests
        XmlPath      = if ($generateXml) { Join-Path $tempResultsDir "$($testFile.BaseName).xml" } else { $null }
    }
}
catch {
    [PSCustomObject]@{
        File         = $testFile.Name
        Passed       = 0
        Failed       = 1
        Skipped      = 0
        Duration     = [TimeSpan]::Zero
        Success      = $false
        Error        = $_.Exception.Message
        FailedTests  = @([PSCustomObject]@{ Name = 'Script execution'; ErrorMessage = $_.Exception.Message })
        SkippedTests = @()
        XmlPath      = $null
    }
}
'@

if ($canParallel) {
    $perFileTimeoutSeconds = 600
    $jobInfos = New-Object System.Collections.Generic.List[object]
    foreach ($testFile in $testFiles) {
        $job = Start-ThreadJob -ScriptBlock ([scriptblock]::Create($runTestBodyText)) -ArgumentList @($testFile, $projectRoot, $Tag, $ExcludeTag, $Output, $tempResultsDir, $generateXml, $helpersPath) -ThrottleLimit $ThrottleLimit -StreamingHost $Host -Name "Pester:$($testFile.BaseName)"
        $jobInfos.Add(@{ File = $testFile; Job = $job })
    }

    foreach ($info in $jobInfos) {
        $job = $info.Job
        $file = $info.File
        $finished = Wait-Job -Job $job -Timeout $perFileTimeoutSeconds
        if (-not $finished) {
            Write-Warning "Test file [$($file.Name)] exceeded ${perFileTimeoutSeconds}s budget; stopping the runspace and recording an orchestrator timeout."
            try { Stop-Job -Job $job -ErrorAction SilentlyContinue } catch { Write-Warning "Stop-Job [$($job.Name)] threw: $_" }
            $results += [PSCustomObject]@{
                File         = $file.Name
                Passed       = 0
                Failed       = 1
                Skipped      = 0
                Duration     = [TimeSpan]::FromSeconds($perFileTimeoutSeconds)
                Success      = $false
                Error        = "Per-file orchestrator timeout (${perFileTimeoutSeconds}s); runspace stopped."
                FailedTests  = @([PSCustomObject]@{ Name = 'Orchestrator timeout'; ErrorMessage = "Test file [$($file.Name)] did not produce a Pester result object within ${perFileTimeoutSeconds}s." })
                SkippedTests = @()
                XmlPath      = $null
            }
        }
        else {
            try {
                $jobOutput = Receive-Job -Job $job -ErrorAction Stop 6> $null
                if ($null -ne $jobOutput) { $results += $jobOutput }
            }
            catch {
                Write-Warning "Receive-Job [$($job.Name)] threw: $_"
                $results += [PSCustomObject]@{
                    File         = $file.Name
                    Passed       = 0
                    Failed       = 1
                    Skipped      = 0
                    Duration     = [TimeSpan]::Zero
                    Success      = $false
                    Error        = "Receive-Job failed: $_"
                    FailedTests  = @([PSCustomObject]@{ Name = 'Receive-Job failure'; ErrorMessage = $_.Exception.Message })
                    SkippedTests = @()
                    XmlPath      = $null
                }
            }
        }
        try { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue } catch { Write-Warning "Remove-Job [$($job.Name)] threw: $_" }
    }
}
else {
    $runTestFile = [scriptblock]::Create($runTestBodyText)
    foreach ($testFile in $testFiles) {
        $results += & $runTestFile $testFile $projectRoot $Tag $ExcludeTag $Output $tempResultsDir $generateXml $helpersPath
    }
}

$endTime = Get-Date
$totalDuration = $endTime - $startTime
$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0
$allFailedTests = @()
$allSkippedTests = @()

foreach ($r in $results) {
    $totalPassed += $r.Passed
    $totalFailed += $r.Failed
    $totalSkipped += $r.Skipped

    if ($r.Error) { Write-Host "[ERROR] $($r.File): $($r.Error)" -ForegroundColor Red }
    foreach ($ft in @($r.FailedTests)) { $allFailedTests += [PSCustomObject]@{ File = $r.File; Test = $ft.Name; ErrorMessage = $ft.ErrorMessage } }
    foreach ($st in @($r.SkippedTests)) { $allSkippedTests += [PSCustomObject]@{ File = $r.File; Test = $st.Name; Reason = $st.Reason } }
}

if ($allFailedTests.Count -gt 0) {
    Write-Host ''
    Write-Host '========== FAILED TESTS ==========' -ForegroundColor Red
    foreach ($ft in $allFailedTests) {
        Write-Host "  $($ft.File)" -ForegroundColor Yellow -NoNewline
        Write-Host ' :: ' -NoNewline
        Write-Host "$($ft.Test)" -ForegroundColor White
        Write-Host "    $($ft.ErrorMessage)" -ForegroundColor DarkGray
    }
    Write-Host '==================================' -ForegroundColor Red
    Write-Host ''
}

if ($allSkippedTests.Count -gt 0) {
    Write-Host ''
    Write-Host '========== SKIPPED TESTS ==========' -ForegroundColor Yellow
    foreach ($st in $allSkippedTests) {
        Write-Host "  $($st.File)" -ForegroundColor Yellow -NoNewline
        Write-Host ' :: ' -NoNewline
        Write-Host "$($st.Test)" -ForegroundColor White
        Write-Host "    $($st.Reason)" -ForegroundColor DarkGray
    }
    Write-Host '===================================' -ForegroundColor Yellow
    Write-Host ''
}

Write-Host ''
Write-Host '========== TEST SUMMARY ==========' -ForegroundColor Cyan
Write-Host "  Total:   $($totalPassed + $totalFailed + $totalSkipped)" -ForegroundColor White
Write-Host "  Passed:  $totalPassed" -ForegroundColor Green
Write-Host "  Failed:  $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Skipped: $totalSkipped" -ForegroundColor Yellow
Write-Host "  Duration: $($totalDuration.ToString('hh\:mm\:ss\.fff'))" -ForegroundColor White
Write-Host '==================================' -ForegroundColor Cyan

if ($OutputPath -and (Test-Path $tempResultsDir)) {
    $xmlFiles = Get-ChildItem -Path $tempResultsDir -Filter '*.xml' -File
    if ($xmlFiles.Count -gt 0 -and $PSCmdlet.ShouldProcess($OutputPath, "Merge $($xmlFiles.Count) test result files")) {
        $mergedDoc = [xml]'<?xml version="1.0" encoding="utf-8"?><test-results></test-results>'
        $root = $mergedDoc.DocumentElement
        $root.SetAttribute('name', 'ConfluencePS Integration Tests')
        $root.SetAttribute('total', ($totalPassed + $totalFailed + $totalSkipped).ToString())
        $root.SetAttribute('errors', '0')
        $root.SetAttribute('failures', $totalFailed.ToString())
        $root.SetAttribute('not-run', $totalSkipped.ToString())
        $root.SetAttribute('inconclusive', '0')
        $root.SetAttribute('ignored', '0')
        $root.SetAttribute('skipped', $totalSkipped.ToString())
        $root.SetAttribute('invalid', '0')
        $root.SetAttribute('date', $startTime.ToString('yyyy-MM-dd'))
        $root.SetAttribute('time', $startTime.ToString('HH:mm:ss'))

        $envElement = $mergedDoc.CreateElement('environment')
        $osName = if ($PSVersionTable.PSVersion.Major -ge 6) { if ($IsWindows) { 'Windows' } elseif ($IsMacOS) { 'macOS' } else { 'Linux' } } else { 'Windows' }
        $envElement.SetAttribute('os-version', $osName)
        $envElement.SetAttribute('platform', "PowerShell $($PSVersionTable.PSVersion)")
        $envElement.SetAttribute('cwd', $projectRoot)
        $envElement.SetAttribute('machine-name', [Environment]::MachineName)
        $envElement.SetAttribute('user', [Environment]::UserName)
        $root.AppendChild($envElement) | Out-Null

        $mainSuite = $mergedDoc.CreateElement('test-suite')
        $mainSuite.SetAttribute('type', 'Assembly')
        $mainSuite.SetAttribute('name', 'ConfluencePS.Integration.Tests')
        $mainSuite.SetAttribute('executed', 'True')
        $mainSuite.SetAttribute('result', $(if ($totalFailed -eq 0) { 'Success' } else { 'Failure' }))
        $mainSuite.SetAttribute('success', $(if ($totalFailed -eq 0) { 'True' } else { 'False' }))
        $mainSuite.SetAttribute('time', $totalDuration.TotalSeconds.ToString('0.000'))
        $mainSuite.SetAttribute('asserts', '0')

        $mainResults = $mergedDoc.CreateElement('results')
        $mainSuite.AppendChild($mainResults) | Out-Null
        foreach ($xmlFile in $xmlFiles) {
            try {
                $fileDoc = [xml](Get-Content $xmlFile.FullName -Raw)
                $testSuites = $fileDoc.SelectNodes('//test-suite[@type="TestFixture" or @type="Describe"]')
                foreach ($suite in $testSuites) { $mainResults.AppendChild($mergedDoc.ImportNode($suite, $true)) | Out-Null }
            }
            catch { Write-Warning "Failed to merge XML from $($xmlFile.Name): $_" }
        }
        $root.AppendChild($mainSuite) | Out-Null
        $mergedDoc.Save($OutputPath)
        Write-Host "Test results written to: $OutputPath" -ForegroundColor Cyan
    }
    if ($PSCmdlet.ShouldProcess($tempResultsDir, 'Remove temporary results directory')) {
        Remove-Item -Path $tempResultsDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($totalFailed -gt 0) { exit 1 }
exit 0
