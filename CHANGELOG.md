# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.0] - 2017-08-14
A new major version! ConfluencePS has been totally refactored to introduce new features and greatly improve efficiency.

"A new major version" means limited older functionality was intentionally broken. In addition, there are a ton of good changes, so some big picture notes first:

- All functions changed from "Wiki" prefix to "Confluence", like `Get-ConfluencePage`
  - But the module accommodates for any prefix you want, e.g. `Import-Module ConfluencePS -Prefix Wiki`
- Functions changed or removed:
  - `Get-WikiLabelApplied` [removed; functionality added to `Get-ConfluencePage -Label foo`]
  - `Get-WikiPageLabel` > `Get-ConfluenceLabel`
  - `New-WikiLabel` > `Add-ConfluenceLabel`
- `Get-*` functions now support paging, and defining your preferred page size
- `-Limit` parameters were removed from functions
  - With paging implementation, modifying the returned object limit isn't necessary
- `-ApiUri` and `-Credential` parameters added to every function
  - This is useful if you have more than one Confluence instance
  - `Set-ConfluenceInfo` now defines `ApiUri` and `Credential` defaults for the current session
  - And you can override any single function:
  - `Get-ConfluenceSpace -ApiUri 'https://wiki2.example.com' -Credential (Get-Credential)`
- All functions now output custom object types, like `[ConfluencePS.Page]`
  - Allows for returning more object properties...
  - ...and only displaying the most relevant in the default output
  - Also enables a much improved pipeline flow
  - This behavior removed the need for the `-Expand` parameter
- Private functions are leveraged heavily to reduce repeat code
  - `Invoke-Method` is the most prominent example

If you like drinking from the firehose, here's [everything we closed for 2.0], because we probably forgot to list something here. Otherwise, read on for summarized details.

### Added
- `Get-*` functions now support paging
- `-ApiUri` and `-Credential` parameters added to functions
  - `Set-ConfluenceInfo` behavior is unchanged
- Objects returned are now custom typed, like `[ConfluencePS.Page]`


### Changed
- Function prefix defaults to "Confluence" instead of "Wiki" (`Get-ConfluenceSpace`)
  - If you like "Wiki", you can `Import-Module ConfluencePS -Prefix Wiki`
- `Add-ConfluenceLabel`
- `Get-ConfluenceChildPage`
  - Default behavior returns only immediate child pages. Which also means...
  - Added `-Recurse` to return all pages below the given page, not just immediate child objects
  - `-ParentID` > `-PageID`
- `Get-ConfluenceLabel`
  - Name used to be `Get-WikiPageLabel`
- `Get-ConfluencePage`
- `Get-ConfluenceSpace`
- `New-ConfluencePage`
- `New-ConfluenceSpace`
- `Remove-ConfluenceLabel`
- `Remove-ConfluencePage`
- `Remove-ConfluenceSpace`
- `Set-ConfluenceInfo`
- `Set-ConfluencePage`

### Fixed
- 

### Removed
- `-Limit` and `-Expand` parameters
  - `Get-*` function paging removes the need for fiddling with returned object limits
  - Custom object types hold relevant properties, removing the need to manually "expand" results
- `Get-WikiLabelApplied`
  - Functionality replaced with `Get-ConfluencePage -Label foo`

### Much ❤
[@lipkau](https://github.com/lipkau) refactored the entire module, and is the only reason `2.0` is a reality. In short, he is amazing. Thanks, @lipkau!


## [1.0.0-69] - 2016-11-28
No changelog available for version `1.0` of ConfluencePS. `1.0` was created in late 2015. Version `.69` was published to the PowerShell Gallery in Nov 2016, and it remained unchanged until `2.0`. If you're looking for things that changed prior to `2.0`...sorry, but these probably aren't the droids you're looking for. :)



[everything we closed for 2.0]: https://github.com/AtlassianPS/ConfluencePS/issues?utf8=%E2%9C%93&q=closed%3A2017-04-01..2017-08-14
