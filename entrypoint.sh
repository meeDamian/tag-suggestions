#!/bin/sh -le

# This script generates convenience Docker Tag suggestions for a provided git tag.
#
# Example usage:
#
#   steps:
#   …
#   - id: tags
#     uses: meeDamian/tag-suggestions@1.0
#     with:
#       tag: 0.0.2
#
#   - name: Print all recommended versions
#     run: |
#       echo "latest: ${{ steps.tags.outputs.latest }}"
#       echo "major:  ${{ steps.tags.outputs.major }}"
#       echo "minor:  ${{ steps.tags.outputs.minor }}"
#   …

PKG="meeDamian/tag-suggestions@1.0"

# If `tag:` not provided, let's try using one available from github's context
TAG="${INPUT_TAG:-${GITHUB_REF#refs/tags/}}"

# If all ways of getting the tag failed, show error
if [ -z "$TAG" ]; then
	>&2 echo "
ERR: Invalid input: 'tag' is required, and must be specified.
	Note: It's used as a base for the suggestions.

Try:
	uses: $PKG
	with:
	  tag: v0.0.1
	  ...
"
	exit 1
fi

SEMVER_REGEX="^[vV]?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

# Verify that provided version conforms to SemVer pattern
if ! echo "$TAG" | grep -Eq "$SEMVER_REGEX"; then
	>&2 echo "
ERR: Provided tag is not valid Semver 2.0
	Note: To learn that constitutes a valid tag see: https://semver.org
"
	exit 1
fi

gh_api_url="https://api.github.com/repos/$GITHUB_REPOSITORY/git/refs/tags"
if ! tags="$(wget -qO- "$gh_api_url" )"; then
	>&2 echo "
ERR: Getting a list of tags failed
	Note: Attempted URL: $gh_api_url
"
	exit 1
fi

tags="$(echo "$tags" | jq -r '.[].ref' | sed 's|refs/tags/||')"

# Print a warning about found non-SemVer version, and list them
if non_semver="$(echo "$tags" | grep -Ev "$SEMVER_REGEX")"; then
	>&2 echo "
WARN: The following tags are ignored, for not being SemVer compliant:
	$(echo "$non_semver" | tr '\n' , | sed -e 's|,$||' -e 's|,|, |g' )
"
fi

tags="$(printf "%s\n%s\n" "$TAG" "$tags" | grep -E "$SEMVER_REGEX" | tr - \~ | sort -Vr | uniq | tr \~ -)"

# See where the provided tag ranks among ALL tags.  Suggest ":latest" if it ranks highest.
pos="$(echo "$tags" | grep -nm1 "^$TAG$")"
if [ -z "${pos%1:*}" ]; then
	echo ::set-output name=latest::latest
fi

# See where the provided tag ranks among tags with the same minor version.  Suggest ex. `:v4.2`, if ranks the highest.
minor="$(echo "$TAG" | cut -d. -f-2)"
[ "$minor" = "v0.0" ] && exit 0

pos=$(echo "$tags" | grep "^$minor" | grep -nm1 "^$TAG$")
[ -n "${pos%1:*}" ] && exit 0

echo ::set-output name=minor::"$minor"


# See where the provided tag ranks among tags with the same major version.  Suggest ex. `:v5`, if ranks the highest.
major="$(echo "$TAG" | cut -d. -f-1)"
[ "$major" = "v0" ] && exit 0

pos="$(echo "$tags" | grep "^$major" | grep -nm1 "^$TAG$")"
[ -n "${pos%1:*}" ] && exit 0

echo ::set-output name=major::"$major"
