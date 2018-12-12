function Get-Page {
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byId"
    )]
    [OutputType([ConfluencePS.Page])]
    param (
        [Parameter( Mandatory = $true )]
        [URi]$ApiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "byId",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [Alias('ID')]
        [int[]]$PageID,

        [Parameter(
            ParameterSetName = "bySpace"
        )]
        [Parameter(
            ParameterSetName = "bySpaceObject"
        )]
        [Alias('Name')]
        [string]$Title,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "bySpace"
        )]
        [Parameter(
            ParameterSetName = "byLabel"
        )]
        [Alias('Key')]
        [string]$SpaceKey,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "bySpaceObject"
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ParameterSetName = "byLabel"
        )]
        [ConfluencePS.Space]$Space,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byLabel"
        )]
        [string[]]$Label,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "byQuery"
        )]
        [string]$Query,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$apiURi/content{0}"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($Space -is [ConfluencePS.Space] -and ($Space.Key)) {
            $SpaceKey = $Space.Key
        }

        $iwParameters = @{
            Uri           = ""
            Method        = 'Get'
            GetParameters = @{
                expand = "space,version,body.storage,ancestors"
                limit  = $PageSize
            }
            OutputType    = [ConfluencePS.Page]
            Credential    = $Credential
        }

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        switch -regex ($PsCmdlet.ParameterSetName) {
            "byId" {
                foreach ($_pageID in $PageID) {
                    $iwParameters["Uri"] = $resourceApi -f "/$_pageID"

                    Invoke-Method @iwParameters
                }
                break
            }
            "bySpace" { # This includes 'bySpaceObject'
                $iwParameters["Paging"] = $true
                $iwParameters["Uri"] = $resourceApi -f ''
                $iwParameters["GetParameters"]["type"] = "page"
                if ($SpaceKey) { $iwParameters["GetParameters"]["spaceKey"] = $SpaceKey }

                if ($Title) {
                    Invoke-Method @iwParameters | Where-Object {$_.Title -like "$Title"}
                }
                else {
                    Invoke-Method @iwParameters
                }
                break
            }
            "byLabel" {
                $iwParameters["Paging"] = $true
                $iwParameters["Uri"] = $resourceApi -f "/search"

                $CQLparameters = @("type=page", "label=$Label")
                if ($SpaceKey) {$CQLparameters += "space=$SpaceKey"}
                $cqlQuery = ConvertTo-URLEncoded ($CQLparameters -join (" AND "))

                $iwParameters["GetParameters"]["cql"] = $cqlQuery

                Invoke-Method @iwParameters
                break
            }
            "byQuery" {
                $iwParameters["Paging"] = $true
                $iwParameters["Uri"] = $resourceApi -f "/search"

                $cqlQuery = ConvertTo-URLEncoded $Query
                $iwParameters["GetParameters"]["cql"] = "type=page AND $cqlQuery"

                Invoke-Method @iwParameters
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
