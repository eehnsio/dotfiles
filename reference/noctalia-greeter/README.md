# greetd + Noctalia Greeter

> In use since 2026-11-01. Replaces [SDDM + SilentSDDM](../sddm/), which left
> a black screen after every log out: `sddm-helper exited with 63` the same
> millisecond the greeter started, and SDDM never retried. A `sleep 1` before
> weston did not help — the helper died before the sleep was over.

Not a stow package: these files live in `/etc` and `/var/lib` and are owned by
root (or the `greeter` user). The copies here are what to put back on a new
machine.

| File here | Goes to | Owner |
|---|---|---|
| `greetd.conf` | `/etc/greetd/greetd.conf` | `root:root 644` |
| `greeter.toml` | `/var/lib/noctalia-greeter/greeter.toml` | `root:greeter 640` |
| [`../greetd/pam.d-greetd`](../greetd/pam.d-greetd) | `/etc/pam.d/greetd` | `root:root 644` |

The PAM file is shared with the old greetd setup and already in place — its
two `pam_gnome_keyring` lines are greeter-agnostic, which is also what the
Noctalia docs recommend.

`/etc/greetd/greetd.conf` currently holds the nwg-hello config. Installing this
one replaces it; the nwg-hello copy stays in `../greetd/`.

## Setup

```bash
sudo pacman -S noctalia-greeter
sudo noctalia-greeter-apply-appearance --setup-system   # creates greeter.toml + sync.toml
sudo install -m640 -o root -g greeter greeter.toml /var/lib/noctalia-greeter/greeter.toml
sudo install -Dm644 greetd.conf /etc/greetd/greetd.conf
stat -c '%U:%G %a %n' /var/lib/noctalia-greeter /var/lib/noctalia-greeter/greeter.toml /etc/greetd/greetd.conf
```

`/var/lib/noctalia-greeter` must be `greeter:greeter 0750`; the package's
tmpfiles rule creates it like that. A wrong owner is the docs' first cause of a
blank greeter.

Then run **Sync Now** in Noctalia (see *Wallpaper and colours*) so the greeter
gets the Drivis palette.

There is **no test mode** for an installed greeter. Don't improvise one by
starting it on another VT — see "What a wedged GPU looks like" in
`../greetd/README.md`.

## Switch

```bash
sudo systemctl disable sddm && sudo systemctl enable greetd
sudo reboot
```

Reboot, don't `systemctl restart greetd` from inside a session: greetd owns
vt1, so restarting it kills the desktop uncleanly (`../greetd/README.md`).

Then check, in this order:

1. Login form on DP-1 only, Swedish layout — type a password with å/ä/ö in a
   text field first if unsure
2. Both `niri` and `umbriel` in the session list
3. **Log out** — the reason for the switch. The greeter must come back
4. Log in again; the keyring should not ask (`gkr-pam` in the journal)

```bash
journalctl -u greetd -b | grep noctalia-greeter
```

## Rollback

`Ctrl+Alt+F2` gives a text login whatever the greeter does. From there:

```bash
sudo systemctl disable greetd && sudo systemctl enable sddm && sudo reboot
```

SDDM's files are untouched by this setup, so nothing else needs restoring.

## Wallpaper and colours

Not in `greeter.toml` on purpose. Noctalia pushes wallpaper, palette, font and
monitor layout with **Settings → Security → Noctalia Greeter → Sync Now**, into
`sync.toml` and `/var/lib/noctalia-greeter/wallpaper*` — files the greeter user
owns, so nothing in `$HOME` gets opened to it (the dms-greeter mistake,
`../greetd/README.md`). Sync goes through `pkexec`, so it needs Noctalia's
polkit agent.

Synced monitor layout includes the session's transforms, so the portrait VG259
should not end up sideways. `greeter.toml` still wins over anything synced.

## Why it looks like this

- **`name = "DP-1"`** puts the form on the landscape VG27AQM1A and switches the
  other output off at KMS level while the greeter runs. If DP-1 is missing the
  greeter shows the form on *every* connected screen — the same "any monitors,
  any number" rule as `../greetd/`. The docs also accept a stable EDID id
  instead of the connector; `noctalia-greeter outputs --details` prints them,
  but only from a running Wayland session. Worth switching to once measured,
  so a cable swap doesn't move the form.
- **No mode lines.** Same lesson as `niri.kdl`: a mode the screen doesn't offer
  gives a black output instead of a fallback. The docs warn the mode change
  between greeter and session can flash; that is cosmetic.
- **`layout = "se"` spelled out.** The greeter reads `XKBLAYOUT` but ignores
  console-only `KEYMAP`; explicit beats discovery for the one place a password
  is typed.
- **No `[session] default`.** The greeter remembers the last session in
  `sync.toml`.

## Not covered by the docs

Checked 2026-11-01 against docs.noctalia.dev/greeter: nothing on NVIDIA, on
which GPU the compositor picks with an iGPU present, or on required groups for
the `greeter` user. The old greetd setup ran niri as `greeter` on this hardware
without extra groups, so expect the same.
