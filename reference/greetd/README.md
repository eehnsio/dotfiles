# greetd + nwg-hello

Not a stow package: these files live in `/etc` and are owned by root. The copies
here are what to put back on a new machine, and this file is why they look the
way they do.

| File here | Goes to |
|---|---|
| `greetd.conf` | `/etc/greetd/greetd.conf` |
| `niri.kdl` | `/etc/nwg-hello/niri.kdl` |
| `nwg-hello.json` | `/etc/nwg-hello/nwg-hello.json` |
| `nwg-hello.css` | `/etc/nwg-hello/nwg-hello.css` |
| `pam.d-greetd` | `/etc/pam.d/greetd` |

All of them must end up `root:root 644`. Check with `stat` after editing: a
greetd config owned by your own user would let you set `user = "root"` on the
greeter.

## Setup

```bash
sudo pacman -S nwg-hello gnome-keyring
sudo cp greetd.conf /etc/greetd/
sudo cp niri.kdl nwg-hello.json nwg-hello.css /etc/nwg-hello/
```

The wallpaper is not in this repo — it is derived, so regenerate it instead of
committing 10 MB of PNG:

```bash
ffmpeg -i ~/Pictures/Wallpapers/Louise_Mac.png -vf scale=2560:-1 -q:v 3 /tmp/wallpaper.jpg
sudo cp /tmp/wallpaper.jpg /etc/nwg-hello/
```

It has to live in `/etc` and not `~/Pictures`. The greeter runs as the user
`greeter` and cannot read your home — see *What we left behind* below.

Then **reboot** rather than log out. greetd reads its config only when the
service starts, and the systemd user manager survives a log out, so a log out
just brings the *old* greeter back. Verify which one actually ran:

```bash
journalctl -b -u greetd | grep -i nwg-hello    # no hits means greetd never reloaded
systemctl show greetd -p ActiveEnterTimestamp  # compare against `uptime -s`
```

`nwg-hello.json` is different: nwg-hello reads it every time it starts, so
changes there show up on a plain log out.

While iterating you do not need a reboot at all — `sudo systemctl restart greetd`
re-reads `greetd.conf` and relaunches the greeter, and `sudo chvt 1` switches to
it. greetd only owns vt1, so a shell on another VT survives both.

## greetd.conf, not config.toml

greetd looks for `/etc/greetd/greetd.conf` **before** `/etc/greetd/config.toml`
— both strings are in the binary. This is not in greetd's own docs; it comes
from nwg-hello's README.

It matters because a `greetd` package upgrade overwrites `config.toml` and
renames yours to `config.toml.pacsave`, which silently restores `agreety`.
Keeping the real config in `greetd.conf` survives that.

It also makes the rollback a deletion: `sudo rm /etc/greetd/greetd.conf` falls
through to whatever `config.toml` says.

## No autologin

`[initial_session]` is gone on purpose. With autologin there is no password, so
`pam_gnome_keyring` has nothing to unlock the login keyring with — every boot
logs `gkr-pam: couldn't unlock the login keyring` and Bitwarden (or anything else
using Secret Service) asks for it again. Typing the password into the greeter
unlocks it for free. The disk is not encrypted either, so autologin meant anyone
at the machine was straight in.

The two `pam_gnome_keyring` lines are the only change to the stock PAM file.
They are `optional`, so a broken keyring can never block a login. They are also
**greeter-agnostic** — `/etc/pam.d/greetd` applies whichever greeter runs, which
is why swapping greeters did not touch the keyring at all.

`rbw` does not benefit from this. It has its own agent that dies with the
session and asks for the master password on first use — the keyring is for the
Bitwarden *desktop app*. See `rbw/README.md`.

## The hard requirement: any monitors, any number

This machine changes monitors — count and maximum resolution both. **The greeter
must let you log in regardless.** Two rules follow, and both were learned the
expensive way on 2026-09-17.

### No `mode` lines in niri.kdl

A mode the screen does not offer makes niri leave the output **dark** rather than
fall back. With `mode "2560x1440@240.001"` in this file the landscape screen went
black, and because only one output came up, the login form pointed at a monitor
index that no longer existed — wallpaper on one screen, no form anywhere, and no
way in except a text console.

Without the line niri takes each screen's preferred mode, which always exists.
The greeter does not need a high refresh rate; the session's `local.kdl` is where
240 Hz belongs.

The `output` blocks themselves can stay. They match on EDID, so a block with no
matching screen is ignored silently — they disable themselves on other hardware.
That is also why the portrait screen can keep its `transform "90"` here: without
it that wallpaper lies on its side, and with it nothing breaks elsewhere.

### `form_on_monitors: []` — the form on every screen

`monitor_nums` and `form_on_monitors` take **GDK monitor indices**. There is no
matching on name, model or EDID, and an index is not stable when the number or
order of screens changes — which is exactly the requirement above.

So the choice is either *works with any monitors* or *form on exactly one
screen*, not both. The requirement wins: `[]` puts the form on every screen that
comes up, and nothing can point it at a monitor that is not there.

If you ever want it on one screen anyway, the indices are measurable — but
measure, never guess, and know it breaks the next time you swap a cable:

```bash
python3 -c '
import gi; gi.require_version("Gdk","3.0")
from gi.repository import Gdk
d = Gdk.Display.get_default()
for i in range(d.get_n_monitors()):
    m = d.get_monitor(i); g = m.get_geometry()
    print(i, f"{g.width}x{g.height} @ {g.x},{g.y}", m.get_model())'
```

Measured 2026-09-17 with both screens up: 0 was the portrait VG259, 1 the
landscape VG27AQM1A. Index 0 looks like the obvious default and was wrong.

The keyboard layout needs `se` spelled out in `niri.kdl` — the password is typed
here, and a wrong layout is indistinguishable from a wrong password.

## What a wedged GPU looks like

Worth recognising, because it sent me down the wrong path for an hour. After the
NVIDIA 610 → 615 upgrade, `2560x1440` vanished from
`/sys/class/drm/card1-DP-1/modes` entirely — the screen's own native mode. It
looked exactly like a driver regression dropping DSC.

It was not. Starting a second niri instance on another VT while the greeter held
the first one deadlocked the driver:

```
nvidia-modeset/:282   blocked 368s on a semaphore held by kworker/2:1
systemd-logind:605    blocked on a mutex held by the same kworker
Tainted: G  OE
```

A `D`-state kernel thread cannot be killed, and with logind wedged **nothing can
log in** — SSH authenticates and then hangs in `[postauth]`, because
`pam_systemd` never returns. A clean reboot brought both the native mode and
logind back; no rollback was needed.

The tell is one command:

```bash
ps -eo pid,stat,comm | awk '$2 ~ /D/'     # anything here means reboot, not config
```

Do not run a second compositor on another VT while the greeter is up.

## Why niri.kdl exists at all

nwg-hello needs a compositor to run in and ships configs for sway, hyprland and
labwc — **not** niri. `niri.kdl` is ours, following their pattern: set up the
outputs, run the greeter, exit when it exits.

```kdl
spawn-at-startup "sh" "-c" "nwg-hello; niri msg action quit -s"
```

Without the `quit`, greetd sits waiting on a compositor with nothing left to
show. `-s` skips niri's "Press Enter to confirm" prompt.

## No Swedish

nwg-hello ships 15 locales and `sv` is not among them, so the greeter is in
English. The system locale is `en_US.UTF-8` anyway, so it matches the rest of the
machine. `X11 Layout: se` is unaffected — that is the keymap, not the language.

## What we left behind — 2026-09-17

dms-greeter is gone. It worked, but it had two problems that nwg-hello does not:

1. **It drew a full login surface on every screen with no way to opt out.** The
   workaround was `/etc/greetd/niri_overrides.kdl`, which ran
   `niri msg output … off` at greeter startup to blank the portrait screen — a
   black screen instead of wallpaper. `form_on_monitors` replaces it.
2. **`dms-greeter sync` handed the `greeter` group read access to `$HOME`.** It
   set ACLs on `~/.config`, `~/.cache` and `~/.local/state`'s
   `DankMaterialShell` directories, **with default ACLs so new files inherited
   them**, and every `sync` could redo it. That covered the clipboard history,
   which holds every password copied from the Bitwarden desktop app — Bitwarden
   does not set `x-kde-passwordManagerHint`, the one mime type DMS refuses to
   store.

   Cleared with:

   ```bash
   for d in ~/.config/DankMaterialShell ~/.cache/DankMaterialShell \
            ~/.local/state/DankMaterialShell; do
       setfacl -R -b "$d" && chgrp -R "$USER" "$d"
   done
   chmod 700 ~/.cache/DankMaterialShell/clipboard
   chmod 600 ~/.cache/DankMaterialShell/clipboard/db
   ```

   Nothing re-creates them now, because nothing runs as `greeter` inside
   `$HOME` any more. That is why the wallpaper is copied into `/etc`.

DMS itself stays — it is still the shell, the notification server, the polkit
agent and the lock screen. Only the greeter changed.

The KDL quirk that used to matter here is gone with dms-greeter: it parsed
`~/.config/niri` with its own parser that choked on node names starting with
`_`, which is why `__GL_SHADER_DISK_CACHE_SIZE` is quoted in niri's
`environment` block. The quotes are harmless, so they stay.

## When it breaks

`Ctrl+Alt+F2` gives a text login even if the greeter never starts. From there,
in order of bluntness:

```bash
sudo rm /etc/greetd/greetd.conf                # fall through to config.toml
sudo systemctl restart greetd                  # no reboot needed
```

`greetd-agreety` is installed as a text fallback. The machine also answers on
`ssh erik@192.168.1.232`, which is the better route — you can fix greetd from
the Mac without touching the console.

A greeter that starts but with a dead keyboard is a different problem — see
`xremap/README.md`.
