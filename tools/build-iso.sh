#!/bin/bash
# Build the Armatos live ISO.
#
#   sudo tools/build-iso.sh
#
# Runs on any Ubuntu 26.04-based system (Armatos, Galactic Mandate, plain
# Ubuntu). Output: out/armatos-<date>.iso and its .sha256, ready for lapicida.
#
# The ISO boots straight into a live session as imperator@roma, works offline
# from the stick (Wi-Fi firmware included), and keeps Secure Boot working by
# using Ubuntu's own signed shim, GRUB and kernel. linux-legio comes later.
#
# Downloaded packages are kept in build/cache, so a second build only fetches
# what changed. Set ARMATOS_MIRROR to use a closer Ubuntu mirror.

set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD

SUITE=resolute
MIRROR="${ARMATOS_MIRROR:-http://archive.ubuntu.com/ubuntu}"
WORK="$ROOT/build/iso"
CHROOT="$WORK/chroot"
IMAGE="$WORK/image"
CACHE="$ROOT/build/cache"
STAMP=$(date +%Y%m%d)
ISO="$ROOT/out/armatos-$STAMP.iso"

say() { printf '\e[38;5;178m== %s\e[0m\n' "$*"; }
die() { printf '\e[38;5;124mbuild-iso: %s\e[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run with sudo: sudo tools/build-iso.sh"

need=(debootstrap mksquashfs xorriso mkfs.vfat mcopy)
missing=()
for t in "${need[@]}"; do command -v "$t" >/dev/null 2>&1 || missing+=("$t"); done
if [ "${#missing[@]}" -gt 0 ]; then
	say "Installing build tools: debootstrap squashfs-tools xorriso dosfstools mtools"
	apt-get install -y debootstrap squashfs-tools xorriso dosfstools mtools
fi
# Older debootstrap releases don't know resolute yet; it builds like noble.
if [ ! -e "/usr/share/debootstrap/scripts/$SUITE" ]; then
	ln -s gutsy "/usr/share/debootstrap/scripts/$SUITE"
fi

# --- Cleanup: never leave the host's /proc, /sys or /dev mounted inside. ---
unmount_chroot() {
	local m
	for m in var/cache/apt/archives run dev/pts dev sys proc; do
		mountpoint -q "$CHROOT/$m" 2>/dev/null && umount -l "$CHROOT/$m"
	done
	return 0
}
trap unmount_chroot EXIT

say "Building the Armatos packages"
tools/build-debs.sh >/dev/null

say "Laying the foundations: Ubuntu 26.04 base (debootstrap)"
unmount_chroot
rm -rf "$WORK"
mkdir -p "$CHROOT" "$IMAGE" "$CACHE/debootstrap" "$CACHE/apt" "$ROOT/out"
debootstrap --arch=amd64 --cache-dir="$CACHE/debootstrap" \
	--components=main,restricted,universe,multiverse "$SUITE" "$CHROOT" "$MIRROR"

mount --bind /proc "$CHROOT/proc"
mount --bind /sys "$CHROOT/sys"
mount --bind /dev "$CHROOT/dev"
mount --bind /dev/pts "$CHROOT/dev/pts"
mount -t tmpfs tmpfs "$CHROOT/run"
mount --bind "$CACHE/apt" "$CHROOT/var/cache/apt/archives"
# Name lookups inside the build use the host's resolver; Ubuntu's usual
# symlink (into an empty /run here) is put back before the image is made.
RESOLV_LINK=$(readlink "$CHROOT/etc/resolv.conf" || true)
rm -f "$CHROOT/etc/resolv.conf"
cp -L /etc/resolv.conf "$CHROOT/etc/resolv.conf"

cat > "$CHROOT/etc/apt/sources.list.d/ubuntu.sources" <<EOF
Types: deb
URIs: $MIRROR
Suites: $SUITE $SUITE-updates $SUITE-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
rm -f "$CHROOT/etc/apt/sources.list"
# Keep downloaded packages for the next build.
echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > "$CHROOT/etc/apt/apt.conf.d/01keep-debs"
# Don't start services inside the build.
printf '#!/bin/sh\nexit 101\n' > "$CHROOT/usr/sbin/policy-rc.d"; chmod 755 "$CHROOT/usr/sbin/policy-rc.d"
echo roma > "$CHROOT/etc/hostname"

in_chroot() { chroot "$CHROOT" /usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8 "$@"; }

say "Installing the laws first (Lex I–III), so nothing forbidden gets in"
cp out/armatos-lex_*.deb out/armatos-release_*.deb "$CHROOT/tmp/"
in_chroot apt-get update
in_chroot sh -c 'apt-get install -y /tmp/armatos-lex_*.deb /tmp/armatos-release_*.deb'

say "Raising the city: kernel, firmware, live boot, network"
in_chroot apt-get install -y --no-install-recommends \
	ubuntu-minimal ubuntu-standard \
	linux-image-generic linux-firmware \
	casper initramfs-tools \
	shim-signed grub-efi-amd64-signed grub-efi-amd64-bin grub-efi-amd64 \
	network-manager wpasupplicant iw wireless-regdb rfkill \
	sudo locales tzdata console-setup kbd keyboard-configuration \
	btrfs-progs cryptsetup dosfstools whiptail curl ca-certificates \
	bash-completion less nano python3 plymouth plymouth-label fontconfig zstd

say "Installing Armatos"
cp out/armatos-*.deb "$CHROOT/tmp/"
in_chroot sh -c 'apt-get install -y /tmp/armatos-voice_*.deb /tmp/armatos-damnatio_*.deb /tmp/armatos-cursus_*.deb /tmp/armatos-lapicida_*.deb /tmp/armatos-boot-theme_*.deb'

say "Raising the desktop: MangoWC, Quickshell and the Marmor shell"
# The provinciae (wlroots 0.20, SceneFX, MangoWC, Quickshell) aren't in
# Ubuntu; tools/build-provinciae.sh builds them.
for p in libwlroots-0.20 libscenefx-0.5 mangowm quickshell; do
	compgen -G "out/provinciae/${p}_*.deb" >/dev/null || die "out/provinciae has no $p: run  sudo tools/build-provinciae.sh  first"
	cp out/provinciae/${p}_*.deb "$CHROOT/tmp/"
done
in_chroot sh -c 'apt-get install -y --no-install-recommends \
	/tmp/libwlroots-0.20_*.deb /tmp/libscenefx-0.5_*.deb /tmp/mangowm_*.deb /tmp/quickshell_*.deb \
	/tmp/armatos-shell_*.deb /tmp/armatos-session_*.deb /tmp/armatos-colonia_*.deb \
	pipewire pipewire-pulse wireplumber libspa-0.2-bluetooth upower power-profiles-daemon bluez \
	fprintd libpam-fprintd polkitd xdg-user-dirs \
	libgl1-mesa-dri libegl-mesa0 mesa-vulkan-drivers \
	fonts-dejavu-core thunar'
rm -f "$CHROOT"/tmp/*.deb

say "Opening the Forum: Discover's engine under the Armatos face"
# Discover is rebuilt by tools/build-provinciae.sh (no web view, no snap).
for p in plasma-discover plasma-discover-common plasma-discover-backend-fwupd plasma-discover-backend-flatpak; do
	compgen -G "out/provinciae/${p}_*armatos*.deb" >/dev/null || die "out/provinciae has no $p: run  sudo tools/build-provinciae.sh  first"
	cp out/provinciae/${p}_*armatos*.deb "$CHROOT/tmp/"
done
cp out/armatos-forum_*.deb out/armatos-socii_*.deb "$CHROOT/tmp/"
in_chroot sh -c 'apt-get install -y --no-install-recommends \
	/tmp/plasma-discover_*.deb /tmp/plasma-discover-common_*.deb \
	/tmp/plasma-discover-backend-fwupd_*.deb /tmp/plasma-discover-backend-flatpak_*.deb \
	/tmp/armatos-forum_*.deb /tmp/armatos-socii_*.deb fwupd'
rm -f "$CHROOT"/tmp/*.deb

say "Stocking the armoury: the apps on the keybinds"
# Super+W Firefox (Mozilla's .deb, British English), Super+V VLC, Super+A
# ani-cli (the horreum's current build) with mpv, fzf and the download tools,
# Super+P Proton VPN (Proton's repository; gnome-keyring holds its sign-in),
# Super+D Discord through vesta-temple. socii and the horreum are in place
# now, so read their indexes first.
in_chroot apt-get update
compgen -G "out/provinciae/ani-cli_*.deb" >/dev/null || die "out/provinciae has no ani-cli: run  sudo tools/build-provinciae.sh  first"
cp out/provinciae/ani-cli_*.deb out/vesta-temple_*.deb "$CHROOT/tmp/"
# Proton's daemon starts its service straight from its install script with
# systemctl, which can't work with no systemd running in the chroot. For this
# step a stand-in found first on PATH skips what needs a running systemd and
# passes the rest (enabling services) to the real systemctl.
mkdir -p "$CHROOT/tmp/build-bin"
cat > "$CHROOT/tmp/build-bin/systemctl" <<'EOF'
#!/bin/sh
case "$1" in
	start|stop|restart|reload|try-restart|reload-or-restart|try-reload-or-restart|daemon-reload|daemon-reexec) exit 0 ;;
esac
exec /usr/bin/systemctl "$@"
EOF
chmod 755 "$CHROOT/tmp/build-bin/systemctl"
in_chroot env PATH=/tmp/build-bin:/usr/sbin:/usr/bin:/sbin:/bin sh -c 'apt-get install -y --no-install-recommends \
	firefox firefox-l10n-en-gb vlc \
	/tmp/ani-cli_*.deb mpv fzf yt-dlp ffmpeg \
	proton-vpn-gnome-desktop gnome-keyring \
	/tmp/vesta-temple_*.deb'
rm -rf "$CHROOT/tmp/build-bin"
rm -f "$CHROOT"/tmp/*.deb
# Discord itself can't go on the ISO (its licence doesn't allow passing it
# on), so a new install fetches it on its first boot with a connection.
in_chroot systemctl enable vesta-temple-first.timer

say "Setting the Imperator's defaults: en_GB, Europe/London, UK keyboard"
in_chroot sh -c 'echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen && locale-gen && update-locale LANG=en_GB.UTF-8'
ln -sf /usr/share/zoneinfo/Europe/London "$CHROOT/etc/localtime"
echo Europe/London > "$CHROOT/etc/timezone"
# British keys, with Russian a press of Alt+Shift away.
cat > "$CHROOT/etc/default/keyboard" <<'EOF'
XKBMODEL="pc105"
XKBLAYOUT="gb,ru"
XKBVARIANT=","
XKBOPTIONS="grp:alt_shift_toggle"
BACKSPACE="guess"
EOF

# The live user is imperator, on host roma; casper creates it at boot.
cat > "$CHROOT/etc/casper.conf" <<'EOF'
export USERNAME="imperator"
export USERFULLNAME="Imperator"
export HOST="roma"
export BUILD_SYSTEM="Ubuntu"
export FLAVOUR="Armatos"
EOF
# greetd raises the desktop for the live Imperator. If the desktop ever
# exits, a plain login prompt takes its place on the same console.
cat > "$CHROOT/etc/greetd/config.toml" <<'EOF'
[terminal]
vt = 7

[initial_session]
command = "armatos-session"
user = "imperator"

[default_session]
command = "/usr/sbin/agreety --cmd armatos-session"
user = "_greetd"
EOF
# NetworkManager manages every interface, so Wi-Fi works from boot (nmtui).
mkdir -p "$CHROOT/etc/NetworkManager/conf.d"
printf '[keyfile]\nunmanaged-devices=none\n' > "$CHROOT/etc/NetworkManager/conf.d/10-armatos-manage-all.conf"

# The system's name (os-release, issue, motd) comes from armatos-release.

say "Rebuilding the initramfs with casper"
in_chroot update-initramfs -c -k all 2>/dev/null || in_chroot update-initramfs -u -k all

KVER=$(find "$CHROOT/lib/modules" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort -V | tail -n 1)
[ -f "$CHROOT/boot/vmlinuz-$KVER" ] && [ -f "$CHROOT/boot/initrd.img-$KVER" ] || die "kernel or initrd missing for $KVER"

say "Clearing the camp"
in_chroot apt-get clean
rm -f "$CHROOT/usr/sbin/policy-rc.d" "$CHROOT/etc/apt/apt.conf.d/01keep-debs"
rm -rf "$CHROOT"/tmp/* "$CHROOT"/var/lib/apt/lists/*_Packages* 2>/dev/null || true
: > "$CHROOT/etc/machine-id"
rm -f "$CHROOT/etc/resolv.conf"
ln -s "${RESOLV_LINK:-../run/systemd/resolve/stub-resolv.conf}" "$CHROOT/etc/resolv.conf"
unmount_chroot

say "Carving the image"
mkdir -p "$IMAGE/casper" "$IMAGE/boot/grub" "$IMAGE/EFI/boot" "$IMAGE/.disk"
cp "$CHROOT/boot/vmlinuz-$KVER" "$IMAGE/casper/vmlinuz"
cp "$CHROOT/boot/initrd.img-$KVER" "$IMAGE/casper/initrd"
# shellcheck disable=SC2016  # dpkg-query expands these itself
chroot "$CHROOT" dpkg-query -W --showformat='${Package} ${Version}\n' > "$IMAGE/casper/filesystem.manifest"
du -sx --block-size=1 "$CHROOT" | cut -f1 > "$IMAGE/casper/filesystem.size"
mksquashfs "$CHROOT" "$IMAGE/casper/filesystem.squashfs" -noappend -comp zstd -Xcompression-level 15 \
	-e boot/efi -wildcards -e 'var/cache/apt/archives/*.deb'
echo "Armatos Linux MMDCCLXXIX \"Resolute\" - amd64 ($STAMP)" > "$IMAGE/.disk/info"

# Secure Boot chain, all signed by Canonical: shim → GRUB (the CD build) → kernel.
cp "$CHROOT/usr/lib/shim/shimx64.efi.signed.latest" "$IMAGE/EFI/boot/bootx64.efi" 2>/dev/null \
	|| cp "$CHROOT/usr/lib/shim/shimx64.efi.signed" "$IMAGE/EFI/boot/bootx64.efi"
cp "$CHROOT/usr/lib/shim/mmx64.efi" "$IMAGE/EFI/boot/mmx64.efi"
cp "$CHROOT/usr/lib/grub/x86_64-efi-signed/gcdx64.efi.signed" "$IMAGE/EFI/boot/grubx64.efi"

# The boot menu: the Armatos theme (rendered into art/grub by tools/make-grub-theme.py).
mkdir -p "$IMAGE/boot/grub/themes"
cp -r "$ROOT/art/grub/armatos" "$IMAGE/boot/grub/themes/armatos"
cat > "$IMAGE/boot/grub/grub.cfg" <<'EOF'
set timeout=5
set default=0
set gfxmode=1920x1280,1920x1200,1920x1080,auto
set gfxpayload=keep
# (Under Secure Boot GRUB loads no modules from disk; the signed GRUB already
# has efi_gop, gfxterm, gfxmenu, png, jpeg and font built in.)
terminal_output gfxterm
set theme=/boot/grub/themes/armatos/theme.txt

# Entry titles are a single space: the carved entry images (icons) are what
# shows, and GRUB sizes the highlight as icon + title width.
menuentry " " --class salve --id salve {
	linux /casper/vmlinuz boot=casper quiet splash ---
	initrd /casper/initrd
}
menuentry " " --class salvesafe --id salvesafe {
	linux /casper/vmlinuz boot=casper nomodeset quiet splash ---
	initrd /casper/initrd
}
menuentry " " --class fundamenta --id fundamenta {
	fwsetup
}
EOF
cp "$IMAGE/boot/grub/grub.cfg" "$IMAGE/EFI/boot/grub.cfg"

# The EFI system partition the firmware boots from on a USB stick.
EFIIMG="$WORK/efi.img"
rm -f "$EFIIMG"
mkfs.vfat -C -n ARMATOS-EFI "$EFIIMG" 8192 >/dev/null
mmd -i "$EFIIMG" ::/EFI ::/EFI/boot
mcopy -i "$EFIIMG" "$IMAGE/EFI/boot/bootx64.efi" "$IMAGE/EFI/boot/grubx64.efi" \
	"$IMAGE/EFI/boot/mmx64.efi" "$IMAGE/EFI/boot/grub.cfg" ::/EFI/boot/

say "Sealing the ISO"
rm -f "$ISO"
xorriso -as mkisofs -r -V "ARMATOS_2779" -o "$ISO" -J -joliet-long -iso-level 3 \
	-append_partition 2 0xef "$EFIIMG" -appended_part_as_gpt \
	-e --interval:appended_partition_2:all:: -no-emul-boot \
	"$IMAGE"
(cd out && sha256sum "$(basename "$ISO")" > "$(basename "$ISO").sha256")
# Hand the result back to the user who ran sudo.
if [ -n "${SUDO_UID:-}" ]; then chown "$SUDO_UID:${SUDO_GID:-$SUDO_UID}" "$ISO" "$ISO.sha256"; fi

say "Factum est: $ISO ($(du -h "$ISO" | cut -f1))"
echo "Write it to a stick with:  lapicida $ISO"
