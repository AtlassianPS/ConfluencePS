@{
    PSDependOptions  = @{
        Target = "CurrentUser"
    }

    InvokeBuild      = "latest"
    BuildHelpers     = @{
        Parameters = @{
            AllowClobber = $true
        }
        Version    = "latest"
    }
    Configuration    = @{
        Parameters = @{
            AllowClobber = $true
        }
        Version    = "latest"
    }
    Pester           = @{
        Parameters = @{
            SkipPublisherCheck = $true
        }
        Version    = "4.10"
    }
    platyPS          = "latest"
    PSScriptAnalyzer = @{
        Parameters = @{
            SkipPublisherCheck = $true
        }
        Version    = "1.25.0"
    }
    'AtlassianPS.Standards' = @{
        Version    = "0.1.2"
    }
}
