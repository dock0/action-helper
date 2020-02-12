#!/usr/bin/env bash

set -euo pipefail

curdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
PATH="${curdir}:${PATH}"

login.sh

image="${GITHUB_REPOSITORY#*/}"

for tag in $(get_tags.sh) ; do
    full_name="docker.pkg.github.com/${GITHUB_REPOSITORY}/${image}:${tag}"
    echo "Tagging ${full_name}"
    docker tag new "${full_name}"
    docker push "${full_name}"
done
