# ghostty

Terminal emulator config, including the cursor shader.

`config.local` is gitignored and seeded from `config.local.example` by
`./install`. It loads last, so it overrides everything tracked here. The `?`
prefix on the include makes it optional, unlike niri which refuses to start when
an include is missing.

Per-machine font size lives there. If two monitors have different pixel density
the better fix is usually compositor scaling, but **the scale must be at least 1
on every output**: Chromium clamps its scale factor there and draws Electron
apps at the wrong size below it. When the displays cannot be matched within that
constraint, `font-size` here is the way out — and Ghostty also resizes per
window on the fly with `ctrl++`, `ctrl+-` and `ctrl+0`.

## Ctrl+C / Ctrl+V on Linux

Linux terminals copy and paste with `ctrl+shift+c/v`, because `ctrl+c` is the
interrupt and `ctrl+v` is literal-next. `Super+C/V` cannot fill in either: niri
binds `Mod+C` and `Mod+V` itself, so the keys never reach Ghostty. That leaves
the terminal as the one app where plain `ctrl` does not copy and paste.

These go in `config.local` on Linux machines, **not** in the tracked config —
the file is shared with macOS, where `cmd` already does the job and `ctrl+c`
should stay an interrupt:

```
keybind = performable:ctrl+c=copy_to_clipboard
keybind = performable:ctrl+v=paste_from_clipboard
selection-clear-on-copy = true
```

`performable:` is what makes this safe, and it matters on both keys:

- **`ctrl+c`** only copies when something is selected. With nothing selected it
  passes through as the interrupt. `selection-clear-on-copy` drops the selection
  after copying, so a second `ctrl+c` always interrupts — without it, text left
  selected by `copy-on-select` would keep turning the interrupt into a copy.
- **`ctrl+v`** only pastes when the clipboard holds *text*. An image-only
  clipboard makes the bind not performable and the key passes through, which is
  how Claude Code still receives `ctrl+v` to paste a screenshot. This is the GTK
  runtime checking the clipboard formats before starting the paste; it was read
  in the source (`src/apprt/gtk/class/surface.zig`, 1.3.1), not assumed.

## Dead keys

`~ ^ \`` and `´` do not compose in Ghostty on Linux, while working everywhere
else. GTK's Wayland input module cannot handle dead keys at all — see
[ghostty#2981](https://github.com/ghostty-org/ghostty/issues/2981) and #8899.
`GTK_IM_MODULE=simple` switches to GTK's own built-in module, which can. It is
set in niri's `environment` block rather than on the Ghostty spawn, because
terminals also get launched from spotlight.

Single-instance is left **on**, which is worth explaining because the workaround
quoted in that issue disables it.

With single-instance on, the first Ghostty process serves every later window, so
a new terminal inherits that process's environment — which may be hours old. That
is why setting the variable appeared to do nothing: the running process predated
it, and `Mod+T` never started a new one. Disabling single-instance is how you
test the fix *without* logging out, not part of the fix.

`niri.service` is a systemd user unit, so niri's `environment` block is applied
at login, before anything is spawned. The first Ghostty process therefore already
has the variable and single-instance spreads it to every window. Turning it off
would only cost memory, since windows would stop sharing a process.

If dead keys ever stop working after a change here, check the running process
rather than the config:

```bash
tr '\0' '\n' < /proc/$(pgrep -x ghostty | head -1)/environ | grep GTK_IM_MODULE
```
