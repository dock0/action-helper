#!/usr/bin/env bash

set -euo pipefail

date="$(date +%Y%m%d)"
full_sha="$(git rev-parse HEAD)"
sha="${full_sha::7}"

tags="${date}-${sha}"

version_regex="^refs/tags/(v[0-9]+)\\.([0-9]+)\\.([0-9]+)$"
if [[ "$GITHUB_REF" =~ $version_regex ]] ; then
    version_tags="$(echo "${GITHUB_REF}" | sed -r "s|${version_regex}|\\1.\\2.\\3 \\1.\\2 \\1|")"
    tags="${tags} ${version_tags}"
fi

if [[ "$GITHUB_REF" =~ ^refs/heads/main$ ]] ; then
    tags="latest ${tags}"
fi

echo "${tags}"
