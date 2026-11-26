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
| `packages/armatos-shell` | The Marmor desktop shell (Quickshell): Titulus, launcher, porta |
| `packages/armatos-session` | MangoWC with the Armatos settings and keybinds |
| `packages/armatos-colonia` | `colonia`, the installer (Calamares in Marmor) |
| `provinciae/` | Packaging for what Ubuntu lacks: wlroots 0.20, SceneFX, MangoWC, Quickshell |
| `kernel/` | `linux-legio` |
| `art/` | Marmor artwork: wallpapers, GRUB, Plymouth, shell, installer |
| `tools/` | Build scripts |

## Building

On any Ubuntu 26.04-based system (Armatos itself, Galactic Mandate, plain Ubuntu):

```sh
sudo tools/build-provinciae.sh   # once: MangoWC, Quickshell and friends (slow)
sudo tools/build-iso.sh
```

The first builds the desktop packages Ubuntu doesn't carry into `out/provinciae/`, in a
clean chroot, and skips anything already built. The second builds the Armatos packages
and the live ISO into `out/`, which git ignores. Downloaded packages are cached in
`build/cache`, so later builds only fetch what changed.

The ISO keeps Secure Boot on, works offline, and boots through the themed GRUB menu and
splash straight into the marble desktop as `imperator@roma`. To install, open the
launcher (Super+Space) and summon **Colonia**, or run `colonia` in a terminal.

Packages alone: `tools/build-debs.sh`.

## The desktop

| Keys | Order |
|---|---|
| Super+1…9 / Super+Shift+1…9 | Go to workspace I–IX / move the window there |
| Super+Tab | The Colosseum: every window in the ring |
| Super+Space | The launcher: *Ave, Imperator. Quid imperas?* |
| Super+S | Tabula Imperii: Wi-Fi, Bluetooth, sound, light, power |
| Super+Q / F / R | Close / maximise / cycle widths (⅓ ½ ⅔ full) |
| Super+X / Z | Seal the porta (lock) / lock and sleep |
| Super+Shift+S, Print | Paint a fresco (screenshot) of an area / the screen |
| Super+W T D V E A P | Browser, terminal, Discord, VLC, files, ani-cli, Proton VPN |
| Alt+Shift | Switch keyboard layout |
| Super+Escape | VALE: lock, sleep, log out, restart, shut down |

Your own Mango settings go in `~/.config/mango/config.conf`; it is read after the Armatos
defaults, so it wins. The shell remembers its numerals and language in
`~/.local/state/armatos/shell.json`.

## Writing a USB stick: `lapicida`

```sh
packages/armatos-lapicida/usr/bin/lapicida out/armatos-*.iso
```

On Armatos it's simply `lapicida`. It only offers removable USB drives, asks you to type the
stick's name before erasing it, and reads the stick back to verify every byte.

## Status

**MMDCCLXXIX (2026)**: the live ISO boots to the desktop and installs with `colonia`.
Still to come: `linux-legio`, Tribunus (GTK), Forum, Senatus, the oracles and Otium.
See `docs/DESIGN.md` for the roadmap.
