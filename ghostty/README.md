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
