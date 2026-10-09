# noctalia

Quickshell-based desktop shell for niri: bar, launcher, notifications, OSD, lock
screen and clipboard history. Linux only. It replaced DankMaterialShell in
September 2026; the DMS package is in the history, not here.

niri starts it with `spawn-at-startup "noctalia"` — it daemonises itself — and
drives it over `noctalia msg` (`bar-toggle`, `session lock`). The launcher is
not used: `Mod+Space` and `Mod+P` go to [rofi](../rofi/), which could be styled
the whole way.

## two config layers, and only one belongs here

Per `noctalia config export --help`:

1. every `*.toml` in `~/.config/noctalia/` ← this package
2. `~/.local/state/noctalia/settings.toml` ← **overrides** layer 1

The settings GUI writes `settings.toml`, so it wins for every key it has ever
touched. `zz-erik.toml` is therefore a base layer, not an override. That is the
point: the GUI never writes here, so the file can be versioned and survives
clicking around in the settings.

`settings.toml` is deliberately left out. It is state — rewritten constantly, and
carrying machine-specific things like the lock screen widget geometry per output
name. Versioning it would mean a merge conflict every time a checkbox moves.

`noctalia config export full` prints every key with its active value. Read it
instead of guessing key names; there is no `font_size`, and `[accessibility]
ui_scale` is the only lever that changes row height.

## the OSD popups you asked about

`[osd.kinds] lock_keys = false`. Caps Lock, Num Lock and Scroll Lock threw a
panel at the top of the screen (`[osd] position = "top_center"`) on every press,
which the keyboard's own LEDs already report.

The other kinds stay on: volume, brightness and media keys have no indicator of
their own, so their OSD is the only feedback. `[osd] enabled = false` kills all of
them at once.

## the palette

`source = "custom"` plus `custom_palette = "Drivis"` in `settings.toml` point at
`palettes/Drivis.json` here. Surface, variant, outline, text and error are the
same values the DMS theme carried, and `mHover` is DMS's `primaryContainer`.

`mPrimary` is `#7fc8ff`, the accent that `ghostty/themes/drivis` assigns to index
6 and niri to its focus ring. It arrived as `#5fa3d0`, a duller blue, which left
everything the shell paints a step quieter than the terminal beside it.

The `terminal` block inside `Drivis.json` does **not** follow that role
assignment — its green and magenta are Tokyo Night values, and blue and cyan sit
opposite to ghostty's roles. It is inert as long as `[theme.templates]` has
`enable_builtin_templates = false` and `builtin_ids = []`, because then nothing
writes terminal configs. Turn templates on and it will fight
`ghostty/themes/drivis`, which is the palette three other tools inherit.

`community_palette = "Oxocarbon"` and `wallpaper_scheme = "soft"` also sit in
`settings.toml` and do nothing while the source is `custom`.

## polkit

`polkit_agent = true`. DMS owned the polkit agent before, and after the shell
swap `polkitd` ran with no registered agent: GUI programs needing root failed
**silently**, because the daemon cannot draw a password dialog itself.

## reload

`noctalia msg config-reload` re-reads these files; the shell does not need a
restart. `noctalia config validate` checks them first.
