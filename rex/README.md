# rex

Config for [Rex](https://www.superlogical.com/rex/), stowed to `~/.config/rex`.
Agent setup (skill and SessionStart hook) comes from `rex skill setup
--session-naming`, not from here.

`init.lua` holds key bindings. `rex config reload` after editing.

`bg.lua` runs a command in a minimized floating pane in the current session.
If the command exits non-zero, the pane comes back up floating (not zoomed);
otherwise it stays minimized with its output kept. Dev servers stay minimized
until they crash. Start it with `rexbg` from `bin`:

```sh
rexbg go test ./...
rexbg npm run dev
```

It is a `rex do` script, not an `init.lua` action, because actions cannot wait
for events (`rex.wait` and `rex.on` only exist in scripts). `rexbg` starts it
in the background so the shell returns at once.
