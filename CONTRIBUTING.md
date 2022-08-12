# Guide for Contributors

## Pushing Changes

1. Read the [Versioning Scheme of this Document](https://github.com/chipsalliance/firrtl-spec/blob/main/spec.md#versioning-scheme-of-this-document)
3. All commit messages have a `[nfc]|[patch]|[minor]|[major]` leading tag.
This can be added after-the-fact to the PR title as this will be re-used for a squash-and-merge flow.
3. PRs/commits that are [patch|minor|major] need to update the `revisionHistory`
section (`thisVersion`) of the YAML header. [nfc] PRs/commits do not.

## Releases

New releases are made automatically through GitHub actions by pushing a version tag to the repo.
After a new version is pushed please move the `thisVersion` section into the main `revisionHistory` section.
