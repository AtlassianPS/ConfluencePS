# Pester. Let's run some tests!
# https://github.com/pester/Pester/wiki/Showing-Test-Results-in-CI-(TeamCity,-AppVeyor)
# https://www.appveyor.com/docs/running-tests/#build-worker-api

# Invoke-Pester runs all .Tests.ps1 in the order found by "Get-ChildItem -Recurse"
$TestResults = Invoke-Pester -OutputFormat NUnitXml -OutputFile ".\TestResults.xml" -PassThru
# Upload the XML file of test results to the current AppVeyor job
(New-Object 'System.Net.WebClient').UploadFile(
    "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
    (Resolve-Path ".\TestResults.xml") )
# If a Pester test failed, use "throw" to end the script here, before deploying
If ($TestResults.FailedCount -gt 0) {
    throw "$($TestResults.FailedCount) Pester test(s) failed."
}

# Line break for readability in AppVeyor console
Write-Host ''

# Stop here if this isn't the master branch, or if this is a pull request
If ($env:APPVEYOR_REPO_BRANCH -ne 'master') {
    Write-Warning "Skipping version increment and gallery publish for branch $env:APPVEYOR_REPO_BRANCH"
} ElseIf ($env:APPVEYOR_PULL_REQUEST_NUMBER -gt 0) {
    Write-Warning "Skipping version increment and gallery publish for pull request #$env:APPVEYOR_PULL_REQUEST_NUMBER"
} Else {
    # Hopefully everything's good, because this is headed out to the world
    # First, update the module's version

    Try {
        # Use the major/minor module version defined in source control
        $Manifest = Test-ModuleManifest .\ConfluencePS\ConfluencePS.psd1
        # Append the current build number
        [Version]$Version = "$($Manifest.Version).$env:APPVEYOR_BUILD_NUMBER"
        # Update the .psd1 with the current major/minor/build SemVer
        # And placeholder text for Functions, because Update-ModuleManifest is the worst
        $UMM = @{
            Path              = '.\ConfluencePS\ConfluencePS.psd1'
            ModuleVersion     = $Version
            FunctionsToExport = 'I hate you, stupid Update-ModuleManifest'
            ErrorAction       = 'Stop'
        }
        Update-ModuleManifest @UMM

        # Fix the mangling of FunctionsToExport
        $Functions = $Manifest.ExportedCommands.Keys
        # Join the functions and apply new lines "`n" and tabs "`t" to match original formatting
        $FunctionString = "@(`n`t'$($Functions -join "',`n`t'")'`n)"
        # Replace the placeholder text
        (Get-Content .\ConfluencePS\ConfluencePS.psd1) `            -replace 'I hate you, stupid Update-ModuleManifest', $FunctionString |            Set-Content .\ConfluencePS\ConfluencePS.psd1 -ErrorAction Stop        # Now, have to get rid of the '' quotes wrapping the function array        # Two replaces because the quotes are on separate lines        (Get-Content .\ConfluencePS\ConfluencePS.psd1) `            -replace "(FunctionsToExport = )(')",'$1' -replace "\)'",')' |            Set-Content .\ConfluencePS\ConfluencePS.psd1 -ErrorAction Stop
    } Catch {
        throw 'Version update failed. Skipping publish to gallery'
    }

    Import-Module .\ConfluencePS\ConfluencePS.psd1
    $Count1 = (Get-Command -Module ConfluencePS).Count
    $Count2 = (Test-ModuleManifest .\ConfluencePS\ConfluencePS.psd1).ExportedCommands.Count
    $Count3 = (Get-ChildItem .\ConfluencePS\Public).Count
    If ($Count1 -ne $Count2) {
        throw "Expected $Count2 commands to be exported, but found $Count1 instead"
    } ElseIf ($Count1 -ne $Count3) {
        throw "Expected $Count3 commands to be exported, but found $Count1 instead"
    }

    Try {
        # Now, publish the update to the PowerShell Gallery
        $PM = @{
            Path         = '.\ConfluencePS'
            NuGetApiKey  = $env:PSGalleryAPIKey
            ReleaseNotes = $env:APPVEYOR_REPO_COMMIT_MESSAGE
            ErrorAction  = 'Stop'
        }
        Publish-Module @PM

        Write-Host "ConfluencePS version $Version published to the PowerShell Gallery." -ForegroundColor Cyan
    } Catch {
        throw "Publishing update $Version to the PowerShell Gallery failed."
    }
}
