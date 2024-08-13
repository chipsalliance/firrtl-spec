Guide for Contributors
======================

Writing
-------

-   One sentence per line.
    No linewraps.
-   Inline FIRRTL code snippets should be tagged as FIRRTL code with `{.firrtl}`.
    -   This isn't recognized by GitHub, but is used for the PDF generation.
-   Match terminology and capitalization preferences used elsewhere by default.
-   Don't forget to spell-check!

Code Blocks
-----------

Code blocks containing FIRRTL, Verilog, or SystemVerilog are, by default, extracted to separate files in the build area and passed through `firtool` or `verilator` to check that they are correct.
You can run this manually with `make test`.

Sometimes, you may want to prune the code block in the generated specification `.pdf`.
You can do this by inserting special keywords in the code block:

-   `snippetbegin` starts a snippet
-   `snippetend` ends a snippet

If a code block has more than one snippet, then each snippet is appended in the output `.pdf`.

You may prevent a code block from being checked by adding a second class with name `notest` to the code block.
E.g., put the following on a FIRRTL code block to cause it to not be tested: `{.firrtl .notest}`.

Pushing Changes
---------------

1.  Read the [Versioning Scheme of this
    Document](https://github.com/chipsalliance/firrtl-spec/blob/main/spec.md#versioning-scheme-of-this-document).

2.  All commit messages have a leading tag indicating how they modify the.
    If you forget to add this to your commit, it can be added to the PR title.
    The PR title should then be used in a squash-and-merge GitHub merge strategy.
    The available tags are:

    -   `[nfc]` -- a "non-functional change" to the spec or to something outside
        the spec should not modify the current spec version
    -   `[patch]` -- a change to the spec that should increment the patch version
    -   `[minor]` -- a change to the spec that should increment the minor version
    -   `[major]` -- a change to the spec that should increment the major version the spec.

3.  PRs or commits that are `[patch]`, `[minor]`, or `[major]` should add an item to [`revision-history.yaml`](revision-history.yaml) under the `thisVersion`key.
    `[nfc]` PRs or commits do not modify this section.

Releases
--------

New releases are made automatically through GitHub actions.
To make a new release, create a new tag using `git tag -s` if you have local GPG keys.
Otherwise, create a new tag using `git tag -a`. The tag should indicate the *new* version of the spec and be of the form: `v.$major.$minor.$patch`.
Push the new tag to GitHub and CI will create the release.

After creating the release and pushing the tag, modify `revision-history.yaml` by creating a new object in the `oldVersions` array with the new version number.
Move all items under `thisVersion` to the new version object.
