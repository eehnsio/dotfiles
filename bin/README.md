# bin

Helper scripts symlinked into `~/.local/bin`.

`niri-cycle-app-windows` backs `Mod+§`. niri has no built-in equivalent because
it does not group windows by app.

`rbw-pick` backs `Mod+P`: it lists the Bitwarden or Vaultwarden vault in rofi and
copies the password. See the [rbw](../rbw/) package for why it exists instead of
rofi-rbw, and how the password stays out of clipboard history.

`screenshot-region-save` backs `Mod+Shift+3` in umbriel: pick a region with
`slurp`, save it with `grim` to `~/Pictures/Screenshots`, same name pattern as
niri's `screenshot-path`. Nothing goes to the clipboard — that is
`Mod+Shift+4`, Noctalia's region screenshot.

The compositors spawn these by **absolute path**, not by name. They are started
by the greeter, and their `PATH` does not contain `~/.local/bin` — that entry
comes from `.zshrc`, which interactive shells read and compositors do not.
