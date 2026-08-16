# tmux

Not a local multiplexer. Ghostty's native splits handle that, and they do it
better — this exists for the one thing a terminal emulator cannot do, which is
survive the connection dying.

Every setting here is aimed at a session on the other end of an SSH link,
usually reattached from a phone.

## The mobile constraints

`mouse on` is what makes swipe-to-scroll work. Without it a phone terminal has
no usable way to reach scrollback at all.

`status-position top` is not taste. A mobile terminal's keyboard bar covers the
bottom row, so a status line down there is invisible exactly when you are
looking for it. Move it back down in `~/.tmux.conf.local` if you want it at the
bottom on the Mac and only at the top on the servers.

## The prefix indicator

tmux does not acknowledge that the prefix key is down, so `Ctrl-b` feels broken
— you press it and nothing happens. `^B` lights up on the left for as long as
tmux is waiting for the next key.

The active window gets the same treatment. By default it is marked with a `*`,
which is effectively invisible once more than two windows are open.

## Why reverse instead of colours

The status line is deliberately bare, and both the prefix indicator and the
active window use `reverse` rather than fixed colours. That inverts whatever the
active theme already provides, so they stay legible under any theme — the same
reasoning as the ANSI indices in `lsd` and the zsh prompt, one step further.

That also means this file has no opinion about the `#7fc8ff` accent. It cannot
drift out of sync with the rest of the theme because it never names a colour.

## Host-specific

`~/.tmux.conf.local` is sourced last if it exists, the same pattern as
`~/.zshrc.local`. Edit that on the host, never `~/.tmux.conf` — it is a symlink
into this repo.
