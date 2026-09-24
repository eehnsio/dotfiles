# bin

Helper scripts symlinked into `~/.local/bin`.

`niri-cycle-app-windows` backs `Mod+§`. niri has no built-in equivalent because
it does not group windows by app.

`noctalia-rbw` backs `Mod+P`: it lists the Bitwarden vault in noctalia's own
launcher and copies the password. See the [rbw](../rbw/) package for why the
picker is a script and how the password stays out of clipboard history.

niri spawns both by **absolute path**, not by name. niri is started by greetd, and
its `PATH` does not contain `~/.local/bin` — that entry comes from `.zshrc`,
which interactive shells read and niri does not.
