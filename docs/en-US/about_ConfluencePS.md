---
locale: en-US
layout: documentation
permalink: /docs/ConfluencePS/
hide: true
---

# About ConfluencePS
## about_ConfluencePS

# SHORT DESCRIPTION
Interact with your Confluence wiki environments from PowerShell.
Create, get, edit, and/or delete many pages at once.

Extensive help is available for all cmdlets:
```powershell
Get-Help Get-ConfluencePage -Full
```

# LONG DESCRIPTION
Confluence is a wiki product from Atlassian. ConfluencePS was introduced to solve two problems:

1. Making it fast and easy to perform bulk operations on many pages
2. Automating documentation updates, to reduce stale information

ConfluencePS interacts with Confluence's REST API, which is the only way
to interact with Atlassian Cloud instances, and will be the only supported
method for Server installations in the future.

## GETTING STARTED
```powershell
Import-Module ConfluencePS
Set-ConfluenceInfo -BaseURI 'https://mywiki.company.com' -PromptCredentials
```

Unless supplying the credentials (`-Credential $cred`), you will be
prompted for a username/password to connect to your wiki instance.

`Set-ConfluenceInfo` sets defaults in your current session for common parameters
`-ApiUri` and `-Credential`. This saves you from entering the info into each command,
while retaining the ability to override them if you manage multiple instances.

## DISCOVERING YOUR ENVIRONMENT
To view all spaces visible to your authentication, run the following command:
```powershell
Get-ConfluenceSpace
```

To view all pages in a specific space, you can do that two ways:
```powershell
Get-ConfluencePage -SpaceKey Demo
# General pipeline operations are also supported
Get-ConfluenceSpace -SpaceKey Demo | Get-Page
```

To view all available details on a returned object, use cmdlets like `Format-List`.
```powershell
Get-ConfluencePage -Title 'Test Page' | Format-List *
```

# EXAMPLES
1. Making it easy to perform the same change on many wiki pages

To apply a new label to all pages matching specified criteria:
```powershell
Get-ConfluencePage -Title '*Azure*' | Add-ConfluenceLabel -Label azure
```

To delete pages with the label "test":
```powershell
Get-ConfluencePage -Label test | Remove-ConfluencePage -WhatIf
```

Use -WhatIf first to be sure only intended pages will be affected,
then run the command again without the -WhatIf parameter.

2. Automating documentation updates

My use case involved wanting a page for each VM with up-to-date specs and purpose,
because the whole team did not have access to the VM management environment.

To accomplish this, assume there is a nightly script that pulls the following
VM info and stores it in a CSV (or database/whatever):
```
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

    If ($ID = (Get-ConfluencePage -Title "$($VM.Name)").ID) {
        # Current page found. Overwrite the body (will be tracked in version history)
        Set-ConfluencePage -PageID $ID -ParentID 123456 -Body $Body
    } Else {
        # No existing page found. Create it
        New-ConfluencePage -Title "$($VM.Name)" -Body $Body -ParentID 123456
    }
}
```

You'll want more error-handling, and probably more stuff on your wiki page.
But that's the basic idea :)

# NOTE
This project is run by the volunteer organization AtlassianPS.
We are always interested in hearing from new users!
Find us on GitHub or Slack, and let us know what you think.

# SEE ALSO
ConfluencePS on Github: https://github.com/AtlassianPS/ConfluencePS

Confluence's REST API documentation: https://docs.atlassian.com/atlassian-confluence/REST/latest/

AtlassianPS org: https://atlassianps.org

AtlassianPS Slack team: https://atlassianps.org/slack

# KEYWORD
- Confluence
- Atlassian
- Wiki
