[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
param(
    $ModuleName = (Split-Path $BuildRoot -Leaf),
    $releasePath = "$BuildRoot/Release"
)

#region Setup
$WarningPreference = "Continue"
if ($PSBoundParameters.ContainsKey('Verbose')) {
    $VerbosePreference = "Continue"
}
if ($PSBoundParameters.ContainsKey('Debug')) {
    $DebugPreference = "Continue"
}

try {
    $script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
    $script:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux
    $script:IsMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS
    $script:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core'
}
catch { }

$PSModulePath = $env:PSModulePath -split ([IO.Path]::PathSeparator)
if ($releasePath -notin $PSModulePath) {
    $PSModulePath += $releasePath
    $env:PSModulePath = $PSModulePath -join ([IO.Path]::PathSeparator)
}

# hide progress bars on linux/macOS
# as they mess with the CI's console
if (-not ($script:IsWindows)) {
    $script:ProgressPreference = 'SilentlyContinue'
}

Set-StrictMode -Version Latest

function Get-AppVeyorBuild {
    param()

    if (-not ($env:APPVEYOR_API_TOKEN)) {
        throw "missing api token for AppVeyor."
    }
    if (-not ($env:APPVEYOR_ACCOUNT_NAME)) {
        throw "not an appveyor build."
    }

    Invoke-RestMethod -Uri "https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG" -Method GET -Headers @{
        "Authorization" = "Bearer $env:APPVEYOR_API_TOKEN"
        "Content-type"  = "application/json"
    }
}
function Get-TravisBuild {
    param()

    if (-not ($env:TRAVIS_API_TOKEN)) {
        throw "missing api token for Travis-CI."
    }
    if (-not ($env:APPVEYOR_ACCOUNT_NAME)) {
        throw "not an appveyor build."
    }

    Invoke-RestMethod -Uri "https://api.travis-ci.org/builds?limit=10" -Method Get -Headers @{
        "Authorization"      = "token $env:TRAVIS_API_TOKEN"
        "Travis-API-Version" = "3"
    }
}

# Synopsis: Create an initial environment for developing on the module
task SetUp InstallDependencies, Build

# Synopsis: Install all module used for the development of this module
task InstallDependencies InstallPandoc, {
    Install-Module platyPS -Scope CurrentUser -Force
    Install-Module Pester -Scope CurrentUser -Force
    Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
}
#endregion Setup

#region HarmonizeVariables
switch ($true) {
    {$env:APPVEYOR_JOB_ID} {
        $CI = "AppVeyor"
        $OS = "Windows"
    }
    {$env:TRAVIS} {
        $CI = "Travis"
        $OS = $env:TRAVIS_OS_NAME
    }
    { (-not($env:APPVEYOR_JOB_ID)) -and (-not($env:TRAVIS)) } {
        $CI = "local"
        $branch = git branch 2>$null | select-string -Pattern "^\*\s(.+)$" | Foreach-Object { $_.Matches.Groups[1].Value}
        $commit = git log 2>$null | select-string -Pattern "^commit ([0-9a-f]{7}) \(HEAD ->.*$branch.*$" | Foreach-Object { $_.Matches.Groups[1].Value}
    }
    {$IsWindows} {
        $OS = "Windows"
        if (-not ($IsCoreCLR)) {
            $OSVersion = $PSVersionTable.BuildVersion.ToString()
        }
    }
    {$IsLinux} {
        $OS = "Linux"
    }
    {$IsMacOs} {
        $OS = "OSX"
    }
    {$IsCoreCLR} {
        $OSVersion = $PSVersionTable.OS
    }
}

$PROJECT_NAME = if ($env:APPVEYOR_PROJECT_NAME) {$env:APPVEYOR_PROJECT_NAME} elseif ($env:TRAVIS_REPO_SLUG) {$env:TRAVIS_REPO_SLUG} else {$ModuleName}
$BUILD_FOLDER = if ($env:APPVEYOR_BUILD_FOLDER) {$env:APPVEYOR_BUILD_FOLDER} elseif ($env:TRAVIS_BUILD_DIR) {$env:TRAVIS_BUILD_DIR} else {$BuildRoot}
$REPO_NAME = if ($env:APPVEYOR_REPO_NAME) {$env:APPVEYOR_REPO_NAME} elseif ($env:TRAVIS_REPO_SLUG) {$env:TRAVIS_REPO_SLUG} else {$ModuleName}
$REPO_BRANCH = if ($env:APPVEYOR_REPO_BRANCH) {$env:APPVEYOR_REPO_BRANCH} elseif ($env:TRAVIS_BRANCH) {$env:TRAVIS_BRANCH} elseif ($branch) {$branch} else {''}
$REPO_COMMIT = if ($env:APPVEYOR_REPO_COMMIT) {$env:APPVEYOR_REPO_COMMIT} elseif ($env:TRAVIS_COMMIT) {$env:TRAVIS_COMMIT} elseif ($commit) {$commit} else {''}
$REPO_COMMIT_AUTHOR = if ($env:APPVEYOR_REPO_COMMIT_AUTHOR) {$env:APPVEYOR_REPO_COMMIT_AUTHOR} else {''}
$REPO_COMMIT_TIMESTAMP = if ($env:APPVEYOR_REPO_COMMIT_TIMESTAMP) {$env:APPVEYOR_REPO_COMMIT_TIMESTAMP} else {''}
$REPO_COMMIT_RANGE = if ($env:TRAVIS_COMMIT_RANGE) {$env:TRAVIS_COMMIT_RANGE} else {''}
$REPO_COMMIT_MESSAGE = if ($env:APPVEYOR_REPO_COMMIT_MESSAGE) {$env:APPVEYOR_REPO_COMMIT_MESSAGE} elseif ($env:TRAVIS_COMMIT_MESSAGE) {$env:TRAVIS_COMMIT_MESSAGE} else {''}
$REPO_COMMIT_MESSAGE_EXTENDED = if ($env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED) {$env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED} else {''}
$REPO_PULL_REQUEST_NUMBER = if ($env:APPVEYOR_PULL_REQUEST_NUMBER) {$env:APPVEYOR_PULL_REQUEST_NUMBER} elseif ($env:TRAVIS_PULL_REQUEST) {$env:TRAVIS_PULL_REQUEST} else {''}
$REPO_PULL_REQUEST_TITLE = if ($env:APPVEYOR_PULL_REQUEST_TITLE) {$env:APPVEYOR_PULL_REQUEST_TITLE} else {''}
$REPO_PULL_REQUEST_SHA = if ($env:TRAVIS_PULL_REQUEST_SHA) {$env:TRAVIS_PULL_REQUEST_SHA} else {''}
$BUILD_ID = if ($env:APPVEYOR_BUILD_ID) {$env:APPVEYOR_BUILD_ID} elseif ($env:TRAVIS_BUILD_ID) {$env:TRAVIS_BUILD_ID} else {''}
$BUILD_NUMBER = if ($env:APPVEYOR_BUILD_NUMBER) {$env:APPVEYOR_BUILD_NUMBER} elseif ($env:TRAVIS_BUILD_NUMBER) {$env:TRAVIS_BUILD_NUMBER} else {''}
$BUILD_VERSION = if ($env:APPVEYOR_BUILD_VERSION) {$env:APPVEYOR_BUILD_VERSION} elseif ($env:TRAVIS_BUILD_NUMBER) {$env:TRAVIS_BUILD_NUMBER} else {''}
$BUILD_JOB_ID = if ($env:APPVEYOR_JOB_ID) {$env:APPVEYOR_JOB_ID} elseif ($env:TRAVIS_JOB_ID) {$env:TRAVIS_JOB_ID} else {''}
$REPO_TAG = if ($env:APPVEYOR_REPO_TAG) {$env:APPVEYOR_REPO_TAG} elseif ($env:TRAVIS_TAG) {([bool]$env:TRAVIS_TAG)} else {''}
$REPO_TAG_NAME = if ($env:APPVEYOR_REPO_TAG_NAME) {$env:APPVEYOR_REPO_TAG_NAME} elseif ($env:TRAVIS_TAG) {$env:TRAVIS_TAG} else {''}
#endregion HarmonizeVariables

#region DebugInformation
task ShowDebug {
    Write-Host "" -Foreground "Gray"
    Write-Host ('Running in:                 {0}' -f $CI) -Foreground "Gray"
    Write-Host "" -Foreground "Gray"
    Write-Host ('Project name:               {0}' -f $PROJECT_NAME) -Foreground "Gray"
    Write-Host ('Project root:               {0}' -f $BUILD_FOLDER) -Foreground "Gray"
    Write-Host ('Repo name:                  {0}' -f $REPO_NAME) -Foreground "Gray"
    Write-Host ('Branch:                     {0}' -f $REPO_BRANCH) -Foreground "Gray"
    Write-Host ('Commit:                     {0}' -f $REPO_COMMIT) -Foreground "Gray"
    Write-Host ('  - Author:                 {0}' -f $REPO_COMMIT_AUTHOR) -Foreground "Gray"
    Write-Host ('  - Time:                   {0}' -f $REPO_COMMIT_TIMESTAMP) -Foreground "Gray"
    Write-Host ('  - Range:                  {0}' -f $REPO_COMMIT_RANGE) -Foreground "Gray"
    Write-Host ('  - Message:                {0}' -f $REPO_COMMIT_MESSAGE) -Foreground "Gray"
    Write-Host ('  - Extended message:       {0}' -f $REPO_COMMIT_MESSAGE_EXTENDED) -Foreground "Gray"
    Write-Host ('Pull request:') -Foreground "Gray"
    Write-Host ('  - Pull request number:    {0}' -f $REPO_PULL_REQUEST_NUMBER) -Foreground "Gray"
    Write-Host ('  - Pull request title:     {0}' -f $REPO_PULL_REQUEST_TITLE) -Foreground "Gray"
    Write-Host ('  - Pull request SHA:       {0}' -f $REPO_PULL_REQUEST_SHA) -Foreground "Gray"
    Write-Host ('CI data:') -Foreground "Gray"
    Write-Host ('  - Build ID:               {0}' -f $BUILD_ID) -Foreground "Gray"
    Write-Host ('  - Build number:           {0}' -f $BUILD_NUMBER) -Foreground "Gray"
    Write-Host ('  - Build version:          {0}' -f $BUILD_VERSION) -Foreground "Gray"
    Write-Host ('  - Job ID:                 {0}' -f $BUILD_JOB_ID) -Foreground "Gray"
    Write-Host ('Build triggered from tag?   {0}' -f $REPO_TAG) -Foreground "Gray"
    Write-Host ('  - Tag name:               {0}' -f $REPO_TAG_NAME) -Foreground "Gray"
    Write-Host "" -Foreground "Gray"
    Write-Host ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString()) -Foreground "Gray"
    Write-Host ('OS:                         {0}' -f $OS) -Foreground "Gray"
    Write-Host ('OS Version:                 {0}' -f $OSVersion) -Foreground "Gray"
    Write-Host "" -Foreground "Gray"
}
#endregion DebugInformation

#region DependecyTasks
# Synopsis: Install pandoc to .\Tools\
task InstallPandoc {
    # Setup
    if (-not (Test-Path "$BuildRoot/Tools")) {
        $null = New-Item -Path "$BuildRoot/Tools" -ItemType Directory
    }

    if ($OS -like "Windows*") {
        $path = $env:Path -split ([IO.Path]::PathSeparator)
        if ("$BuildRoot/Tools" -notin $path) {
            $path += Join-path $BuildRoot "Tools"
            $env:Path = $path -join ([IO.Path]::PathSeparator)
        }
    }

    $pandocVersion = $false
    try {
        $pandocVersion = & { pandoc --version }
    }
    catch { }
    If (-not ($pandocVersion)) {

        $installationFile = "$([System.IO.Path]::GetTempPath()){0}"

        # Get latest bits
        switch -regex ($OS) {
            "^[wW]indows" {
                $latestRelease = "https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-windows.msi"
                Invoke-WebRequest -Uri $latestRelease -OutFile ($installationFile -f "pandoc.msi")

                # Extract bits
                $extractionPath = "$([System.IO.Path]::GetTempPath())pandoc"
                $null = New-Item -Path $extractionPath -ItemType Directory -Force
                Start-Process -Wait -FilePath msiexec.exe -ArgumentList " /qn /a `"$($installationFile -f "pandoc.msi")`" targetdir=`"$extractionPath`""

                # Move to Tools folder
                Copy-Item -Path "$extractionPath/Pandoc/pandoc.exe" -Destination "$BuildRoot/Tools/"
                Copy-Item -Path "$extractionPath/Pandoc/pandoc-citeproc.exe" -Destination "$BuildRoot/Tools/"

                # Clean
                Remove-Item -Path ($installationFile -f "pandoc.msi") -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $extractionPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            "^[lL]inux" {
                $latestRelease = "https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-1-amd64.deb"
                Invoke-WebRequest -Uri $latestRelease -OutFile ($installationFile -f "pandoc.deb")

                sudo dpkg -i $($installationFile -f "pandoc.deb")

                Remove-Item -Path ($installationFile -f "pandoc.deb") -Force -ErrorAction SilentlyContinue
            }
            "osx" {
                $latestRelease = "https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-osx.pkg"
                Invoke-WebRequest -Uri $latestRelease -OutFile ($installationFile -f "pandoc.pkg")

                sudo installer -pkg $($installationFile -f "pandoc.pkg") -target /

                Remove-Item -Path ($installationFile -f "pandoc.deb") -Force -ErrorAction SilentlyContinue
            }
        }
    }

    $out = & { pandoc --version }
    if (-not($out)) {throw "Could not install pandoc"}

}
#endregion DependecyTasks

#region BuildRelease
# Synopsis: Build shippable release
task Build GenerateRelease, ConvertMarkdown, UpdateManifest

# Synopsis: Generate .\Release structure
task GenerateRelease {
    # Copy module
    Copy-Item -Path "$BuildRoot/$PROJECT_NAME" -Destination "$releasePath/$PROJECT_NAME" -Recurse -Force
    # Copy additional files
    Copy-Item -Path @(
        "$BuildRoot/CHANGELOG.md"
        "$BuildRoot/LICENSE"
        "$BuildRoot/README.md"
    ) -Destination "$releasePath/$PROJECT_NAME" -Force
    # Copy Tests
    $null = New-Item -Path "$releasePath/Tests" -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Path "$BuildRoot/Tests/*" -Destination "$releasePath/Tests" -Recurse -Force
    # Include Analyzer Settings
    Copy-Item -Path "$BuildRoot/PSScriptAnalyzerSettings.psd1" -Destination "$releasePath/PSScriptAnalyzerSettings.psd1" -Force
    Update-MetaData -Path "$releasePath/PSScriptAnalyzerSettings.psd1" -PropertyName ExcludeRules -Value ''

}, CompileModule, CreateHelp

# Synopsis: Compile all functions into the .psm1 file
task CompileModule {
    $regionsToKeep = @('Dependencies', 'ModuleConfig')

    $targetFile = "$releasePath/$PROJECT_NAME/$PROJECT_NAME.psm1"
    $content = Get-Content -Encoding UTF8 -LiteralPath $targetFile
    $capture = $false
    $compiled = ""

    foreach ($line in $content) {
        if ($line -match "^#region ($($regionsToKeep -join "|"))$") {
            $capture = $true
        }
        if (($capture -eq $true) -and ($line -match "^#endregion")) {
            $capture = $false
            $compiled += "$line`n`n"
        }

        if ($capture) {
            $compiled += "$line`n"
        }
    }

    $PublicFunctions = @( Get-ChildItem -Path "$releasePath/$PROJECT_NAME/Public/*.ps1" -ErrorAction SilentlyContinue )
    $PrivateFunctions = @( Get-ChildItem -Path "$releasePath/$PROJECT_NAME/Private/*.ps1" -ErrorAction SilentlyContinue )

    foreach ($function in @($PublicFunctions + $PrivateFunctions)) {
        $compiled += (Get-Content -Path $function.FullName -Raw)
        $compiled += "`n"
    }

    Set-Content -LiteralPath $targetFile -Value $compiled -Encoding UTF8 -Force
    "Private", "Public" | Foreach-Object { Remove-Item -Path "$releasePath/$PROJECT_NAME/$_" -Recurse -Force }
}

# Synopsis: Generate external XML-help file from Markdown
task CreateHelp -If (Get-ChildItem "$BuildRoot/docs/commands" -ErrorAction SilentlyContinue) {
    Import-Module platyPS -Force
    $null = New-ExternalHelp -Path "$BuildRoot/docs/commands" -OutputPath "$releasePath/$PROJECT_NAME/en-US" -Force
    Remove-Module $PROJECT_NAME, platyPS
}

$ConvertMarkdown = @{
    # <http://johnmacfarlane.net/pandoc/>
    Inputs  = { Get-ChildItem "$releasePath/$PROJECT_NAME/*.md" -Recurse }
    Outputs = {process {
            [System.IO.Path]::ChangeExtension($_, 'htm')
        }
    }
}
# Synopsis: Converts *.md and *.markdown files to *.htm
task ConvertMarkdown -Partial @ConvertMarkdown InstallPandoc, {
    process {
        pandoc $_ --standalone --from=markdown_github "--output=$2"
    }
}, RemoveMarkdownFiles

# Synopsis: Update the manifest of the module
task UpdateManifest GetVersion, {
    Remove-Module $PROJECT_NAME -ErrorAction SilentlyContinue
    Import-Module "$BuildRoot/$PROJECT_NAME/$PROJECT_NAME.psd1" -Force
    $ModuleAlias = @(Get-Alias | Where-Object {$_.ModuleName -eq "$PROJECT_NAME"})

    Remove-Module $PROJECT_NAME -ErrorAction SilentlyContinue
    Import-Module $PROJECT_NAME -Force

    Remove-Module BuildHelpers -ErrorAction SilentlyContinue
    Import-Module BuildHelpers -Force

    BuildHelpers\Update-Metadata -Path "$releasePath/$PROJECT_NAME/$PROJECT_NAME.psd1" -PropertyName ModuleVersion -Value $script:Version
    # BuildHelpers\Update-Metadata -Path "$releasePath/$PROJECT_NAME/$PROJECT_NAME.psd1" -PropertyName FileList -Value (Get-ChildItem "$releasePath/$PROJECT_NAME" -Recurse).Name
    if ($ModuleAlias) {
        BuildHelpers\Update-Metadata -Path "$releasePath/$PROJECT_NAME/$PROJECT_NAME.psd1" -PropertyName AliasesToExport -Value @($ModuleAlias.Name)
    }
    else {
        BuildHelpers\Update-Metadata -Path "$releasePath/$PROJECT_NAME/$PROJECT_NAME.psd1" -PropertyName AliasesToExport -Value ''
    }
    BuildHelpers\Set-ModuleFunctions -Name "$releasePath/$PROJECT_NAME/$PROJECT_NAME.psd1" -FunctionsToExport ([string[]](Get-ChildItem "$BuildRoot\$PROJECT_NAME\Public\*.ps1").BaseName)
}

task GetVersion {
    $manifestContent = Get-Content -Path "$releasePath/$PROJECT_NAME/$PROJECT_NAME.psd1" -Raw
    if ($manifestContent -notmatch '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')') {
        throw "Module version was not found in manifest file."
    }

    $currentVersion = [Version]($Matches.ModuleVersion)
    if ($BUILD_NUMBER) {
        $newRevision = $BUILD_NUMBER
    }
    else {
        $newRevision = 0
    }
    $script:Version = New-Object -TypeName System.Version -ArgumentList $currentVersion.Major,
    $currentVersion.Minor,
    $newRevision
}
#endregion BuildRelease

#region Test
function allCIsFinished {
    param()

    if (-not ($env:APPVEYOR_REPO_COMMIT)) {
        return $true
    }

    Write-Host "[IDLE] :: waiting on travis to finish"

    [datetime]$stop = ([datetime]::Now).AddMinutes($env:TimeOutMins)

    do {
        $currentBuild = (Get-TravisBuild).builds | Where-Object {$_.commit.sha -eq $env:APPVEYOR_REPO_COMMIT}
        switch -regex ($currentBuild.state) {
            "^passed$" {
                return $true
            }
            "^(errored|failed|canceled)" {
                throw "Travis Job ($($currentBuild.id)) failed"
            }
        }

        Start-sleep 5
    } while (([datetime]::Now) -lt $stop)
    if (!$currentBuild) {
        throw "Could not get information about Travis build with sha $REPO_COMMIT"
    }

    throw "Travis build did not finished in $env:TimeOutMins minutes"
}
# Synopsis: Run Pester tests on the module
task Test Build, {
    # $null = allCIsFinished

    assert { Test-Path "$releasePath/Tests/" -PathType Container } "No Test folder available."

    Remove-Module BuildHelpers -ErrorAction SilentlyContinue
    Import-Module BuildHelpers -Force

    try {
        $result = Invoke-Pester -Script "$releasePath/Tests/*" -PassThru -OutputFile "$BuildRoot/TestResult.xml" -OutputFormat "NUnitXml"
        if ($CI -eq "AppVeyor") {
            BuildHelpers\Add-TestResultToAppveyor -TestFile "$BuildRoot/TestResult.xml"
        }
        Remove-Item "$BuildRoot/TestResult.xml" -Force
        assert ($result.FailedCount -eq 0) "$($result.FailedCount) Pester test(s) failed."
    }
    catch {
        throw $_
    }
}
#endregion

#region Publish
function allJobsFinished {
    param()
    $buildData = Get-AppVeyorBuild
    $lastJob = ($buildData.build.jobs | Select-Object -Last 1).jobId

    if ($lastJob -ne $env:APPVEYOR_JOB_ID) {
        return $false
    }

    write-host "[IDLE] :: waiting for other jobs to complete"

    [datetime]$stop = ([datetime]::Now).AddMinutes($env:TimeOutMins)

    do {
        $project = Get-AppVeyorBuild
        $continue = @()
        $project.build.jobs | Where-Object {$_.jobId -ne $env:APPVEYOR_JOB_ID} | Foreach-Object {
            $job = $_
            switch -regex ($job.status) {
                "failed" { throw "AppVeyor's Job ($($job.jobId)) failed." }
                "(running|success)" { $continue += $true; continue }
                Default { $continue += $false; Write-Host "new state: $_.status" }
            }
        }
        if ($false -notin $continue) { return $true }
        Start-sleep 5
    } while (([datetime]::Now) -lt $stop)

    throw "Test jobs were not finished in $env:TimeOutMins minutes"
}

$shouldDeploy = (
    # only deploy from AppVeyor
    ($CI -eq "AppVeyor") -and
    # only deploy from last Job
    (allJobsFinished) -and
    # only deploy master branch
    ($REPO_BRANCH -eq 'master') -and
    # it cannot be a PR
    (-not ($REPO_PULL_REQUEST_NUMBER)) -and
    # it cannot have a commit message that contains "skip-deploy"
    ($REPO_COMMIT_MESSAGE -notlike '*skip-deploy*')
)
# Synopsis: Publish a new release on github, PSGallery and the homepage
task Deploy -If $shouldDeploy PublishToGallery, UpdateHomepage, GeneratePackage

# Synipsis: Publish the $release to the PSGallery
task PublishToGallery {
    assert ($env:PSGalleryAPIKey) "No key for the PSGallery"

    Remove-Module $PROJECT_NAME -ErrorAction SilentlyContinue
    Import-Module $PROJECT_NAME -ErrorAction Stop
    Publish-Module -Name $PROJECT_NAME -NuGetApiKey $env:PSGalleryAPIKey
}

# Synopsis: Update the HEAD of this git repo in the homepage repository
task UpdateHomepage {
    $originalErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        # Get the repo of the homepage
        git clone https://github.com/AtlassianPS/AtlassianPS.github.io --recursive 2>$null
        Write-Host "Cloned"
        Set-Location "AtlassianPS.github.io/"

        # Update all submodules
        # git submodule foreach git pull origin master 2>$null
        # Write-Host "Fetched"

        # Check if this repo was changed
        $status = git status -s 2>$null
        Write-Host $status
        if ($status -contains " M modules/$PROJECT_NAME") {
            Write-Host "Has changes"
            # Update the repo in the homepage repo
            git add modules/$PROJECT_NAME 2>$null
            Write-Host "Added"
            git commit -m "Update module $PROJECT_NAME" 2>$null
            Write-Host "Commited"
            git push 2>$null
            Write-Host "Pushed"
        }
    }
    catch {
        throw $_
    }
    finally {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

# Synopsis: Create a zip package file of the release
task GeneratePackage {
    $null = Compress-Archive -Path "$releasePath\$PROJECT_NAME" -DestinationPath "$releasePath\$PROJECT_NAME.zip"
}
# endregion

#region Cleaning tasks
# Synopsis: Clean the working dir
task Clean RemoveGeneratedFiles

# Synopsis: Remove generated and temp files.
task RemoveGeneratedFiles {
    $itemsToRemove = @(
        'Release'
        '*.htm'
        'TestResult.xml'
        '$PROJECT_NAME\en-US\*'
    )
    Remove-Item $itemsToRemove -Force -Recurse -ErrorAction 0
}

task RemoveMarkdownFiles {
    Remove-Item "$releasePath\$PROJECT_NAME\*.md" -Force -ErrorAction 0
}
# endregion

task . ShowDebug, Clean, Build, Test, Deploy
