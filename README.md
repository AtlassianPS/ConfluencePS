---
layout: module
permalink: /module/ConfluencePS/
---
# [ConfluencePS](https://atlassianps.org/module/ConfluencePS)

[![GitHub release](https://img.shields.io/github/release/AtlassianPS/ConfluencePS.svg)](https://github.com/AtlassianPS/ConfluencePS/releases/latest) [![Build status](https://img.shields.io/appveyor/ci/AtlassianPS/ConfluencePS/master.svg)](https://ci.appveyor.com/project/AtlassianPS/confluenceps/branch/master) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/ConfluencePS.svg)](https://www.powershellgallery.com/packages/ConfluencePS) ![License](https://img.shields.io/badge/license-MIT-blue.svg)

Automate your documentation! ConfluencePS is a PowerShell module that interacts with Atlassian's [Confluence] wiki product.

Need to add 100 new pages based on some dumb CSV file? Are you trying to figure out how to delete all pages labeled 'deleteme'? Are you sick of manually editing the same page every single day? ConfluencePS has you covered!

ConfluencePS communicates with Atlassian's actively supported [REST API] via basic authentication. The REST implementation is the only way to interact with their cloud-hosted instances via API, and will eventually be the only way to interact with server installations.

Join the conversation on [![SlackLogo][] AtlassianPS.Slack.com](https://atlassianps.org/slack)

[SlackLogo]: https://atlassianps.org/assets/img/Slack_Mark_Web_28x28.png
<!--more-->

---

## Instructions

### Installation

Install ConfluencePS from the [PowerShell Gallery]! `Install-Module` requires PowerShellGet (included in PS v5, or download for v3/v4 via the gallery link)

```powershell
# One time only install: (requires an admin PowerShell window)
Install-Module ConfluencePS

# Check for updates occasionally:
Update-Module ConfluencePS

# To use each session:
Import-Module ConfluencePS
Set-ConfluenceInfo -BaseURI 'https://YourCloudWiki.atlassian.net/wiki' -PromptCredentials
```

### Usage

You can find the full documentation on our [homepage](https://atlassianps.org/docs/ConfluencePS) and in the console.
```powershell
# Review the help at any time!
Get-Help about_ConfluencePS
Get-Command -Module ConfluencePS
Get-Help Get-ConfluencePage -Full   # or any other command
```

For first steps to get up and running, check out the [Getting Started](https://atlassianps.org/docs/ConfluencePS/#getting-started) page.

### Contribute

Want to contribute to AtlassianPS? Great!
We appreciate [everyone](https://atlassianps.org/#people) who invests their time to make our modules the best they can be.

Check out our guidelines on [Contributing](https://atlassianps.org/docs/Contributing/) to our modules and documentation.

## Acknowledgments

* Thanks to [brianbunke] for getting this module on it's feet
* Thanks to [thomykay] for his [PoshConfluence] SOAP API module, which provided enough of a starting point to feel comfortable undertaking this project.
* Thanks to everyone ([Our Contributors](https://atlassianps.org/#people)) that helped with this module

## Useful links

* [Source Code]
* [Latest Release]
* [Submit an Issue]
* How you can help us: [List of Issues](https://github.com/AtlassianPS/ConfluencePS/issues?q=is%3Aissue+is%3Aopen+label%3Aup-for-grabs)

## Disclaimer

Hopefully this is obvious, but:
> This is an open source project (under the [MIT license]), and all contributors are volunteers. All commands are executed at your own risk. Please have good backups before you start, because you can delete a lot of stuff if you're not careful.

  [Confluence]: <https://www.atlassian.com/software/confluence>
  [REST API]: <https://docs.atlassian.com/atlassian-confluence/REST/latest/>
  [PowerShell Gallery]: <https://www.powershellgallery.com/>
  [thomykay]: <https://github.com/thomykay>
  [PoshConfluence]: <https://github.com/thomykay/PoshConfluence>
  [RamblingCookieMonster]: <https://github.com/RamblingCookieMonster>
  [PSStackExchange]: <https://github.com/RamblingCookieMonster/PSStackExchange>
  [Source Code]: <https://github.com/AtlassianPS/ConfluencePS>
  [Latest Release]: <https://github.com/AtlassianPS/ConfluencePS/releases/latest>
  [Submit an Issue]: <https://github.com/AtlassianPS/ConfluencePS/issues/new>
  [juneb]: <https://github.com/juneb>
  [brianbunke]: <https://github.com/brianbunke>
  [Check this out]: <https://github.com/juneb/PowerShellHelpDeepDive>
  [MIT license]: <https://github.com/brianbunke/ConfluencePS/blob/master/LICENSE>

<!-- [//]: # (Sweet online markdown editor at http://dillinger.io) -->
<!-- [//]: # ("GitHub Flavored Markdown" https://help.github.com/articles/github-flavored-markdown/) -->
