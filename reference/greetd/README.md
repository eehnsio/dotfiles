# greetd + DMS greeter

Not a stow package: these files live in `/etc` and are owned by root. The copies
here are what to put back on a new machine, and this file is why they look the
way they do.

| File here | Goes to |
|---|---|
| `config.toml` | `/etc/greetd/config.toml` |
| `niri_overrides.kdl` | `/etc/greetd/niri_overrides.kdl` |
| `pam.d-greetd` | `/etc/pam.d/greetd` |

All three must end up `root:root 644`. Check with `stat` after editing: a greetd
config owned by your own user would let you set `user = "root"` on the greeter.

## Setup

```bash
paru -S greetd-dms-greeter-bin gnome-keyring
dms-greeter enable     # points greetd at dms-greeter, sets ACLs and the greeter group
dms-greeter sync       # links theme, wallpaper and settings; writes /etc/greetd/niri/
```

Then install the three files, and **reboot** rather than log out. greetd reads
its config only when the service starts, and the systemd user manager survives a
log out, so neither the new greeter nor the `greeter` group shows up until then.
`dms-greeter status` should be all green afterwards.

## No autologin

`[initial_session]` is gone on purpose. With autologin there is no password, so
`pam_gnome_keyring` has nothing to unlock the login keyring with — every boot
logs `gkr-pam: couldn't unlock the login keyring` and Bitwarden (or anything else
using Secret Service) asks for it again. Typing the password into the greeter
unlocks it for free. The disk is not encrypted either, so autologin meant anyone
at the machine was straight in.

The two `pam_gnome_keyring` lines are the only change to the stock PAM file.
They are `optional`, so a broken keyring can never block a login.

## Which screen gets the login box

The greeter puts the input on `Quickshell.screens[0]` — the first output niri
announces, which is **connector order** on the GPU. It ignores the lock screen
monitor set in DMS. The portrait VG259 used to sit in DP-2 ahead of the landscape
screen in DP-3, so the box landed on the portrait screen.

The fix was a cable: the landscape screen is now in DP-1. Nothing else needed to
change, because outputs are named by EDID everywhere (see `niri/README.md`), and
DMS matches its screen preferences on model.

## Only one screen

The greeter draws a full login surface on every screen, with no setting to leave
one out. `niri_overrides.kdl` turns the portrait screen off for the greeter only:

- An `output … { off }` block does **not** work. The generated greeter config
  already has a block for that screen, and niri uses the first matching block.
- `niri msg output … off` at startup does, and it matches the EDID name. The
  session's niri starts afterwards with its own config, so the screen comes back
  on at login.

The trade-off is a black portrait screen instead of wallpaper. Wallpaper-only on
the second screen would need a change in the greeter itself.

`dms-greeter sync` leaves the overrides file alone.

## The KDL quirk

`dms-greeter sync` builds the greeter's niri config by parsing `~/.config/niri`
with its own KDL parser, which stops at a node name starting with `_`. When it
fails it writes no greeter config at all — and the greeter falls back to niri's
defaults, US layout included, which is how a password with `å ä ö` stops
working. That is why `__GL_SHADER_DISK_CACHE_SIZE` is quoted in niri's
`environment` block.

## When it breaks

`Ctrl+Alt+F2` gives a text login even if the greeter never starts. From there:

```bash
sudo cp /etc/greetd/config.toml.bak /etc/greetd/config.toml   # or a backup-* file
```

A greeter that starts but with a dead keyboard is a different problem — see
`xremap/README.md`.
