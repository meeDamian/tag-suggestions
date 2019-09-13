# meeDamian/tag-suggestions

[![main_gh_action_svg]][main_gh_action_url]
[![branches_gh_action_svg]][branches_gh_action_url]
[![gh_last_release_svg]][gh_last_release_url]
[![tippin_svg]][tippin_url]

[main_gh_action_svg]: https://github.com/meeDamian/tag-suggestions/workflows/.github/workflows/main.yml/badge.svg
[main_gh_action_url]: https://github.com/meeDamian/tag-suggestions/blob/master/.github/workflows/main.yml

[branches_gh_action_svg]: https://github.com/meeDamian/tag-suggestions/workflows/.github/workflows/on-tag.yml/badge.svg
[branches_gh_action_url]: https://github.com/meeDamian/tag-suggestions/blob/master/.github/workflows/on-tag.yml

[gh_last_release_svg]: https://img.shields.io/github/v/release/meeDamian/tag-suggestions?sort=semver
[gh_last_release_url]: https://github.com/meeDamian/tag-suggestions/releases/latest

[tippin_svg]: https://img.shields.io/badge/donate-lightning-FDD023?logo=bitcoin&style=flat
[tippin_url]: https://tippin.me/@meeDamian

Github Action to, based on git tags, generate convenience Docker tags.

#### Human language

In other words, this action suggests you what extra tags to create for Docker Hub upon new version-tag creation.  For example, given existing tags: `v1.0.0`, `v1.0.1`, `v1.1.0`, and new tag being added: `v1.0.2` this action would recommend the creation of `v1.0`, but not `:latest` (as a tag with higher version exists), nor `:v1` (as a newer tag with the same major version exists).

#### Geekspeak 

```shell script
$ INPUT_TAG="v1.0.2" \
  INPUT_CMD="echo 'v1.0.0 v1.0.1 v1.1.0' | tr ' ' '\n'" \
  ./entrypoint.sh | awk -F: '{print $NF}'
v1.0

$ INPUT_TAG="v1.1.2" \
  INPUT_CMD="echo 'v1.0.0 v1.0.1 v1.1.0' | tr ' ' '\n'" \
  ./entrypoint.sh | awk -F: '{print $NF}'
latest
v1
v1.1
``` 

> Note: `awk` above just strips required [Github notation].

[Github notation]: https://help.github.com/en/articles/development-tools-for-github-actions#set-an-output-parameter-set-output

# Usage

See [action.yml](action.yml)

### Minimal


```yaml
on:
  push:
    tags:
      - '*'
…

steps:
- uses: actions/checkout@v1
- uses: meeDamian/tag-suggestions@1.0
```

### Arguments

| name             | required   | description 
|:----------------:|:----------:|-------------
| `tag`            | sometimes  | Git tag to base suggestions on.  If not provided, an extraction from `${GITHUB_REF}` is attempted (AKA not needed on git tag push).
| `cmd`            | no         | A command listing all existing tags to take into account for tags suggestion.  By default `git tag -l` is used.


### Advanced example

```yaml
steps:
- uses: actions/checkout@master

- uses: meeDamian/tag-suggestions@0.1
  with:
    tag: v1.3.6
    cmd: "git tag -l | grep variant-one"
```

This example would be useful if your repo contains 2 variants of your software.  It seeks tag suggestions for version `v1.3.6` only among tags that are marked as `variant-one`. 

### Versioning

As of Sep 2019, Github Actions doesn't natively understand shortened tags in `uses:` directive.

To go around that and not do what `git-tag-manual` calls _"[The insane thing]"_, I'm creating permanent git tags for each release in a semver format prefixed with `v`, **as well as** maintain branches with shortened tags.  You can see the exact process [here].

Ex. `1.0` branch always points to the newest `v1.0.x` tag.

In practice:

```yaml
# For exact version
steps:
  uses: meeDamian/tag-suggestions@v1.0.1
```
Or
```yaml
# For newest minor version 1.0
steps:
  uses: meeDamian/tag-suggestions@1.0
```

Note: It's likely branches will be deprecated once Github Actions fixes its limitation.

[The insane thing]: https://git-scm.com/docs/git-tag#_on_re_tagging
[here]: .github/workflows/on-tag.yml

# License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
