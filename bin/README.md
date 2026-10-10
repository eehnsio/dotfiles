# bin

Helper scripts symlinked into `~/.local/bin`.

`niri-cycle-app-windows` backs `Mod+§`. niri has no built-in equivalent because
it does not group windows by app.

`rbw-pick` backs `Mod+P`: it lists the Bitwarden or Vaultwarden vault in rofi and
types the login into the focused window, or copies it. See the [rbw](../rbw/) package for why it exists instead of
rofi-rbw, and how the password stays out of clipboard history.

niri spawns both by **absolute path**, not by name. niri is started by SDDM, and
its `PATH` does not contain `~/.local/bin` — that entry comes from `.zshrc`,
which interactive shells read and niri does not.
