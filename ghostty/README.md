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
