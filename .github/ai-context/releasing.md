# Releasing ConfluencePS

ConfluencePS releases are tag-driven from `master`.

## Steps

1. Ensure CI is green on `master`.
2. Update `CHANGELOG.md`.
3. Update `ConfluencePS/ConfluencePS.psd1` version metadata if needed.
4. Push an annotated tag:

```bash
git checkout master
git pull --ff-only origin master
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin master --tags
```

The `release.yml` workflow then:
- Downloads the `Release` artifact from a successful `ci.yml` run for the tagged commit.
- Publishes to PowerShell Gallery.
- Creates a GitHub release.
