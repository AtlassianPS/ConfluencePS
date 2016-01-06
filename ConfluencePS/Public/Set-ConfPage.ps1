function Set-ConfPage {
    <#
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
    param (
		[Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
		[Alias('ID')]
        [int]$PageID,

		[Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [int]$ParentID,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]$Title,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]$Body,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[int]$CurrentVersion,

        [switch]$Convert
    )

    BEGIN {
        If (!($Header) -or !($BaseURI)) {
            Write-Debug 'URI or authentication not found. Calling Set-ConfInfo'
            Set-ConfInfo
        }
    }

    PROCESS {
        # Title & Version must be specified in the PUT
        # If one or both are not found, use Get-ConfPage to capture them
        If ((!$CurrentVersion) -or (!$Title)) {
            Write-Verbose "Title and/or version unspecified. Calling Get-ConfPage w/ ID $PageID"
            $CurrentPage = Get-ConfPage -PageID $PageID -Expand
            [int]$Version = $CurrentPage.Ver
            $Title = $CurrentPage.Title
        }

        # The PUT wants new version, not current, so increment by one
        $Version++
        
        # If -Convert is flagged, call ConvertTo-ConfStorageFormat against the -Body
        If ($Convert) {
            Write-Verbose '-Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-ConfStorageFormat -Content $Body
        }

        $URI = $BaseURI + "/content/$PageID"

        $Content = @{version   = @{number = $Version}
                     title     = $Title
                     type      = 'page'
                     body      = @{storage = @{value          = $Body
                                               representation = 'storage'
                                              }
                                  }
                     ancestors = @{id = $ParentID}
                    # Using -Compress to make the -replace below easier
                    } | ConvertTo-Json -Compress
        
        # Ancestors requires [] brackets around its JSON values to work correctly
        # This is RegEx magic. If you're not familiar, regex101.com or similar sites
        $Content = $Content -replace '(\{\"id\"\:\d+\})','[$1]'
                
        Write-Verbose "PUT (edit) to $URI"
        # -WhatIf wrapper
        If ($PSCmdlet.ShouldProcess("PageID $PageID, Body $Body")) {
            $Rest = Invoke-RestMethod -Headers $Header -Uri $URI -Body $Content -Method Put -ContentType 'application/json'

            # Hashing everything because I don't like the lower case property names from the REST call
            $Rest | Select @{n='ID';      e={$_.id}},
                           @{n='Key';     e={$_.space.key}},
                           @{n='Title';   e={$_.title}},
                           @{n='ParentID';e={$_.ancestors.id}}
        }
    }
}
