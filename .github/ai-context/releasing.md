# Releasing ConfluencePS

ConfluencePS delegates release planning and publication to the reusable workflow in [AtlassianPS.Standards](https://github.com/AtlassianPS/AtlassianPS.Standards/blob/master/docs/ReleaseBlueprint.md).

Pull requests declare exactly one `release:*` label.
User-facing changes also use a `changelog:*` label or add a `.changelog/<pr>.<impact>.<type>.md` fragment.

After a releasing pull request merges:

1. CI validates the merged commit.
2. The shared workflow reconciles merged release intent and commits the next version and changelog.
3. CI builds and tests that exact release candidate on every supported platform.
4. The shared workflow tags the tested commit, publishes it to PSGallery, creates the GitHub release, and notifies the homepage repository.

For a lasting release failure, merge a reviewed fix and publish the next version.
Do not delete or recreate tags or PSGallery versions.
