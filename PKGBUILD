# Maintainer: Till Ehrengruber <till@ehrengruber.ch>
#
# Dex, the OpenID Connect identity provider, built from the upstream release.
#
# Vendored rather than taken from the AUR. The AUR carries dex-idp, which was
# four minor releases behind upstream when this was written, with two votes and
# each release pinned by commit hash.
# Packaging it here costs a pkgver and a checksum per release (see ./update.sh).
#
# Upstream publishes container images only, no binaries, so this builds from
# the source tarball. The web assets (templates, themes) are embedded in the
# binary, so nothing beyond it needs to be installed.
#
# Ships a unit, but no live config: what dex should use for storage, which
# connectors and which clients are specific to wherever it runs. The upstream
# example goes to /usr/share/doc/dex-idp/ to start from.

pkgname=dex-idp
pkgver=2.46.1
pkgrel=1
pkgdesc="OpenID Connect identity (OIDC) and OAuth 2.0 provider with pluggable connectors"
arch=('x86_64' 'aarch64')
url="https://dexidp.io/"
license=('Apache-2.0')
# cgo, for the sqlite3 storage backend.
depends=('glibc')
makedepends=('go')
# extra/dex (the desktop entry executor) also installs /usr/bin/dex.
conflicts=('dex')
source=("dex-${pkgver}.tar.gz::https://github.com/dexidp/dex/archive/refs/tags/v${pkgver}.tar.gz"
        'dex.service'
        'dex.sysusers'
        'dex.tmpfiles')
sha256sums=('05e2e149b53f9876269362fefa9061b4b1abd3d5437f23247d79e44a77ac487d'
            'fa1b169c85c42564c9a8cae58824303c06f52a5b662f82675ff99aa020176f95'
            '776fbaabb3baaad59b3f1ff8be3f8300fe669b259e78b55165c4ccfee7acd656'
            'cfc94af824bd2fef45f5e6dbe7c52d4a5e534c782649d3b02fb5d51e09de8c7f')

build() {
  cd "dex-${pkgver}"
  # The Go package guidelines: https://wiki.archlinux.org/title/Go_package_guidelines
  export CGO_CPPFLAGS="${CPPFLAGS}"
  export CGO_CFLAGS="${CFLAGS}"
  export CGO_CXXFLAGS="${CXXFLAGS}"
  export CGO_LDFLAGS="${LDFLAGS}"
  export GOFLAGS="-buildmode=pie -trimpath -mod=readonly -modcacherw"
  # Upstream's Makefile takes the version from git, which a tarball lacks.
  go build -o dex \
    -ldflags "-linkmode=external -X main.version=v${pkgver}" \
    ./cmd/dex
}

package() {
  cd "dex-${pkgver}"
  install -Dm755 dex "${pkgdir}/usr/bin/dex"
  install -Dm644 config.yaml.dist "${pkgdir}/usr/share/doc/${pkgname}/config.yaml.dist"
  install -Dm644 "${srcdir}/dex.service" "${pkgdir}/usr/lib/systemd/system/dex.service"
  install -Dm644 "${srcdir}/dex.sysusers" "${pkgdir}/usr/lib/sysusers.d/dex.conf"
  install -Dm644 "${srcdir}/dex.tmpfiles" "${pkgdir}/usr/lib/tmpfiles.d/dex.conf"
}
