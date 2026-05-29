#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

param()

$script:ConfluencePSIntegrationFocus = 'Attachments'
. "$PSScriptRoot/Helpers/IntegrationLifecycle.ps1"
