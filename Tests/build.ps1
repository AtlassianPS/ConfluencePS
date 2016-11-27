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
        $BaseVersion = (Test-ModuleManifest .\ConfluencePS\ConfluencePS.psd1).Version
        # Append the current build number
        [Version]$Version = "$BaseVersion.$env:APPVEYOR_BUILD_NUMBER"
        # Update the .psd1 with the current major/minor/build SemVer
        Update-ModuleManifest -Path .\ConfluencePS\ConfluencePS.psd1 -ModuleVersion $Version -ErrorAction Stop
    } Catch {
        throw 'Version update failed. Skipping publish'
    }

    # Now, publish the update to the PowerShell Gallery
    Publish-Module -Path .\ConfluencePS -NuGetApiKey $env:PSGalleryAPIKey -ErrorAction Stop
}
