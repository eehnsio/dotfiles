# spotify

Forces the Spotify client onto native Wayland. Linux only.

The client picks X11 on its own and passes `--ozone-platform=x11` down to its
subprocesses. Neither the launcher, the `.desktop` file, nor
`ELECTRON_OZONE_PLATFORM_HINT` overrides it — that variable is Electron-specific
and the Spotify client is CEF, so it never reads it.

`extra_arguments` in `spotify-launcher.conf` overrides it.

Under XWayland the window is `app_id=Chromium-browser`, a generic class shared
with any other CEF app, and it refuses to be resized. On Wayland it becomes
`app_id=spotify` and behaves normally.

```bash
spotify-launcher -v --skip-update --no-exec   # prints the assembled command
niri msg --json windows | grep app_id
```
