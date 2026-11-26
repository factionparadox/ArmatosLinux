# Armatos Linux

*Ave, Imperator. Legio parata est.*

> **Rome's engineering, and you are the Imperator.**

Armatos Linux is a desktop distribution based on Ubuntu 26.04 LTS and built for the
Framework Laptop 13 Pro. It keeps Ubuntu's certified hardware support and leaves the
rest behind: no snaps, no GNOME, and systemd held at version 259, before the
`birthDate` field arrived.

In their place:

- **`linux-legio`**, a CachyOS-patched kernel compiled for Panther Lake
- **Btrfs snapshots** before every update, so any change can be undone with one command
- **MangoWC** with a marble Quickshell desktop
- **Local AI tools** that run entirely on the laptop: a log reader, a security adviser
  and a companion for bad days

The whole system speaks Latin, counts its workspaces in Roman numerals and dates its
releases from the founding of Rome. You are the Imperator. The legion answers to you.

*Armatos* is Latin for "the armed ones", and the name comes from the Armatos Legio deck.

## Why Armatos exists

1. **The Ubuntu that says no.** It keeps Canonical's certified, Framework-supported base,
   but drops snaps and GNOME and freezes systemd at 259, before the `birthDate` field.
2. **The best Linux for the 13 Pro.** `linux-legio` is the newest stable kernel with
   CachyOS's mature patches, compiled for Panther Lake.
3. **Local AI that works on the system.** `haruspex` reads your logs and explains
   failures offline, `centurion` watches for malware and reports to you, and Lar is
   there to talk to. Nothing leaves the laptop.
4. **Every change can be undone.** `damnatio` snapshots before every `cursus` run.

## Layout

| Path | What lives there |
|---|---|
| `docs/DESIGN.md` | The full design |
| `docs/LEXICON.md` | Every Armatos term and what it means |
| `packages/` | Armatos's own packages, built into `.deb`s by `tools/build-debs.sh` |
| `kernel/` | `linux-legio` |
| `iso/` | ISO build (`colonia` / Calamares) |
| `art/` | Marmor artwork: wallpapers, GRUB, Plymouth, installer |
| `tools/` | Build scripts |

## Building

On any Ubuntu 26.04-based system (Armatos itself, Galactic Mandate, plain Ubuntu):

```sh
sudo tools/build-iso.sh
```

This builds the packages and the live ISO into `out/`, which git ignores. The ISO boots straight
into a live session as `imperator@roma`, works offline, and keeps Secure Boot on.
Downloaded packages are cached in `build/cache`, so later builds only fetch what changed.

Packages alone: `tools/build-debs.sh`.

## Writing a USB stick: `lapicida`

```sh
packages/armatos-lapicida/usr/bin/lapicida out/armatos-*.iso
```

On Armatos it's simply `lapicida`. It only offers removable USB drives, asks you to type the
stick's name before erasing it, and reads the stick back to verify every byte.

## Status

**MMDCCLXXIX (2026)**: foundations are being laid. See `docs/DESIGN.md` for the roadmap.
