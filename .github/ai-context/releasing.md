# Releasing ConfluencePS

ConfluencePS delegates release planning and publication to the reusable workflow in [AtlassianPS.Standards](https://github.com/AtlassianPS/AtlassianPS.Standards/blob/master/docs/ReleaseBlueprint.md).

## Current v3 rollout guard

ConfluencePS will collect the `v3.0.0` change set on `master`.
Automatic releases stay off until that version is intentionally published.

- Keep the repository variable `CONFLUENCEPS_CD_ENABLED` unset or set to `false` until the prepared v3 release commit and its CI artifact have been reviewed.
- Do not create a release tag manually.
- When the v3 release is approved, manually dispatch `Continuous Release` with `major` to prepare `v3.0.0` from the full `Unreleased` changelog.
- Let CI finish while the gate remains disabled, then review the prepared commit and its release artifact.
- Set `CONFLUENCEPS_CD_ENABLED=true` and rerun CI for the prepared release commit; the successful rerun publishes that exact artifact.
- Verify PSGallery and the GitHub release, then leave the variable enabled for normal post-merge releases.

## Release flow

Pull requests declare exactly one `release:*` label.
User-facing changes also use a `changelog:*` label or add a `.changelog/<pr>.<impact>.<type>.md` fragment.

After a releasing pull request merges, and while `CONFLUENCEPS_CD_ENABLED` is `true`:

1. CI validates the merged commit.
2. The shared workflow reconciles merged release intent and commits the next version and changelog.
3. CI builds and tests that exact release candidate on every supported platform.
4. The shared workflow tags the tested commit, publishes it to PSGallery, creates the GitHub release, and notifies the homepage repository.

For a lasting release failure, merge a reviewed fix and publish the next version.
Do not delete or recreate tags or PSGallery versions.
