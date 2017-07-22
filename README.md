[![Build status](https://ci.appveyor.com/api/projects/status/jcyw4oxnpqp3djtn?svg=true)](https://ci.appveyor.com/project/brianbunke/confluenceps)

# ConfluencePS
A PowerShell module that interacts with Atlassian's [Confluence] wiki product.

Need to add 100 new pages based on some dumb CSV file? Are you trying to figure out how to delete all pages labeled 'deleteme'? Are you sick of manually editing the same page every single day? PowerShell and ConfluencePS have you covered!

ConfluencePS communicates with Atlassian's actively supported [REST API] via basic authentication. The REST implementation is the only way to interact with their cloud-hosted instances via API, and will eventually be the only way to interact with an on-premises installation.

## Instructions
Install ConfluencePS from the [PowerShell Gallery]! `Install-Module` requires PowerShellGet (included in PS v5, or download for v3/v4 via the gallery link)

```posh
# One time only install:
Install-Module ConfluencePS

# Check for updates occasionally:
Update-Module ConfluencePS

# To use each session:
Import-Module ConfluencePS
Set-ConfluenceInfo -BaseURI 'https://YourCloudWiki.atlassian.net/wiki'

# Review the help at any time!
Get-Help about_ConfluencePS
Get-Command -Module ConfluencePS
Get-Help Get-ConfluencePage -Full   # or any other command
```

## Potential Future Work
I can provide no timeframe for future improvements, but I'm trying to keep track of my roadmap publicly in case other interested parties have feedback.

1. Implement unit tests for existing commands
    1. Better quality control & more rapid feedback
    2. Hopefully encourage additional contributions from others
2. Investigate other authentication options
    1. Currently, Confluence's documentation is pretty bad here
3. Custom typing of page/space/etc. objects
	1. Allows for some custom formatting to show just the important properties of returned objects
	2. Which would allow for keeping a lot more properties from an -Expand operation
4. Introduce new commands

Honestly, the module meets my needs at this point, and my motivation is low to introduce additional functionality I won't use. HOWEVER! Time permitting, I am more than happy to investigate new work if an issue is filed demonstrating a need.

Feel free to speak up if the module could be more helpful to you!

## Acknowledgments
Many thanks to [thomykay] for his [PoshConfluence] SOAP API module, which gave me enough of a starting point to feel comfortable undertaking this project.

I ~~stole~~ repurposed much of [RamblingCookieMonster]'s example module, [PSStackExchange], which was a huge help in standing up my first full module correctly. My efforts to implement a continuous deployment pipeline to the PowerShell Gallery were also sped up due to his prior work.

[juneb] has a wealth of information on the right way to supply module help. [Check this out] for starters.

## Disclaimer
Hopefully this is obvious, but:

This is an open source project (under the [MIT license]). I am a volunteer, as are any other contributors. All commands are executed at your own risk. Please have good backups before you start, because you can delete a lot of stuff if you're not careful.

  [Confluence]: <https://www.atlassian.com/software/confluence>
  [REST API]: <https://docs.atlassian.com/atlassian-/REST/latest/>
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
