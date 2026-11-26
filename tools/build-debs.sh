#!/bin/bash
# Build every package under packages/ into out/*.deb.
#   tools/build-debs.sh            all packages
#   tools/build-debs.sh cursus     just packages whose name contains "cursus"
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out
filter="${1:-}"
for dir in packages/*/; do
	name=$(basename "$dir")
	[ -n "$filter" ] && [[ "$name" != *"$filter"* ]] && continue
	[ -f "$dir/DEBIAN/control" ] || continue
	version=$(sed -n 's/^Version: //p' "$dir/DEBIAN/control")
	arch=$(sed -n 's/^Architecture: //p' "$dir/DEBIAN/control")
	# Copy to a staging tree so permissions are right regardless of checkout.
	stage=$(mktemp -d)
	cp -a "$dir/." "$stage/"
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
	dpkg-deb --root-owner-group -Zxz --build "$stage" "out/${name}_${version}_${arch}.deb" >/dev/null
	rm -rf "$stage"
	echo "built out/${name}_${version}_${arch}.deb"
done
