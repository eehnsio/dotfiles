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

That fix is invisible without `gtk-single-instance = false`, and the two belong
together. With single-instance on, the first Ghostty process serves every later
window, so a new terminal inherits an environment that may be hours old — a new
variable appears to do nothing until the last window closes and the process
finally exits. The workaround quoted in that issue includes
`--gtk-single-instance=false` for exactly this reason.

The cost is memory: windows no longer share a process.
