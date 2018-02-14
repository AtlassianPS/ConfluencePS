function Get-AttachmentFile {
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter( Mandatory = $true )]
        [URi]$apiURi,

        [Parameter( Mandatory = $true )]
        [PSCredential]$Credential,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Attachment]$Attachment,

        [String]$OutFile
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Attachment])) {
            $message = "The Object in the pipe is not an Attachment."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        if (-not($OutFile)) {
            $OutFile = "{0}"
        }

        foreach ($_Attachment in $Attachment) {
            # resolve any use of format elements in the file name
            # {0} is file_name, {1} is the ID, {2} is space key, {3} is page id, {4} is version
            $_OutFile = $OutFile -f $_Attachment.Title, $_Attachment.ID, $_Attachment.SpaceKey, $_Attachment.PageID, $_Attachment.Version.Number

            if (-not(Test-Path $_OutFile -IsValid)) {
              $message = "Invalid file name generated : $($_OutFile)"
              $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
              Throw $exception
            }

            $iwParameters = @{
                Uri           = $_Attachment.URL
                Method        = 'Get'
                Headers       = @{"Accept" = $_Attachment.MediaType}
                OutFile       = $_OutFile
                Credential    = $Credential
            }

            Invoke-Method @iwParameters
       }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
