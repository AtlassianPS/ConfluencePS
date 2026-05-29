# Releasing ConfluencePS

ConfluencePS follows the canonical [AtlassianPS release blueprint](https://github.com/AtlassianPS/AtlassianPS.Standards/blob/master/docs/ReleaseBlueprint.md).
Keep cross-repository release strategy in the blueprint and keep this runbook limited to ConfluencePS-specific details.

## Files to Update

| File | What to Change |
|------|----------------|
| `CHANGELOG.md` | Add a release entry matching the tag: `## vX.Y.Z - YYYY-MM-DD` |
| `ConfluencePS/ConfluencePS.psd1` | Update `ModuleVersion` to `X.Y.Z` |

## Local Preflight

```powershell
Invoke-Build -Task Build, Test
Invoke-Build -Task Build, SetVersion -VersionToPublish vX.Y.Z
```

The release metadata preflight must find a matching changelog section before a tag is pushed.

## Release Flow

1. Start from an up-to-date `master` branch.
2. Update `CHANGELOG.md` and `ConfluencePS/ConfluencePS.psd1`.
3. Run the local preflight commands above.
4. Commit the release changes.
5. Create and push an annotated `vX.Y.Z` tag.

`release.yml` validates the annotated tag, downloads the `Release` artifact from CI for the tagged commit, builds release notes from `CHANGELOG.md`, publishes to PSGallery, creates the GitHub Release from the same release-notes file, and notifies the homepage repository for stable releases.

## Version Format

Use `vX.Y.Z` tags and `## vX.Y.Z - YYYY-MM-DD` changelog headings for future releases.
Pre-release tags may use suffixes such as `vX.Y.Z-beta`.
