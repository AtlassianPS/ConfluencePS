function Get-User
{
    [CmdletBinding(
        SupportsPaging = $true
    )]
    [OutputType([ConfluencePS.User])]
    param (
        [Parameter( Mandatory = $true )]
        [URi]$ApiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $true,
        ParameterSetName = 'ByUserName'
        )]
        [string]$Username,

        [Parameter( Mandatory = $true,
        ParameterSetName = 'ByKey'
        )]
        [string]$UserKey
    )

    BEGIN
    {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$apiURi/user{0}"
    }

    PROCESS
    {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = @{
            Uri           = ""
            Method        = 'Get'
            OutputType    = [ConfluencePS.User]
            Credential    = $Credential
        }

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }
        switch ($PsCmdlet.ParameterSetName)
        {
            'ByUsername'
            {
                $iwParameters["Uri"] = $resourceApi -f "?username=$Username"
                break
            }
            'ByKey'
            {
                $iwParameters["Uri"] = $resourceApi -f "?key=$UserKey"
                break
            }
        }
        Invoke-Method @iwParameters
    }

    END
    {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
