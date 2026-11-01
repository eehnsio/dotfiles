# umbriel

Second Wayland session next to niri, from the Noctalia project. Linux only.
Both sessions show up in the greeter, which remembers the last one picked —
niri stays untouched as the fallback.

Why try it at all, when niri is stable: the portrait VG259 scrolls **down**
(`workspace_axis = "horizontal"`), which niri cannot do
([niri-wm/niri#1071](https://github.com/niri-wm/niri/issues/1071), open since
2025). Plus HDR, tearing control, pointer confinement for games, scratchpad.

## Install

```bash
sudo pacman -S wlroots0.20          # already there: noctalia-greeter needs it
paru -S umbriel-git xdg-desktop-portal-umbriel-git
```

It is a C++ build that takes every core — not during a game.

**Pin it** right after, next to the NVIDIA packages in `/etc/pacman.conf`:

```
IgnorePkg = … umbriel-git xdg-desktop-portal-umbriel-git
```

paru has `Devel` on, so without the pin every `paru -Syu` rebuilds it on each
upstream commit — slow, and a failed build stops the whole upgrade. Update on
purpose with `paru -S umbriel-git xdg-desktop-portal-umbriel-git`, which
ignores `IgnorePkg`.

`~/.config/umbriel/` must exist as a real directory before stow, like
`~/.config/noctalia`, so the file links on its own.

## The config

`config.toml` **replaces** upstream's `/usr/share/umbriel/config.toml` — it is
a fallback path, not a base that gets merged. So what upstream had active is
copied in (blur, Noctalia's window and layer rules, the overview hot corner),
next to our own settings. `[keybinds]` likewise replaces the built-in set, so
every bind is listed; they mirror niri's on purpose, so switching session
doesn't mean switching muscle memory. After an Umbriel update, diff against
upstream's file for new defaults.

Live reload on save; a broken file keeps the last good one. Always:

```bash
umbriel config validate        # also: umbriel config schema --json
tail ~/.cache/umbriel/umbriel.log
```

Things learned 2026-11-01:

- **Outputs need explicit modes.** Umbriel takes each screen's *preferred*
  mode, which is 60 Hz on both — it felt sluggish next to niri until DP-1 got
  240 and DP-2 144.
- **`center_underfull_strip = false`**, or a lone half-width window sits in
  the middle of the screen.
- **No relative workspace switch.** `workspace-switch next` is rejected; the
  PgUp/PgDn and scroll binds use `window-focus-or-workspace-*` instead.
- **`spawn` runs through a shell**, so `pkill … || rofi …` works as-is.
- **Regex has no `(?i)`** — pinentry matches `^[Pp]inentry`.
- **Dwindle as default was tried and dropped**: a game opened next to another
  window gets half the screen. Scrolling it is; `umbriel msg
  workspace-set-layout dwindle` per workspace when wanted.
- **`Mod+Escape` quits the session.** Remember it before trying anything new.

## Not ported from niri

- `Mod+§` window cycling — `niri-cycle-app-windows` talks to `niri msg`
- `Mod+Shift+M` (fill screen, stay floating), `Mod+Ctrl+F` (expand to
  available width) — no direct equivalents found
- Screenshots are Noctalia's (`noctalia msg screenshot-*`), not built in
