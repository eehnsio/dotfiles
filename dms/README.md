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

## Plugins

Plugins are installed by DMS itself, not stowed. `plugins.lock.json` pins each
one to an exact commit, the same idea as `lazy-lock.json`:

```bash
dms plugins restore
```

## niri includes

DMS generates KDL fragments for niri. Check whether one is actually loaded:

```bash
dms config resolve-include niri layout.kdl
```

Two are deliberately **not** included — `niri/README.md` explains why.
