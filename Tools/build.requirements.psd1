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
    Configuration = @{
        Parameters = @{
            AllowClobber = $true
        }
        Version = "latest"
    }
    Pester           = @{
        Parameters = @{
            SkipPublisherCheck = $true
        }
        Version    = "4.4.0"
    }
    platyPS          = @{
        Version = "0.8.3"
    }
    PSScriptAnalyzer = @{
        Parameters = @{
            SkipPublisherCheck = $true
        }
        Version    = "latest"
    }
}
