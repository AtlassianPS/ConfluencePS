### Description

<!-- Describe the change and why it is needed. -->

### Release intent

<!-- Maintainers apply exactly one release label: release:none, release:patch, release:minor, or release:major. -->
<!-- A releasing PR also needs one changelog:* label or one .changelog/<pr>.<impact>.<type>.md fragment. -->

- [ ] This change needs no independent package release (`release:none`).
- [ ] This change needs a patch, minor, or major release and includes release-note intent.

### Validation

- [ ] I ran the relevant focused tests.
- [ ] I ran `Invoke-Build -Task Build, Test`, or explained why it was not applicable.
- [ ] I updated user documentation for user-visible behavior.
- [ ] I checked both Cloud and Data Center behavior when API behavior changed.
