# Wine tray icons under niri

Why Wine/Proton apps draw a stray white window on this machine, and the one
registry key that stops it. Reference only — nothing here is stowed.

## The white 160×20 window

Wine still speaks the old XEmbed system-tray protocol. On niri nothing owns the
X11 tray selection `_NET_SYSTEM_TRAY_S0`, so Wine falls back to drawing its own
tray: a small window with an empty title and app-id `steam_app_default`, dropped
into the layout. niri has no minimize, so it cannot be tucked away, and closing
it only hides it until the app exits.

`ShowSystray=0` stops it from ever being created. It is read when the prefix
starts and it is **per prefix**, so every Faugus prefix with a tray icon needs
it:

```bash
WINEPREFIX=~/Faugus/battlenet PROTONPATH="Proton-CachyOS Latest" \
    ~/.local/share/faugus-launcher/umu-run \
    reg add 'HKCU\Software\Wine\Explorer' /v ShowSystray /t REG_DWORD /d 0 /f
```

This key is **load-bearing**. With no tray owner running and `ShowSystray=0`
set, Wine has nowhere to put an icon and never draws one — that is the quiet
state this machine wants. Remove the key and the stray window comes back.

## Close-to-tray is a trap without a tray

Battle.net's Settings → General → *When I close Battle.net* can keep the app
running in the system tray. With no tray that makes it unreachable: still
running, no window, no icon. Set it to exit completely.

The same applies to any Wine app with that option. It is not a niri bug — niri
has no minimize, so an always-open window is the normal state and a tray icon
has no job to do.

## We used to bridge these icons — 2026-09-17, removed

[xembsni](https://github.com/jmylchreest/xembsni) took the tray selection,
embedded the icons and republished each one as a StatusNotifierItem for the DMS
bar. It was a stow package here (`xembsni/`) with a local patch under
`reference/xembsni/`. Both are gone; `git show 40c7f8e` and `git show e1585f6`
have them if they are ever wanted back.

It was removed because the icons were not worth their cost:

- **Nothing but Battle.net ever used it.** Five embeds in the whole journal
  history, every one `app=steam_app_default` — the WM class shared by
  everything launched through umu/Faugus.
- **A tray icon has no job under niri.** No minimize means the app is always a
  window, so the icon duplicates something already on screen.
- **It cost a pinned-commit `cargo` build** plus a local patch to keep applying,
  and a source review each time the pin moved.
- **It kept producing window bugs.** xembsni parks each icon in an
  override-redirect container at `-16000,-16000`. xwayland-satellite maps
  override-redirect windows as `xdg_popup`s on the last hovered or focused
  toplevel and slides them back into view, so the container turned up stuck to
  the corner of another window. The patch shrank it to 1×1, which fixed that —
  but the container is sometimes mapped as a plain **toplevel** instead, and
  niri then tiles it to full column width: a black half-screen window with the
  20×20 icon in its corner.

  That last one had no clean fix. `host.rs`'s `embed()` creates the container
  with neither `WM_CLASS` nor `WM_NAME`, and niri cannot match a window that has
  no app-id *and* no title — `src/window/mod.rs:412-427` (v26.04) returns
  `false` for both patterns when the property is absent, and every other match
  criterion is state-based and would catch all windows. Making it matchable
  would have meant extending the patch to set `WM_CLASS`.

If tray icons are ever needed again — Steam is installed and has never docked
one here, but another Wine app might — that patch is the way, not the 1×1 one.

## Re-docking, if a bridge ever comes back

While a tray owner exists, Wine docks into it at app start. It does **not**
re-dock afterwards when `ShowSystray=0` is set: restarting the bridge under a
running app leaves the icon gone until the app itself restarts. Measured
2026-09-17 — with the key unset a bridge restart re-docked within the same
second, with it set nothing came back at all.
