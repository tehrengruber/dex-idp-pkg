#!/bin/bash
#
# Bump this PKGBUILD to an upstream release.
#
#   ./update.sh [version]      # default: the latest release
#
# Upstream attaches no assets to its releases, so there is no published digest
# to take the checksum from: the source tarball (a few MB) is downloaded and
# hashed. Only the first sha256sums entry is rewritten; the others belong to
# the files in this repository.
#
set -euo pipefail

repo=dexidp/dex

here=$(cd "$(dirname "$0")" && pwd)
pkgbuild=$here/PKGBUILD

# Authenticate when a token is available. Anonymous API requests are limited to
# 60 an hour per IP, and CI runners share their IPs, so in a workflow the
# anonymous limit is usually already spent (curl: 403). Locally it works
# without one.
auth=()
if [[ -n ${GH_TOKEN:-} ]]; then
    auth=(-H "Authorization: Bearer $GH_TOKEN")
fi

version=${1:-}
if [[ -z $version ]]; then
    # Fetch first, then parse: in a pipeline a failed request only shows up as
    # a JSON traceback on empty input.
    latest=$(curl -sSf "${auth[@]}" -H 'Accept: application/vnd.github+json' \
                  "https://api.github.com/repos/$repo/releases/latest")
    version=$(printf '%s' "$latest" |
              python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')
fi

current=$(sed -n 's/^pkgver=//p' "$pkgbuild")
if [[ $current == "$version" ]]; then
    printf 'already at %s\n' "$version"
    exit 0
fi

# The same URL as source=() in the PKGBUILD.
sum=$(curl -sSfL "https://github.com/$repo/archive/refs/tags/v$version.tar.gz" |
      sha256sum | cut -d' ' -f1)

sed -i -e "s/^pkgver=.*/pkgver=$version/" \
       -e "s/^pkgrel=.*/pkgrel=1/" \
       -e "s/^sha256sums=('[0-9a-f]*'/sha256sums=('$sum'/" \
       "$pkgbuild"

printf '%s -> %s\n' "$current" "$version"
