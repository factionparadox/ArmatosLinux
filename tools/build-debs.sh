#!/bin/bash
# Build every package under packages/ into out/*.deb.
#   tools/build-debs.sh            all packages
#   tools/build-debs.sh cursus     just packages whose name contains "cursus"
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out
filter="${1:-}"
# Each package's control file holds a base version (2779.1). The build adds the
# time of the last commit, in UTC: 2779.1.202611272256. Every checkout of the
# same commit makes the same versions, and every later commit makes higher
# ones, so the horreum (tools/horreum.sh) always offers a real upgrade.
stamp=$(TZ=UTC git -c safe.directory="$PWD" log -1 --format=%cd --date=format-local:%Y%m%d%H%M 2>/dev/null || TZ=UTC date +%Y%m%d%H%M)
for dir in packages/*/; do
	name=$(basename "$dir")
	[ -n "$filter" ] && [[ "$name" != *"$filter"* ]] && continue
	[ -f "$dir/DEBIAN/control" ] || continue
	base=$(sed -n 's/^Version: //p' "$dir/DEBIAN/control")
	version="$base.$stamp"
	arch=$(sed -n 's/^Architecture: //p' "$dir/DEBIAN/control")
	# Copy to a staging tree so permissions are right regardless of checkout.
	stage=$(mktemp -d)
	cp -a "$dir/." "$stage/"
	# Stamp the version, and pins on sibling packages ("armatos-shell (= 2779.1)").
	sed -i -e "s/^Version: .*/Version: $version/" \
	       -e "s/(\(=\|>=\) $base)/(\1 $version)/g" "$stage/DEBIAN/control"
	find "$stage" -name __pycache__ -prune -exec rm -rf {} +
	# A package can pull generated files (e.g. themes rendered into art/) in here.
	if [ -x "$stage/assemble" ]; then
		"$stage/assemble" "$PWD" "$stage"
		rm -f "$stage/assemble"
	fi
	find "$stage" -type d -exec chmod 755 {} +
	find "$stage" -type f -exec chmod 644 {} +
	for exe in "$stage"/usr/bin/* "$stage"/usr/sbin/* "$stage"/usr/lib/armatos/{imago,arcesse} "$stage"/etc/grub.d/* "$stage"/DEBIAN/{preinst,postinst,prerm,postrm}; do
		[ -f "$exe" ] && chmod 755 "$exe"
	done
	# One build per package in out/, so the ISO's globs pick exactly one.
	rm -f out/"${name}"_*_"${arch}".deb
	dpkg-deb --root-owner-group -Zxz --build "$stage" "out/${name}_${version}_${arch}.deb" >/dev/null
	rm -rf "$stage"
	echo "built out/${name}_${version}_${arch}.deb"
done
