# SDDM + SilentSDDM

Not a stow package: these files live in `/etc` and `/usr/share` and are owned by
root. Replaces [greetd + nwg-hello](../greetd/), which is kept as the fallback.

| File here | Goes to |
|---|---|
| `silent.conf` | `/etc/sddm.conf.d/silent.conf` |
| `weston.ini` | `/etc/sddm/weston.ini` |
| `drivis.conf` | `/usr/share/sddm/themes/silent/configs/drivis.conf` |
| `pam.d-sddm` | `/etc/pam.d/sddm` |

All of them `root:root 644`.

## Setup

```bash
sudo pacman -S --needed sddm weston qt6-virtualkeyboard qt6-multimedia-ffmpeg
paru -S sddm-silent-theme

sudo install -Dm644 silent.conf /etc/sddm.conf.d/silent.conf
sudo install -Dm644 weston.ini  /etc/sddm/weston.ini
sudo install -Dm644 drivis.conf /usr/share/sddm/themes/silent/configs/drivis.conf
sudo install -Dm644 pam.d-sddm  /etc/pam.d/sddm
sudo install -Dm644 /etc/nwg-hello/wallpaper.jpg /usr/share/sddm/themes/silent/backgrounds/drivis.jpg
sudo sed -i 's|^ConfigFile=.*|ConfigFile=configs/drivis.conf|' /usr/share/sddm/themes/silent/metadata.desktop
```

The wallpaper is the same derived JPEG the greetd setup uses — see
[its README](../greetd/README.md#setup) to regenerate it. It must sit in the
theme's `backgrounds/`; the theme resolves `background =` relative to that.

`metadata.desktop` is in the package's `backup=` array, so the `ConfigFile=` edit
survives upgrades (pacman writes `.pacnew` instead). `drivis.conf` and
`drivis.jpg` are not owned by the package and are left alone.

**Test before switching** — a broken theme means a broken login screen:

```bash
cd /usr/share/sddm/themes/silent && timeout 20 ./test.sh   # never logs in
```

Test mode **cannot** log in: entering a password leaves the "Loggar in" spinner
running forever, and the greeter keeps the keyboard. That is not a hang. End it
with `pkill -f sddm-greeter-qt6` from another terminal or over SSH — hence the
`timeout`. Do not start a second niri on another VT to get out: ghostty is
single-instance over D-Bus, so launching it there opens the window in the
*first* session, and the second one looks like ghostty is broken. Since
`test.sh` sends all output to `/dev/null`, use `./test.sh debug` to see errors.

Then switch and reboot:

```bash
sudo systemctl disable greetd && sudo systemctl enable sddm
```

## Rollback

`Ctrl+Alt+F2` gives a text login whatever the greeter does. From there:

```bash
sudo systemctl disable sddm && sudo systemctl enable greetd && reboot
```

## Why it looks like this

- **Wayland under weston.** There is no Xorg on this machine, and SDDM's greeter
  needs a compositor. `weston --shell=kiosk` is the smallest one that works;
  kwin would pull in half of Plasma.
- **`weston.ini` sets `se`.** The password is typed here, and a wrong layout is
  indistinguishable from a wrong password — same lesson as `niri.kdl` in the
  greetd setup.
- **The empty `LIBVA_DRIVER_NAME=` / `QT_MULTIMEDIA_PREFERRED_PLUGINS=`** are the
  theme wiki's fix for the greeter segfaulting on Nvidia. Harmless when not
  needed.
- **`drivis.conf` is a full copy of `default.conf`**, palette and Swedish
  strings edited in. The wiki says missing keys fall back to the defaults; they
  do not. 74 of the 205 keys in `components/Config.qml` have no fallback and
  become `0`/`""`/`false`. A preset with only the overrides put the login box at
  the very top of the screen: `LoginArea/margin` became `0` ("pin to top")
  instead of `-1` ("center"). After a theme upgrade, diff `default.conf` for new
  keys. Strings must be double-quoted (SilentSDDM issue #77).
- **No `QT_WAYLAND_SHELL_INTEGRATION=layer-shell`**, although the theme wiki
  suggests it for the virtual keyboard. The plugin comes from `layer-shell-qt`,
  which is not installed, so the greeter aborted on the first boot
  (2026-10-08) before drawing anything. `test.sh` never sets it, which is why
  the test passed. Weston's kiosk shell is fine with the default xdg-shell.
- **No ~2 s delay on a wrong password.** `pam_unix` waits ~2 s after a failure
  unless given `nodelay`. Putting that in `system-auth` would drop the delay for
  sudo, su and ssh too, so `pam.d-sddm` writes out the auth stack from
  `system-login` + `system-auth` instead of including it, with `nodelay` on the
  one line. faillock (`deny = 10`, 60 s) still limits guessing. The `[success=N]`
  jumps count lines — keep the order, and re-sync if `pambase` changes those
  files. `/etc/pam.d/sddm` is a `backup=` file, so upgrades leave it alone.
- **Keyring** needs nothing: Arch's `/etc/pam.d/sddm` already has the
  `pam_gnome_keyring` lines.

## Not fixed by switching greeter

- **Black gap after login** is niri and noctalia starting.
