#!/bin/bash
# horreum — publish Armatos Linux's own APT repository.
#
#   tools/horreum.sh                build the repository from out/ and publish it
#   tools/horreum.sh --key FILE     first run on a machine: take the signing key from FILE
#   tools/horreum.sh --dry-run      build it in build/horreum/new, sign it, don't push
#
# The repository is the "horreum" branch of the GitHub repo, served from
#   https://raw.githubusercontent.com/factionparadox/ArmatosLinux/horreum
# armatos-release points every Armatos system at it (etc/apt/sources.list.d/
# armatos.sources) and carries the public key.
#
#   italia      out/*.deb             (tools/build-debs.sh, run here if needed)
#   provinciae  out/provinciae/*.deb  (sudo tools/build-provinciae.sh)
#
# Each publish replaces the branch with a single commit, so it never grows.
# The previous publish's packages and index files are kept alongside, because
# GitHub's cache can serve the old index for a few minutes after a push.
#
# Run it as yourself, not with sudo: the signing key lives in your home, in
# ~/.local/share/armatos/horreum-key (or $ARMATOS_HORREUM_KEY).

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD

SUITE=resolute
BRANCH=horreum
KEYRING_PUB=packages/armatos-release/usr/share/keyrings/armatos-archive-keyring.asc
export GNUPGHOME="${ARMATOS_HORREUM_KEY:-$HOME/.local/share/armatos/horreum-key}"
WORK="$ROOT/build/horreum"
NEW="$WORK/new"
PREV="$WORK/prev"

die() { echo "horreum: $*" >&2; exit 1; }
say() { echo "== $*"; }

dry=0
keyfile=
while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) dry=1 ;;
		--key) keyfile="${2:-}"; [ -n "$keyfile" ] || die "--key needs a file"; shift ;;
		*) die "unknown option $1 (see the top of tools/horreum.sh)" ;;
	esac
	shift
done

[ "$(id -u)" -ne 0 ] || [ -n "${ARMATOS_HORREUM_KEY:-}" ] \
	|| die "run it as yourself, without sudo: the key is in your home, not root's"
for t in apt-ftparchive gpg xz git; do
	command -v "$t" >/dev/null || die "needs $t (sudo apt install apt-utils gnupg xz-utils git)"
done

# --- The key -----------------------------------------------------------------
want=$(gpg --show-keys --with-colons "$KEYRING_PUB" 2>/dev/null | awk -F: '/^fpr/{print $10; exit}')
[ -n "$want" ] || die "can't read the public key in $KEYRING_PUB"
mkdir -p "$GNUPGHOME"; chmod 700 "$GNUPGHOME"
if [ -n "$keyfile" ]; then
	[ -r "$keyfile" ] || die "can't read $keyfile"
	gpg --batch --quiet --import "$keyfile"
fi
gpg --batch --list-secret-keys "$want" >/dev/null 2>&1 \
	|| die "the signing key ($want) isn't in $GNUPGHOME. First time on this machine: tools/horreum.sh --key /path/to/armatos-horreum-SECRET.asc"

# --- The packages ------------------------------------------------------------
# Versions come from the last commit (see tools/build-debs.sh), so publishing
# uncommitted work would put different packages under the same version.
if [ $dry = 0 ] && [ -n "$(git status --porcelain -- packages tools art 2>/dev/null)" ]; then
	die "commit (or stash) your changes first: package versions come from the last commit"
fi
stamp=$(TZ=UTC git -c safe.directory="$ROOT" log -1 --format=%cd --date=format-local:%Y%m%d%H%M)
stale=0
for dir in packages/*/; do
	name=$(basename "$dir")
	base=$(sed -n 's/^Version: //p' "$dir/DEBIAN/control")
	arch=$(sed -n 's/^Architecture: //p' "$dir/DEBIAN/control")
	[ -e "out/${name}_${base}.${stamp}_${arch}.deb" ] || stale=1
done
if [ $stale = 1 ]; then
	say "Building the Armatos packages for this commit"
	if [ -w out ] || [ ! -e out ]; then tools/build-debs.sh >/dev/null; else sudo tools/build-debs.sh >/dev/null; fi
fi
compgen -G "out/provinciae/*.deb" >/dev/null || die "out/provinciae is empty: run  sudo tools/build-provinciae.sh  first"

# --- The tree ----------------------------------------------------------------
say "Laying out the horreum"
rm -rf "$WORK"; mkdir -p "$NEW" "$PREV"
if git fetch --quiet origin "$BRANCH" 2>/dev/null; then
	git archive FETCH_HEAD | tar -x -C "$PREV"
fi

mkdir -p "$NEW/pool/italia" "$NEW/pool/provinciae"
for dir in packages/*/; do
	name=$(basename "$dir")
	base=$(sed -n 's/^Version: //p' "$dir/DEBIAN/control")
	arch=$(sed -n 's/^Architecture: //p' "$dir/DEBIAN/control")
	cp "out/${name}_${base}.${stamp}_${arch}.deb" "$NEW/pool/italia/"
done
cp out/provinciae/*.deb "$NEW/pool/provinciae/"

cd "$NEW"
for comp in italia provinciae; do
	d="dists/$SUITE/$comp/binary-amd64"
	mkdir -p "$d"
	apt-ftparchive packages "pool/$comp" > "$d/Packages"
	xz -k -9 "$d/Packages"
done

# Keep the previous generation, which a stale cached index may still name.
if [ -d "$PREV/dists/$SUITE" ]; then
	for comp in italia provinciae; do
		p="$PREV/dists/$SUITE/$comp/binary-amd64/Packages"
		[ -f "$p" ] || continue
		sed -n 's/^Filename: //p' "$p" | while read -r f; do
			[ -e "$f" ] || { [ -e "$PREV/$f" ] && mkdir -p "$(dirname "$f")" && cp "$PREV/$f" "$f"; }
		done || true
		# Its index files, by hash.
		sed -n '/^SHA256:/,/^[A-Z]/s/^ \([0-9a-f]\{64\}\) .* \(.*\)$/\1 \2/p' "$PREV/dists/$SUITE/Release" \
			| while read -r h f; do
				[[ "$f" == "$comp/"* ]] || continue
				src="$PREV/dists/$SUITE/$(dirname "$f")/by-hash/SHA256/$h"
				dst="dists/$SUITE/$(dirname "$f")/by-hash/SHA256/$h"
				[ -e "$src" ] && [ ! -e "$dst" ] && mkdir -p "$(dirname "$dst")" && cp "$src" "$dst"
			done || true
	done
fi

apt-ftparchive \
	-o APT::FTPArchive::DoByHash=true \
	-o APT::FTPArchive::MD5=false -o APT::FTPArchive::SHA1=false \
	-o APT::FTPArchive::Release::Origin=Armatos \
	-o APT::FTPArchive::Release::Label="Armatos Linux" \
	-o APT::FTPArchive::Release::Suite=$SUITE \
	-o APT::FTPArchive::Release::Codename=$SUITE \
	-o APT::FTPArchive::Release::Architectures=amd64 \
	-o APT::FTPArchive::Release::Components="italia provinciae" \
	-o APT::FTPArchive::Release::Description="Armatos Linux: the horreum" \
	release "dists/$SUITE" > "$WORK/Release"
mv "$WORK/Release" "dists/$SUITE/Release"

say "Sealing it with the key"
gpg --batch --yes --digest-algo SHA512 --local-user "$want" --clearsign -o "dists/$SUITE/InRelease" "dists/$SUITE/Release"
gpg --batch --yes --digest-algo SHA512 --local-user "$want" -abs -o "dists/$SUITE/Release.gpg" "dists/$SUITE/Release"
check=$(mktemp -d)
gpg --batch --quiet --homedir "$check" --import "$ROOT/$KEYRING_PUB" 2>/dev/null
gpg --batch --quiet --homedir "$check" --verify "dists/$SUITE/InRelease" 2>/dev/null \
	|| die "the signature doesn't verify against $KEYRING_PUB"
cp "$ROOT/$KEYRING_PUB" armatos-archive-keyring.asc
cat > README.md <<EOF
# The horreum

Armatos Linux's APT repository, published by \`tools/horreum.sh\` from the
[main branch](https://github.com/factionparadox/ArmatosLinux). Don't commit
here by hand: every publish replaces this branch.

Every Armatos system already uses it (\`armatos-release\`). By hand:

    Types: deb
    URIs: https://raw.githubusercontent.com/factionparadox/ArmatosLinux/horreum
    Suites: $SUITE
    Components: italia provinciae
    Signed-By: /usr/share/keyrings/armatos-archive-keyring.asc

Signing key fingerprint: \`$want\`
EOF

count() { grep -c '^Package:' "dists/$SUITE/$1/binary-amd64/Packages"; }
say "italia: $(count italia) packages, provinciae: $(count provinciae), version stamp $stamp"

if [ $dry = 1 ]; then
	say "Dry run: the tree is in $NEW"
	exit 0
fi

# --- Publish -----------------------------------------------------------------
say "Publishing to the $BRANCH branch"
index=$(mktemp -u)
export GIT_DIR="$ROOT/.git" GIT_WORK_TREE="$NEW" GIT_INDEX_FILE="$index"
git add -A -f .
tree=$(git write-tree)
msg="horreum: $stamp ($(git -C "$ROOT" rev-parse --short HEAD))"
[ -n "${HORREUM_TRAILER:-}" ] && msg="$msg

$HORREUM_TRAILER"
commit=$(GIT_AUTHOR_NAME="Armatos horreum" GIT_AUTHOR_EMAIL=factionparadox@users.noreply.github.com \
	GIT_COMMITTER_NAME="Armatos horreum" GIT_COMMITTER_EMAIL=factionparadox@users.noreply.github.com \
	git commit-tree "$tree" -m "$msg")
rm -f "$index"
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
git -C "$ROOT" push --quiet --force origin "$commit:refs/heads/$BRANCH"
say "Published. Armatos systems will see it at their next  cursus  (or apt update)."
