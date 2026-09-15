# xembsni

Puts legacy X11 tray icons — Wine/Proton apps such as Battle.net — into the DMS
bar. Linux only.

## The problem

Wine still speaks the old XEmbed system-tray protocol. On niri nothing owns the
X11 tray selection, so Wine falls back to drawing its own tray: a small floating
window with an empty title and app-id `steam_app_default`, dropped in the middle
of the screen. niri has no minimize, so it cannot be tucked away, and a window
rule can at best push it into a corner.

[xembsni](https://github.com/jmylchreest/xembsni) takes the
`_NET_SYSTEM_TRAY_S0` selection, embeds the icons and republishes each one as a
StatusNotifierItem, which the DMS bar already hosts. Right-click menus are
forwarded back to the app.

## Install

Not packaged anywhere, so the binary is built from a **pinned commit**. That
commit was read through before it was run (no process spawning, no network, no
file writes, `unsafe` forbidden); move the pin deliberately, not by habit.

It is built with one local patch,
[`container-1x1.patch`](../reference/xembsni/container-1x1.patch) — see below
for why. Check that it still applies whenever the pin moves.

```bash
src=$(mktemp -d)
git clone https://github.com/jmylchreest/xembsni "$src"
git -C "$src" checkout 7de94a2
git -C "$src" apply ~/Developer/dotfiles/reference/xembsni/container-1x1.patch
cargo install --locked --root ~/.local --path "$src/crates/xembsni"
systemctl --user daemon-reload
systemctl --user enable --now xembsni.service
```

The unit is this package; the binary lands in `~/.local/bin` outside it. The
patch lives under `reference/` because anything inside this package would be
stowed into `$HOME`.

## The icon stuck to another window

Unpatched, a copy of the tray icon sits on the top-left corner of some other
window — Steam, usually — on top of the one in the bar.

xembsni parks each icon in a 20×20 override-redirect container at
`-16000,-16000`, trusting that nothing draws that far off screen. xwayland-satellite
does not work that way: it maps every override-redirect X window as an
`xdg_popup` on the last hovered or focused toplevel, and the positioner slides
it back into view. The container ends up pinned to whichever window that was
when the icon docked.

The patch makes the container 1×1. The icon itself keeps its size, and since a
composite-redirected window is not clipped by its parent, the captured image is
unchanged — measured byte-identical in the bar before and after. One pixel is
left on screen, where the icon used to be.

## Wine's own tray window

While no tray owner exists — before the service is up, or for the second it
restarts — Wine opens its fallback tray again: a white 160×20 window that stays
behind even after the icon re-docks. Closing it hides it until the app exits.

`ShowSystray=0` stops it from ever showing. Wine still docks into the bar, and
re-docks when a tray owner appears; only the standalone window is gone. It is
read when the prefix starts, and it is **per prefix**, so every Faugus prefix
with a tray icon needs it:

```bash
WINEPREFIX=~/Faugus/battlenet PROTONPATH="Proton-CachyOS Latest" \
    ~/.local/share/faugus-launcher/umu-run \
    reg add 'HKCU\Software\Wine\Explorer' /v ShowSystray /t REG_DWORD /d 0 /f
```

The trade-off: with the service down, the icon is nowhere at all.

## Behaviour worth knowing

- **No restart needed.** Wine re-docks its icons as soon as a tray owner
  appears, and the app keeps running through it.
- **Start order with DMS does not matter.** The bridge watches for
  `org.kde.StatusNotifierWatcher` and re-registers every item when it appears,
  so the unit has no `After=` on the bar.
- **The bar tooltip says `steam_app_default`.** Every app launched through
  umu/Faugus shares that WM class, so it is not a useful name, but it is what
  the app reports.

## Checking it

```bash
journalctl --user -u xembsni -f      # "embedded icon" + "published item"
busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
    org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems
```

`RUST_LOG=debug` in the unit for more. If an icon does not react to clicks, that
is the known limit: interactions are sent with `XSendEvent`, which a few apps
ignore.
