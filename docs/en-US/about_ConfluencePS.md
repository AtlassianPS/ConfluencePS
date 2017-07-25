---
external help file: ConfluencePS-help.xml
online version: https://github.com/AtlassianPS/ConfluencePS/blob/master/docs/en-US/about_ConfluencePS.md
locale: en-US
schema: 2.0.0
---

# About ConfluencePS
## about_ConfluencePS

# SHORT DESCRIPTION
Interact with your Confluence wiki environments from PowerShell.
Create, get, edit, and delete many pages at once.

Extensive Help is available for all cmdlets:
```powershell
Get-Help Get-ConfluencePage -Full
```

# LONG DESCRIPTION
Confluence is a wiki product from Atlassian.
ConfluencePS is a module provided to interact with Confluence's REST API.

ConfluencePS was introduced to solve two problems:
1) Making it easy to perform the same change on many wiki pages
2) Automating documentation updates

## GETTING STARTED
```powershell
Import-Module ConfluencePS
Set-ConfluenceInfo -BaseURI 'https://mywiki.company.com'
```

Unless supplying the credentials (-Credential $cred), you will then be
prompted for a username/password to connect to the wiki instance.
The connection is established via basic header authentication, and
Set-ConfluenceInfo needs to be run at the beginning of each PowerShell session.

## DISCOVERING YOUR ENVIRONMENT
To view all spaces, run the following command:
```powershell
Get-ConfluenceSpace
```

To view all pages in a specific space, you can use the pipeline:
```powershell
Get-ConfluenceSpace -Key Demo | Get-Page -PageSize 1000
```

Note that the REST API will limit your results in different ways.

For example, if you do not supply the -PageSize parameter,
only 25 entries will be fetch per call. This can result in a lot of calls to the
server in order to fetch all records.
You can limit the amount of results you want returned by using
Select-Object -First.

# EXAMPLES
1) Making it easy to perform the same change on many wiki pages
To apply a new label to all pages matching specified criteria:
```powershell
Get-ConfluencePage -Title 'Azure' -PageSize 1000 | Add-ConfluenceLabel -Label azure
```

To delete pages with the label "test":
```powershell
Get-ConfluencePage -Label test -PageSize 1000 | Remove-ConfluencePage -WhatIf
```

Use -WhatIf first to be sure only intended pages will be affected,
then run the command again without the -WhatIf parameter.

2) Automating documentation updates
My use case involved wanting a page for each VM with up-to-date specs
and purpose, because the whole team did not have access to the VM management
environment.

To accomplish this, assume there is a nightly script that pulls the following
VM info and stores it in a CSV (or database/whatever):
```powershell
Name, IP, Dept, Purpose
```

That script also populates a TXT file with names of VMs whose values
changed in the last 24 hours.

With this info, you can have another nightly script connect to the wiki
instance, see if anything has changed, and update pages accordingly with
something like the following:
```powershell
$CSV = Import-Csv .\vmlist.csv
ForEach ($VM in (Get-Content .\changes.txt)) {
    $Table = $CSV | Where Name -eq $VM | ConvertTo-ConfluenceTable | Out-String
    $Body = $Table | ConvertTo-ConfluenceStorageFormat

    If ($ID = (Get-ConfluencePage -Title "$($VM.Name)" -PageSize 500).ID) {
        # Current page found. With the ID, get the expanded result
        $PageExists = Get-ConfluencePage -PageID $ID -Expand
        $PageExists | Set-ConfluencePage -ParentID 123456 -Body $Body
    } Else {
        New-ConfluencePage -Title "$($VM.Name)" -Body $Body -ParentID 123456
    }
}
```

You want more error-handling, and probably more stuff on your wiki page.
But that's the basic idea :)

# NOTE
Support for the full REST API has not been finished, and will be supplemented
over time.

# SEE ALSO
The project on Github:
    https://github.com/AtlassianPS/ConfluencePS
Confluence's REST API documentation:
    https://docs.atlassian.com/atlassian-confluence/REST/latest/

# KEYWORDS
- Confluence
- Atlassian
- Wiki
