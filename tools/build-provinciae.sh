#!/bin/bash
# Build the "provinciae": software Ubuntu 26.04 doesn't carry, as .debs.
#
#   sudo tools/build-provinciae.sh
#
# wlroots 0.20, SceneFX 0.5 and MangoWC come from upstream git tags with our
# packaging in provinciae/<name>/debian; Quickshell is Ubuntu's own source
# package from the next release, rebuilt for 26.04; Discover (the engine under
# Forum) is Ubuntu's own, rebuilt with provinciae/plasma-discover's patch and
# without its web view or snap backend. Everything builds in a
# clean 26.04 chroot (build/pkg/chroot). Results go to out/provinciae/; a
# package whose .deb is already there is skipped, so nothing is rebuilt twice.

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
MIRROR="${ARMATOS_MIRROR:-http://archive.ubuntu.com/ubuntu}"
CHROOT="$ROOT/build/pkg/chroot"
SRC="$ROOT/build/src"
OUT="$ROOT/out/provinciae"
ORDER=(wlroots-0.20 scenefx-0.5 mangowm)
QS_SUITE=stonking

say() { printf '\e[38;5;178m== %s\e[0m\n' "$*"; }
die() { printf '\e[38;5;124mbuild-provinciae: %s\e[0m\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || die "run with sudo: sudo tools/build-provinciae.sh"
for t in debootstrap git; do command -v "$t" >/dev/null || apt-get install -y "$t"; done
[ -e /usr/share/debootstrap/scripts/resolute ] || ln -s gutsy /usr/share/debootstrap/scripts/resolute

unmount() {
	local m
	for m in dev/pts dev sys proc; do mountpoint -q "$CHROOT/$m" 2>/dev/null && umount -l "$CHROOT/$m"; done
	return 0
}
trap unmount EXIT
mkdir -p "$SRC" "$OUT" "$ROOT/build/cache/debootstrap"

if [ ! -x "$CHROOT/usr/bin/dpkg-buildpackage" ]; then
	say "Setting up the build camp (a clean Ubuntu 26.04 chroot)"
	rm -rf "$CHROOT"
	debootstrap --arch=amd64 --variant=buildd --cache-dir="$ROOT/build/cache/debootstrap" \
		--components=main,restricted,universe,multiverse resolute "$CHROOT" "$MIRROR"
fi
cat > "$CHROOT/etc/apt/sources.list.d/ubuntu.sources" <<SOURCES
Types: deb deb-src
URIs: $MIRROR
Suites: resolute resolute-updates resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb-src
URIs: $MIRROR
Suites: $QS_SUITE
Components: universe
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
SOURCES
rm -f "$CHROOT/etc/apt/sources.list" "$CHROOT/etc/resolv.conf"
cp -L /etc/resolv.conf "$CHROOT/etc/resolv.conf"
for m in proc sys dev dev/pts; do mount --bind "/$m" "$CHROOT/$m"; done
in_chroot() { chroot "$CHROOT" /usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8 "$@"; }
in_chroot apt-get update -qq
in_chroot apt-get install -y -qq --no-install-recommends build-essential devscripts \
	debhelper fakeroot meson ninja-build pkgconf git ca-certificates >/dev/null

# Install what we've already built, so later packages can build against it.
install_built() {
	local debs=("$OUT"/*.deb)
	[ -e "${debs[0]}" ] || return 0
	rm -rf "$CHROOT/tmp/prov" && mkdir -p "$CHROOT/tmp/prov"
	cp "$OUT"/*.deb "$CHROOT/tmp/prov/"
	in_chroot sh -c 'apt-get install -y -qq /tmp/prov/*-dev_*.deb /tmp/prov/lib*.deb >/dev/null 2>&1 || apt-get install -y -qq -f >/dev/null'
}

build_tree() {   # build_tree <dir inside chroot>
	in_chroot sh -c "cd '$1' && apt-get build-dep -y -qq --no-install-recommends ./ >/dev/null && dpkg-buildpackage -b -uc -us"
	cp "$CHROOT$(dirname "$1")"/*.deb "$OUT/"
	rm -f "$CHROOT$(dirname "$1")"/*.deb "$CHROOT$(dirname "$1")"/*.buildinfo "$CHROOT$(dirname "$1")"/*.changes
}

for p in "${ORDER[@]}"; do
	# shellcheck disable=SC1090
	. "provinciae/$p/source"
	ver=$(sed -n '1s/.*(\(.*\)).*/\1/p' "provinciae/$p/debian/changelog")
	if compgen -G "$OUT/*_${ver}_*.deb" >/dev/null; then say "$p $ver: already built"; install_built; continue; fi
	say "Building $p $ver from $GIT ($TAG)"
	[ -d "$SRC/$p-$TAG" ] || git -c advice.detachedHead=false clone -q --depth 1 --branch "$TAG" "$GIT" "$SRC/$p-$TAG"
	install_built
	rm -rf "$CHROOT/build/$p" && mkdir -p "$CHROOT/build/$p/src"
	git -C "$SRC/$p-$TAG" archive HEAD | tar -x -C "$CHROOT/build/$p/src/"
	cp -r "provinciae/$p/debian" "$CHROOT/build/$p/src/debian"
	build_tree "/build/$p/src"
done
install_built

say "Quickshell (Ubuntu's $QS_SUITE source, rebuilt for 26.04)"
if compgen -G "$OUT/quickshell_*armatos*_amd64.deb" >/dev/null; then
	say "quickshell: already built"
else
	rm -rf "$CHROOT/build/quickshell" && mkdir -p "$CHROOT/build/quickshell"
	in_chroot sh -c "cd /build/quickshell && apt-get source -qq quickshell/$QS_SUITE >/dev/null"
	dir=$(find "$CHROOT/build/quickshell" -mindepth 1 -maxdepth 1 -type d -name 'quickshell-*' | head -n 1)
	[ -n "$dir" ] || die "couldn't fetch the quickshell source package"
	# Armatos changes: no crash reporter (its cpptrace library isn't in 26.04)
	# and no Hyprland integration (Armatos runs MangoWC).
	sed -i '/libcpptrace-dev,/d' "$dir/debian/control"
	sed -i 's/-DDISTRIBUTOR="Debian"/-DDISTRIBUTOR="Armatos" -DCRASH_HANDLER=OFF -DHYPRLAND=OFF/' "$dir/debian/rules"
	grep -q CRASH_HANDLER=OFF "$dir/debian/rules" || die "couldn't adjust quickshell's debian/rules"
	in_chroot sh -c "cd /build/quickshell/$(basename "$dir") && DEBFULLNAME=Armatos DEBEMAIL=factionparadox@users.noreply.github.com dch --local '~armatos' --distribution resolute --force-distribution 'Rebuilt for Armatos (Ubuntu 26.04): no crash reporter, no Hyprland integration.'"
	build_tree "/build/quickshell/$(basename "$dir")"
fi

say "Discover, the engine under Forum (Ubuntu's own source, rebuilt)"
if compgen -G "$OUT/plasma-discover_*armatos*_amd64.deb" >/dev/null; then
	say "plasma-discover: already built"
else
	rm -rf "$CHROOT/build/discover" && mkdir -p "$CHROOT/build/discover"
	in_chroot sh -c "cd /build/discover && apt-get source -qq plasma-discover/resolute-updates >/dev/null"
	dir=$(find "$CHROOT/build/discover" -mindepth 1 -maxdepth 1 -type d -name 'plasma-discover-*' | head -n 1)
	[ -n "$dir" ] || die "couldn't fetch the plasma-discover source package"
	d="$dir/debian"
	# Armatos changes: no web view (it drags in QtWebEngine, which is
	# Chromium), no snap backend (Lex II), no KDE telemetry, none of the
	# Kirigami QML (Forum brings its own face), and the patch that loads
	# Forum's window in place of Discover's.
	sed -i -e '/qt6-webview-dev/d' -e '/libsnapd-qt-dev/d' -e '/libkf6userfeedback-dev/d' \
		-e '/dh-sequence-qmldeps/d' -e '/^ *\${qml6:Depends},$/d' \
		-e '/^ *plasma-discover-backend-snap,$/d' -e 's/^\( *\)software-properties-qt,$/\1armatos-forum,/' "$d/control"
	awk 'BEGIN { RS = ""; ORS = "\n\n" } !/^Package: plasma-discover-backend-snap\n/' "$d/control" > "$d/control.new"
	mv "$d/control.new" "$d/control"
	rm -f "$d"/plasma-discover-backend-snap.* "$d"/plasma-discover.qmlfiles "$d"/qmldeps.*
	echo usr/share/applications/org.kde.discover.snap.desktop >> "$d/not-installed"
	grep -q 'backend-snap\|qml6:Depends\|webview' "$d/control" && die "couldn't adjust plasma-discover's debian/control"
	printf '\noverride_dh_auto_configure:\n\tdh_auto_configure -- %s\n' \
		'-DBUILD_SnapBackend=OFF -DCMAKE_DISABLE_FIND_PACKAGE_Qt6WebView=ON -DCMAKE_DISABLE_FIND_PACKAGE_KF6UserFeedback=ON' >> "$d/rules"
	cp provinciae/plasma-discover/armatos-forum-window.patch "$d/patches/"
	echo armatos-forum-window.patch >> "$d/patches/series"
	in_chroot sh -c "cd /build/discover/$(basename "$dir") && DEBFULLNAME=Armatos DEBEMAIL=factionparadox@users.noreply.github.com dch --local '+armatos' --distribution resolute --force-distribution 'Rebuilt for Armatos as the engine under Forum: no web view, no snap backend, no telemetry; loads the Forum window when it is installed.'"
	build_tree "/build/discover/$(basename "$dir")"
fi

ls -1 "$OUT"
say "Factum est: provinciae built into out/provinciae/"
