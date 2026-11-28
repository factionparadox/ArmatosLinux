# Armatos Linux — Design

Release: **MMDCCLXXIX** (AUC 2779 = 2026), codename base: Ubuntu 26.04 LTS "Resolute".

Theme: historical Rome with a few fictional touches. The fiction is a legion of our
own, the Armatos, whose standard is the logo. The flavour text tells a story; the
system itself stays an honest Ubuntu underneath, so Ubuntu documentation still
applies.

---

## 1. Base

| Decision | Detail |
|---|---|
| Base | Ubuntu 26.04 LTS, classic APT (not image-based) |
| systemd | Pinned at **259.x** for the life of the release (`lex I`). Ubuntu doesn't bump systemd majors inside an LTS, but the pin guards against PPAs and backports bringing in 260+. |
| Removed | `snapd` (pinned out at priority -1), GNOME Shell and the Ubuntu desktop session |
| Filesystem | Btrfs root (`@`, `@snapshots`) for `damnatio`; `/home` on its own LUKS2 + Btrfs partition, opened by a key kept inside the encrypted root, so one passphrase unlocks both |
| Encryption | LUKS2 full-disk; the passphrase is the only password you type |
| Login | Autologin straight to the desktop after LUKS unlock |
| Auth | Fingerprint (`fprintd`) for sudo and the lock screen; LUKS passphrase as fallback |
| MAC | AppArmor in enforce mode, plus Armatos profiles: the **Praetorian Guard** |

## 2. Kernel — `linux-legio`

- Tracks the **newest stable mainline series**, never release candidates.
- A series ships only once it reaches roughly **x.y.3**, after the first-week regressions.
- Carries CachyOS's **mature** patches only (BORE scheduler and similar); experimental ones are skipped.
- Two flavours:
  - `linux-legio-pantherlake`: compiled for Panther Lake, the default on the 13 Pro.
  - `linux-legio-generic`: x86-64-v3, carried on the ISO so it installs on any machine.
- The previous kernel always stays installed as a GRUB fallback.
- `damnatio` snapshots before every kernel change.

## 3. Packaging and repositories

Armatos runs its own APT repository, the **horreum**, split into the following components:

| Component | Contents |
|---|---|
| `italia` | Core Armatos packages (tools, themes, kernel) |
| `provinciae` | Extra software we package ourselves: MangoWC, SceneFX, wlroots 0.20, the Quickshell backport, Discover rebuilt for Forum, current ani-cli |
| `barbaricum` | Non-free firmware and blobs *(not yet needed)* |

How it works:

- **Hosting:** the `horreum` branch of this GitHub repo, served from
  `https://raw.githubusercontent.com/factionparadox/ArmatosLinux/horreum`. Each publish
  replaces the branch with one commit, so it never grows; the previous publish's packages
  and indexes are kept beside the new ones (with `Acquire-By-Hash`), because GitHub's cache
  can serve an old index for a few minutes.
- **Trust:** signed with an Ed25519 key, fingerprint
  `E682 ED64 41E7 446A 0BF6 0299 EEEE 883B DA60 A8CA`. `armatos-release` ships the public
  key and `armatos.sources`; *Lex IV* (`armatos-lex`) pins the Armatos origin at 600, so our
  builds win over Ubuntu's packages of the same name without forcing downgrades.
- **Versions:** each package's control file holds a base (2779.1); `tools/build-debs.sh`
  adds the time of the last commit in UTC (2779.1.202611272256). Every later commit is an
  upgrade, and an ISO built from a commit matches what the horreum carries for it.
- **Publishing:** `tools/horreum.sh`, run as yourself after committing. It builds anything
  missing, lays out the tree with `apt-ftparchive`, signs it and force-pushes the branch.
  The private key lives in `~/.local/share/armatos/horreum-key`; on a new machine, give it
  once with `tools/horreum.sh --key armatos-horreum-SECRET.asc`. Keep an offline copy: every
  Armatos install trusts this key, so losing it means re-keying them all.

Other sources:

- **Quickshell** is backported from Debian's packaging (0.3.x), since 26.04 doesn't carry it.
- **MangoWC + SceneFX** are packaged from scratch, using Arch's PKGBUILD as the recipe.
- **Proton VPN** comes from Proton's official apt repo (a `socii` ally), as Proton's
  `proton-vpn-gnome-desktop` set: despite the name it brings no GNOME desktop, just the app,
  the CLI, the daemon and keyring support. gnome-keyring holds its sign-in.
- **Discord** comes through `vesta-temple`, an installer package that fetches the official
  `.deb` from Discord at install and update time. Discord's binary is never re-hosted, so it
  isn't on the ISO: a new install fetches it on its first boot with a connection
  (`vesta-temple-first.timer`).
- **On the ISO**, every app on the keybinds: Firefox (with en-GB), foot, VLC, Thunar, ani-cli
  (the horreum's build, newer than Ubuntu's) with mpv and fzf, and Proton VPN.
- **Flatpak** apps are **peregrina**, foreign goods. They are only used when no `.deb`
  exists (for example Sober) and are always labelled as foreign in Forum.

## 4. Tools

| Tool | Role |
|---|---|
| `cursus` | APT wrapper. Takes a `damnatio` snapshot first, then runs apt with Roman voice. |
| `damnatio` | Btrfs snapshots and rollback, also used as an APT pre-invoke hook. |
| `colonia` | The installer: Calamares with QML branding, working offline from the ISO with Wi-Fi up at boot. |
| `census` | Fetch-style system report. |
| `lex` | Policy files (APT pins and similar), numbered like laws. |
| `socii` | Rome's allies: outside APT repositories that keep the laws. Mozilla's, so Firefox is a real .deb built by Mozilla (Ubuntu's `firefox` is a snap shim, pinned out), and Proton's, for Proton VPN; catalogue entries make both show in Forum. |
| Forum | Software market for APT, Flatpak and firmware: KDE Discover's engine (libdiscover over PackageKit, Flatpak and fwupd, rebuilt without QtWebEngine or snap) with Forum's own QML pages in marble and porphyry. |
| Senatus | Settings app, where the laws get passed. |
| `vesta-temple` | Discord installer package. |
| `lapicida` | The stonecutter: writes an ISO to a USB stick. Removable drives only, typed confirmation, read-back verification. |

## 5. Desktop

- **Compositor:** MangoWC.
- **Shell:** Quickshell; the bar is **Titulus**, styled as an inscription band.
- **Workspaces:** Roman numerals I–IX.
- **Colosseum:** the Super+Tab overview, showing windows in an arena ring if
  MangoWC exposes previews to Quickshell, and app icons and titles otherwise.
- **Launcher:** wofi-style, prompting *Ave, Imperator. Quid imperas?*
- **Lock screen:** *porta*, the city gate. *Portae clausae sunt.*

## 6. Look — Marmor

- **Marmor** is the overall theme: veined white marble, gold inlay, Pompeian red for alerts and
  Tyrian purple, with Cinzel for headings.
- **Tribunus** is the GTK3/GTK4 theme. libadwaita is patched and shipped in `italia` so
  Tribunus applies fully. GTK3 Flatpaks get the theme through an extension;
  libadwaita Flatpaks stay mostly stock.
- **Kvantum** carries a matching Qt theme.
- **Art plan:**
  - Atlas city: wallpaper and GRUB
  - Legion on the march: wallpaper
  - White cliffs landing: `colonia` installer background
  - Colosseum aerial: the overview
  - Rome burning: the `damnatio` recovery screen
  - The centurion's shield wall: `centurion`'s portrait

## 7. Voice

Latin by default, with an English toggle in Senatus. Readings (battery VIS, volume SONUS, brightness LUX) show in Roman numerals by default, with a separate ROMANI · ARABICI switch for ordinary numbers. The voice appears only in
interactive use; scripts and logs see normal output.

| Moment | Line |
|---|---|
| Terminal opens | *Ave, Imperator. Legio parata est. Quid imperas?* |
| Command succeeds (long-running) | *Factum est.* |
| Command fails | *Iussum defecit, Imperator. Arcessamne haruspicem?* |
| Unknown command | *Nemo miles hoc nomine respondet.* |
| sudo | *Auctoritas Senatus quaeritur…* |
| Exit | *Vale, Imperator.* |
| Low battery | *Commeatus deficit.* |
| Disk nearly full | *Horreum paene plenum est.* |
| Updates waiting | *Tributum e provinciis advenit.* |
| Wi-Fi lost | *Cursus publicus interruptus est.* |

Other names:

- Trash: the Cloaca Maxima.
- Screenshots: frescoes, saved to `~/Frescoes`.
- Clipboard: the tabula.
- The terminal greeting is the daily **acta**, dated in the Roman calendar.

## 8. Local AI

Every model runs on the laptop through llama.cpp, using the Arc B390. Nothing leaves the machine.

| Name | Role |
|---|---|
| `sibylla` | General assistant |
| `haruspex` | Reads logs and failed commands and explains them |
| `augur` | Quick one-line answers in the terminal |
| `centurion` | Security AI. Reads what the Praetorian Guard (AppArmor + ClamAV) reports, explains each threat, ranks it and asks you. **It never acts on the model's judgement alone.** |
| Lar | Household companion for a bad day. No canned scripts. |

A small model ships on the ISO so the AI works from the first boot. Bigger models come
later with `cursus` or from a USB drive.

## 9. Wellbeing — Otium

| Part | What it does |
|---|---|
| Break reminders | *Tempus est quiescere, Imperator.* |
| Bedtime | *Nox adest. Requiesce.* |
| lucerna | The screen warms to oil-lamp light in the evening |
| Thermae | Ambience: your own rain and thunder soundscapes and meditation tracks |
| Meditations | Guided sessions using Marcus Aurelius, George Long translation (1862, public domain). A daily line also appears in the acta. |

## 10. Roadmap

1. **Foundations:** repo, design, `lex`, `cursus`, `damnatio`, the voice and `vesta-temple`. *Done.*
2. **Provinciae:** package MangoWC + SceneFX, backport Quickshell, set up the APT repo (the horreum). *Done.*
3. **`linux-legio`:** kernel build pipeline.
4. **Marmor:** Titulus, launcher, Tabula, porta, edicta, GRUB and Plymouth *(done)*; Tribunus and Kvantum still to come.
5. **colonia:** Calamares in Marmor; LUKS2 + Btrfs (@, @snapshots), /home on its own encrypted partition (a quarter of the disk to root, 40–128 GiB; the rest to /home), separate plain /boot, greetd autologin. *Built; the system it lays down is tested booting under Secure Boot, the installer's pages still want a full run on hardware.*
6. **The oracles and Lar:** llama.cpp packaging, then `haruspex` first.
7. **Forum** *(done: Discover's engine, Armatos's face)*, then **centurion and Senatus.**
8. **Otium.**

Builds run on the Framework or in Arch WSL, never on the EliteBook natively. Outputs stay on the Linux side.
