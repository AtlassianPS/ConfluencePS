# ConfluencePS
A PowerShell module that interacts with Atlassian's [Confluence] wiki product.

ConfluencePS communicates with Atlassian's actively supported [REST API] via basic authentication. This is the only way to interact with their cloud-hosted instances via API, and will eventually be the only way to interact with an on-premises installation.

## Instructions
* "Download ZIP" near the top-right of this page
* If necessary, unblock the zip
* Extract the ConfluencePS folder to a module path
  * For example, $env:USERPROFILE\Documents\WindowsPowerShell\Modules\

**NOTE:** The top-level ConfluencePS folder (that contains readme.md) is just for GitHub presentation. You'll want to keep the ConfluencePS child folder, discarding the top level.

```posh
# Import the module
    Import-Module ConfluencePS
	# Alternatively,
    Import-Module C:\ConfluencePS
	# or
    Import-Module \\server\share\ConfluencePS

# Get commands in the module
    Get-Command -Module ConfluencePS

# Get help
    Get-Help Set-WikiInfo -Full
	
# Set your instance's info, so PowerShell knows where to send requests
# Local installs may be 'http://wiki.mydomain.com', for example, but Atlassian cloud installs need the /wiki subdirectory
	Set-WikiInfo -BaseURI 'https://brianbunke.atlassian.net/wiki'
# You will then be prompted for your Confluence credentials
```

## Examples
Not yet included here while the module is still in constant development. In the interim, you can always:
```posh
Get-Help New-WikiLabel -Examples
```

## Acknowledgments
Many thanks to thomykay for his [PoshConfluence] SOAP API module, which gave me enough of a starting point to feel comfortable undertaking this project.

I ~~stole~~ repurposed much of RamblingCookieMonster's example module, [PSStackExchange], which was a huge help in standing up everything correctly.

  [Confluence]: <https://www.atlassian.com/software/confluence>
  [REST API]: <https://docs.atlassian.com/atlassian-confluence/REST/latest/>
  [PoshConfluence]: <https://github.com/thomykay/PoshConfluence>
  [PSStackExchange]: <https://github.com/RamblingCookieMonster/PSStackExchange>

[//]: # (Sweet online markdown editor at http://dillinger.io)
[//]: # ("GitHub Flavored Markdown" https://help.github.com/articles/github-flavored-markdown/)