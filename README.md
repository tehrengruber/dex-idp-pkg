# dex-idp-pkg

Arch Linux package for [Dex](https://dexidp.io/), the OpenID Connect identity
provider with pluggable connectors, built from the upstream release.

## Why this exists

The AUR package, `dex-idp`, was four minor releases behind upstream when this
was written, with two votes. A package that has stopped tracking upstream looks
exactly like one that has not, which is the awkward part — and for an identity
provider, falling behind on releases is the wrong failure to have.

Upstream publishes container images but no binaries, so this builds from the
source tarball. Packaging it costs a `pkgver` and a checksum per release. This
repository automates that and keeps itself current.

## Contents

    /usr/bin/dex
    /usr/lib/systemd/system/dex.service
    /usr/lib/sysusers.d/dex.conf
    /usr/lib/tmpfiles.d/dex.conf
    /usr/share/doc/dex-idp/config.yaml.dist

The web templates and themes are embedded in the binary. `extra/dex` (the
desktop entry executor) also installs `/usr/bin/dex`, so the two conflict.

The unit runs `dex serve /etc/dex/config.yaml` as the `dex` user, but no config
is shipped: storage, connectors and clients are specific to wherever it runs.
Start from the upstream example:

    sudo install -m640 -g dex /usr/share/doc/dex-idp/config.yaml.dist /etc/dex/config.yaml

`/etc/dex` is `root:dex 0750`, since the config holds client secrets and
connector credentials. `/var/lib/dex` is the unit's state directory, the place
for the sqlite3 backend (`file: /var/lib/dex/dex.db`); the example config uses
the in-memory store, which forgets everything on restart.

## Updating

    ./update.sh            # latest upstream release
    ./update.sh 2.45.0     # a specific one

`update.sh` rewrites `pkgver`, `pkgrel` and the source checksum. Upstream
attaches no assets to its releases, so there is no published digest to use: the
source tarball is downloaded and hashed. It exits without touching anything if
the version already matches.

This runs on its own: a scheduled workflow checks for a new upstream release
every day and opens a pull request with the bump, skipping it if a pull request
already proposes that version. The package is built in an Arch container, for
both x86_64 and aarch64, as a check on that pull request, and the pull request
merges once the check is green. Both workflows are thin callers of the reusable
ones in
[arch-pre-built-packages](https://github.com/tehrengruber/arch-pre-built-packages),
which need an `UPDATE_PAT` secret, auto-merge enabled, and `main` protected by
the `build / build` check.

Building — rather than bumping the checksum alone — is the part that matters.
Dex tracks new Go releases closely (its `go.mod` asks for the current one), so
a release can require a Go that Arch does not ship yet; that would otherwise
turn up when building on the host instead of here. The merged pull request stays
as the record of what changed, and the thing to revert if a release turns out
to break something.
