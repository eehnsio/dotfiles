# bin

Helper scripts symlinked into `~/.local/bin`.

`niri-cycle-app-windows` backs `Mod+§`. niri has no built-in equivalent because
it does not group windows by app.

niri spawns it by **absolute path**, not by name. niri is started by greetd, and
its `PATH` does not contain `~/.local/bin` — that entry comes from `.zshrc`,
which interactive shells read and niri does not.
