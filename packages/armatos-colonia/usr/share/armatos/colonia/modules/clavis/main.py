#!/usr/bin/env python3
# clavis — the house key.
#
# colonia puts /home (and any other encrypted data partition) in its own
# LUKS2 container, next to an encrypted root and a plain /boot. Calamares'
# own keyfile step (luksbootkeyfile) stands aside when /boot is plain, which
# would leave a second passphrase prompt at every boot.
#
# So for each encrypted partition other than root, this job cuts a random key
# into the target's /etc/cryptsetup-keys.d/<mapper>.key (inside the encrypted
# root, readable only by root), enrols it in that container with the
# passphrase the Imperator chose, and names it in /etc/crypttab. At boot the
# root is unlocked with the passphrase as before, and systemd-cryptsetup then
# opens /home with the key: one passphrase, as ever.
#
# If root itself is not encrypted, nothing is done: a key on a plain root
# would be no lock at all, so /home keeps asking.

import os
import subprocess

import libcalamares

KEY_DIR = "etc/cryptsetup-keys.d"


def pretty_name():
    return "Cutting the key to /home"


def _key_path(mapper):
    return "/" + KEY_DIR + "/" + mapper + ".key"


def _name_key_in_crypttab(root, mapper, luks_uuid):
    """Point the container's crypttab line at its key, adding one if Calamares
    wrote none."""
    path = os.path.join(root, "etc", "crypttab")
    lines = []
    if os.path.exists(path):
        with open(path) as f:
            lines = f.read().splitlines()
    found = False
    for i, line in enumerate(lines):
        fields = line.split()
        if fields and not fields[0].startswith("#") and fields[0] == mapper:
            while len(fields) < 4:
                fields.append("luks" if len(fields) == 3 else "none")
            fields[2] = _key_path(mapper)
            lines[i] = " ".join(fields)
            found = True
    if not found:
        lines.append(" ".join([mapper, "UUID=" + luks_uuid, _key_path(mapper), "luks,discard"]))
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


def run():
    root = libcalamares.globalstorage.value("rootMountPoint")
    partitions = libcalamares.globalstorage.value("partitions") or []
    if not root:
        return ("The new system is not mounted", "clavis needs the target's root to keep the key in.")

    root_part = next((p for p in partitions if p.get("mountPoint") == "/"), None)
    if not root_part or not root_part.get("luksMapperName"):
        libcalamares.utils.debug("clavis: root is not encrypted; leaving other containers to ask.")
        return None

    for part in partitions:
        mapper = part.get("luksMapperName")
        if not mapper or part.get("mountPoint") in ("/", "/boot", None, ""):
            continue
        device = part.get("device")
        passphrase = part.get("luksPassphrase")
        if not device or not passphrase:
            libcalamares.utils.warning("clavis: no device or passphrase for " + str(part.get("mountPoint")))
            continue

        key_dir = os.path.join(root, KEY_DIR)
        os.makedirs(key_dir, mode=0o700, exist_ok=True)
        os.chmod(key_dir, 0o700)
        key_file = os.path.join(key_dir, mapper + ".key")
        fd = os.open(key_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o400)
        with os.fdopen(fd, "wb") as f:
            f.write(os.urandom(512))
        os.chmod(key_file, 0o400)

        # The key is 4096 random bits, so a slow key-derivation buys nothing;
        # a quick one keeps /home from adding seconds to every boot.
        try:
            result = subprocess.run(
                ["cryptsetup", "luksAddKey", "--batch-mode", "--pbkdf", "pbkdf2", "--iter-time", "200",
                 "--key-file=-", device, key_file],
                input=passphrase.encode(), capture_output=True)
            failure = None if result.returncode == 0 else (
                result.stderr.decode(errors="replace").strip() or "cryptsetup luksAddKey failed.")
        except OSError as e:
            failure = "Could not run cryptsetup: " + str(e)
        if failure:
            os.unlink(key_file)
            return ("Could not cut the key to " + part["mountPoint"], failure)

        _name_key_in_crypttab(root, mapper, part.get("luksUuid", ""))
        libcalamares.utils.debug("clavis: " + part["mountPoint"] + " now opens with " + _key_path(mapper))

    return None
