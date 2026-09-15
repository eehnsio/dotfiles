# dms

DankMaterialShell: the theme, and a lockfile pinning installed plugins.

## Drivis

`themes/drivis/theme.json` is pointed at by `customThemeFile` in the shell's own
settings, which are **not** in this repo. Set it once per machine:

```bash
dms ipc call settings set customThemeFile ~/.config/DankMaterialShell/themes/drivis/theme.json
dms ipc call settings set currentThemeName custom
```

The accent is `#7fc8ff` — the same blue as niri's focus ring. Surfaces are
near-neutral greys on purpose: the blue is what points, so nothing else should
compete with it. That was the fix for a setup that felt "too blue" while still
wanting a blue accent.

## Cursor

Bibata Modern Ice, unpacked straight into `~/.local/share/icons` — a user-level
install with no package manager involved, so it needs no root and travels with
the same one-liner on any machine:

```bash
curl -fsSL https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz \
    | tar -xJ -C ~/.local/share/icons
```

DMS keeps the choice in `cursorSettings.theme`, in the settings that are not in
this repo. IPC rejects that key (`SETTINGS_INVALID_KEY`), so it is Settings →
Personalization, or `jq` on `settings.json` — the running shell picks the file
change up either way and regenerates `~/.config/niri/dms/cursor.kdl`. niri then
exports `XCURSOR_THEME` to everything it spawns.

Apps started by a portal or D-Bus activation never see that variable, so
gsettings needs the same answer:

```bash
gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice
```

Already-running apps keep the old cursor until they restart.

## Plugins

Plugins are installed by DMS itself, not stowed. `plugins.lock.json` pins each
one to an exact commit, the same idea as `lazy-lock.json`:

```bash
dms plugins restore
```

## Greeter

The login screen is dms-greeter under greetd, with no autologin so the password
unlocks the keyring. Its files live in `/etc` — copies and the reasoning are in
[reference/greetd](../reference/greetd/).

## niri includes

DMS generates KDL fragments for niri. Check whether one is actually loaded:

```bash
dms config resolve-include niri layout.kdl
```

Two are deliberately **not** included — `niri/README.md` explains why.
