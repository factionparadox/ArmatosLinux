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
| Filesystem | Btrfs root with `@` and `@home` subvolumes, for `damnatio` |
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

Armatos runs its own APT repository, split into the following components:

| Component | Contents |
|---|---|
| `italia` | Core Armatos packages (tools, themes, kernel) |
| `provinciae` | Extra software we package ourselves: MangoWC, SceneFX, Quickshell backport, wlroots if needed |
| `barbaricum` | Non-free firmware and blobs |

Other sources:

- **Quickshell** is backported from Debian's packaging (0.3.x), since 26.04 doesn't carry it.
- **MangoWC + SceneFX** are packaged from scratch, using Arch's PKGBUILD as the recipe.
- **Proton VPN** comes from Proton's official apt repo, installed without the GNOME metapackage.
- **Discord** comes through `vesta-temple`, an installer package that fetches the official
  `.deb` from Discord at install and update time. Discord's binary is never re-hosted.
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
| Forum | GUI store for APT and Flatpak (PackageKit + libflatpak + AppStream, GTK4). |
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
2. **Provinciae:** package MangoWC + SceneFX, backport Quickshell *(done)*; set up the APT repo.
3. **`linux-legio`:** kernel build pipeline.
4. **Marmor:** Titulus, launcher, Tabula, porta, edicta, GRUB and Plymouth *(done)*; Tribunus and Kvantum still to come.
5. **colonia:** Calamares in Marmor; LUKS2 + Btrfs (@, @home, @snapshots), separate plain /boot, greetd autologin. *Built; the system it lays down is tested booting under Secure Boot, the installer's pages still want a full run on hardware.*
6. **The oracles and Lar:** llama.cpp packaging, then `haruspex` first.
7. **centurion, Forum and Senatus.**
8. **Otium.**

Builds run on the Framework or in Arch WSL, never on the EliteBook natively. Outputs stay on the Linux side.
