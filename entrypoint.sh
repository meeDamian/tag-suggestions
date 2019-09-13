#!/bin/sh -le

# This script generates convenience Docker Tag suggestions for a provided git tag.
#
# Example usage:
#
#   steps:
#   …
#   - id: tags
#     uses: meeDamian/tag-suggestions@master
#     with:
#       tag: 0.0.2
#
#   - name: Print all recommended versions
#     run: >
#       echo "latest: ${{ steps.tags.outputs.latest }}"
#       echo "major:  ${{ steps.tags.outputs.major }}"
#       echo "minor:  ${{ steps.tags.outputs.minor }}"
#   …
#
# `tag:` is SemVer-compliant git tag, which then gets compared against already existing tags (see <alt-command>).
#   The result is a list of recommended Docker tags to be created, or overriden upon release. For example:
#
#     Given already existing git tags:  v0.0.1  v1.0.1  v1.0.2  v1.1.0
#         Running:  `./shortcut-tags.sh `v1.1.1`  only yield the following result:   latest  v1  v1.1
#         As the tag being created was the highest(/latest) available.
#
#     Given the same starting git tags: v0.0.1  v1.0.1  v1.0.2  v1.1.0  v1.1.1
#         Running:  `./shortcut-tags.sh v1.0.3`  only recommends:  v1.0
#         As anything else would either created a downgrade, or confused the user.
#
# <alt-command> is an optional path to a new-line separated tags to be compared against. If not provided `git tag` is used.

TAG="${INPUT_TAG}"

# If `tag:` not provided, let's try using one available from github's context
if [ -z "${TAG}" ]; then
  TAG="$(echo "${GITHUB_REF}" | awk -F/ '{print $NF}')"
fi

# If all ways of getting the tag failed, show error
if [ -z "${TAG}" ]; then
  >&2 printf "\nERR: Invalid input: 'tag' is required, and must be specified.\n"
  >&2 printf "\tNote: It's used as a base for the suggestions.\n\n"
  >&2 printf "Try:\n"
  >&2 printf "\tuses: meeDamian/tag-suggestions@1.0\n"
  >&2 printf "\twith:\n"
  >&2 printf "\t  tag: v0.0.1\n"
  >&2 printf "\t  ...\n"
  exit 1
fi

# A command to get a list of currently existing tags.  Default, defined in `action.yml`, is `git tag -l`.
CMD="${INPUT_CMD}"

SEMVER_REGEX="^[vV]?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

# Verify that provided version conforms to SemVer pattern
if ! echo "${TAG}" | grep -Eq "${SEMVER_REGEX}"; then
  >&2 printf "\nERR: Provided tag is not a valid Semver 2.0\n"
  >&2 printf "\tNote: To learn that constitues a valid tag see: https://semver.org\n"
  exit 1
fi

# Print a warning about found non-SemVer version, and list them
NON_SEMVER="$(eval "${CMD}" | grep -Ev "${SEMVER_REGEX}" || true)"
if [ -n "${NON_SEMVER}" ]; then
  >&2 printf "\n\tWARNING: The following tags are ignored, for not being SemVer compilant:\n"
  >&2 printf "\n%s\n\n" "$(echo "${NON_SEMVER}" | head -c -1 | tr '\n' ' ' | sed 's/ /, /g')"
fi

# make sure tag is on the list of tags
LIST=$(printf "%s\n%s\n" "$(eval "${CMD}")" "${TAG}" | sort | uniq)

# Return a list of semver-compliant tags in newest-first order.
sorted_tags() {
  echo "${LIST}" | grep -E "${SEMVER_REGEX}" | tr - \~ | sort -Vr | tr \~ -
}

# See where the provided tag ranks among ALL tags.  Suggest ":latest" if it ranks highest.
NUMBER_IN_TOTAL_ORDER=$(sorted_tags | grep -nm1 "^${TAG}$" | cut -d: -f1)
if [ "${NUMBER_IN_TOTAL_ORDER}" -eq "1" ]; then
  echo ::set-output name=latest::latest
fi

# See where the provided tag ranks among tags with the same MAJOR version.  Suggest ex. `:v5`, if ranks the highest.
MAJOR="$(echo "${TAG}" | cut -d. -f-1)"
NUMBER_IN_MAJOR_ORDER=$(sorted_tags | grep "^${MAJOR}" | grep -nm1 "^${TAG}$" | cut -d: -f1)
if [ "${NUMBER_IN_MAJOR_ORDER}" -eq "1" ]; then
  echo ::set-output name=major::"${MAJOR}"
fi

# See where the provided tag ranks among tags with the same MINOR version.  Suggest ex. `:v4.2`, if ranks the highest.
MINOR="$(echo "${TAG}" | cut -d. -f-2)"
NUMBER_IN_MINOR_ORDER=$(sorted_tags | grep "^${MINOR}" | grep -nm1 "^${TAG}$" | cut -d: -f1)
if [ "${NUMBER_IN_MINOR_ORDER}" -eq "1" ]; then
  echo ::set-output name=minor::"${MINOR}"
fi
