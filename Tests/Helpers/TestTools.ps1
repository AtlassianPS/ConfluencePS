# Captured at dot-source time when $PSScriptRoot is this file's directory (Tests/Helpers/)
$script:_TestToolsDir = $PSScriptRoot

function Resolve-ProjectRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $candidate = (Resolve-Path $script:_TestToolsDir).Path
    while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
        $buildScript = Join-Path $candidate "ConfluencePS.build.ps1"
        $manifest = Join-Path $candidate "ConfluencePS/ConfluencePS.psd1"
        if ((Test-Path $buildScript) -and (Test-Path $manifest)) {
            return $candidate
        }
        $candidate = Split-Path $candidate -Parent
    }

    throw "Could not find project root (missing ConfluencePS.build.ps1 and ConfluencePS/ConfluencePS.psd1 in parent directories of $($script:_TestToolsDir))."
}

function Initialize-TestEnvironment {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string]$CallerPath = $PSScriptRoot
    )

    $projectRoot = Resolve-ProjectRoot
    $projectName = "ConfluencePS"

    $env:BHProjectName = $projectName
    $env:BHProjectPath = $projectRoot
    $env:BHModulePath = Join-Path $projectRoot $projectName
    $env:BHPSModulePath = $env:BHModulePath
    $env:BHPSModuleManifest = Join-Path $env:BHModulePath "$projectName.psd1"
    $env:BHBuildOutput = Join-Path $projectRoot "Release"

    $isBuild = $CallerPath -like "*$([System.IO.Path]::DirectorySeparatorChar)Release$([System.IO.Path]::DirectorySeparatorChar)*"
    $env:BHManifestToTest = $env:BHPSModuleManifest
    if ($isBuild) {
        $pattern = [regex]::Escape($env:BHProjectPath)
        $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $pattern, $env:BHBuildOutput
        $env:BHManifestToTest = $env:BHBuildModuleManifest
    }

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    return $env:BHManifestToTest
}

function Get-FileEncoding {
    [CmdletBinding()]
    [OutputType('EncodingInfo')]
    param (
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [Alias('FullName')]
        [String]$Path
    )

    begin {
        $signatures = [Ordered]@{
            'UTF32-LE'   = 'FF-FE-00-00'
            'UTF32-BE'   = '00-00-FE-FF'
            'UTF8-BOM'   = 'EF-BB-BF'
            'UTF16-LE'   = 'FF-FE'
            'UTF16-BE'   = 'FE-FF'
            'UTF7'       = '2B-2F-76-38', '2B-2F-76-39', '2B-2F-76-2B', '2B-2F-76-2F'
            'UTF1'       = 'F7-64-4C'
            'UTF-EBCDIC' = 'DD-73-66-73'
            'SCSU'       = '0E-FE-FF'
            'BOCU-1'     = 'FB-EE-28'
            'GB-18030'   = '84-31-95-33'
        }

        [String[]]$keys = $signatures.Keys
        foreach ($name in $keys) {
            [System.Collections.Generic.List[System.Collections.Generic.List[Byte]]]$values = foreach ($value in $signatures[$name]) {
                [System.Collections.Generic.List[Byte]]$signatureBytes = foreach ($byte in $value.Split('-')) {
                    [Convert]::ToByte($byte, 16)
                }
                , $signatureBytes
            }
            $signatures[$name] = $values
        }
    }

    process {
        try {
            $Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)

            $bytes = [Byte[]]::new(8)
            $stream = New-Object System.IO.StreamReader($Path)
            $null = $stream.Peek()
            $enc = $stream.CurrentEncoding
            $stream.Close()
            $stream = [System.IO.File]::OpenRead($Path)
            $null = $stream.Read($bytes, 0, $bytes.Count)
            $bytes = [System.Collections.Generic.List[Byte]]$bytes
            $stream.Close()

            if ($enc -eq [System.Text.Encoding]::UTF8) {
                $encoding = "UTF8"
            }

            foreach ($name in $signatures.Keys) {
                $sampleEncoding = foreach ($sequence in $signatures[$name]) {
                    $sample = $bytes.GetRange(0, $sequence.Count)
                    if ([System.Linq.Enumerable]::SequenceEqual($sample, $sequence)) {
                        $name
                        break
                    }
                }
                if ($sampleEncoding) {
                    $encoding = $sampleEncoding
                    break
                }
            }

            if (-not $encoding) {
                $encoding = "ASCII"
            }

            [PSCustomObject]@{
                Name      = Split-Path $Path -Leaf
                Extension = [System.IO.Path]::GetExtension($Path)
                Encoding  = $encoding
                Path      = $Path
            } | Add-Member -TypeName 'EncodingInfo' -PassThru
        }
        catch {
            $pscmdlet.WriteError($_)
        }
    }
}
