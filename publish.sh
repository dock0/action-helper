#!/usr/bin/env bash

set -euo pipefail

curdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
PATH="${curdir}:${PATH}"

for tag in $(get_tags.sh) ; do
    full_name="ghcr.io/${GITHUB_REPOSITORY}:${tag}"
    echo "Tagging ${full_name}"
    docker tag new "${full_name}"
    docker push "${full_name}"
done
