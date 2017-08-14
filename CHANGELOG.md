# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.0] - 2017-08-14
A new major version! ConfluencePS has been totally refactored to introduce new features and greatly improve efficiency.

There are a ton of changes, so some big picture notes first:

- A new major version means some older functionality has been broken. Read on for details
- All commands changed from "Wiki" prefix to "Confluence", like `Get-ConfluencePage`
  - But the module accommodates for any prefix you want, e.g. `Import-Module ConfluencePS -Prefix Wiki`
- Commands changed or removed:
  - `Get-WikiLabelApplied` [removed; functionality added to `Get-ConfluencePage -Label foo`]
  - `Get-WikiPageLabel` > `Get-ConfluenceLabel`
  - `New-WikiLabel` > `Add-ConfluenceLabel`
- `-ApiUri` and `-Credential` parameters added to every function
  - This is useful if you have more than one Confluence instance
  - `Set-ConfluenceInfo` now defines `ApiUri` and `Credential` defaults for the current session
  - And you can override any single command:
  - `Get-ConfluenceSpace -ApiUri 'https://wiki2.example.com' -Credential (Get-Credential)`
- All commands now output custom object types, like `[ConfluencePS.Page]`
  - Allows for returning more object properties...
  - ...and only displaying the most relevant in the default output
  - Also enables a much improved pipeline flow
- Private functions are leveraged heavily to reduce repeat code
  - `Invoke-Method` is the most prominent example
- `Get-*` commands now support paging, and defining your preferred page size

If you like drinking from the firehose, here's [everything we closed for 2.0], because we probably forgot to list something here. Otherwise, read on for summarized details.

### Added
- [#19][issue-19]: `-ApiUri` and `-Credential` parameters added to every function
  - `Set-ConfluenceInfo` behavior is unchanged

### Changed
- 

### Fixed
- 

### Removed
- 

### Much ❤
[@lipkau](https://github.com/lipkau) is amazing!


## [1.0.0-69] - 2016-11-28
No changelog available for version `1.0` of ConfluencePS. `1.0` was created in late 2015, and version `.69` published to the PowerShell Gallery in Nov 2016. If you're looking for things that changed prior to `2.0`...sorry, but these probably aren't the droids you're looking for. :)



[everything we closed for 2.0]: https://github.com/AtlassianPS/ConfluencePS/issues?utf8=%E2%9C%93&q=closed%3A2017-04-01..2017-08-14

[issue-19]: https://github.com/AtlassianPS/ConfluencePS/issues/19
