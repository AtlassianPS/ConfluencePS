[![Build status](https://ci.appveyor.com/api/projects/status/jcyw4oxnpqp3djtn?svg=true)](https://ci.appveyor.com/project/brianbunke/confluenceps)

# ConfluencePS
Automate your documentation! ConfluencePS is a PowerShell module that interacts with Atlassian's [Confluence] wiki product.

Need to add 100 new pages based on some dumb CSV file? Are you trying to figure out how to delete all pages labeled 'deleteme'? Are you sick of manually editing the same page every single day? ConfluencePS has you covered!

ConfluencePS communicates with Atlassian's actively supported [REST API] via basic authentication. The REST implementation is the only way to interact with their cloud-hosted instances via API, and will eventually be the only way to interact with server installations.

## Instructions
Install ConfluencePS from the [PowerShell Gallery]! `Install-Module` requires PowerShellGet (included in PS v5, or download for v3/v4 via the gallery link)

```posh
# One time only install: (requires an admin PowerShell window)
Install-Module ConfluencePS

# Check for updates occasionally:
Update-Module ConfluencePS

# To use each session:
Import-Module ConfluencePS
Set-ConfluenceInfo -BaseURI 'https://YourCloudWiki.atlassian.net/wiki' -PromptCredentials

# Review the help at any time!
Get-Help about_ConfluencePS
Get-Command -Module ConfluencePS
Get-Help Get-ConfluencePage -Full   # or any other command
```

## Acknowledgments
Many thanks to [thomykay] for his [PoshConfluence] SOAP API module, which provided enough of a starting point to feel comfortable undertaking this project.

## Disclaimer
Hopefully this is obvious, but:

This is an open source project (under the [MIT license]), and all contributors are volunteers. All commands are executed at your own risk. Please have good backups before you start, because you can delete a lot of stuff if you're not careful.

  [Confluence]: <https://www.atlassian.com/software/confluence>
  [REST API]: <https://docs.atlassian.com/atlassian-confluence/REST/latest/>
  [PowerShell Gallery]: <https://www.powershellgallery.com/>
  [thomykay]: <https://github.com/thomykay>
  [PoshConfluence]: <https://github.com/thomykay/PoshConfluence>
  [RamblingCookieMonster]: <https://github.com/RamblingCookieMonster>
  [PSStackExchange]: <https://github.com/RamblingCookieMonster/PSStackExchange>
  [juneb]: <https://github.com/juneb>
  [Check this out]: <https://github.com/juneb/PowerShellHelpDeepDive>
  [MIT license]: <https://github.com/brianbunke/ConfluencePS/blob/master/LICENSE>

<!-- [//]: # (Sweet online markdown editor at http://dillinger.io) -->
<!-- [//]: # ("GitHub Flavored Markdown" https://help.github.com/articles/github-flavored-markdown/) -->
