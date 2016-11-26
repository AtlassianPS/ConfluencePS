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

# Future code to handle the PSGallery deployment here
