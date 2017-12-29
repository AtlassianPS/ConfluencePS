try {
    Add-Type -AssemblyName System.Core
}
catch {
    Write-Host "FFFF"
}

# Load the ConfluencePS namespace from C#
if (!("ConfluencePS.Space" -as [Type])) {
    Add-Type -Path (Join-Path $PSScriptRoot ConfluencePS.Types.cs) -ReferencedAssemblies Microsoft.CSharp
}

# Load Web assembly when needed
# PowerShell Core has the assembly preloaded
if (!("System.Web.HttpUtility" -as [Type])) {
    Add-Type -Assembly System.Web
}

# Gather all files
$PublicFunctions = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the functions
ForEach ($File in @($PublicFunctions + $PrivateFunctions)) {
    Try {
        . $File.FullName
    }
    Catch {
        Write-Error -Message "Failed to import function $($File.FullName): $_"
    }
}
