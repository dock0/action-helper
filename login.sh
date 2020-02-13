#!/usr/bin/env bash

set -euo pipefail

docker login docker.pkg.github.com -u nobody -p "${GITHUB_TOKEN}"

