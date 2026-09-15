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

```bash
cargo install --git https://github.com/jmylchreest/xembsni --rev 7de94a2 \
    --locked --root ~/.local xembsni
systemctl --user daemon-reload
systemctl --user enable --now xembsni.service
```

The unit is this package; the binary lands in `~/.local/bin` outside it.

## Behaviour worth knowing

- **No restart needed.** Wine re-docks its icons as soon as a tray owner
  appears: Battle.net, already running with the fallback window, moved into the
  bar the moment the service started.
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
